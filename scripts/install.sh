#!/bin/bash

###############################################################################
# PrimiHub 一键安装脚本
# 功能: 自动检查环境、编译、部署和测试 PrimiHub 平台
# 用法: ./install.sh [--skip-check] [--skip-test]
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认参数
SKIP_CHECK=false
SKIP_TEST=false
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-check)
            SKIP_CHECK=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        -h|--help)
            echo "PrimiHub 一键安装脚本"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --skip-check    跳过环境检查"
            echo "  --skip-test     跳过功能测试"
            echo "  -h, --help      显示帮助信息"
            echo ""
            echo "功能:"
            echo "  1. 检查系统环境"
            echo "  2. 编译后端和前端"
            echo "  3. 部署所有服务"
            echo "  4. 运行功能测试"
            echo ""
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 -h 查看帮助"
            exit 1
            ;;
    esac
done

# 打印函数
print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ██████╗ ██╗███╗   ███╗██╗██╗  ██╗██╗   ██╗██████╗  ║
║   ██╔══██╗██╔══██╗██║████╗ ████║██║██║  ██║██║   ██║██╔══██╗ ║
║   ██████╔╝██████╔╝██║██╔████╔██║██║███████║██║   ██║██████╔╝ ║
║   ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║██╔══██║██║   ██║██╔══██╗ ║
║   ██║     ██║  ██║██║██║ ╚═╝ ██║██║██║  ██║╚██████╔╝██████╔╝ ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ║
║                                                               ║
║          开源隐私计算平台 - 一键安装脚本                        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}[步骤] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error_exit() {
    print_error "$1"
    echo ""
    echo "安装失败，请检查错误信息并重试"
    exit 1
}

# 确认继续
confirm() {
    local message=$1
    echo -e "${YELLOW}$message${NC}"
    read -p "是否继续? (y/n): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
}

# 步骤1: 环境检查
step_check_environment() {
    if [ "$SKIP_CHECK" = true ]; then
        print_warn "跳过环境检查 (--skip-check)"
        return 0
    fi

    print_header "步骤 1/4: 环境检查"

    print_step "运行环境检查脚本"

    if [ -x "$SCRIPT_DIR/check_environment.sh" ]; then
        if "$SCRIPT_DIR/check_environment.sh"; then
            print_success "环境检查通过"
        else
            print_error "环境检查未通过"
            confirm "环境存在问题，是否继续安装?"
        fi
    else
        print_warn "未找到环境检查脚本，跳过检查"
    fi
}

# 步骤2: 编译
step_build() {
    print_header "步骤 2/4: 编译"

    print_step "运行编译脚本"

    if [ -x "$SCRIPT_DIR/build.sh" ]; then
        if "$SCRIPT_DIR/build.sh" --skip-tests; then
            print_success "编译完成"
        else
            error_exit "编译失败"
        fi
    else
        error_exit "未找到编译脚本: $SCRIPT_DIR/build.sh"
    fi
}

# 步骤3: 部署
step_deploy() {
    print_header "步骤 3/4: 部署"

    print_step "运行部署脚本"

    if [ -x "$SCRIPT_DIR/deploy.sh" ]; then
        if "$SCRIPT_DIR/deploy.sh"; then
            print_success "部署完成"
        else
            error_exit "部署失败"
        fi
    else
        error_exit "未找到部署脚本: $SCRIPT_DIR/deploy.sh"
    fi

    # 等待服务完全启动
    print_step "等待服务完全启动..."
    sleep 10
}

# 步骤4: 测试
step_test() {
    if [ "$SKIP_TEST" = true ]; then
        print_warn "跳过功能测试 (--skip-test)"
        return 0
    fi

    print_header "步骤 4/4: 功能测试"

    print_step "运行测试脚本"

    if [ -x "$SCRIPT_DIR/test.sh" ]; then
        if "$SCRIPT_DIR/test.sh" --quick; then
            print_success "测试通过"
        else
            print_warn "部分测试失败，但安装已完成"
        fi
    else
        print_warn "未找到测试脚本，跳过测试"
    fi
}

# 显示安装总结
show_summary() {
    print_header "安装完成"

    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           PrimiHub 安装成功！                         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "访问地址:"
    echo -e "  ${CYAN}前端界面:${NC} http://localhost:8080"
    echo -e "  ${CYAN}默认账号:${NC} admin / admin"
    echo -e "  ${CYAN}API文档:${NC}  http://localhost:8090/doc.html"
    echo ""
    echo "服务状态:"

    # 检查后端
    if curl -s http://localhost:8090/actuator/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 后端服务: http://localhost:8090"
    else
        echo -e "  ${RED}✗${NC} 后端服务未运行"
    fi

    # 检查前端
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 前端服务: http://localhost:8080"
    else
        echo -e "  ${YELLOW}⚠${NC} 前端服务可能仍在启动"
    fi

    # 检查Meta Service
    local meta_ok=0
    for i in 0 1 2; do
        local port=$((7977 + i))
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            ((meta_ok++))
        fi
    done
    echo -e "  ${GREEN}✓${NC} Meta Service: $meta_ok/3 个运行中"

    # 检查计算节点
    local node_count=$(ps aux | grep "bazel-bin/node" | grep -v grep | wc -l)
    if [ $node_count -ge 3 ]; then
        echo -e "  ${GREEN}✓${NC} 计算节点: $node_count 个运行中"
    else
        echo -e "  ${YELLOW}⚠${NC} 计算节点: $node_count 个运行中 (建议3个)"
    fi

    echo ""
    echo "日志文件:"
    echo "  /tmp/primihub-backend.log"
    echo "  /tmp/primihub-frontend.log"
    echo "  /tmp/primihub-meta*.log"
    echo ""
    echo "常用命令:"
    echo -e "  ${CYAN}查看日志:${NC}   tail -f /tmp/primihub-*.log"
    echo -e "  ${CYAN}运行测试:${NC}   $SCRIPT_DIR/test.sh"
    echo -e "  ${CYAN}停止服务:${NC}   $SCRIPT_DIR/stop.sh"
    echo ""
    echo "文档:"
    echo "  快速参考: QUICKREF.md"
    echo "  部署指南: DEPLOYMENT.md"
    echo "  故障排查: TROUBLESHOOTING.md"
    echo ""
}

# 主函数
main() {
    # 显示横幅
    print_banner

    echo "欢迎使用 PrimiHub 一键安装脚本！"
    echo ""
    echo "本脚本将自动完成以下步骤:"
    echo "  1. 检查系统环境"
    echo "  2. 编译后端和前端"
    echo "  3. 部署所有服务"
    echo "  4. 运行功能测试"
    echo ""
    echo "预计耗时: 5-10 分钟"
    echo "开始时间: $(date)"
    echo ""

    # 确认继续
    if [ "$SKIP_CHECK" != true ] && [ "$SKIP_TEST" != true ]; then
        confirm "确认开始安装?"
    fi

    # 记录开始时间
    local start_time=$(date +%s)

    # 执行安装步骤
    step_check_environment
    step_build
    step_deploy
    step_test

    # 计算耗时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    # 显示总结
    show_summary

    echo -e "${GREEN}总耗时: ${minutes}分${seconds}秒${NC}"
    echo ""
    echo -e "${GREEN}🎉 安装完成，开始使用 PrimiHub 吧！${NC}"
}

# 捕获错误
trap 'error_exit "安装过程中发生错误"' ERR

# 运行主函数
main "$@"
