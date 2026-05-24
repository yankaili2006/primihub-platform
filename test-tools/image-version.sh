#!/bin/bash
# PrimiHub 镜像版本管理
# 所有镜像版本号统一管理，供部署脚本引用
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../VERSION"

# ===== 版本定义 =====
PRIMIHUB_VERSION="2.0.0"
PLATFORM_IMAGE="primihub-platform:${PRIMIHUB_VERSION}"
NODE_IMAGE="primihub-node:${PRIMIHUB_VERSION}"
WEB_IMAGE="primihub-web:${PRIMIHUB_VERSION}"
META_IMAGE="primihub-meta:${PRIMIHUB_VERSION}"

# 基础设施镜像（使用上游版本号）
NACOS_IMAGE="registry.cn-beijing.aliyuncs.com/primihub/nacos-server:v2.0.4"
MYSQL_IMAGE="registry.cn-beijing.aliyuncs.com/primihub/mysql:5.7"
REDIS_IMAGE="registry.cn-beijing.aliyuncs.com/primihub/redis:7"
RABBITMQ_IMAGE="registry.cn-beijing.aliyuncs.com/primihub/rabbitmq:3.6.15-management"
LOKI_IMAGE="registry.cn-beijing.aliyuncs.com/primihub/loki:latest"

# ===== 函数 =====

show_versions() {
  echo "=========================================="
  echo "  PrimiHub 镜像版本清单"
  echo "=========================================="
  echo "  平台:        $PLATFORM_IMAGE"
  echo "  节点:        $NODE_IMAGE"
  echo "  Web:         $WEB_IMAGE"
  echo "  元数据:      $META_IMAGE"
  echo "  Nacos:       $NACOS_IMAGE"
  echo "  MySQL:       $MYSQL_IMAGE"
  echo "  Redis:       $REDIS_IMAGE"
  echo "  RabbitMQ:    $RABBITMQ_IMAGE"
  echo "  Loki:        $LOKI_IMAGE"
  echo "=========================================="
  echo "  数据库架构:  privacy0/1/2 + fusion0/1/2"
  echo "  每租户表数:  67+74"
  echo "=========================================="
}

tag_all() {
  echo "标记所有镜像版本 v${PRIMIHUB_VERSION}..."
  for pair in "primihub-platform $PLATFORM_IMAGE" \
              "primihub-node $NODE_IMAGE" \
              "primihub-web $WEB_IMAGE" \
              "primihub-meta $META_IMAGE"; do
    local_name=$(echo $pair | awk '{print $1}')
    versioned=$(echo $pair | awk '{print $2}')
    docker tag "${local_name}:latest" "$versioned" 2>/dev/null && \
      echo "  ✓ $versioned" || echo "  ⚠ $local_name not found"
  done
}

verify_all() {
  echo "验证镜像..."
  local all_ok=true
  for img in "$PLATFORM_IMAGE" "$NODE_IMAGE" "$WEB_IMAGE" "$META_IMAGE"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${img}$"; then
      echo "  ✓ $img"
    else
      echo "  ✗ $img MISSING"
      all_ok=false
    fi
  done
  $all_ok && echo "全部镜像就绪 ✅" || echo "存在缺失镜像 ❌"
}

# ===== 主逻辑 =====
case "${1:-show}" in
  show)
    show_versions
    ;;
  tag)
    tag_all
    ;;
  verify)
    verify_all
    ;;
  *)
    echo "用法: $0 {show|tag|verify}"
    echo "  show    显示版本清单"
    echo "  tag     标记所有本地镜像为当前版本"
    echo "  verify  验证所有镜像是否存在"
    exit 1
    ;;
esac
