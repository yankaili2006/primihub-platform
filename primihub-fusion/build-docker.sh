#!/bin/bash

# PrimiHub Fusion Docker 镜像构建脚本
# 用于构建 primihub-fusion 项目的 Docker 镜像

set -e  # 遇到错误立即退出

# 默认配置
DEFAULT_IMAGE_NAME="primihub-fusion"
DEFAULT_TAG="latest"
DOCKERFILE="Dockerfile"

# 显示使用说明
usage() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -n, --name IMAGE_NAME    指定镜像名称 (默认: $DEFAULT_IMAGE_NAME)"
    echo "  -t, --tag TAG            指定镜像标签 (默认: $DEFAULT_TAG)"
    echo "  -f, --file DOCKERFILE    指定 Dockerfile (默认: $DOCKERFILE)"
    echo "  -l, --local              使用 Dockerfile.local 进行完整构建"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                          # 使用默认配置构建镜像"
    echo "  $0 -n my-fusion -t v1.0     # 构建名为 my-fusion:v1.0 的镜像"
    echo "  $0 -l                       # 使用 Dockerfile.local 进行完整构建"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -f|--file)
                DOCKERFILE="$2"
                shift 2
                ;;
            -l|--local)
                USE_LOCAL=true
                DOCKERFILE="Dockerfile.local"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "错误: 未知选项 $1"
                usage
                exit 1
                ;;
        esac
    done
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "错误: Docker 未安装，请先安装 Docker"
        exit 1
    fi
}

# 检查构建产物（仅在使用默认 Dockerfile 时）
check_build_artifacts() {
    if [[ "$DOCKERFILE" == "Dockerfile" ]]; then
        local jar_file=$(find fusion-api/target -name "*-SNAPSHOT.jar" -type f 2>/dev/null | head -n 1)
        if [[ -z "$jar_file" ]]; then
            echo "错误: 未找到构建产物，请先运行 build.sh 或使用 -l 选项进行完整构建"
            echo "提示: 运行 ./build.sh 构建项目，或使用 ./build-docker.sh -l 进行完整 Docker 构建"
            exit 1
        fi
        echo "找到构建产物: $jar_file"
    fi
}

# 构建 Docker 镜像
build_image() {
    local full_image_name="${IMAGE_NAME}:${TAG}"
    
    echo "开始构建 Docker 镜像..."
    echo "镜像名称: $full_image_name"
    echo "使用 Dockerfile: $DOCKERFILE"
    
    # 检查 Dockerfile 是否存在
    if [[ ! -f "$DOCKERFILE" ]]; then
        echo "错误: Dockerfile '$DOCKERFILE' 不存在"
        exit 1
    fi
    
    # 执行 Docker 构建
    docker build -t "$full_image_name" -f "$DOCKERFILE" .
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo "=== 构建成功 ==="
        echo "镜像: $full_image_name"
        echo ""
        echo "运行容器:"
        echo "  docker run -d -p 8099:8099 --name primihub-fusion $full_image_name"
        echo ""
        echo "查看镜像:"
        echo "  docker images | grep $IMAGE_NAME"
    else
        echo "错误: Docker 构建失败"
        exit 1
    fi
}

# 主函数
main() {
    # 设置默认值
    IMAGE_NAME="${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}"
    TAG="${TAG:-$DEFAULT_TAG}"
    USE_LOCAL=${USE_LOCAL:-false}
    
    # 解析参数
    parse_args "$@"
    
    echo "=== PrimiHub Fusion Docker 镜像构建 ==="
    echo ""
    
    # 检查 Docker
    check_docker
    
    # 检查构建产物（如果使用默认 Dockerfile）
    if [[ "$USE_LOCAL" == "false" ]]; then
        check_build_artifacts
    fi
    
    # 构建镜像
    build_image
}

# 执行主函数
main "$@"
