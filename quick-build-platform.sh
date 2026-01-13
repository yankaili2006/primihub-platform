#!/bin/bash

###############################################################################
# PrimiHub Platform 前端镜像快速构建脚本
# 简化版本，适合快速构建和测试
###############################################################################

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}
IMAGE_TAG="192.168.99.10/primihub/platform:${BUILD_NUMBER}"

echo "========================================"
echo "PrimiHub 前端 Docker 快速构建"
echo "========================================"
echo "Build Number: $BUILD_NUMBER"
echo "Image Tag:    $IMAGE_TAG"
echo ""

# 进入前端目录
cd "$SCRIPT_DIR/primihub-webconsole"

# 安装依赖并构建
echo "[1/2] 构建前端项目..."
npm install -q && npm run build:prod

# 构建镜像
echo "[2/2] 构建 Docker 镜像..."
docker build \
  -t "$IMAGE_TAG" \
  -f Dockerfile.local \
  .

# 添加 latest 标签
docker tag "$IMAGE_TAG" "192.168.99.10/primihub/platform:latest"

echo ""
echo "✓ 构建完成！"
echo ""
echo "镜像标签:"
echo "  - $IMAGE_TAG"
echo "  - 192.168.99.10/primihub/platform:latest"
echo ""
echo "运行容器:"
echo "  docker run -d -p 80:80 --name primihub-web $IMAGE_TAG"
echo ""
echo "访问地址:"
echo "  http://localhost"
echo ""
