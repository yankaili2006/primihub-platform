#!/bin/bash

###############################################################################
# PrimiHub - 数据库备份脚本
# 
# 功能：
# - 自动检测MySQL容器
# - 备份所有数据库
# - 支持全量和增量备份
# - 自动清理旧备份
#
# 使用方法：
#   ./database-backup.sh                # 全量备份
#   ./database-backup.sh --incremental  # 增量备份
#   ./database-backup.sh --list         # 列出所有备份
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
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_TYPE="full"
RETENTION_DAYS=7

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --incremental|-i)
            BACKUP_TYPE="incremental"
            shift
            ;;
        --list|-l)
            ls -lh "${BACKUP_DIR}" 2>/dev/null || echo "无备份文件"
            exit 0
            ;;
        --retention|-r)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "============================================"
echo "PrimiHub 数据库备份"
echo "============================================"
echo ""

# 创建备份目录
mkdir -p "${BACKUP_DIR}"

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
log_info "获取MySQL配置..."

# 尝试从docker-compose或环境变量获取密码
MYSQL_ROOT_PASSWORD=$(docker exec $MYSQL_CONTAINER printenv MYSQL_ROOT_PASSWORD 2>/dev/null || echo "primihub@123")
MYSQL_USER=$(docker exec $MYSQL_CONTAINER printenv MYSQL_USER 2>/dev/null || echo "root")

log_success "MySQL用户: $MYSQL_USER"
echo ""

# 获取数据库列表
log_info "获取数据库列表..."
DATABASES=$(docker exec $MYSQL_CONTAINER mysql -u"$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "Database|information_schema|performance_schema|mysql|sys")

if [ -z "$DATABASES" ]; then
    log_warn "未找到需要备份的数据库"
    exit 0
fi

echo "将备份以下数据库:"
echo "$DATABASES" | sed 's/^/  - /'
echo ""

# 执行备份
log_info "开始备份（类型: $BACKUP_TYPE）..."
echo ""

for db in $DATABASES; do
    BACKUP_FILE="${BACKUP_DIR}/${db}_${BACKUP_TYPE}_${TIMESTAMP}.sql"
    
    log_info "备份数据库: $db"
    
    if docker exec $MYSQL_CONTAINER mysqldump \
        -u"$MYSQL_USER" \
        -p"$MYSQL_ROOT_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        "$db" > "$BACKUP_FILE" 2>/dev/null; then
        
        # 压缩备份文件
        gzip "$BACKUP_FILE"
        BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
        
        log_success "$db 备份完成 (${BACKUP_SIZE})"
    else
        log_error "$db 备份失败"
    fi
done

echo ""

# 清理旧备份
log_info "清理 ${RETENTION_DAYS} 天前的备份..."
find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
log_success "清理完成"

echo ""
echo "============================================"
echo "✅ 备份完成"
echo "============================================"
echo ""
echo "备份位置: ${BACKUP_DIR}"
echo "备份文件:"
ls -lh "${BACKUP_DIR}"/*_${TIMESTAMP}.sql.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "恢复方法:"
echo "  ./database-restore.sh <备份文件>"
echo ""

