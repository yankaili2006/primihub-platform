#!/bin/bash

# 快速构建ARM版本镜像脚本
# 用法: ./quick-build-arm.sh [镜像标签]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== PrimiHub ARM镜像快速构建 ===${NC}"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    exit 1
fi

# 检查Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}错误: Maven未安装${NC}"
    exit 1
fi

# 设置镜像标签
TAG=${1:-"primihub/privacy:arm64-latest"}

echo -e "${YELLOW}构建镜像标签: $TAG${NC}"
echo -e "${YELLOW}系统架构: $(arch)${NC}"

# 清理之前的构建
echo -e "\n${YELLOW}[1/4] 清理构建文件...${NC}"
find . -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

# 编译SDK
echo -e "\n${YELLOW}[2/4] 编译primihub-sdk...${NC}"
cd primihub-sdk
ARCH=$(arch | sed 's/arm64/aarch_64/' | sed 's/aarch64/aarch_64/' | sed 's/amd64/x86_64/')
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=linux-${ARCH}
cd ..

# 编译Service
echo -e "\n${YELLOW}[3/4] 编译primihub-service...${NC}"
cd primihub-service
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true
cd ..

# 构建Docker镜像
echo -e "\n${YELLOW}[4/4] 构建Docker镜像...${NC}"
docker build --platform linux/arm64 -t "$TAG" .

# 验证镜像
echo -e "\n${GREEN}=== 构建完成 ===${NC}"
echo -e "镜像信息:"
docker images | grep "$(echo $TAG | cut -d: -f1)"

echo -e "\n${GREEN}镜像架构验证:${NC}"
ARCH=$(docker inspect "$TAG" --format='{{.Architecture}}')
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    echo -e "${GREEN}✓ 镜像架构: $ARCH (ARM64)${NC}"
else
    echo -e "${YELLOW}⚠ 镜像架构: $ARCH${NC}"
fi

echo -e "\n${GREEN}使用说明:${NC}"
echo "运行容器: docker run -d -p 8080:8080 $TAG"
echo "导出镜像: docker save $TAG -o primihub-arm64.tar"
echo "加载镜像: docker load -i primihub-arm64.tar"