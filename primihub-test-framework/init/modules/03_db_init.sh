#!/bin/bash
################################################################################
# 数据库初始化模块
# Database Initialization Module
#
# 功能: 初始化PrimiHub数据库结构和基础数据
# Features: Initialize PrimiHub database schema and base data
#
# 执行步骤:
# 1. 检查数据库连接
# 2. 备份现有数据库（可选）
# 3. 创建/重置数据库
# 4. 执行schema SQL文件
# 5. 执行权限数据SQL文件
# 6. 验证表结构完整性
################################################################################

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 加载配置
if [ -f "${SCRIPT_DIR}/../config/env.conf" ]; then
    source "${SCRIPT_DIR}/../config/env.conf"
else
    echo "[ERROR] Configuration file not found: ${SCRIPT_DIR}/../config/env.conf"
    exit 1
fi

# 创建日志目录
mkdir -p "${PROJECT_ROOT}/logs"
LOG_FILE="${PROJECT_ROOT}/logs/db_init_$(date +%Y%m%d_%H%M%S).log"

################################################################################
# 日志函数
################################################################################
log_info() {
    echo "[INFO] [$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[WARN] [$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] [$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" >&2
}

log_success() {
    echo "[SUCCESS] [$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# MySQL命令封装
################################################################################
mysql_exec() {
    local sql="$1"
    mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
          --default-character-set=utf8mb4 \
          -e "$sql" 2>&1 | tee -a "$LOG_FILE"
}

mysql_exec_file() {
    local sql_file="$1"
    local database="${2:-}"

    if [ -n "$database" ]; then
        mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
              --default-character-set=utf8mb4 \
              "$database" < "$sql_file" 2>&1 | tee -a "$LOG_FILE"
    else
        mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
              --default-character-set=utf8mb4 \
              < "$sql_file" 2>&1 | tee -a "$LOG_FILE"
    fi
}

################################################################################
# 1. 检查数据库连接
################################################################################
check_database_connection() {
    log_info "检查数据库连接..."

    if ! mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
         -e "SELECT 1" &>/dev/null; then
        log_error "无法连接到数据库 ${DB_HOST}:${DB_PORT}"
        log_error "请检查数据库服务是否运行，用户名和密码是否正确"
        return 1
    fi

    log_success "数据库连接成功"
    return 0
}

################################################################################
# 2. 备份现有数据库
################################################################################
backup_database() {
    if [ "${ENABLE_DB_BACKUP}" != "true" ]; then
        log_info "跳过数据库备份（配置中已禁用）"
        return 0
    fi

    # 检查数据库是否存在
    local db_exists=$(mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
                      -e "SHOW DATABASES LIKE '${DB_NAME}'" 2>/dev/null | grep -c "${DB_NAME}" || true)

    if [ "$db_exists" -eq 0 ]; then
        log_info "数据库 ${DB_NAME} 不存在，跳过备份"
        return 0
    fi

    log_info "开始备份数据库 ${DB_NAME}..."

    # 创建备份目录
    local backup_dir="${PROJECT_ROOT}/backups"
    mkdir -p "$backup_dir"

    # 备份文件名
    local backup_file="${backup_dir}/${DB_NAME}_backup_$(date +%Y%m%d_%H%M%S).sql"

    # 执行备份
    if mysqldump -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
                 --default-character-set=utf8mb4 \
                 --single-transaction \
                 --routines \
                 --triggers \
                 --events \
                 "${DB_NAME}" > "$backup_file" 2>>"$LOG_FILE"; then
        log_success "数据库备份成功: $backup_file"

        # 清理旧备份
        cleanup_old_backups "$backup_dir"
    else
        log_warn "数据库备份失败，继续执行初始化..."
    fi
}

cleanup_old_backups() {
    local backup_dir="$1"
    local retention_days="${BACKUP_RETENTION_DAYS:-7}"

    log_info "清理 ${retention_days} 天前的备份文件..."
    find "$backup_dir" -name "${DB_NAME}_backup_*.sql" -mtime +"$retention_days" -delete 2>>"$LOG_FILE" || true
}

################################################################################
# 3. 创建/重置数据库
################################################################################
create_database() {
    log_info "创建/重置数据库 ${DB_NAME}..."

    if [ "${CLEAN_EXISTING_DATA}" = "true" ]; then
        log_warn "将删除现有数据库 ${DB_NAME}..."
        mysql_exec "DROP DATABASE IF EXISTS \`${DB_NAME}\`"
    fi

    # 创建数据库
    mysql_exec "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
                DEFAULT CHARACTER SET utf8mb4
                DEFAULT COLLATE utf8mb4_general_ci"

    log_success "数据库 ${DB_NAME} 创建成功"
}

################################################################################
# 4. 执行SQL文件
################################################################################
execute_sql_files_in_dir() {
    local sql_dir="$1"
    local dir_name=$(basename "$sql_dir")

    if [ ! -d "$sql_dir" ]; then
        log_warn "SQL目录不存在: $sql_dir"
        return 0
    fi

    log_info "执行 ${dir_name} 目录下的SQL文件..."

    local sql_files=($(ls -1 "$sql_dir"/*.sql 2>/dev/null | sort))

    if [ ${#sql_files[@]} -eq 0 ]; then
        log_warn "${dir_name} 目录下没有SQL文件"
        return 0
    fi

    local total=${#sql_files[@]}
    local current=0

    for sql_file in "${sql_files[@]}"; do
        current=$((current + 1))
        local file_name=$(basename "$sql_file")

        log_info "[$current/$total] 执行: $file_name"

        if mysql_exec_file "$sql_file" "${DB_NAME}"; then
            log_success "[$current/$total] $file_name 执行成功"
        else
            log_error "[$current/$total] $file_name 执行失败"
            return 1
        fi
    done

    log_success "${dir_name} 目录所有SQL文件执行完成"
}

################################################################################
# 5. 验证表结构
################################################################################
verify_database_schema() {
    log_info "验证数据库表结构..."

    local table_count=$(mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
                        -sN -e "SELECT COUNT(*) FROM information_schema.tables
                                WHERE table_schema = '${DB_NAME}'" 2>>"$LOG_FILE")

    log_info "数据库中共有 ${table_count} 个表"

    if [ "$table_count" -lt 10 ]; then
        log_warn "表数量少于预期（期望至少10个表），可能初始化不完整"
        return 1
    fi

    # 检查核心表是否存在
    local core_tables=("sys_user" "sys_role" "sys_auth" "data_project" "data_resource" "data_task")

    for table in "${core_tables[@]}"; do
        local exists=$(mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" \
                       -sN -e "SELECT COUNT(*) FROM information_schema.tables
                               WHERE table_schema = '${DB_NAME}'
                               AND table_name = '${table}'" 2>>"$LOG_FILE")

        if [ "$exists" -eq 1 ]; then
            log_info "✓ 核心表 ${table} 存在"
        else
            log_error "✗ 核心表 ${table} 不存在"
            return 1
        fi
    done

    log_success "数据库表结构验证通过"
}

################################################################################
# 主函数
################################################################################
main() {
    log_info "================================"
    log_info "开始数据库初始化"
    log_info "================================"
    log_info "数据库主机: ${DB_HOST}:${DB_PORT}"
    log_info "数据库名称: ${DB_NAME}"
    log_info "数据库用户: ${DB_USER}"
    log_info "================================"

    # 1. 检查数据库连接
    if ! check_database_connection; then
        exit 1
    fi

    # 2. 备份现有数据库
    backup_database

    # 3. 创建/重置数据库
    create_database

    # 4. 执行schema SQL文件
    local schema_dir="${SCRIPT_DIR}/../sql/schema"
    execute_sql_files_in_dir "$schema_dir"

    # 5. 执行权限数据SQL文件
    local permissions_dir="${SCRIPT_DIR}/../sql/permissions"
    execute_sql_files_in_dir "$permissions_dir"

    # 6. 验证表结构
    verify_database_schema

    log_info "================================"
    log_success "数据库初始化完成"
    log_info "日志文件: $LOG_FILE"
    log_info "================================"
}

# 执行主函数
main "$@"
