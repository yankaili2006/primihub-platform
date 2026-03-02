#!/bin/bash

# =============================================================================
# PrimiHub 数据库管理工具
# =============================================================================
# 用途: 统一的数据库备份、恢复、验证和故障排查工具
# 用法: bash database.sh [命令]
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 数据库配置
MYSQL_ROOT_PASSWORD="root"
MYSQL_USER="primihub"
MYSQL_PASSWORD="primihub@123"
DATABASES=("nacos_config" "privacy1" "privacy2" "privacy3")

# 日志函数
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查MySQL容器
check_mysql() {
    if ! docker ps --filter "name=mysql" --filter "status=running" --format "{{.Names}}" | grep -q "mysql"; then
        log_error "MySQL 容器未运行"
        echo "请先启动: docker compose up -d mysql"
        exit 1
    fi
}

# 等待MySQL就绪
wait_mysql() {
    echo -n "等待 MySQL 就绪"
    for i in $(seq 1 30); do
        if docker exec mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" --silent 2>/dev/null; then
            echo ""
            return 0
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    log_error "MySQL 服务超时"
    return 1
}

# =============================================================================
# 备份命令
# =============================================================================
cmd_backup() {
    echo "============================================"
    echo "数据库备份"
    echo "============================================"
    echo ""

    check_mysql

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$SCRIPT_DIR/database-backup-${TIMESTAMP}"
    mkdir -p "$BACKUP_DIR"

    log_info "备份目录: $BACKUP_DIR"
    echo ""

    BACKUP_COUNT=0
    for db in "${DATABASES[@]}"; do
        echo -n "  备份 $db ... "
        BACKUP_FILE="$BACKUP_DIR/${db}.sql"

        if docker exec mysql mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" \
            --single-transaction --routines --triggers \
            "$db" > "$BACKUP_FILE" 2>/dev/null; then
            SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
            echo "完成 ($SIZE)"
            ((BACKUP_COUNT++))
        else
            echo "失败"
            rm -f "$BACKUP_FILE"
        fi
    done

    echo ""
    if [ $BACKUP_COUNT -gt 0 ]; then
        # 压缩
        tar czf "${BACKUP_DIR}.tar.gz" -C "$SCRIPT_DIR" "$(basename "$BACKUP_DIR")"
        rm -rf "$BACKUP_DIR"
        ARCHIVE_SIZE=$(du -h "${BACKUP_DIR}.tar.gz" | cut -f1)
        log_info "备份完成: ${BACKUP_DIR}.tar.gz ($ARCHIVE_SIZE)"
    else
        log_error "没有数据库被备份"
        rm -rf "$BACKUP_DIR"
        exit 1
    fi
}

# =============================================================================
# 恢复命令
# =============================================================================
cmd_restore() {
    echo "============================================"
    echo "数据库恢复"
    echo "============================================"
    echo ""

    check_mysql

    # 查找备份文件
    BACKUP_FILE="$1"

    if [ -z "$BACKUP_FILE" ]; then
        # 列出可用备份
        BACKUPS=$(find "$SCRIPT_DIR" -maxdepth 1 -name "database-backup-*.tar.gz" 2>/dev/null | sort -r)
        if [ -z "$BACKUPS" ]; then
            log_error "未找到备份文件"
            exit 1
        fi

        echo "可用备份:"
        i=1
        for f in $BACKUPS; do
            echo "  $i) $(basename "$f") ($(du -h "$f" | cut -f1))"
            ((i++))
        done
        echo ""
        read -p "选择备份编号: " choice
        BACKUP_FILE=$(echo "$BACKUPS" | sed -n "${choice}p")
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "备份文件不存在: $BACKUP_FILE"
        exit 1
    fi

    log_warn "此操作将覆盖当前数据库数据！"
    read -p "确认恢复? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "已取消"
        exit 0
    fi

    # 解压并恢复
    TEMP_DIR=$(mktemp -d)
    tar xzf "$BACKUP_FILE" -C "$TEMP_DIR"
    BACKUP_DIR=$(ls "$TEMP_DIR")

    echo ""
    for sql_file in "$TEMP_DIR/$BACKUP_DIR"/*.sql; do
        if [ -f "$sql_file" ]; then
            db_name=$(basename "$sql_file" .sql)
            echo -n "  恢复 $db_name ... "
            if docker exec -i mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$db_name" < "$sql_file" 2>/dev/null; then
                echo "完成"
            else
                echo "失败"
            fi
        fi
    done

    rm -rf "$TEMP_DIR"
    echo ""
    log_info "恢复完成"
}

# =============================================================================
# 验证命令
# =============================================================================
cmd_verify() {
    echo "============================================"
    echo "数据库验证"
    echo "============================================"
    echo ""

    check_mysql
    wait_mysql

    PASSED=0
    FAILED=0

    # 检查数据库
    echo "检查数据库:"
    for db in "${DATABASES[@]}"; do
        if docker exec mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $db" 2>/dev/null; then
            TABLE_COUNT=$(docker exec mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -D "$db" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null)
            echo -e "  ${GREEN}✓${NC} $db ($TABLE_COUNT 张表)"
            ((PASSED++))
        else
            echo -e "  ${RED}✗${NC} $db 不存在"
            ((FAILED++))
        fi
    done

    echo ""
    echo "检查用户权限:"
    if docker exec mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" 2>/dev/null >/dev/null; then
        echo -e "  ${GREEN}✓${NC} 用户 $MYSQL_USER 可连接"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} 用户 $MYSQL_USER 连接失败"
        ((FAILED++))
    fi

    echo ""
    echo "────────────────────────────────────────────"
    echo -e "通过: ${GREEN}$PASSED${NC}  失败: ${RED}$FAILED${NC}"

    if [ $FAILED -gt 0 ]; then
        exit 1
    fi
}

# =============================================================================
# 状态命令
# =============================================================================
cmd_status() {
    echo "============================================"
    echo "数据库状态"
    echo "============================================"
    echo ""

    # 容器状态
    echo "容器状态:"
    if docker ps --filter "name=mysql" --filter "status=running" --format "{{.Names}}" | grep -q "mysql"; then
        STATUS=$(docker ps --filter "name=mysql" --format "{{.Status}}")
        echo -e "  ${GREEN}✓${NC} MySQL 运行中 ($STATUS)"
    else
        echo -e "  ${RED}✗${NC} MySQL 未运行"
        exit 1
    fi

    echo ""
    echo "数据库列表:"
    docker exec mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -N -e "SHOW DATABASES" 2>/dev/null | grep -v -E "^(information_schema|performance_schema|mysql|sys)$" | while read db; do
        echo "  - $db"
    done

    echo ""
    echo "连接信息:"
    echo "  地址: localhost:3306"
    echo "  Root密码: $MYSQL_ROOT_PASSWORD"
    echo "  用户: $MYSQL_USER"
    echo "  密码: $MYSQL_PASSWORD"
}

# =============================================================================
# Shell命令
# =============================================================================
cmd_shell() {
    check_mysql
    echo "进入 MySQL Shell (输入 exit 退出)"
    echo ""
    docker exec -it mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD"
}

# =============================================================================
# 日志命令
# =============================================================================
cmd_logs() {
    LINES="${1:-100}"
    docker logs --tail "$LINES" mysql
}

# =============================================================================
# 重置命令
# =============================================================================
cmd_reset() {
    log_warn "此操作将删除所有数据库数据！"
    read -p "确认重置? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "已取消"
        exit 0
    fi

    echo ""
    log_info "停止服务..."
    docker compose down 2>/dev/null || true

    log_info "删除数据..."
    sudo rm -rf data/mysql/*

    log_info "启动 MySQL..."
    docker compose up -d mysql

    log_info "等待初始化 (60秒)..."
    sleep 60

    cmd_verify
}

# =============================================================================
# 帮助
# =============================================================================
show_help() {
    echo "PrimiHub 数据库管理工具"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  backup              备份所有数据库"
    echo "  restore [文件]      从备份恢复数据库"
    echo "  verify              验证数据库初始化"
    echo "  status              查看数据库状态"
    echo "  shell               进入 MySQL Shell"
    echo "  logs [行数]         查看 MySQL 日志"
    echo "  reset               重置数据库 (危险)"
    echo "  help                显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 backup"
    echo "  $0 restore database-backup-20240114.tar.gz"
    echo "  $0 verify"
    echo "  $0 logs 200"
}

# =============================================================================
# 主入口
# =============================================================================
case "${1:-help}" in
    backup)
        cmd_backup
        ;;
    restore)
        cmd_restore "$2"
        ;;
    verify)
        cmd_verify
        ;;
    status)
        cmd_status
        ;;
    shell)
        cmd_shell
        ;;
    logs)
        cmd_logs "$2"
        ;;
    reset)
        cmd_reset
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
