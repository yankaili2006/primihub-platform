#!/bin/bash

# PrimiHub 前端自动化测试工具安装和运行脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/frontend-test"

echo "=========================================="
echo "PrimiHub 前端自动化测试工具"
echo "=========================================="
echo ""

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "错误: 未安装 Node.js"
    echo "请先安装 Node.js: https://nodejs.org/"
    exit 1
fi

echo "Node.js 版本: $(node --version)"
echo "npm 版本: $(npm --version)"
echo ""

# 检查测试目录
if [ ! -d "$TEST_DIR" ]; then
    echo "错误: 测试目录不存在: $TEST_DIR"
    exit 1
fi

cd "$TEST_DIR"

# 安装依赖
if [ ! -d "node_modules" ]; then
    echo "正在安装依赖包..."
    npm install --legacy-peer-deps
    echo ""
fi

# 运行测试
echo "开始运行测试..."
echo ""

node test.js

echo ""
echo "测试完成！"
echo ""
echo "截图文件保存在 /tmp/ 目录下："
echo "  - /tmp/primihub-login-page.png"
echo "  - /tmp/primihub-after-login.png"
echo "  - /tmp/primihub-*.png"
echo ""
