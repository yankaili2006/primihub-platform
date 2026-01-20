#!/bin/bash

# 联邦分析菜单访问测试脚本
# 用于在无痕模式下测试联邦分析菜单的访问权限

set -e

echo "=========================================="
echo "联邦分析菜单访问测试"
echo "=========================================="
echo ""

# 检查是否安装了 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 错误: 未安装 Node.js"
    echo "请先安装 Node.js: https://nodejs.org/"
    exit 1
fi

echo "✓ Node.js 版本: $(node --version)"
echo ""

# 进入项目目录
cd "$(dirname "$0")"

# 检查是否已安装依赖
if [ ! -d "node_modules" ]; then
    echo "📦 安装测试依赖..."
    npm install
    echo ""
fi

# 获取配置参数
BASE_URL="${BASE_URL:-http://localhost:8080}"
TEST_USERNAME="${TEST_USERNAME:-admin}"
TEST_PASSWORD="${TEST_PASSWORD:-admin123}"
HEADLESS="${HEADLESS:-true}"

echo "配置信息:"
echo "  - 基础URL: $BASE_URL"
echo "  - 用户名: $TEST_USERNAME"
echo "  - 无头模式: $HEADLESS"
echo ""

# 提示用户确认
read -p "是否继续测试? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "测试已取消"
    exit 0
fi

echo ""
echo "=========================================="
echo "开始执行测试..."
echo "=========================================="
echo ""

# 运行测试
BASE_URL="$BASE_URL" \
TEST_USERNAME="$TEST_USERNAME" \
TEST_PASSWORD="$TEST_PASSWORD" \
HEADLESS="$HEADLESS" \
node test_federated_analysis_access.js

# 保存退出码
EXIT_CODE=$?

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 测试完成 - 所有测试通过"
else
    echo "❌ 测试完成 - 部分测试失败"
fi
echo "=========================================="

exit $EXIT_CODE
