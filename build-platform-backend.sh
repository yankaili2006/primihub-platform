#!/bin/bash

###############################################################################
# PrimiHub Platform 后端镜像快速构建脚本 (修复版)
# 用途: 构建包含 Java 应用的后端镜像
# 使用: ./build-platform-backend.sh [version]
###############################################################################

set -e

# 默认配置
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERSION=${1:-1.8.0}
DOCKER_REGISTRY="192.168.99.10"
IMAGE_NAME="primihub/platform"
IMAGE_TAG="${DOCKER_REGISTRY}/${IMAGE_NAME}:${VERSION}"

# 使用 Ubuntu 22.04 + OpenJDK 8 的 Dockerfile
DOCKERFILE="./primihub-service/Dockerfile.ubuntu"
BUILD_CONTEXT="./primihub-service"

echo "========================================"
echo "PrimiHub Platform 后端镜像构建"
echo "========================================"
echo "版本号:       $VERSION"
echo "镜像标签:     $IMAGE_TAG"
echo "Dockerfile:   $DOCKERFILE"
echo ""

# 检查前置条件
echo "[检查] 检查前置条件..."
if ! command -v mvn &> /dev/null; then
    echo "错误: Maven 未安装"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/primihub-service" ]; then
    echo "错误: primihub-service 目录不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/$DOCKERFILE" ]; then
    echo "错误: Dockerfile 不存在: $DOCKERFILE"
    exit 1
fi

echo "✓ 前置条件检查通过"
echo ""

# Stage 1: 编译 SDK
echo "[1/3] 编译 primihub-sdk..."
cd "$SCRIPT_DIR/primihub-sdk"
mvn clean install \
    -Dmaven.test.skip=true \
    -Dasciidoctor.skip=true \
    -Dos.detected.classifier=linux-x86_64 \
    || { echo "错误: SDK 编译失败"; exit 1; }

echo "✓ SDK 编译成功"
echo ""

# Stage 2: 编译 Service (Application + Gateway)
echo "[2/3] 编译 primihub-service (application.jar + gateway.jar)..."
cd "$SCRIPT_DIR/primihub-service"
mvn clean install \
    -Dmaven.test.skip=true \
    -Dasciidoctor.skip=true \
    || { echo "错误: Service 编译失败"; exit 1; }

# 验证 JAR 文件
if [ ! -f "application/target/application-1.0-SNAPSHOT.jar" ]; then
    echo "错误: application.jar 不存在"
    exit 1
fi

if [ ! -f "gateway/target/gateway-1.0-SNAPSHOT.jar" ]; then
    echo "错误: gateway.jar 不存在"
    exit 1
fi

APP_SIZE=$(du -h application/target/application-1.0-SNAPSHOT.jar | cut -f1)
GW_SIZE=$(du -h gateway/target/gateway-1.0-SNAPSHOT.jar | cut -f1)

echo "✓ Service 编译成功"
echo "  - application.jar: $APP_SIZE"
echo "  - gateway.jar:     $GW_SIZE"
echo ""

# Stage 3: 构建 Docker 镜像
echo "[3/3] 构建 Docker 镜像..."
cd "$SCRIPT_DIR"
docker build \
    -t "$IMAGE_TAG" \
    -f "$DOCKERFILE" \
    "$BUILD_CONTEXT" \
    || { echo "错误: 镜像构建失败"; exit 1; }

# 添加 latest 标签
docker tag "$IMAGE_TAG" "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"

echo "✓ 镜像构建成功"
echo ""

# 显示镜像信息
echo "========================================"
echo "构建完成！"
echo "========================================"
echo ""
echo "镜像信息:"
docker images "${DOCKER_REGISTRY}/${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | head -n 10
echo ""

# 验证镜像包含 Java
echo "[验证] 检查镜像是否包含 Java..."
if docker run --rm --entrypoint /bin/sh "$IMAGE_TAG" -c "java -version" &> /dev/null; then
    JAVA_VERSION=$(docker run --rm --entrypoint /bin/sh "$IMAGE_TAG" -c "java -version 2>&1" | head -1)
    echo "✓ Java 已安装: $JAVA_VERSION"
else
    echo "❌ 警告: 镜像中未找到 Java！"
    exit 1
fi

# 验证 JAR 文件
echo "[验证] 检查 JAR 文件..."
if docker run --rm --entrypoint /bin/sh "$IMAGE_TAG" -c "ls -lh /applications/*.jar" 2>&1 | grep -q "application.jar\|gateway.jar"; then
    echo "✓ JAR 文件已包含:"
    docker run --rm --entrypoint /bin/sh "$IMAGE_TAG" -c "ls -lh /applications/" 2>&1 | grep "\.jar"
else
    echo "❌ 警告: JAR 文件未找到！"
    exit 1
fi

echo ""
echo "下一步操作:"
echo ""
echo "  1. 测试容器:"
echo "     docker run -d -p 8090:8090 --name test-app $IMAGE_TAG"
echo ""
echo "  2. 更新 docker-all-in-one 部署:"
echo "     cd ~/github/primihub-deploy/docker-all-in-one"
echo "     # 修改 .env 文件"
echo "     PRIMIHUB_PLATFORM=$IMAGE_TAG"
echo "     # 重新部署"
echo "     docker compose up -d --force-recreate application0 application1 application2 gateway0 gateway1 gateway2"
echo ""
echo "  3. 推送到仓库 (可选):"
echo "     docker push $IMAGE_TAG"
echo ""
