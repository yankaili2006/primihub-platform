#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=========================================="
echo "  PrimiHub v2.0.0 离线部署"
echo "=========================================="
echo ""

# Import images
echo "步骤1: 导入镜像..."
bash import-images.sh

# Start services via docker-compose
echo "步骤2: 启动服务..."
if [ -f "docker-compose.yaml" ]; then
  docker-compose up -d
else
  echo "⚠️  未找到 docker-compose.yaml"
fi

echo ""
echo "步骤3: 执行一键修复..."
if [ -f "scripts/fix-all.sh" ]; then
  bash scripts/fix-all.sh
fi

echo ""
echo "=========================================="
echo "  部署完成"
echo "  验证: docker logs application0 | grep Init"
echo "=========================================="
