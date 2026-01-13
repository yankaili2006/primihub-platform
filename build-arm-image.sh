#!/bin/bash

###############################################################################
# PrimiHub Platform ARM Docker 镜像构建脚本
# 专门用于构建ARM架构（arm64/aarch64）的Docker镜像
# 用法: ./build-arm-image.sh [OPTIONS]
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
IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:arm64-${BUILD_NUMBER}"
DOCKERFILE="${DOCKERFILE:-./Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
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

    # 检查当前架构
    local current_arch=$(arch)
    print_info "当前系统架构: $current_arch"
    
    if [[ "$current_arch" != "arm64" && "$current_arch" != "aarch64" ]]; then
        print_warning "当前系统不是ARM架构，但将继续构建ARM镜像"
    fi

    if [[ $missing_deps -gt 0 ]]; then
        error_exit "缺少 $missing_deps 个依赖项，请先安装"
    fi

    print_success "所有前置条件检查通过"
}

# ============================================================================
# 清理构建
# ============================================================================
clean_build() {
    print_header "清理构建文件"

    print_step "清理 Maven 构建文件"
    if [[ -d "primihub-sdk" ]]; then
        cd primihub-sdk && mvn clean 2>&1 | grep -E "(BUILD|ERROR|WARNING)" || true
        cd "$SCRIPT_DIR"
    fi

    if [[ -d "primihub-service" ]]; then
        cd primihub-service && mvn clean 2>&1 | grep -E "(BUILD|ERROR|WARNING)" || true
        cd "$SCRIPT_DIR"
    fi

    print_step "清理 target 目录"
    find . -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

    print_success "清理完成"
}

# ============================================================================
# 编译 primihub-sdk (ARM架构)
# ============================================================================
build_sdk() {
    print_header "编译 primihub-sdk (ARM架构)"

    if [[ ! -d "primihub-sdk" ]]; then
        error_exit "primihub-sdk 目录不存在"
    fi

    local start_time=$(date +%s)
    
    print_step "检测系统架构并设置Maven参数"
    local arch_param=""
    local current_arch=$(arch)
    
    case $current_arch in
        "arm64"|"aarch64")
            arch_param="-Dos.detected.classifier=linux-aarch_64"
            print_info "检测到ARM64架构，使用参数: $arch_param"
            ;;
        "x86_64"|"amd64")
            arch_param="-Dos.detected.classifier=linux-x86_64"
            print_info "检测到x86_64架构，使用参数: $arch_param"
            ;;
        *)
            print_warning "未知架构: $current_arch，使用默认参数"
            arch_param="-Dos.detected.classifier=linux-aarch_64"
            ;;
    esac

    print_step "开始编译 primihub-sdk"
    cd primihub-sdk
    
    if ! mvn clean install \
        -Dmaven.test.skip=true \
        -Dasciidoctor.skip=true \
        $arch_param \
        2>&1 | tee sdk-build.log; then
        error_exit "primihub-sdk 编译失败，请查看 sdk-build.log"
    fi

    # 验证 JAR 文件
    if ! find . -name "*.jar" -type f | grep -q .; then
        error_exit "未找到生成的 JAR 文件"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "primihub-sdk 编译成功 (耗时: ${duration}s)"
    cd "$SCRIPT_DIR"
}

# ============================================================================
# 编译 primihub-service
# ============================================================================
build_service() {
    print_header "编译 primihub-service"

    if [[ ! -d "primihub-service" ]]; then
        error_exit "primihub-service 目录不存在"
    fi

    local start_time=$(date +%s)
    
    print_step "开始编译 primihub-service"
    cd primihub-service
    
    if ! mvn clean install \
        -Dmaven.test.skip=true \
        -Dasciidoctor.skip=true \
        2>&1 | tee service-build.log; then
        error_exit "primihub-service 编译失败，请查看 service-build.log"
    fi

    # 验证 JAR 文件
    local jar_files=$(find . -name "*-SNAPSHOT.jar" -type f)
    if [[ -z "$jar_files" ]]; then
        error_exit "未找到生成的 SNAPSHOT JAR 文件"
    fi
    
    print_info "找到以下JAR文件:"
    echo "$jar_files"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "primihub-service 编译成功 (耗时: ${duration}s)"
    cd "$SCRIPT_DIR"
}

# ============================================================================
# 构建 Docker 镜像 (ARM架构)
# ============================================================================
build_docker_image() {
    print_header "构建 Docker 镜像 (ARM架构)"

    if [[ ! -f "$DOCKERFILE" ]]; then
        error_exit "Dockerfile 不存在: $DOCKERFILE"
    fi

    local start_time=$(date +%s)
    
    print_info "镜像标签: $IMAGE_TAG"
    print_info "Dockerfile: $DOCKERFILE"
    print_info "构建上下文: $BUILD_CONTEXT"
    
    print_step "开始构建 Docker 镜像"
    
    # 使用 --platform 参数指定ARM架构
    if ! docker build \
        --platform linux/arm64 \
        -t "$IMAGE_TAG" \
        -f "$DOCKERFILE" \
        "$BUILD_CONTEXT" \
        2>&1 | tee docker-build.log; then
        error_exit "Docker 镜像构建失败，请查看 docker-build.log"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Docker 镜像构建成功 (耗时: ${duration}s)"
    
    # 显示镜像信息
    print_step "镜像信息:"
    docker images | grep "$IMAGE_TAG"
    
    # 检查镜像架构
    print_step "验证镜像架构:"
    docker inspect "$IMAGE_TAG" --format='{{.Architecture}}' | tee -a docker-build.log
}

# ============================================================================
# 推送镜像到仓库
# ============================================================================
push_image() {
    if [[ "$PUSH_IMAGE" != "true" ]]; then
        return 0
    fi

    print_header "推送镜像到仓库"

    print_step "推送镜像: $IMAGE_TAG"
    
    if ! docker push "$IMAGE_TAG" 2>&1 | tee docker-push.log; then
        error_exit "镜像推送失败，请查看 docker-push.log"
    fi

    print_success "镜像推送成功"
}

# ============================================================================
# 显示帮助信息
# ============================================================================
show_help() {
    cat << EOF
PrimiHub Platform ARM Docker 镜像构建脚本

用法: $0 [OPTIONS]

选项:
  -h, --help            显示此帮助信息
  -c, --clean           清理构建文件
  -s, --skip-build      跳过编译步骤，直接构建镜像
  -p, --push            构建完成后推送镜像到仓库
  -t, --tag TAG         指定镜像标签 (默认: arm64-\${BUILD_NUMBER})
  -r, --registry REG    指定Docker仓库地址 (默认: 192.168.99.10)
  -n, --name NAME       指定镜像名称 (默认: primihub/privacy)
  -f, --file FILE       指定Dockerfile路径 (默认: ./Dockerfile)
  --context CONTEXT     指定构建上下文路径 (默认: .)

环境变量:
  BUILD_NUMBER          构建编号 (默认: 时间戳)
  DOCKER_REGISTRY       Docker仓库地址
  IMAGE_NAME            镜像名称
  IMAGE_TAG             完整镜像标签
  DOCKERFILE            Dockerfile路径
  BUILD_CONTEXT         构建上下文路径
  PUSH_IMAGE            是否推送镜像 (true/false)
  SKIP_BUILD            是否跳过编译 (true/false)
  CLEAN_BUILD           是否清理构建 (true/false)

示例:
  $0                    标准ARM镜像构建
  $0 -c                 清理后构建
  $0 -p                 构建并推送镜像
  $0 -t v1.0.0-arm64    指定标签构建
  $0 --registry my.registry.com --name myapp 使用自定义仓库和名称

EOF
}

# ============================================================================
# 解析命令行参数
# ============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD="true"
                shift
                ;;
            -s|--skip-build)
                SKIP_BUILD="true"
                shift
                ;;
            -p|--push)
                PUSH_IMAGE="true"
                shift
                ;;
            -t|--tag)
                IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:$2"
                shift 2
                ;;
            -r|--registry)
                DOCKER_REGISTRY="$2"
                IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:arm64-${BUILD_NUMBER}"
                shift 2
                ;;
            -n|--name)
                IMAGE_NAME="$2"
                IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:arm64-${BUILD_NUMBER}"
                shift 2
                ;;
            -f|--file)
                DOCKERFILE="$2"
                shift 2
                ;;
            --context)
                BUILD_CONTEXT="$2"
                shift 2
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    print_header "PrimiHub Platform ARM Docker 镜像构建"
    print_info "开始时间: $(date)"
    print_info "工作目录: $SCRIPT_DIR"
    
    parse_args "$@"
    
    check_prerequisites
    
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        clean_build
    fi
    
    if [[ "$SKIP_BUILD" != "true" ]]; then
        build_sdk
        build_service
    else
        print_warning "跳过编译步骤"
    fi
    
    build_docker_image
    
    if [[ "$PUSH_IMAGE" == "true" ]]; then
        push_image
    fi
    
    print_header "构建完成"
    print_success "ARM Docker 镜像构建成功!"
    print_info "镜像标签: $IMAGE_TAG"
    print_info "完成时间: $(date)"
    
    # 显示使用说明
    echo -e "\n${YELLOW}使用说明:${NC}"
    echo "运行容器: docker run -d -p 8080:8080 $IMAGE_TAG"
    echo "查看镜像: docker images | grep $(echo $IMAGE_TAG | cut -d: -f1)"
    echo "检查架构: docker inspect $IMAGE_TAG --format='{{.Architecture}}'"
}

# ============================================================================
# 脚本入口
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi