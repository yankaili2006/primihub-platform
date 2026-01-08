#!/bin/bash

###############################################################################
# PrimiHub 停止脚本
# 功能: 停止所有 PrimiHub 服务
# 用法: ./stop.sh [--force]
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认参数
FORCE=false
PID_DIR="/tmp/primihub"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --force    强制停止所有进程"
            echo "  -h, --help 显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_info() {
    echo -e "  $1"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 停止进程
stop_process() {
    local name=$1
    local pid_file=$2

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_info "停止 $name (PID: $pid)..."
            kill "$pid"
            sleep 1

            # 确认已停止
            if kill -0 "$pid" 2>/dev/null; then
                if [ "$FORCE" = true ]; then
                    kill -9 "$pid" 2>/dev/null || true
                    print_success "$name 已强制停止"
                else
                    print_warn "$name 进程仍在运行 (PID: $pid)"
                fi
            else
                print_success "$name 已停止"
            fi
        else
            print_info "$name 未运行"
        fi
        rm -f "$pid_file"
    else
        print_info "$name PID文件不存在"
    fi
}

# 停止服务
stop_services() {
    print_header "停止 PrimiHub 服务"

    # 停止后端
    stop_process "后端服务" "$PID_DIR/backend.pid"

    # 停止前端
    stop_process "前端服务" "$PID_DIR/frontend.pid"

    # 停止Meta Service
    for i in 0 1 2; do
        stop_process "Meta Service $i" "$PID_DIR/meta$i.pid"
    done

    # 如果使用force，停止所有相关进程
    if [ "$FORCE" = true ]; then
        print_info "强制停止所有相关进程..."

        # 停止Java进程
        pkill -f "application.jar" 2>/dev/null || true
        pkill -f "fusion-simple.jar" 2>/dev/null || true

        # 停止npm进程
        pkill -f "npm run serve" 2>/dev/null || true
        pkill -f "vue-cli-service" 2>/dev/null || true

        print_success "所有进程已停止"
    fi
}

# 检查服务状态
check_status() {
    print_header "检查服务状态"

    # 检查后端
    if curl -s http://localhost:8090/actuator/health > /dev/null 2>&1; then
        print_warn "后端服务仍在运行: http://localhost:8090"
    else
        print_success "后端服务已停止"
    fi

    # 检查前端
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        print_warn "前端服务仍在运行: http://localhost:8080"
    else
        print_success "前端服务已停止"
    fi

    # 检查Meta Service
    for i in 0 1 2; do
        local port=$((7977 + i))
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            print_warn "Meta Service $i 仍在运行: http://localhost:$port"
        else
            print_success "Meta Service $i 已停止"
        fi
    done

    # 检查计算节点
    local node_count=$(ps aux | grep "bazel-bin/node" | grep -v grep | wc -l)
    if [ $node_count -gt 0 ]; then
        print_info "计算节点仍在运行 ($node_count 个)"
        print_info "计算节点需要手动停止"
    fi
}

# 主函数
main() {
    echo "PrimiHub 停止脚本"
    echo "时间: $(date)"
    echo ""

    stop_services
    sleep 2
    check_status

    echo ""
    echo -e "${GREEN}✓ 服务停止完成${NC}"
    echo ""
    echo "日志文件保留在 /tmp/primihub-*.log"
    echo "要重新启动服务，运行: ./deploy.sh 或 ./install.sh"
}

# 运行主函数
main "$@"
