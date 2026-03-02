#!/bin/bash

# PrimiHub部署问题修复脚本
# 用途: 自动清理失败的容器并验证核心服务健康状态

set -e

echo "=========================================="
echo "  PrimiHub 部署问题自动修复工具"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker是否运行
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker未运行或无权限访问"
        exit 1
    fi
    log_info "Docker运行正常"
}

# 显示当前容器状态
show_current_status() {
    echo ""
    log_info "当前容器状态:"
    echo "----------------------------------------"
    docker ps -a --format "table {{.Names}}\t{{.Status}}" | head -20
    echo ""
}

# 清理失败的Vault容器
cleanup_vault() {
    echo ""
    log_warn "准备清理Vault相关容器..."

    VAULT_CONTAINERS="vault-node-1 vault-node-2 vault-node-3 vault-node-4 vault-haproxy vault-prometheus"

    for container in $VAULT_CONTAINERS; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            log_info "停止并删除容器: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        else
            log_info "容器不存在,跳过: $container"
        fi
    done

    log_info "Vault容器清理完成"
}

# 清理失败的PostgreSQL容器
cleanup_postgres() {
    echo ""
    log_warn "准备清理PostgreSQL容器..."

    POSTGRES_CONTAINER="local-dev-postgres-1"

    if docker ps -a --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
        log_info "停止并删除容器: $POSTGRES_CONTAINER"
        docker stop "$POSTGRES_CONTAINER" 2>/dev/null || true
        docker rm "$POSTGRES_CONTAINER" 2>/dev/null || true
        log_info "PostgreSQL容器清理完成"
    else
        log_info "PostgreSQL容器不存在,跳过"
    fi
}

# 健康检查
health_check() {
    echo ""
    log_info "执行核心服务健康检查..."
    echo "----------------------------------------"

    # 检查MySQL
    if docker exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo -e "✅ MySQL: ${GREEN}运行正常${NC}"
    else
        echo -e "❌ MySQL: ${RED}异常${NC}"
    fi

    # 检查Nacos
    if curl -s http://localhost:8848/nacos/v1/console/health/readiness | grep -q "OK"; then
        echo -e "✅ Nacos: ${GREEN}运行正常${NC}"
    else
        echo -e "❌ Nacos: ${RED}异常${NC}"
    fi

    # 检查Application0
    if docker ps --filter "name=application0" --filter "status=running" | grep -q "application0"; then
        if docker inspect application0 --format '{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
            echo -e "✅ Application0: ${GREEN}运行正常 (healthy)${NC}"
        else
            echo -e "⚠️  Application0: ${YELLOW}运行中 (无健康检查或不健康)${NC}"
        fi
    else
        echo -e "❌ Application0: ${RED}未运行${NC}"
    fi

    # 检查Meta服务
    META_HEALTHY=0
    for i in 0 1 2; do
        if docker inspect "primihub-meta${i}" --format '{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
            ((META_HEALTHY++))
        fi
    done
    echo -e "✅ Meta服务: ${GREEN}${META_HEALTHY}/3 健康${NC}"

    # 检查Node服务
    NODE_RUNNING=0
    for i in 0 1 2; do
        if docker ps --filter "name=primihub-node${i}" --filter "status=running" | grep -q "primihub-node${i}"; then
            ((NODE_RUNNING++))
        fi
    done
    echo -e "✅ Node服务: ${GREEN}${NODE_RUNNING}/3 运行中${NC}"

    # 检查Gateway
    GATEWAY_RUNNING=0
    for i in 0 1 2; do
        if docker ps --filter "name=gateway${i}" --filter "status=running" | grep -q "gateway${i}"; then
            ((GATEWAY_RUNNING++))
        fi
    done
    echo -e "✅ Gateway: ${GREEN}${GATEWAY_RUNNING}/3 运行中${NC}"

    # 检查Web界面
    WEB_RUNNING=0
    for i in 0 1 2; do
        if docker ps --filter "name=manage-web${i}" --filter "status=running" | grep -q "manage-web${i}"; then
            ((WEB_RUNNING++))
        fi
    done
    echo -e "✅ Web界面: ${GREEN}${WEB_RUNNING}/3 运行中${NC}"

    echo ""
}

# 显示访问信息
show_access_info() {
    echo ""
    log_info "服务访问地址:"
    echo "----------------------------------------"
    echo "  📊 机构0管理界面: http://localhost:30811"
    echo "  📊 机构1管理界面: http://localhost:30812"
    echo "  📊 机构2管理界面: http://localhost:30813"
    echo "  📊 Nacos控制台:   http://localhost:8848/nacos"
    echo "  📊 NocoDB:        http://localhost:18081"
    echo "  📊 Loki:          http://localhost:3100"
    echo ""
}

# 主函数
main() {
    check_docker
    show_current_status

    echo ""
    read -p "是否清理失败的Vault容器? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_vault
    else
        log_info "跳过Vault容器清理"
    fi

    echo ""
    read -p "是否清理失败的PostgreSQL容器? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_postgres
    else
        log_info "跳过PostgreSQL容器清理"
    fi

    health_check
    show_access_info

    echo ""
    log_info "修复完成!"
    echo ""
    log_info "建议操作:"
    echo "  1. 访问Web管理界面测试功能"
    echo "  2. 检查日志: docker logs -f application0"
    echo "  3. 查看完整报告: cat DEPLOYMENT_DIAGNOSIS_REPORT.md"
    echo ""
}

# 如果使用--auto参数,自动执行所有清理
if [[ "$1" == "--auto" ]]; then
    log_warn "自动模式: 将自动清理所有失败的容器"
    check_docker
    show_current_status
    cleanup_vault
    cleanup_postgres
    health_check
    show_access_info
else
    main
fi
