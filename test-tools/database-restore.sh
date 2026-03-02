#!/bin/bash

###############################################################################
# PrimiHub - 数据库恢复脚本
# 
# 功能：
# - 从备份恢复数据库
# - 支持恢复单个或全部数据库
# - 恢复前自动备份当前数据
#
# 使用方法：
#   ./database-restore.sh <备份文件>
#   ./database-restore.sh <备份文件> --database primihub  # 恢复指定数据库
#   ./database-restore.sh --latest                         # 恢复最新备份
#
# 日期：2026-02-12
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups/database"
SPECIFIC_DB=""
BACKUP_FILE=""

# 显示帮助
show_help() {
    cat << EOF
PrimiHub 数据库恢复脚本

使用方法:
  $0 <备份文件>                    # 恢复指定备份
  $0 --latest                       # 恢复最新备份
  $0 <备份文件> --database <数据库名>  # 恢复指定数据库

选项:
  --database, -d    指定要恢复的数据库名
  --latest, -l      恢复最新的备份
  --help, -h        显示此帮助信息

示例:
  $0 backups/database/primihub_full_20260212-120000.sql.gz
  $0 --latest
  $0 --latest --database primihub

EOF
}

# 解析参数
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --database|-d)
            SPECIFIC_DB="$2"
            shift 2
            ;;
        --latest|-l)
            BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/*.sql.gz 2>/dev/null | head -1)
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            if [ -f "$1" ]; then
                BACKUP_FILE="$1"
            elif [ -f "${BACKUP_DIR}/$1" ]; then
                BACKUP_FILE="${BACKUP_DIR}/$1"
            fi
            shift
            ;;
    esac
done

# 检查备份文件
if [ -z "$BACKUP_FILE" ]; then
    log_error "未指定备份文件"
    echo ""
    echo "可用备份:"
    ls -lh "${BACKUP_DIR}"/*.sql.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ", " $6 " " $7 ")"}'
    echo ""
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    log_error "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

echo "============================================"
echo "PrimiHub 数据库恢复"
echo "============================================"
echo ""

log_info "备份文件: $BACKUP_FILE"
log_info "文件大小: $(du -h "$BACKUP_FILE" | cut -f1)"
echo ""

# 检测MySQL容器
log_info "检测MySQL容器..."
MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i mysql | head -1)

if [ -z "$MYSQL_CONTAINER" ]; then
    log_error "未找到运行中的MySQL容器"
    exit 1
fi

log_success "找到MySQL容器: $MYSQL_CONTAINER"
echo ""

# 获取MySQL配置
MYSQL_ROOT_PASSWORD=$(docker exec $MYSQL_CONTAINER printenv MYSQL_ROOT_PASSWORD 2>/dev/null || echo "primihub@123")
MYSQL_USER=$(docker exec $MYSQL_CONTAINER printenv MYSQL_USER 2>/dev/null || echo "root")

# 从备份文件名提取数据库名
BACKUP_BASENAME=$(basename "$BACKUP_FILE")
DB_NAME=$(echo "$BACKUP_BASENAME" | cut -d'_' -f1)

if [ -n "$SPECIFIC_DB" ]; then
    DB_NAME="$SPECIFIC_DB"
fi

log_info "目标数据库: $DB_NAME"
echo ""

# 确认恢复
log_warn "⚠️  警告: 此操作将覆盖数据库 '$DB_NAME' 的现有数据！"
echo ""
read -p "是否继续恢复？(输入 yes 确认): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "用户取消恢复"
    exit 0
fi

echo ""

# 恢复前备份当前数据
log_info "恢复前备份当前数据..."
PRE_RESTORE_BACKUP="${BACKUP_DIR}/${DB_NAME}_pre_restore_$(date +%Y%m%d-%H%M%S).sql"

docker exec $MYSQL_CONTAINER mysqldump \
    -u"$MYSQL_USER" \
    -p"$MYSQL_ROOT_PASSWORD" \
    --single-transaction \
    "$DB_NAME" > "$PRE_RESTORE_BACKUP" 2>/dev/null || log_warn "当前数据备份失败（数据库可能不存在）"

if [ -f "$PRE_RESTORE_BACKUP" ]; then
    gzip "$PRE_RESTORE_BACKUP"
    log_success "当前数据已备份: ${PRE_RESTORE_BACKUP}.gz"
else
    log_info "跳过当前数据备份（数据库可能不存在）"
fi

echo ""

# 解压备份文件
log_info "解压备份文件..."
TEMP_SQL="/tmp/restore_${DB_NAME}_$$.sql"

if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" > "$TEMP_SQL"
else
    cp "$BACKUP_FILE" "$TEMP_SQL"
fi

log_success "解压完成"
echo ""

# 确保数据库存在
log_info "确保数据库存在..."
docker exec $MYSQL_CONTAINER mysql -u"$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" \
    -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;" 2>/dev/null

log_success "数据库 $DB_NAME 已准备"
echo ""

# 执行恢复
log_info "开始恢复数据..."

if docker exec -i $MYSQL_CONTAINER mysql \
    -u"$MYSQL_USER" \
    -p"$MYSQL_ROOT_PASSWORD" \
    "$DB_NAME" < "$TEMP_SQL" 2>/dev/null; then
    
    log_success "数据恢复成功"
else
    log_error "数据恢复失败"
    rm -f "$TEMP_SQL"
    exit 1
fi

# 清理临时文件
rm -f "$TEMP_SQL"

echo ""

# 验证恢复
log_info "验证恢复结果..."
TABLE_COUNT=$(docker exec $MYSQL_CONTAINER mysql \
    -u"$MYSQL_USER" \
    -p"$MYSQL_ROOT_PASSWORD" \
    -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null)

log_success "数据库 $DB_NAME 包含 $TABLE_COUNT 个表"

echo ""
echo "============================================"
echo "✅ 恢复完成"
echo "============================================"
echo ""
echo "数据库: $DB_NAME"
echo "表数量: $TABLE_COUNT"
echo ""
echo "恢复前备份: ${PRE_RESTORE_BACKUP}.gz"
echo ""
echo "如需回滚到恢复前状态:"
echo "  ./database-restore.sh ${PRE_RESTORE_BACKUP}.gz"
echo ""

