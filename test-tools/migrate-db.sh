#!/bin/bash
# migrate-db.sh — 数据库迁移脚本
# 在服务启动后运行，补齐历史部署中缺失的表结构，并清理异常任务状态
# 用法: ./migrate-db.sh
#   或在 deploy.sh / setup-all.sh 末尾调用

set -e

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-root}"
MYSQL_CMD="docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS}"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[MIGRATE]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[MIGRATE]${NC} $*"; }
log_error() { echo -e "${RED}[MIGRATE]${NC} $*"; }

# 等待 MySQL 就绪
wait_for_mysql() {
    log_info "等待 MySQL 就绪..."
    local retries=30
    while ! $MYSQL_CMD -e "SELECT 1;" > /dev/null 2>&1; do
        retries=$((retries - 1))
        if [ $retries -le 0 ]; then
            log_error "MySQL 启动超时，迁移终止"
            exit 1
        fi
        sleep 2
    done
    log_info "MySQL 已就绪"
}

# 检查并创建表（如果不存在）
ensure_table() {
    local db="$1"
    local table="$2"
    local create_sql="$3"

    local exists
    exists=$($MYSQL_CMD -sN -e \
        "SELECT COUNT(*) FROM information_schema.tables \
         WHERE table_schema='${db}' AND table_name='${table}';" 2>/dev/null)

    if [ "${exists}" = "0" ]; then
        log_warn "表 ${db}.${table} 不存在，正在创建..."
        $MYSQL_CMD "${db}" -e "${create_sql}" 2>/dev/null
        log_info "✓ 已创建 ${db}.${table}"
    fi
}

# ──────────────────────────────────────────────
# 迁移1：在所有业务库中创建 data_requirement 系列表
# ──────────────────────────────────────────────
migrate_data_requirement() {
    log_info "迁移1: 检查 data_requirement 表..."

    local SQL_REQUIREMENT="
CREATE TABLE IF NOT EXISTS \`data_requirement\` (
  \`id\` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  \`requirement_code\` VARCHAR(64) NOT NULL COMMENT '需求编码',
  \`requirement_name\` VARCHAR(128) NOT NULL COMMENT '需求名称',
  \`requirement_desc\` TEXT COMMENT '需求描述',
  \`requirement_type\` VARCHAR(32) COMMENT '需求类型',
  \`data_fields\` TEXT COMMENT '所需数据字段(JSON格式)',
  \`data_volume\` BIGINT COMMENT '所需数据量',
  \`data_format\` VARCHAR(32) COMMENT '所需数据格式',
  \`priority\` TINYINT DEFAULT 0 COMMENT '优先级(0-低 1-中 2-高)',
  \`status\` TINYINT DEFAULT 0 COMMENT '状态(0-待匹配 1-已匹配 2-已完成 3-已关闭)',
  \`user_id\` BIGINT NOT NULL COMMENT '创建人用户ID',
  \`user_name\` VARCHAR(64) COMMENT '创建人用户名',
  \`organ_id\` BIGINT COMMENT '机构ID',
  \`organ_name\` VARCHAR(128) COMMENT '机构名称',
  \`start_date\` DATETIME COMMENT '需求开始日期',
  \`end_date\` DATETIME COMMENT '需求结束日期',
  \`remark\` VARCHAR(500) COMMENT '备注',
  \`is_del\` TINYINT DEFAULT 0 COMMENT '删除标记',
  \`create_date\` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  \`update_date\` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`uk_requirement_code\` (\`requirement_code\`),
  KEY \`idx_user_id\` (\`user_id\`),
  KEY \`idx_status\` (\`status\`),
  KEY \`idx_create_date\` (\`create_date\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求表';"

    local SQL_CONFIG="
CREATE TABLE IF NOT EXISTS \`data_requirement_config\` (
  \`id\` BIGINT NOT NULL AUTO_INCREMENT,
  \`config_key\` VARCHAR(64) NOT NULL,
  \`config_value\` TEXT NOT NULL,
  \`config_desc\` VARCHAR(255),
  \`config_type\` VARCHAR(32),
  \`is_enabled\` TINYINT DEFAULT 1,
  \`is_del\` TINYINT DEFAULT 0,
  \`create_date\` DATETIME DEFAULT CURRENT_TIMESTAMP,
  \`update_date\` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`uk_config_key\` (\`config_key\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求配置表';"

    local SQL_MATCH="
CREATE TABLE IF NOT EXISTS \`data_requirement_match\` (
  \`id\` BIGINT NOT NULL AUTO_INCREMENT,
  \`requirement_id\` BIGINT NOT NULL,
  \`resource_id\` BIGINT NOT NULL,
  \`match_score\` DECIMAL(5,2) DEFAULT 0.00,
  \`match_status\` TINYINT DEFAULT 0,
  \`match_type\` VARCHAR(32),
  \`match_details\` TEXT,
  \`is_del\` TINYINT DEFAULT 0,
  \`create_date\` DATETIME DEFAULT CURRENT_TIMESTAMP,
  \`update_date\` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (\`id\`),
  KEY \`idx_requirement_id\` (\`requirement_id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求匹配表';"

    for DB in privacy privacy1 privacy2 privacy3; do
        ensure_table "$DB" "data_requirement"       "$SQL_REQUIREMENT"
        ensure_table "$DB" "data_requirement_config" "$SQL_CONFIG"
        ensure_table "$DB" "data_requirement_match"  "$SQL_MATCH"
    done

    log_info "✓ 迁移1 完成"
}

# ──────────────────────────────────────────────
# 迁移2：清理服务重启后卡在"运行中"的僵尸任务
# 判断标准：task_state=2 且 update_date 超过 30 分钟未更新
# ──────────────────────────────────────────────
cleanup_stuck_tasks() {
    log_info "迁移2: 清理僵尸任务（运行中超过30分钟未更新）..."

    local CLEANUP_SQL="
UPDATE data_task
SET
    task_state   = 4,
    task_end_time = UNIX_TIMESTAMP() * 1000,
    task_error_msg = CONCAT(
        IFNULL(task_error_msg, ''),
        IF(task_error_msg IS NOT NULL AND task_error_msg != '', ' | ', ''),
        '服务重启时检测到异常：任务状态为运行中但超过30分钟无更新，已自动标记为失败'
    )
WHERE task_state = 2
  AND update_date < DATE_SUB(NOW(), INTERVAL 30 MINUTE);"

    local total=0
    for DB in privacy privacy1 privacy2 privacy3; do
        local count
        count=$($MYSQL_CMD -sN "$DB" -e \
            "SELECT COUNT(*) FROM data_task WHERE task_state=2 AND update_date < DATE_SUB(NOW(), INTERVAL 30 MINUTE);" \
            2>/dev/null || echo "0")

        if [ "${count:-0}" -gt 0 ]; then
            log_warn "在 ${DB} 中发现 ${count} 个僵尸任务，正在清理..."
            $MYSQL_CMD "$DB" -e "$CLEANUP_SQL" 2>/dev/null
            total=$((total + count))
        fi
    done

    if [ "$total" -gt 0 ]; then
        log_info "✓ 共清理 ${total} 个僵尸任务"
    else
        log_info "✓ 无僵尸任务"
    fi
}

# ──────────────────────────────────────────────
# 迁移3：修复 fusion 数据库中 organ_id 错误
# 将 test0001/test0002 的资源改为正确的节点 org UUID，
# 并在 fusion2/fusion3 中注册节点各自拥有的训练数据集
# ──────────────────────────────────────────────
fix_fusion_organ_ids() {
    log_info "迁移3: 修复 fusion 数据库 organ_id 配置..."

    local NODE1_ORG="550e8400-e29b-41d4-a716-446655440001"
    local NODE2_ORG="550e8400-e29b-41d4-a716-446655440002"
    local OLD_ORG1="000000000000000000000000test0001"
    local OLD_ORG2="000000000000000000000000test0002"

    # 修复 fusion1: 将 test0001/test0002 的 organ_id 更新为正确的 UUID
    $MYSQL_CMD -e "
        UPDATE fusion1.fusion_resource SET organ_id='${NODE1_ORG}' WHERE organ_id='${OLD_ORG1}';
        UPDATE fusion1.fusion_resource SET organ_id='${NODE2_ORG}' WHERE organ_id='${OLD_ORG2}';
        UPDATE fusion1.fusion_organ SET global_id='${NODE1_ORG}', global_name='API测试机构'
          WHERE global_id='${OLD_ORG1}';
        UPDATE fusion1.fusion_organ SET global_id='${NODE2_ORG}', global_name='PSI协作机构'
          WHERE global_id='${OLD_ORG2}';
    " 2>/dev/null && log_info "✓ fusion1 organ_id 已修复"

    # 在 fusion2 中注册 node1 拥有的训练数据集
    $MYSQL_CMD -e "
        INSERT IGNORE INTO fusion2.fusion_organ (global_id, global_name, register_time, is_del)
        VALUES ('${NODE1_ORG}', 'API测试机构', NOW(3), 0),
               ('${NODE2_ORG}', 'PSI协作机构', NOW(3), 0);

        INSERT IGNORE INTO fusion2.fusion_resource
          (resource_id, resource_name, resource_desc, resource_type, resource_auth_type,
           resource_rows_count, resource_column_count, resource_column_name_list,
           resource_contains_y, resource_y_rows_count, resource_y_ratio, resource_tag,
           organ_id, resource_hash_code, resource_state, user_name, is_del)
        VALUES
          ('demo0org0001-de7f2cb1-ef24-11f0-bac8-463ab87cfb66',
           '联邦LR训练数据_机构1_真实数据', '带标签的用户特征数据', 0, 1, 50, 5,
           'user_id,age,income,credit_score,label', 1, 50, 1.00, '联邦学习,LR',
           '${NODE1_ORG}', '4ce953e1a019be81f028781dd0ff0f76', 0, 'admin', 0),
          ('demo0org0001-9a9a1424-d8a6-473d-b300-2f7f5538edaa',
           '端到端测试_机构1_训练数据', '端到端测试使用的真实训练数据', 1, 1, 50, 5,
           NULL, 1, NULL, NULL, NULL, '${NODE1_ORG}', NULL, 0, NULL, 0);
    " 2>/dev/null && log_info "✓ fusion2 node1 数据集已注册"

    # 在 fusion3 中注册 node2 拥有的训练数据集
    $MYSQL_CMD -e "
        INSERT IGNORE INTO fusion3.fusion_organ (global_id, global_name, register_time, is_del)
        VALUES ('${NODE1_ORG}', 'API测试机构', NOW(3), 0),
               ('${NODE2_ORG}', 'PSI协作机构', NOW(3), 0);

        INSERT IGNORE INTO fusion3.fusion_resource
          (resource_id, resource_name, resource_desc, resource_type, resource_auth_type,
           resource_rows_count, resource_column_count, resource_column_name_list,
           resource_contains_y, resource_y_rows_count, resource_y_ratio, resource_tag,
           organ_id, resource_hash_code, resource_state, user_name, is_del)
        VALUES
          ('demo0org0001-e4fdfcf0-ef24-11f0-bac8-463ab87cfb66',
           '联邦LR训练数据_机构2_真实数据', '带标签的用户特征数据', 0, 1, 50, 5,
           'user_id,age,income,credit_score,label', 1, 50, 1.00, '联邦学习,LR',
           '${NODE2_ORG}', '9206c3955249615748f55fce76ce0530', 0, 'admin', 0),
          ('demo0org0001-563831ec-aba5-458a-9611-6c365d237624',
           '端到端测试_机构2_训练数据', '端到端测试使用的真实训练数据', 1, 1, 50, 5,
           NULL, 1, NULL, NULL, NULL, '${NODE2_ORG}', NULL, 0, NULL, 0);
    " 2>/dev/null && log_info "✓ fusion3 node2 数据集已注册"

    log_info "✓ 迁移3 完成"
}

# ──────────────────────────────────────────────
# 迁移4：修复 privacy.sys_organ 中缺失的 gateway URL
# demo0org0001 (node0 自身) 需要指向自己的 gateway 地址
# ──────────────────────────────────────────────
fix_sys_organ_gateway() {
    log_info "迁移4: 修复 sys_organ gateway URL..."

    # 从 Nacos 读取主机 gateway 地址（demo0 tenant 的 organ_info）
    local NODE0_GW
    NODE0_GW=$($MYSQL_CMD -sN -e "
        SELECT JSON_UNQUOTE(JSON_EXTRACT(content, '$.organGateway'))
        FROM nacos_config.config_info
        WHERE data_id='organ_info.json' AND tenant_id='demo0'
        LIMIT 1;" 2>/dev/null)

    if [ -n "$NODE0_GW" ] && [ "$NODE0_GW" != "NULL" ]; then
        $MYSQL_CMD -e "
            UPDATE privacy.sys_organ
            SET organ_gateway = '${NODE0_GW}'
            WHERE organ_id = '000000000000000000000000demo0org0001'
              AND organ_gateway IS NULL;
        " 2>/dev/null
        log_info "✓ demo0org0001 gateway 已设置: ${NODE0_GW}"
    else
        log_warn "无法从 Nacos 读取 demo0 gateway，跳过"
    fi

    log_info "✓ 迁移4 完成"
}

# ──────────────────────────────────────────────
# 迁移5：修复项目表中的 organ_id 引用
# data_project_resource 和 data_project_organ 表中仍有 test0001/test0002 引用
# ──────────────────────────────────────────────
fix_project_organ_ids() {
    log_info "迁移5: 修复项目表 organ_id..."

    local NODE0_ORG="550e8400-e29b-41d4-a716-446655440000"
    local NODE1_ORG="550e8400-e29b-41d4-a716-446655440001"
    local NODE2_ORG="550e8400-e29b-41d4-a716-446655440002"
    local OLD_DEMO="000000000000000000000000demo0org0001"
    local OLD_ORG1="000000000000000000000000test0001"
    local OLD_ORG2="000000000000000000000000test0002"

    # 修复 data_project_resource
    $MYSQL_CMD -e "
        UPDATE privacy.data_project_resource
        SET organ_id = '${NODE1_ORG}'
        WHERE organ_id = '${OLD_ORG1}';

        UPDATE privacy.data_project_resource
        SET organ_id = '${NODE2_ORG}'
        WHERE organ_id = '${OLD_ORG2}';

        UPDATE privacy.data_project_resource
        SET initiate_organ_id = '${NODE0_ORG}'
        WHERE initiate_organ_id = '${OLD_DEMO}';

        UPDATE privacy.data_project_resource
        SET initiate_organ_id = '${NODE1_ORG}'
        WHERE initiate_organ_id = '${OLD_ORG1}';

        UPDATE privacy.data_project_resource
        SET initiate_organ_id = '${NODE2_ORG}'
        WHERE initiate_organ_id = '${OLD_ORG2}';
    " 2>/dev/null && log_info "✓ data_project_resource 已修复"

    # 修复 data_project_organ
    $MYSQL_CMD -e "
        UPDATE privacy.data_project_organ
        SET organ_id = '${NODE1_ORG}'
        WHERE organ_id = '${OLD_ORG1}';

        UPDATE privacy.data_project_organ
        SET organ_id = '${NODE2_ORG}'
        WHERE organ_id = '${OLD_ORG2}';

        UPDATE privacy.data_project_organ
        SET initiate_organ_id = '${NODE0_ORG}'
        WHERE initiate_organ_id = '${OLD_DEMO}';

        UPDATE privacy.data_project_organ
        SET initiate_organ_id = '${NODE1_ORG}'
        WHERE initiate_organ_id = '${OLD_ORG1}';

        UPDATE privacy.data_project_organ
        SET initiate_organ_id = '${NODE2_ORG}'
        WHERE initiate_organ_id = '${OLD_ORG2}';
    " 2>/dev/null && log_info "✓ data_project_organ 已修复"

    log_info "✓ 迁移5 完成"
}

# ──────────────────────────────────────────────
# 主流程
# ──────────────────────────────────────────────
main() {
    echo ""
    log_info "========================================"
    log_info "  PrimiHub 数据库迁移开始"
    log_info "========================================"

    wait_for_mysql
    migrate_data_requirement
    cleanup_stuck_tasks
    fix_fusion_organ_ids
    fix_sys_organ_gateway
    fix_project_organ_ids

    log_info "========================================"
    log_info "  数据库迁移完成"
    log_info "========================================"
    echo ""
}

main "$@"
