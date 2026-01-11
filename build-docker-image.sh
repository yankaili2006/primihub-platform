#!/bin/bash

###############################################################################
# PrimiHub Platform Docker 镜像构建脚本
# 基于 Jenkins Pipeline 配置生成
# 功能: 编译项目并构建 Docker 镜像
# 用法: ./build-docker-image.sh [OPTIONS]
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
IMAGE_NAME="${IMAGE_NAME:-primihub/privacy}"
IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
DOCKERFILE="${DOCKERFILE:-./primihub-service/Dockerfile.local}"
BUILD_CONTEXT="${BUILD_CONTEXT:-./primihub-service}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
SKIP_BUILD="${SKIP_BUILD:-false}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"

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

    # 检查 Maven
    if ! command -v mvn &> /dev/null; then
        print_error "Maven 未安装"
        ((missing_deps++))
    else
        local mvn_version=$(mvn --version 2>&1 | head -1)
        print_success "Maven: $mvn_version"
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

    # 检查 Java
    if ! command -v java &> /dev/null; then
        print_error "Java 未安装"
        ((missing_deps++))
    else
        local java_version=$(java -version 2>&1 | head -1)
        print_success "Java: $java_version"
    fi

    if [ $missing_deps -gt 0 ]; then
        error_exit "缺少 $missing_deps 个必需工具，请先安装"
    fi

    # 检查项目目录
    if [ ! -d "$SCRIPT_DIR/primihub-sdk" ]; then
        error_exit "primihub-sdk 目录不存在"
    fi

    if [ ! -d "$SCRIPT_DIR/primihub-service" ]; then
        error_exit "primihub-service 目录不存在"
    fi

    if [ ! -f "$SCRIPT_DIR/$DOCKERFILE" ]; then
        error_exit "Dockerfile 不存在: $DOCKERFILE"
    fi

    print_success "所有前置条件满足"
}

# ============================================================================
# Stage 1: Build (编译阶段)
# ============================================================================
build_sdk() {
    print_header "Stage 1.1: 编译 primihub-sdk"

    cd "$SCRIPT_DIR/primihub-sdk"
    print_info "当前目录: $(pwd)"
    print_info "Maven 命令: mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=linux-x86_64"

    local start_time=$(date +%s)

    if [ "$CLEAN_BUILD" = "true" ]; then
        print_step "执行 Maven clean..."
        mvn clean || error_exit "Maven clean 失败"
    fi

    print_step "开始编译 primihub-sdk..."
    if mvn clean install \
        -Dmaven.test.skip=true \
        -Dasciidoctor.skip=true \
        -Dos.detected.classifier=linux-x86_64; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "primihub-sdk 编译成功 (耗时: ${duration}s)"
    else
        error_exit "primihub-sdk 编译失败"
    fi

    # 验证编译产物
    if [ -f "target/primihub-sdk-1.0.1.jar" ]; then
        local jar_size=$(du -h target/primihub-sdk-1.0.1.jar | cut -f1)
        print_success "SDK JAR 文件: target/primihub-sdk-1.0.1.jar ($jar_size)"
    else
        print_warning "未找到 SDK JAR 文件"
    fi

    cd "$SCRIPT_DIR"
}

build_service() {
    print_header "Stage 1.2: 编译 primihub-service"

    cd "$SCRIPT_DIR/primihub-service"
    print_info "当前目录: $(pwd)"
    print_info "Maven 命令: mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true"

    local start_time=$(date +%s)

    print_step "开始编译 primihub-service..."
    if mvn clean install \
        -Dmaven.test.skip=true \
        -Dasciidoctor.skip=true; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "primihub-service 编译成功 (耗时: ${duration}s)"
    else
        error_exit "primihub-service 编译失败"
    fi

    # 验证编译产物
    print_step "验证编译产物..."

    if [ -f "application/target/application-1.0-SNAPSHOT.jar" ]; then
        local app_size=$(du -h application/target/application-1.0-SNAPSHOT.jar | cut -f1)
        print_success "Application JAR: application/target/application-1.0-SNAPSHOT.jar ($app_size)"
    else
        error_exit "未找到 application JAR 文件"
    fi

    if [ -f "gateway/target/gateway-1.0-SNAPSHOT.jar" ]; then
        local gw_size=$(du -h gateway/target/gateway-1.0-SNAPSHOT.jar | cut -f1)
        print_success "Gateway JAR: gateway/target/gateway-1.0-SNAPSHOT.jar ($gw_size)"
    else
        error_exit "未找到 gateway JAR 文件"
    fi

    cd "$SCRIPT_DIR"
}

# ============================================================================
# Stage 2: Building app image (构建镜像阶段)
# ============================================================================
build_docker_image() {
    print_header "Stage 2: 构建 Docker 镜像"

    cd "$SCRIPT_DIR"

    print_info "构建配置:"
    echo "  Registry:    $DOCKER_REGISTRY"
    echo "  Image Name:  $IMAGE_NAME"
    echo "  Image Tag:   $IMAGE_TAG"
    echo "  Build Number: $BUILD_NUMBER"
    echo "  Dockerfile:  $DOCKERFILE"
    echo "  Context:     $BUILD_CONTEXT"

    local start_time=$(date +%s)

    print_step "开始构建 Docker 镜像..."
    print_info "执行命令: docker build -t $IMAGE_TAG -f $DOCKERFILE $BUILD_CONTEXT"

    if docker build \
        -t "$IMAGE_TAG" \
        -f "$DOCKERFILE" \
        "$BUILD_CONTEXT"; then

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
    echo "编译产物:"
    echo "  SDK:         primihub-sdk/target/primihub-sdk-1.0.1.jar"
    echo "  Application: primihub-service/application/target/application-1.0-SNAPSHOT.jar"
    echo "  Gateway:     primihub-service/gateway/target/gateway-1.0-SNAPSHOT.jar"
    echo ""
    echo "Docker 镜像:"
    docker images "${DOCKER_REGISTRY}/${IMAGE_NAME}" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
    echo ""
    echo "下一步操作:"
    echo "  1. 运行容器:"
    echo "     docker run -d -p 8080:8080 --name primihub-platform $IMAGE_TAG"
    echo ""
    echo "  2. 推送到仓库:"
    echo "     docker push $IMAGE_TAG"
    echo ""
    echo "  3. 使用 docker-compose 部署:"
    echo "     docker-compose up -d"
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

构建 PrimiHub Platform Docker 镜像

选项:
  -h, --help              显示此帮助信息
  -b, --build-number NUM  设置构建编号 (默认: 时间戳)
  -r, --registry ADDR     设置 Docker 仓库地址 (默认: 192.168.99.10)
  -n, --name NAME         设置镜像名称 (默认: primihub/privacy)
  -f, --dockerfile FILE   指定 Dockerfile (默认: ./primihub-service/Dockerfile.local)
  -c, --context PATH      指定构建上下文 (默认: ./primihub-service)
  -p, --push              构建后推送镜像到仓库
  -s, --skip-build        跳过编译阶段，仅构建镜像
  -C, --clean             执行 clean build
  --no-cleanup            不清理悬空镜像

环境变量:
  BUILD_NUMBER            构建编号
  DOCKER_REGISTRY         Docker 仓库地址
  IMAGE_NAME              镜像名称
  PUSH_IMAGE              是否推送镜像 (true/false)
  SKIP_BUILD              是否跳过编译 (true/false)
  CLEAN_BUILD             是否清理后构建 (true/false)

示例:
  # 基本构建
  $0

  # 指定构建号并推送
  $0 --build-number 1.7.0 --push

  # 使用自定义仓库
  $0 --registry registry.example.com --name myapp/platform

  # 仅构建 Docker 镜像（跳过编译）
  $0 --skip-build

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
        -c|--context)
            BUILD_CONTEXT="$2"
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

    print_header "PrimiHub Platform Docker 镜像构建"

    echo "构建配置:"
    echo "  开始时间:    $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  构建目录:    $SCRIPT_DIR"
    echo "  构建编号:    $BUILD_NUMBER"
    echo "  镜像标签:    $IMAGE_TAG"
    echo "  跳过编译:    $SKIP_BUILD"
    echo "  清理构建:    $CLEAN_BUILD"
    echo "  推送镜像:    $PUSH_IMAGE"
    echo ""

    # 检查前置条件
    check_prerequisites

    # Stage 1: Build (编译阶段)
    if [ "$SKIP_BUILD" != "true" ]; then
        build_sdk
        build_service
    else
        print_warning "跳过编译阶段 (--skip-build)"
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

    print_success "总耗时: ${total_duration}s ($(date -u -d @${total_duration} +%H:%M:%S))"
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
