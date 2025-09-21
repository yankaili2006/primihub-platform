#!/bin/bash

# PrimiHub WebConsole 项目构建脚本
# 用于构建 primihub-webconsole 前端项目

set -e  # 遇到错误立即退出

echo "开始构建 primihub-webconsole 项目..."

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
    echo "错误: Node.js 未安装，请先安装 Node.js"
    exit 1
fi

# 检查 npm 是否安装
if ! command -v npm &> /dev/null; then
    echo "错误: npm 未安装，请先安装 npm"
    exit 1
fi

# 检查 Node.js 版本
NODE_VERSION=$(node -v)
echo "当前 Node.js 版本: $NODE_VERSION"

# 检查 npm 版本
NPM_VERSION=$(npm -v)
echo "当前 npm 版本: $NPM_VERSION"

# 安装依赖
echo "安装项目依赖..."
npm install

# 执行构建
echo "执行生产环境构建..."
npm run build:prod

echo "构建完成!"
echo "构建产物位于 dist/ 目录"

# 显示构建结果
echo ""
echo "=== 构建结果 ==="
if [ -d "dist" ]; then
    ls -la dist/
    echo ""
    echo "构建文件统计:"
    find dist/ -type f | wc -l
else
    echo "dist/ 目录不存在，构建可能失败"
    exit 1
fi

echo ""
echo "构建成功完成！"
