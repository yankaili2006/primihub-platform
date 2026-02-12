#!/bin/bash

###############################################################################
# PrimiHub 前端 - userId修复版本构建脚本
###############################################################################

set -e

echo "============================================"
echo "PrimiHub 前端 - 构建userId修复版本"
echo "============================================"
echo ""

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
WEB_DIR="$SCRIPT_DIR/primihub-webconsole"

# 检查是否在正确的目录
if [ ! -d "$WEB_DIR" ]; then
    echo "错误：找不到 primihub-webconsole 目录"
    echo "当前目录: $(pwd)"
    exit 1
fi

echo "✓ 工作目录: $WEB_DIR"
echo ""

# 进入前端目录
cd "$WEB_DIR"

# 检查修改是否存在
echo "[1/5] 验证代码修改..."
if grep -q "从 localStorage 读取" src/utils/request.js; then
    echo "✓ request.js 已包含userId修复"
else
    echo "⚠ request.js 可能未正确修改"
    echo "请检查 src/utils/request.js 文件"
    read -p "是否继续构建？(y/n): " continue_build
    if [ "$continue_build" != "y" ]; then
        exit 1
    fi
fi
echo ""

# 清理旧的构建文件
echo "[2/5] 清理旧的构建文件..."
rm -rf dist/ node_modules/.cache/
echo "✓ 清理完成"
echo ""

# 构建前端
echo "[3/5] 构建前端项目（这可能需要几分钟）..."
echo "运行: npm run build:prod"
echo ""

if npm run build:prod; then
    echo ""
    echo "✓ 前端构建成功"
else
    echo ""
    echo "✗ 前端构建失败"
    echo "请检查错误信息并修复后重试"
    exit 1
fi
echo ""

# 查看构建结果
echo "[4/5] 检查构建结果..."
if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
    echo "✓ dist 目录已生成"
    echo "  文件大小: $(du -sh dist | cut -f1)"
    echo "  文件数量: $(find dist -type f | wc -l)"
else
    echo "✗ dist 目录为空或不存在"
    exit 1
fi
echo ""

# 复制到容器
echo "[5/5] 更新容器中的文件..."
echo ""

CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

for container in "${CONTAINERS[@]}"; do
    echo "处理容器: $container"

    # 检查容器是否运行
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "  ⚠ 容器未运行，跳过"
        continue
    fi

    # 备份原始文件
    echo "  - 备份原始文件..."
    docker exec $container sh -c "cp -r /usr/local/nginx/html /usr/local/nginx/html.backup-\$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

    # 复制新文件
    echo "  - 复制新构建的文件..."
    docker cp dist/. $container:/usr/local/nginx/html/

    if [ $? -eq 0 ]; then
        echo "  ✓ 更新成功"
    else
        echo "  ✗ 更新失败"
    fi
    echo ""
done

echo "============================================"
echo "构建完成！"
echo "============================================"
echo ""
echo "下一步操作："
echo ""
echo "选项1: 不重启容器（推荐）"
echo "  - 在浏览器中按 Ctrl+F5 强制刷新"
echo "  - 清除浏览器缓存"
echo ""
echo "选项2: 重启前端容器"
echo "  docker-compose restart manage-web0 manage-web1 manage-web2"
echo ""
read -p "是否现在重启前端容器？(y/n): " restart_containers

if [ "$restart_containers" = "y" ]; then
    echo ""
    echo "重启前端容器..."
    cd /mnt/data1/github/primihub-deploy/docker-all-in-one
    docker-compose restart manage-web0 manage-web1 manage-web2
    echo ""
    echo "✓ 容器已重启"
    echo "等待10秒让服务完全启动..."
    sleep 10
fi

echo ""
echo "============================================"
echo "✓ 所有操作完成！"
echo "============================================"
echo ""
echo "验证修复："
echo "1. 访问系统并登录"
echo "2. 按 F12 打开浏览器开发者工具"
echo "3. 切换到 Network 标签"
echo "4. 点击"我的资源""
echo "5. 查看请求头中是否包含 userId"
echo ""
echo "如果还有问题，请查看浏览器 Console 中的日志"
echo ""
