#!/bin/bash

# =============================================================================
# PrimiHub 数据库验证脚本
# =============================================================================
# 功能：
#   1. 验证所有数据库是否正确创建
#   2. 验证数据库表结构
#   3. 验证数据库用户权限
#   4. 验证 Nacos 配置数据
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# MySQL 连接信息
MYSQL_CONTAINER="mysql"
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASS="root"
MYSQL_USER="primihub"
MYSQL_PASS="primihub@123"

# 必需的数据库列表
REQUIRED_DATABASES=(
    "nacos_config"
    "privacy1"
    "privacy2"
    "privacy3"
)

# 可选的数据库列表（fusion 数据库）
OPTIONAL_DATABASES=(
    "fusion1"
    "fusion2"
    "fusion3"
)

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              PrimiHub 数据库验证工具                             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# 检查 MySQL 容器状态
# =============================================================================
log_info "检查 MySQL 容器状态..."

if ! docker ps --filter "name=^${MYSQL_CONTAINER}$" --filter "status=running" -q | grep -q .; then
    log_error "MySQL 容器未运行"
    echo ""
    echo "请先启动 MySQL 容器:"
    echo "  docker compose up -d mysql"
    exit 1
fi

log_success "MySQL 容器运行正常"

# =============================================================================
# 验证数据库连接
# =============================================================================
log_info "验证数据库连接..."

if ! docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -e "SELECT 1" &>/dev/null; then
    log_error "无法连接到 MySQL 数据库"
    exit 1
fi

log_success "数据库连接正常"

# =============================================================================
# 验证必需数据库
# =============================================================================
echo ""
log_info "验证必需数据库..."

MISSING_DBS=()
for db in "${REQUIRED_DATABASES[@]}"; do
    if docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -e "USE $db" 2>/dev/null; then
        # 获取表数量
        TABLE_COUNT=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -N -e \
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}✓${NC} $db ($TABLE_COUNT 张表)"
    else
        echo -e "  ${RED}✗${NC} $db (不存在)"
        MISSING_DBS+=("$db")
    fi
done

if [ ${#MISSING_DBS[@]} -gt 0 ]; then
    echo ""
    log_error "缺少 ${#MISSING_DBS[@]} 个必需数据库: ${MISSING_DBS[*]}"
    exit 1
fi

log_success "所有必需数据库验证通过"

# =============================================================================
# 验证可选数据库
# =============================================================================
echo ""
log_info "验证可选数据库 (fusion)..."

MISSING_FUSION_DBS=()
for db in "${OPTIONAL_DATABASES[@]}"; do
    if docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -e "USE $db" 2>/dev/null; then
        TABLE_COUNT=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -N -e \
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}✓${NC} $db ($TABLE_COUNT 张表)"
    else
        echo -e "  ${YELLOW}○${NC} $db (不存在，将自动创建)"
        MISSING_FUSION_DBS+=("$db")
    fi
done

# =============================================================================
# 创建缺失的 fusion 数据库
# =============================================================================
if [ ${#MISSING_FUSION_DBS[@]} -gt 0 ]; then
    echo ""
    log_info "创建缺失的 fusion 数据库..."
    
    for db in "${MISSING_FUSION_DBS[@]}"; do
        if docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -e \
            "CREATE DATABASE IF NOT EXISTS \`$db\` CHARACTER SET utf8 COLLATE utf8_bin;" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} 已创建 $db"
        else
            log_warn "创建 $db 失败"
        fi
    done
fi

# =============================================================================
# 验证数据库用户权限
# =============================================================================
echo ""
log_info "验证数据库用户权限..."

# 检查 primihub 用户是否存在
USER_EXISTS=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -N -e \
    "SELECT COUNT(*) FROM mysql.user WHERE user='$MYSQL_USER'" 2>/dev/null || echo "0")

if [ "$USER_EXISTS" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} 用户 $MYSQL_USER 存在"
    
    # 验证用户权限
    for db in "${REQUIRED_DATABASES[@]}" "${OPTIONAL_DATABASES[@]}"; do
        if docker exec $MYSQL_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASS -e "USE $db" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $MYSQL_USER 可以访问 $db"
        else
            echo -e "  ${YELLOW}○${NC} $MYSQL_USER 无法访问 $db"
        fi
    done
else
    log_warn "用户 $MYSQL_USER 不存在"
fi

# =============================================================================
# 验证 Nacos 配置数据
# =============================================================================
echo ""
log_info "验证 Nacos 配置数据..."

# 检查 config_info 表
CONFIG_COUNT=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -N -e \
    "SELECT COUNT(*) FROM nacos_config.config_info" 2>/dev/null || echo "0")

if [ "$CONFIG_COUNT" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} Nacos 配置表包含 $CONFIG_COUNT 条记录"
    
    # 检查各个命名空间的配置
    for tenant in "demo0" "demo1" "demo2"; do
        TENANT_CONFIG=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -N -e \
            "SELECT COUNT(*) FROM nacos_config.config_info WHERE tenant_id='$tenant'" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}✓${NC} 命名空间 $tenant: $TENANT_CONFIG 条配置"
    done
else
    log_warn "Nacos 配置表为空"
fi

# =============================================================================
# 验证关键表结构
# =============================================================================
echo ""
log_info "验证关键表结构..."

# 验证 privacy1 数据库的关键表
PRIVACY_TABLES=(
    "data_model"
    "data_resource"
    "data_organ"
    "sys_user"
    "sys_role"
)

for table in "${PRIVACY_TABLES[@]}"; do
    if docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -e \
        "DESC privacy1.$table" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} privacy1.$table"
    else
        echo -e "  ${YELLOW}○${NC} privacy1.$table (不存在)"
    fi
done

# =============================================================================
# 数据库大小统计
# =============================================================================
echo ""
log_info "数据库大小统计..."

for db in "${REQUIRED_DATABASES[@]}"; do
    DB_SIZE=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASS -N -e \
        "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) 
         FROM information_schema.tables 
         WHERE table_schema='$db'" 2>/dev/null || echo "0")
    echo -e "  $db: ${DB_SIZE} MB"
done

# =============================================================================
# 完成
# =============================================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    验证完成                                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

log_success "数据库验证完成"
echo ""
echo "下一步操作:"
echo "  - 查看数据库详情: docker exec mysql mysql -uroot -proot -e 'SHOW DATABASES'"
echo "  - 查看表结构: docker exec mysql mysql -uroot -proot nacos_config -e 'SHOW TABLES'"
echo "  - 备份数据库: ./backup-database.sh"
echo ""
