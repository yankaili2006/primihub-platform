#!/bin/bash

###############################################################################
# PrimiHub Platform 前端镜像构建脚本
# 基于 Jenkins Pipeline 配置生成
# 功能: 编译前端项目并构建 Docker 镜像
# 用法: ./build-platform-image.sh [OPTIONS]
###############################################################################

set -e  # 遇到错误立即退出

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# 默认配置
# ============================================================================
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}
DOCKER_REGISTRY="${DOCKER_REGISTRY:-192.168.99.10}"
IMAGE_NAME="${IMAGE_NAME:-primihub/platform}"
IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.local}"
BUILD_CONTEXT="${BUILD_CONTEXT:-./primihub-webconsole}"
WEBCONSOLE_DIR="$SCRIPT_DIR/primihub-webconsole"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
SKIP_BUILD="${SKIP_BUILD:-false}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"
NPM_REGISTRY="${NPM_REGISTRY:-}"  # 留空使用默认，或设置为淘宝镜像

# ============================================================================
# 工具函数
# ============================================================================
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${CYAN}[步骤] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

error_exit() {
    print_error "$1"
    exit 1
}

# ============================================================================
# 前置检查
# ============================================================================
check_prerequisites() {
    print_header "检查前置条件"

    local missing_deps=0

    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js 未安装"
        ((missing_deps++))
    else
        local node_version=$(node --version)
        print_success "Node.js: $node_version"

        # 检查 Node.js 版本（建议 12.x 或更高）
        local node_major=$(node --version | cut -d'.' -f1 | sed 's/v//')
        if [ "$node_major" -lt 12 ]; then
            print_warning "Node.js 版本过低，建议使用 12.x 或更高版本"
        fi
    fi

    # 检查 npm
    if ! command -v npm &> /dev/null; then
        print_error "npm 未安装"
        ((missing_deps++))
    else
        local npm_version=$(npm --version)
        print_success "npm: $npm_version"
    fi

    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装"
        ((missing_deps++))
    else
        local docker_version=$(docker --version)
        print_success "Docker: $docker_version"

        # 检查 Docker daemon 是否运行
        if ! docker info &> /dev/null; then
            print_error "Docker daemon 未运行，请先启动 Docker"
            ((missing_deps++))
        else
            print_success "Docker daemon 运行中"
        fi
    fi

    if [ $missing_deps -gt 0 ]; then
        error_exit "缺少 $missing_deps 个必需工具，请先安装"
    fi

    # 检查项目目录
    if [ ! -d "$WEBCONSOLE_DIR" ]; then
        error_exit "primihub-webconsole 目录不存在"
    fi

    if [ ! -f "$WEBCONSOLE_DIR/package.json" ]; then
        error_exit "package.json 不存在"
    fi

    if [ ! -f "$WEBCONSOLE_DIR/$DOCKERFILE" ]; then
        error_exit "Dockerfile 不存在: $DOCKERFILE"
    fi

    print_success "所有前置条件满足"
}

# ============================================================================
# 显示系统信息
# ============================================================================
show_system_info() {
    print_header "系统信息"

    print_info "PATH: $PATH"

    # 检查是否有 devtoolset（CentOS/RHEL）
    if command -v scl &> /dev/null; then
        print_info "SCL (Software Collections) 可用"
        if scl --list 2>/dev/null | grep -q devtoolset; then
            print_success "检测到 devtoolset"
        fi
    else
        print_info "SCL 不可用 (非 CentOS/RHEL 系统)"
    fi

    # 检查 C++ 编译器（某些 npm 包可能需要）
    if command -v g++ &> /dev/null; then
        local gpp_version=$(g++ --version 2>&1 | head -1)
        print_success "g++: $gpp_version"
    else
        print_warning "g++ 未安装 (某些 npm 包可能需要)"
    fi

    # 检查 Python（某些 npm 包可能需要）
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version)
        print_success "Python3: $python_version"
    elif command -v python &> /dev/null; then
        local python_version=$(python --version)
        print_success "Python: $python_version"
    else
        print_warning "Python 未安装 (某些 npm 包可能需要)"
    fi
}

# ============================================================================
# 清理构建目录
# ============================================================================
clean_build_artifacts() {
    if [ "$CLEAN_BUILD" != "true" ]; then
        return 0
    fi

    print_header "清理构建产物"

    cd "$WEBCONSOLE_DIR"

    if [ -d "dist" ]; then
        print_step "删除 dist 目录..."
        rm -rf dist
        print_success "dist 目录已删除"
    fi

    if [ -d "node_modules" ]; then
        print_step "删除 node_modules 目录..."
        rm -rf node_modules
        print_success "node_modules 目录已删除"
    fi

    cd "$SCRIPT_DIR"
}

# ============================================================================
# Stage 1: Build (编译阶段)
# ============================================================================
build_frontend() {
    print_header "Stage 1: 编译前端项目"

    cd "$WEBCONSOLE_DIR"
    print_info "当前目录: $(pwd)"

    local start_time=$(date +%s)

    # 配置 npm 镜像（如果指定）
    if [ -n "$NPM_REGISTRY" ]; then
        print_step "配置 npm 镜像..."
        npm config set registry "$NPM_REGISTRY"
        print_success "npm 镜像已设置: $NPM_REGISTRY"
    fi

    # 安装依赖
    print_step "安装 npm 依赖..."
    print_info "执行命令: npm install"

    if npm install; then
        print_success "npm 依赖安装成功"
    else
        error_exit "npm 依赖安装失败"
    fi

    # 显示 node_modules 大小
    if [ -d "node_modules" ]; then
        local node_modules_size=$(du -sh node_modules | cut -f1)
        print_info "node_modules 大小: $node_modules_size"
    fi

    # 构建生产版本
    print_step "构建生产版本..."
    print_info "执行命令: npm run build:prod"

    if npm run build:prod; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "前端构建成功 (耗时: ${duration}s)"
    else
        error_exit "前端构建失败"
    fi

    # 验证构建产物
    print_step "验证构建产物..."

    if [ ! -d "dist" ]; then
        error_exit "dist 目录不存在，构建可能失败"
    fi

    local dist_size=$(du -sh dist | cut -f1)
    print_success "dist 目录大小: $dist_size"

    # 列出 dist 目录内容
    print_info "dist 目录结构:"
    ls -lh dist/ | tail -n +2 | while read line; do
        echo "  $line"
    done

    cd "$SCRIPT_DIR"
}

# ============================================================================
# Stage 2: Building app image (构建镜像阶段)
# ============================================================================
build_docker_image() {
    print_header "Stage 2: 构建 Docker 镜像"

    cd "$WEBCONSOLE_DIR"
    print_info "当前目录: $(pwd)"

    print_info "构建配置:"
    echo "  Registry:    $DOCKER_REGISTRY"
    echo "  Image Name:  $IMAGE_NAME"
    echo "  Image Tag:   $IMAGE_TAG"
    echo "  Build Number: $BUILD_NUMBER"
    echo "  Dockerfile:  $DOCKERFILE"

    local start_time=$(date +%s)

    print_step "开始构建 Docker 镜像..."
    print_info "执行命令: docker build -t $IMAGE_TAG -f $DOCKERFILE ."

    if docker build \
        -t "$IMAGE_TAG" \
        -f "$DOCKERFILE" \
        .; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "Docker 镜像构建成功 (耗时: ${duration}s)"
    else
        error_exit "Docker 镜像构建失败"
    fi

    # 显示镜像信息
    print_step "镜像信息:"
    docker images "$IMAGE_TAG" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}"

    # 可选: 添加 latest 标签
    print_step "添加 latest 标签..."
    docker tag "$IMAGE_TAG" "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
    print_success "已添加标签: ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"

    cd "$SCRIPT_DIR"
}

# ============================================================================
# Stage 3: Push image (推送镜像阶段 - 可选)
# ============================================================================
push_docker_image() {
    print_header "Stage 3: 推送 Docker 镜像"

    if [ "$PUSH_IMAGE" != "true" ]; then
        print_warning "跳过镜像推送 (使用 --push 启用)"
        return 0
    fi

    print_step "推送镜像到仓库: $IMAGE_TAG"

    if docker push "$IMAGE_TAG"; then
        print_success "镜像推送成功: $IMAGE_TAG"
    else
        error_exit "镜像推送失败"
    fi

    # 推送 latest 标签
    if docker push "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"; then
        print_success "latest 标签推送成功"
    else
        print_warning "latest 标签推送失败"
    fi
}

# ============================================================================
# 清理函数
# ============================================================================
cleanup() {
    print_header "清理临时文件"

    # 清理悬空镜像
    local dangling_images=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        print_step "清理悬空镜像..."
        docker rmi $dangling_images || print_warning "部分悬空镜像清理失败"
    else
        print_info "没有悬空镜像需要清理"
    fi
}

# ============================================================================
# 显示构建总结
# ============================================================================
show_summary() {
    print_header "构建总结"

    echo -e "${GREEN}✓ 构建完成！${NC}"
    echo ""
    echo "构建信息:"
    echo "  Build Number: $BUILD_NUMBER"
    echo "  Image Tag:    $IMAGE_TAG"
    echo "  Latest Tag:   ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
    echo ""
    echo "构建产物:"
    echo "  Dist:        primihub-webconsole/dist/"
    if [ -d "$WEBCONSOLE_DIR/dist" ]; then
        local dist_size=$(du -sh "$WEBCONSOLE_DIR/dist" | cut -f1)
        echo "  Size:        $dist_size"
    fi
    echo ""
    echo "Docker 镜像:"
    docker images "${DOCKER_REGISTRY}/${IMAGE_NAME}" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
    echo ""
    echo "下一步操作:"
    echo "  1. 运行容器:"
    echo "     docker run -d -p 80:80 --name primihub-web $IMAGE_TAG"
    echo ""
    echo "  2. 推送到仓库:"
    echo "     docker push $IMAGE_TAG"
    echo ""
    echo "  3. 访问前端:"
    echo "     http://localhost"
    echo ""
    echo "  4. 查看 Nginx 日志:"
    echo "     docker logs -f primihub-web"
    echo ""

    if [ "$PUSH_IMAGE" = "true" ]; then
        echo -e "${GREEN}✓ 镜像已推送到仓库${NC}"
    else
        echo -e "${YELLOW}! 镜像未推送 (使用 --push 参数启用自动推送)${NC}"
    fi
}

# ============================================================================
# 使用说明
# ============================================================================
usage() {
    cat << EOF
用法: $0 [OPTIONS]

构建 PrimiHub Platform 前端 Docker 镜像

选项:
  -h, --help              显示此帮助信息
  -b, --build-number NUM  设置构建编号 (默认: 时间戳)
  -r, --registry ADDR     设置 Docker 仓库地址 (默认: 192.168.99.10)
  -n, --name NAME         设置镜像名称 (默认: primihub/platform)
  -f, --dockerfile FILE   指定 Dockerfile (默认: Dockerfile.local)
  -p, --push              构建后推送镜像到仓库
  -s, --skip-build        跳过编译阶段，仅构建镜像
  -C, --clean             清理后重新构建
  --npm-registry URL      设置 npm 镜像源
  --no-cleanup            不清理悬空镜像

环境变量:
  BUILD_NUMBER            构建编号
  DOCKER_REGISTRY         Docker 仓库地址
  IMAGE_NAME              镜像名称
  PUSH_IMAGE              是否推送镜像 (true/false)
  SKIP_BUILD              是否跳过编译 (true/false)
  CLEAN_BUILD             是否清理后构建 (true/false)
  NPM_REGISTRY            npm 镜像源

示例:
  # 基本构建
  $0

  # 指定构建号并推送
  $0 --build-number 1.7.0 --push

  # 使用自定义仓库
  $0 --registry registry.example.com --name myapp/web

  # 使用淘宝 npm 镜像加速
  $0 --npm-registry https://registry.npmmirror.com

  # 仅构建 Docker 镜像（跳过 npm 编译）
  $0 --skip-build

  # 清理后重新构建
  $0 --clean

  # 使用环境变量
  BUILD_NUMBER=1.8.0 PUSH_IMAGE=true $0

EOF
}

# ============================================================================
# 参数解析
# ============================================================================
CLEANUP=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--build-number)
            BUILD_NUMBER="$2"
            IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
            shift 2
            ;;
        -f|--dockerfile)
            DOCKERFILE="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_IMAGE=true
            shift
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -C|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        --npm-registry)
            NPM_REGISTRY="$2"
            shift 2
            ;;
        --no-cleanup)
            CLEANUP=false
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

    print_header "PrimiHub Platform 前端镜像构建"

    echo "构建配置:"
    echo "  开始时间:    $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  构建目录:    $SCRIPT_DIR"
    echo "  前端目录:    $WEBCONSOLE_DIR"
    echo "  构建编号:    $BUILD_NUMBER"
    echo "  镜像标签:    $IMAGE_TAG"
    echo "  跳过编译:    $SKIP_BUILD"
    echo "  清理构建:    $CLEAN_BUILD"
    echo "  推送镜像:    $PUSH_IMAGE"
    if [ -n "$NPM_REGISTRY" ]; then
        echo "  npm 镜像:    $NPM_REGISTRY"
    fi
    echo ""

    # 检查前置条件
    check_prerequisites

    # 显示系统信息
    show_system_info

    # 清理构建产物（如果需要）
    clean_build_artifacts

    # Stage 1: Build (编译阶段)
    if [ "$SKIP_BUILD" != "true" ]; then
        build_frontend
    else
        print_warning "跳过编译阶段 (--skip-build)"
        # 检查 dist 目录是否存在
        if [ ! -d "$WEBCONSOLE_DIR/dist" ]; then
            error_exit "dist 目录不存在，无法构建镜像。请先运行完整构建或移除 --skip-build 参数"
        fi
    fi

    # Stage 2: Building app image (构建镜像阶段)
    build_docker_image

    # Stage 3: Push image (推送镜像阶段)
    push_docker_image

    # 清理
    if [ "$CLEANUP" = "true" ]; then
        cleanup
    fi

    # 显示总结
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - total_start_time))

    show_summary

    print_success "总耗时: ${total_duration}s ($(date -u -d @${total_duration} +%H:%M:%S 2>/dev/null || echo ${total_duration}s))"
    print_success "构建流程完成！"
}

# ============================================================================
# 错误处理
# ============================================================================
trap 'error_exit "构建过程中发生错误 (第 $LINENO 行)"' ERR

# ============================================================================
# 执行主函数
# ============================================================================
main "$@"
