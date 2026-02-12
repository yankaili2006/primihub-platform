#!/bin/bash

###############################################################################
# PrimiHub 前端 - 使用Docker构建userId修复版本
###############################################################################

set -e

echo "============================================"
echo "PrimiHub 前端 - Docker构建userId修复版本"
echo "============================================"
echo ""

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
WEB_DIR="$SCRIPT_DIR/primihub-webconsole"

# 检查是否在正确的目录
if [ ! -d "$WEB_DIR" ]; then
    echo "错误：找不到 primihub-webconsole 目录"
    exit 1
fi

echo "✓ 工作目录: $WEB_DIR"
echo ""

# 进入前端目录
cd "$WEB_DIR"

# 检查修改
echo "[1/4] 验证代码修改..."
if grep -q "从 localStorage 读取" src/utils/request.js; then
    echo "✓ request.js 已包含userId修复"
else
    echo "⚠ request.js 可能未正确修改"
fi
echo ""

# 构建Docker镜像
echo "[2/4] 使用Docker构建镜像..."
echo "这可能需要几分钟，请耐心等待..."
echo ""

IMAGE_TAG="primihub-web-fix:latest"

docker build -t "$IMAGE_TAG" -f Dockerfile . 2>&1 | tail -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✓ Docker镜像构建成功"
else
    echo ""
    echo "✗ Docker镜像构建失败"
    exit 1
fi
echo ""

# 从镜像中提取dist目录
echo "[3/4] 从镜像中提取构建文件..."

# 创建临时容器
TEMP_CONTAINER="temp_web_extract_$$"
docker create --name "$TEMP_CONTAINER" "$IMAGE_TAG" > /dev/null

# 复制文件
mkdir -p /tmp/primihub-web-fix
docker cp "$TEMP_CONTAINER":/usr/local/nginx/html/. /tmp/primihub-web-fix/

# 删除临时容器
docker rm "$TEMP_CONTAINER" > /dev/null

echo "✓ 文件已提取到 /tmp/primihub-web-fix"
echo ""

# 更新运行中的容器
echo "[4/4] 更新运行中的容器..."
echo ""

CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

for container in "${CONTAINERS[@]}"; do
    echo "处理容器: $container"

    # 检查容器是否运行
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "  ⚠ 容器未运行，跳过"
        continue
    fi

    # 备份
    echo "  - 备份原始文件..."
    docker exec $container sh -c "cp -r /usr/local/nginx/html /usr/local/nginx/html.backup-\$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

    # 复制新文件
    echo "  - 复制新构建的文件..."
    docker cp /tmp/primihub-web-fix/. $container:/usr/local/nginx/html/

    if [ $? -eq 0 ]; then
        echo "  ✓ 更新成功"
    else
        echo "  ✗ 更新失败"
    fi
    echo ""
done

# 清理
echo "清理临时文件..."
rm -rf /tmp/primihub-web-fix

echo ""
echo "============================================"
echo "✓ 构建和部署完成！"
echo "============================================"
echo ""
echo "镜像信息："
echo "  - 镜像名称: $IMAGE_TAG"
echo "  - 镜像大小: $(docker images $IMAGE_TAG --format '{{.Size}}')"
echo ""
echo "验证修复："
echo "1. 在浏览器中按 Ctrl+F5 强制刷新"
echo "2. 按 F12 打开开发者工具"
echo "3. 切换到 Network 标签"
echo "4. 点击"我的资源""
echo "5. 查看请求头中是否包含 userId"
echo ""
read -p "是否现在重启前端容器以立即生效？(y/n): " restart_now

if [ "$restart_now" = "y" ]; then
    echo ""
    echo "重启前端容器..."
    cd /mnt/data1/github/primihub-deploy/docker-all-in-one
    docker-compose restart manage-web0 manage-web1 manage-web2
    echo ""
    echo "✓ 容器已重启，等待服务启动..."
    sleep 10
    echo "✓ 完成！"
fi

echo ""
