#!/bin/bash

###############################################################################
# PrimiHub 完整镜像构建脚本
# 功能: 同时构建后端 (privacy) 和前端 (platform) 镜像
# 用法: ./build-all-images.sh [OPTIONS]
###############################################################################

set -e

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# 默认配置
# ============================================================================
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}
DOCKER_REGISTRY="${DOCKER_REGISTRY:-192.168.99.10}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
BUILD_BACKEND="${BUILD_BACKEND:-true}"
BUILD_FRONTEND="${BUILD_FRONTEND:-true}"

# ============================================================================
# 工具函数
# ============================================================================
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error_exit() {
    print_error "$1"
    exit 1
}

# ============================================================================
# 使用说明
# ============================================================================
usage() {
    cat << EOF
用法: $0 [OPTIONS]

同时构建 PrimiHub Platform 后端和前端 Docker 镜像

选项:
  -h, --help              显示此帮助信息
  -b, --build-number NUM  设置构建编号 (默认: 时间戳)
  -r, --registry ADDR     设置 Docker 仓库地址 (默认: 192.168.99.10)
  -p, --push              构建后推送镜像到仓库
  --backend-only          仅构建后端镜像
  --frontend-only         仅构建前端镜像
  --parallel              并行构建（实验性）

环境变量:
  BUILD_NUMBER            构建编号
  DOCKER_REGISTRY         Docker 仓库地址
  PUSH_IMAGE              是否推送镜像 (true/false)
  BUILD_BACKEND           是否构建后端 (true/false)
  BUILD_FRONTEND          是否构建前端 (true/false)

示例:
  # 构建所有镜像
  $0

  # 指定版本号
  $0 --build-number 1.8.0

  # 构建并推送
  $0 --build-number 1.8.0 --push

  # 仅构建后端
  $0 --backend-only

  # 仅构建前端
  $0 --frontend-only

  # 并行构建（更快但日志混乱）
  $0 --parallel

EOF
}

# ============================================================================
# 参数解析
# ============================================================================
PARALLEL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_IMAGE=true
            shift
            ;;
        --backend-only)
            BUILD_BACKEND=true
            BUILD_FRONTEND=false
            shift
            ;;
        --frontend-only)
            BUILD_BACKEND=false
            BUILD_FRONTEND=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        *)
            print_error "未知参数: $1"
            usage
            exit 1
            ;;
    esac
done

# ============================================================================
# 主函数
# ============================================================================
main() {
    local total_start_time=$(date +%s)

    print_header "PrimiHub Platform 完整镜像构建"

    echo "构建配置:"
    echo "  开始时间:    $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  构建编号:    $BUILD_NUMBER"
    echo "  仓库地址:    $DOCKER_REGISTRY"
    echo "  推送镜像:    $PUSH_IMAGE"
    echo "  构建后端:    $BUILD_BACKEND"
    echo "  构建前端:    $BUILD_FRONTEND"
    echo "  并行构建:    $PARALLEL"
    echo ""

    # 检查脚本是否存在
    if [ "$BUILD_BACKEND" = "true" ] && [ ! -f "$SCRIPT_DIR/build-docker-image.sh" ]; then
        error_exit "后端构建脚本不存在: build-docker-image.sh"
    fi

    if [ "$BUILD_FRONTEND" = "true" ] && [ ! -f "$SCRIPT_DIR/build-platform-image.sh" ]; then
        error_exit "前端构建脚本不存在: build-platform-image.sh"
    fi

    # 构建参数
    local build_args="--build-number $BUILD_NUMBER --registry $DOCKER_REGISTRY"
    if [ "$PUSH_IMAGE" = "true" ]; then
        build_args="$build_args --push"
    fi

    if [ "$PARALLEL" = "true" ]; then
        # 并行构建
        print_header "并行构建模式"

        local pids=()

        if [ "$BUILD_BACKEND" = "true" ]; then
            print_info "启动后端构建..."
            "$SCRIPT_DIR/build-docker-image.sh" $build_args > /tmp/build-backend-$BUILD_NUMBER.log 2>&1 &
            pids+=($!)
        fi

        if [ "$BUILD_FRONTEND" = "true" ]; then
            print_info "启动前端构建..."
            "$SCRIPT_DIR/build-platform-image.sh" $build_args > /tmp/build-frontend-$BUILD_NUMBER.log 2>&1 &
            pids+=($!)
        fi

        # 等待所有构建完成
        print_info "等待构建完成..."
        local all_success=true
        for pid in "${pids[@]}"; do
            if ! wait $pid; then
                all_success=false
            fi
        done

        if [ "$all_success" = "false" ]; then
            print_error "部分构建失败，请查看日志:"
            [ "$BUILD_BACKEND" = "true" ] && echo "  后端: /tmp/build-backend-$BUILD_NUMBER.log"
            [ "$BUILD_FRONTEND" = "true" ] && echo "  前端: /tmp/build-frontend-$BUILD_NUMBER.log"
            exit 1
        fi

    else
        # 串行构建
        print_header "串行构建模式"

        if [ "$BUILD_BACKEND" = "true" ]; then
            print_info "开始构建后端镜像..."
            if ! "$SCRIPT_DIR/build-docker-image.sh" $build_args; then
                error_exit "后端镜像构建失败"
            fi
        fi

        if [ "$BUILD_FRONTEND" = "true" ]; then
            print_info "开始构建前端镜像..."
            if ! "$SCRIPT_DIR/build-platform-image.sh" $build_args; then
                error_exit "前端镜像构建失败"
            fi
        fi
    fi

    # 显示总结
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - total_start_time))

    print_header "构建总结"

    echo -e "${GREEN}✓ 所有镜像构建完成！${NC}"
    echo ""
    echo "构建信息:"
    echo "  Build Number: $BUILD_NUMBER"
    echo "  总耗时:      ${total_duration}s"
    echo ""
    echo "Docker 镜像:"
    if [ "$BUILD_BACKEND" = "true" ]; then
        docker images "$DOCKER_REGISTRY/primihub/privacy:$BUILD_NUMBER" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
    fi
    if [ "$BUILD_FRONTEND" = "true" ]; then
        docker images "$DOCKER_REGISTRY/primihub/platform:$BUILD_NUMBER" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
    fi
    echo ""
    echo "下一步操作:"
    echo "  1. 使用 docker-compose 部署完整环境:"
    echo "     docker-compose up -d"
    echo ""
    echo "  2. 或分别运行容器:"
    if [ "$BUILD_BACKEND" = "true" ]; then
        echo "     docker run -d -p 8080:8080 --name primihub-backend $DOCKER_REGISTRY/primihub/privacy:$BUILD_NUMBER"
    fi
    if [ "$BUILD_FRONTEND" = "true" ]; then
        echo "     docker run -d -p 80:80 --name primihub-frontend $DOCKER_REGISTRY/primihub/platform:$BUILD_NUMBER"
    fi
    echo ""

    if [ "$PUSH_IMAGE" = "true" ]; then
        echo -e "${GREEN}✓ 镜像已推送到仓库${NC}"
    else
        echo -e "${YELLOW}! 镜像未推送 (使用 --push 参数启用自动推送)${NC}"
    fi

    print_success "构建流程完成！"
}

# ============================================================================
# 执行主函数
# ============================================================================
main "$@"
