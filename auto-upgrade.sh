#!/bin/bash

###############################################################################
# PrimiHub Platform 自动升级脚本
# 等待镜像构建完成后自动升级 docker-all-in-one 部署
###############################################################################

set -e

VERSION="1.8.0"
IMAGE="192.168.99.10/primihub/platform:${VERSION}"
DEPLOY_DIR="$HOME/github/primihub-deploy/docker-all-in-one"

echo "========================================"
echo "等待镜像构建完成并自动升级部署"
echo "========================================"
echo "目标镜像: $IMAGE"
echo "部署目录: $DEPLOY_DIR"
echo ""

# 等待构建进程完成
echo "[1/5] 等待构建进程完成..."
while ps aux | grep -q "build-platform-backend.sh" | grep -v grep; do
    echo "  构建进程运行中..."
    sleep 10
done
echo "✓ 构建进程已完成"
echo ""

# 等待镜像出现（检查镜像大小是否正确）
echo "[2/5] 验证镜像..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # 检查镜像是否存在且大小合理（应该大于500MB）
    IMAGE_SIZE=$(docker images --format "{{.Size}}" "$IMAGE" 2>/dev/null | head -1)

    if [ -n "$IMAGE_SIZE" ]; then
        # 转换大小为 MB 进行比较
        SIZE_NUM=$(echo "$IMAGE_SIZE" | sed 's/[^0-9.]//g')
        SIZE_UNIT=$(echo "$IMAGE_SIZE" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')

        if [ "$SIZE_UNIT" = "GB" ]; then
            echo "✓ 镜像已就绪: $IMAGE_SIZE"
            break
        elif [ "$SIZE_UNIT" = "MB" ] && [ "$(echo "$SIZE_NUM > 500" | bc)" -eq 1 ]; then
            echo "✓ 镜像已就绪: $IMAGE_SIZE"
            break
        fi
    fi

    ((RETRY_COUNT++))
    echo "  等待镜像就绪... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 10
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "❌ 错误: 镜像构建超时或失败"
    exit 1
fi

# 验证镜像包含 Java
echo ""
echo "[3/5] 验证镜像内容..."
if docker run --rm --entrypoint /bin/sh "$IMAGE" -c "java -version" &> /dev/null; then
    JAVA_VERSION=$(docker run --rm --entrypoint /bin/sh "$IMAGE" -c "java -version 2>&1" | head -1)
    echo "✓ Java已安装: $JAVA_VERSION"
else
    echo "❌ 错误: 镜像中未找到 Java！"
    exit 1
fi

# 验证 JAR 文件
if docker run --rm --entrypoint /bin/sh "$IMAGE" -c "test -f /applications/application.jar && test -f /applications/gateway.jar" 2>/dev/null; then
    echo "✓ JAR 文件已验证"
else
    echo "❌ 错误: JAR 文件未找到！"
    exit 1
fi

# 更新 .env 配置
echo ""
echo "[4/5] 更新配置..."
cd "$DEPLOY_DIR"

if grep -q "^PRIMIHUB_PLATFORM=" .env; then
    sed -i "s|^PRIMIHUB_PLATFORM=.*|PRIMIHUB_PLATFORM=$IMAGE|" .env
    echo "✓ .env 文件已更新"
else
    echo "❌ 错误: .env 文件中未找到 PRIMIHUB_PLATFORM 配置"
    exit 1
fi

# 显示更新后的配置
echo ""
echo "更新后的配置:"
grep "PRIMIHUB_PLATFORM" .env

# 升级部署
echo ""
echo "[5/5] 升级部署..."
docker compose up -d --force-recreate \
    application0 application1 application2 \
    gateway0 gateway1 gateway2

echo ""
echo "等待容器启动..."
sleep 15

# 验证部署状态
echo ""
echo "========================================"
echo "部署状态"
echo "========================================"
docker compose ps | grep -E "(application|gateway)" | head -6

echo ""
echo "检查容器健康状态..."
sleep 10

RUNNING_COUNT=$(docker compose ps | grep -E "(application|gateway)" | grep -c "Up" || true)

if [ "$RUNNING_COUNT" -eq 6 ]; then
    echo "✓ 所有容器运行正常 (6/6)"
else
    echo "⚠️ 部分容器可能未正常启动 ($RUNNING_COUNT/6)"
    echo ""
    echo "请检查日志："
    echo "  docker logs application0 --tail 50"
    echo "  docker logs gateway0 --tail 50"
fi

echo ""
echo "========================================"
echo "升级完成！"
echo "========================================"
echo ""
echo "镜像版本: $VERSION"
echo "镜像标签: $IMAGE"
echo ""
echo "验证命令:"
echo "  docker compose ps"
echo "  docker logs application0 --tail 20"
echo ""
echo "访问地址:"
echo "  http://192.168.99.5:30811  (机构1)"
echo "  http://192.168.99.5:30812  (机构2)"
echo "  http://192.168.99.5:30813  (机构3)"
echo ""
