#!/bin/bash

# Primihub Service 项目构建脚本
# 用于构建 primihub-service 项目

set -e  # 遇到错误立即退出

echo "开始构建 primihub-service 项目..."

# 检查 Maven 是否安装
if ! command -v mvn &> /dev/null; then
    echo "错误: Maven 未安装，请先安装 Maven"
    exit 1
fi

# 检查 Java 版本
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo "当前 Java 版本: $JAVA_VERSION"

# 执行 Maven 构建
echo "执行 Maven clean package..."
mvn clean package -DskipTests

echo "构建完成!"
echo "构建产物位于:"
find . -name "*.jar" -type f

# 显示构建结果
echo ""
echo "=== 构建结果 ==="
ls -la application/target/ 2>/dev/null || echo "application/target/ 目录不存在"
ls -la gateway/target/ 2>/dev/null || echo "gateway/target/ 目录不存在"
ls -la biz/target/ 2>/dev/null || echo "biz/target/ 目录不存在"
