#!/bin/bash

###############################################################################
# PrimiHub Platform Docker 镜像快速构建脚本
# 简化版本，适合快速构建和测试
###############################################################################

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}
IMAGE_TAG="192.168.99.10/primihub/privacy:${BUILD_NUMBER}"

echo "========================================"
echo "PrimiHub Docker 快速构建"
echo "========================================"
echo "Build Number: $BUILD_NUMBER"
echo "Image Tag:    $IMAGE_TAG"
echo ""

# 编译 SDK
echo "[1/3] 编译 primihub-sdk..."
cd "$SCRIPT_DIR/primihub-sdk"
mvn clean install \
  -Dmaven.test.skip=true \
  -Dasciidoctor.skip=true \
  -Dos.detected.classifier=linux-x86_64 \
  -q -DskipTests

# 编译 Service
echo "[2/3] 编译 primihub-service..."
cd "$SCRIPT_DIR/primihub-service"
mvn clean install \
  -Dmaven.test.skip=true \
  -Dasciidoctor.skip=true \
  -q -DskipTests

# 构建镜像
echo "[3/3] 构建 Docker 镜像..."
cd "$SCRIPT_DIR"
docker build \
  -t "$IMAGE_TAG" \
  -f ./primihub-service/Dockerfile.local \
  ./primihub-service

# 添加 latest 标签
docker tag "$IMAGE_TAG" "192.168.99.10/primihub/privacy:latest"

echo ""
echo "✓ 构建完成！"
echo ""
echo "镜像标签:"
echo "  - $IMAGE_TAG"
echo "  - 192.168.99.10/primihub/privacy:latest"
echo ""
echo "运行容器:"
echo "  docker run -d -p 8080:8080 $IMAGE_TAG"
echo ""
