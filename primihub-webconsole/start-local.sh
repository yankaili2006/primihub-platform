#!/bin/bash

# PrimiHub WebConsole 本地编译和启动脚本
# 作者: PrimiHub FrontEnd Team
# 描述: 用于本地开发环境的编译和启动

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="PrimiHub WebConsole"
VERSION="1.0.0"
PORT=8080

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装，请先安装 Node.js"
        exit 1
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        log_error "npm 未安装，请先安装 npm"
        exit 1
    fi
    
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    
    log_success "Node.js 版本: $NODE_VERSION"
    log_success "npm 版本: $NPM_VERSION"
}

# 安装依赖
install_dependencies() {
    log_info "安装项目依赖..."
    
    if [ ! -d "node_modules" ]; then
        log_info "执行 npm install..."
        npm install
        if [ $? -eq 0 ]; then
            log_success "依赖安装完成"
        else
            log_error "依赖安装失败"
            exit 1
        fi
    else
        log_info "node_modules 目录已存在，跳过依赖安装"
    fi
}

# 代码检查
run_lint() {
    log_info "运行代码检查..."
    npm run lint
    if [ $? -eq 0 ]; then
        log_success "代码检查通过"
    else
        log_warning "代码检查发现一些问题，但将继续构建"
    fi
}

# 构建项目
build_project() {
    log_info "开始构建项目..."
    
    # 检查构建模式
    BUILD_MODE=${1:-"prod"}
    
    case $BUILD_MODE in
        "prod")
            log_info "使用生产模式构建..."
            npm run build:prod
            ;;
        "stage")
            log_info "使用预发布模式构建..."
            npm run build:stage
            ;;
        *)
            log_error "未知的构建模式: $BUILD_MODE"
            log_info "可用模式: prod, stage"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        log_success "项目构建完成"
        
        # 检查构建输出
        if [ -d "dist" ]; then
            DIST_SIZE=$(du -sh dist | cut -f1)
            log_success "构建输出目录: dist (大小: $DIST_SIZE)"
        else
            log_error "构建输出目录 dist 不存在"
            exit 1
        fi
    else
        log_error "项目构建失败"
        exit 1
    fi
}

# 启动开发服务器
start_dev_server() {
    log_info "启动开发服务器..."
    log_info "开发服务器将在 http://localhost:$PORT 启动"
    log_info "按 Ctrl+C 停止服务器"
    
    npm run dev
}

# 预览构建结果
preview_build() {
    log_info "预览构建结果..."
    
    if [ ! -d "dist" ]; then
        log_error "构建输出目录不存在，请先运行构建"
        exit 1
    fi
    
    # 检查是否有预览服务器
    if command -v serve &> /dev/null; then
        serve -s dist -l $PORT
    else
        log_warning "未安装 serve，尝试使用 Python 简单服务器"
        cd dist
        python3 -m http.server $PORT 2>/dev/null || python -m SimpleHTTPServer $PORT 2>/dev/null || {
            log_error "无法启动预览服务器，请安装 serve: npm install -g serve"
            exit 1
        }
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}$PROJECT_NAME 本地编译和启动脚本${NC}"
    echo ""
    echo "用法: ./start-local.sh [命令]"
    echo ""
    echo "命令:"
    echo "  dev          启动开发服务器 (默认)"
    echo "  build        构建项目 (生产模式)"
    echo "  build:stage  构建项目 (预发布模式)" 
    echo "  preview      预览构建结果"
    echo "  install      仅安装依赖"
    echo "  lint         运行代码检查"
    echo "  help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./start-local.sh dev        # 启动开发服务器"
    echo "  ./start-local.sh build      # 构建生产版本"
    echo "  ./start-local.sh preview    # 预览构建结果"
    echo ""
}

# 主函数
main() {
    COMMAND=${1:-"dev"}
    
    log_info "=== $PROJECT_NAME 本地环境启动脚本 ==="
    log_info "项目版本: $VERSION"
    log_info "工作目录: $(pwd)"
    
    case $COMMAND in
        "dev")
            check_dependencies
            install_dependencies
            start_dev_server
            ;;
        "build")
            check_dependencies
            install_dependencies
            run_lint
            build_project "prod"
            ;;
        "build:stage")
            check_dependencies
            install_dependencies
            run_lint
            build_project "stage"
            ;;
        "preview")
            preview_build
            ;;
        "install")
            check_dependencies
            install_dependencies
            ;;
        "lint")
            check_dependencies
            run_lint
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "未知命令: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
