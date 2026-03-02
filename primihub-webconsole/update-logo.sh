#!/bin/bash
#
# 更新管理平台Logo和品牌文字
# 使用方法: ./update-logo.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"

echo "========================================="
echo "更新DataItem管理平台Logo和品牌文字"
echo "========================================="
echo ""

# 检查dist目录是否存在
if [ ! -d "$DIST_DIR" ]; then
    echo "❌ 错误: dist目录不存在"
    echo "请先运行: npm run build:prod"
    exit 1
fi

echo "✅ 找到构建输出目录: $DIST_DIR"
echo ""

# 检查Docker容器是否运行
echo "检查管理平台容器状态..."
containers=$(docker ps --format "{{.Names}}" | grep "manage-web" || true)

if [ -z "$containers" ]; then
    echo "⚠️  警告: 未找到运行中的manage-web容器"
    echo ""
    echo "可用选项:"
    echo "  1. 启动容器后再运行此脚本"
    echo "  2. 手动部署dist目录到Web服务器"
    echo ""
    exit 1
fi

echo "找到以下容器:"
echo "$containers" | sed 's/^/  - /'
echo ""

# 询问是否继续
read -p "是否要更新这些容器中的前端文件? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消更新"
    exit 0
fi

echo ""
echo "开始更新容器..."

for container in $containers; do
    echo ""
    echo ">>> 更新容器: $container"

    # 备份现有文件（可选）
    echo "  - 创建备份..."
    docker exec "$container" sh -c "cd /usr/share/nginx/html && tar -czf /tmp/html-backup-$(date +%Y%m%d-%H%M%S).tar.gz ." 2>/dev/null || echo "  ⚠️  备份失败（可能无tar命令），跳过..."

    # 复制新文件
    echo "  - 复制新文件到容器..."
    docker cp "$DIST_DIR/." "$container:/usr/share/nginx/html/"

    if [ $? -eq 0 ]; then
        echo "  ✅ $container 更新成功"
    else
        echo "  ❌ $container 更新失败"
    fi
done

echo ""
echo "========================================="
echo "更新完成!"
echo "========================================="
echo ""
echo "验证步骤:"
echo "  1. 浏览器访问管理平台 (http://localhost:30811)"
echo "  2. 检查左上角logo是否显示为新logo"
echo "  3. 检查顶部导航栏是否显示'DataItem'"
echo "  4. 检查页面底部是否显示'海会科技'"
echo ""
echo "如需重启容器使更改生效（通常不需要）:"
echo "  docker restart manage-web0 manage-web1 manage-web2"
echo ""
