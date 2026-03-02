#!/bin/bash

# =============================================================================
# PrimiHub 清理脚本
# =============================================================================
# 功能：
#   1. 停止所有服务
#   2. 删除容器
#   3. 清理数据（可选）
#   4. 清理镜像（可选）
#   5. 完全卸载
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 清理级别
CLEANUP_LEVEL="soft"  # soft, hard, complete
BACKUP_BEFORE_CLEAN=false
FORCE=false

# 确定 docker compose 命令
if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# =============================================================================
# 显示横幅
# =============================================================================

show_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              PrimiHub 清理工具                                   ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

# =============================================================================
# 显示帮助
# =============================================================================

show_help() {
    cat <<EOF
PrimiHub 清理工具

用法: $0 [选项]

清理级别:
  --soft              软清理：仅停止容器（默认）
  --hard              硬清理：停止容器 + 删除容器
  --complete          完全清理：停止容器 + 删除容器 + 删除数据 + 删除镜像

选项:
  --backup            清理前备份数据库
  --force             跳过确认提示
  -h, --help          显示帮助信息

示例:
  $0                  软清理（仅停止服务）
  $0 --hard           删除容器但保留数据
  $0 --complete       完全清理所有内容
  $0 --hard --backup  删除容器前先备份数据

警告:
  --complete 将删除所有数据，包括数据库、配置等！
  建议先使用 --backup 选项备份数据。
EOF
}

# =============================================================================
# 参数解析
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --soft)
            CLEANUP_LEVEL="soft"
            shift
            ;;
        --hard)
            CLEANUP_LEVEL="hard"
            shift
            ;;
        --complete)
            CLEANUP_LEVEL="complete"
            shift
            ;;
        --backup)
            BACKUP_BEFORE_CLEAN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# =============================================================================
# 确认函数
# =============================================================================

confirm() {
    local message=$1

    if [ "$FORCE" = true ]; then
        return 0
    fi

    echo ""
    echo -e "${YELLOW}$message${NC}"
    read -p "确认继续? (yes/no): " -r
    echo

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_warn "操作已取消"
        exit 0
    fi
}

# =============================================================================
# 备份数据
# =============================================================================

backup_data() {
    if [ "$BACKUP_BEFORE_CLEAN" = true ]; then
        echo ""
        log_info "备份数据库..."

        if [ -f "./backup-database.sh" ]; then
            if ./backup-database.sh; then
                log_success "数据库备份完成"
            else
                log_warn "数据库备份失败，但继续清理"
            fi
        else
            log_warn "备份脚本不存在，跳过备份"
        fi
    fi
}

# =============================================================================
# 软清理：仅停止服务
# =============================================================================

soft_cleanup() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  软清理：停止所有服务                                           ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    confirm "这将停止所有 PrimiHub 服务，但保留容器和数据。"

    log_info "停止所有服务..."
    if $DOCKER_COMPOSE stop; then
        log_success "所有服务已停止"
    else
        log_error "停止服务失败"
        return 1
    fi

    echo ""
    log_info "当前状态:"
    $DOCKER_COMPOSE ps -a

    echo ""
    log_success "软清理完成"
    echo ""
    echo "重新启动服务:"
    echo "  $DOCKER_COMPOSE start"
    echo "  或"
    echo "  ./deploy.sh"
}

# =============================================================================
# 硬清理：停止并删除容器
# =============================================================================

hard_cleanup() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  硬清理：停止并删除容器                                         ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    confirm "这将停止并删除所有容器，但保留数据卷。"

    backup_data

    log_info "停止并删除所有容器..."
    if $DOCKER_COMPOSE down; then
        log_success "所有容器已删除"
    else
        log_error "删除容器失败"
        return 1
    fi

    echo ""
    log_info "清理未使用的网络..."
    docker network prune -f

    echo ""
    log_success "硬清理完成"
    echo ""
    echo "数据已保留在以下目录:"
    echo "  - data/mysql/"
    echo "  - data/redis/"
    echo "  - data/nacos/"
    echo ""
    echo "重新部署:"
    echo "  ./deploy.sh"
}

# =============================================================================
# 完全清理：删除所有内容
# =============================================================================

complete_cleanup() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  完全清理：删除所有容器、数据和镜像                             ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${RED}警告：这将删除所有数据，包括数据库、配置等！${NC}"
    echo -e "${RED}此操作不可恢复！${NC}"
    echo ""

    confirm "确认要完全清理所有内容吗？"

    backup_data

    # 1. 停止并删除容器
    echo ""
    log_info "停止并删除所有容器..."
    $DOCKER_COMPOSE down -v

    # 2. 删除数据目录
    echo ""
    log_info "删除数据目录..."

    if [ -d "data/mysql" ]; then
        log_info "删除 MySQL 数据..."
        rm -rf data/mysql/*
    fi

    if [ -d "data/redis" ]; then
        log_info "删除 Redis 数据..."
        rm -rf data/redis/*
    fi

    if [ -d "data/nacos" ]; then
        log_info "删除 Nacos 数据..."
        rm -rf data/nacos/*
    fi

    if [ -d "data/rabbitmq" ]; then
        log_info "删除 RabbitMQ 数据..."
        rm -rf data/rabbitmq*
    fi

    # 3. 删除日志
    if [ -d "logs" ]; then
        log_info "删除日志文件..."
        rm -rf logs/*
    fi

    # 4. 清理 Docker 资源
    echo ""
    log_info "清理 Docker 资源..."

    # 删除 PrimiHub 相关镜像
    log_info "删除 PrimiHub 镜像..."
    docker images | grep primihub | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true

    # 清理未使用的镜像
    log_info "清理未使用的镜像..."
    docker image prune -f

    # 清理未使用的网络
    log_info "清理未使用的网络..."
    docker network prune -f

    # 清理未使用的卷
    log_info "清理未使用的卷..."
    docker volume prune -f

    echo ""
    log_success "完全清理完成"
    echo ""

    if [ "$BACKUP_BEFORE_CLEAN" = true ]; then
        echo "数据备份位置:"
        echo "  backups/database/"
        echo ""
    fi

    echo "重新部署:"
    echo "  ./setup-all.sh"
}

# =============================================================================
# 显示清理前状态
# =============================================================================

show_current_status() {
    echo ""
    log_info "当前状态:"
    echo ""

    # 容器状态
    echo "容器:"
    $DOCKER_COMPOSE ps -a 2>/dev/null || echo "  无容器"

    # 数据目录大小
    echo ""
    echo "数据目录:"
    if [ -d "data" ]; then
        du -sh data/* 2>/dev/null | sed 's/^/  /' || echo "  无数据"
    else
        echo "  无数据目录"
    fi

    # 镜像
    echo ""
    echo "PrimiHub 镜像:"
    docker images | grep -E "(primihub|REPOSITORY)" | sed 's/^/  /' || echo "  无镜像"
}

# =============================================================================
# 主执行流程
# =============================================================================

main() {
    show_banner

    # 显示当前状态
    show_current_status

    # 根据清理级别执行
    case $CLEANUP_LEVEL in
        soft)
            soft_cleanup
            ;;
        hard)
            hard_cleanup
            ;;
        complete)
            complete_cleanup
            ;;
        *)
            log_error "未知的清理级别: $CLEANUP_LEVEL"
            exit 1
            ;;
    esac

    echo ""
}

# =============================================================================
# 运行主程序
# =============================================================================

main
