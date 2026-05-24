#!/bin/bash
# PrimiHub 统一版本管理器
# 管理所有组件的版本：platform/node/web/meta/infra
# 单一数据源: VERSION 文件
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$PROJECT_DIR/VERSION"

# ===== 加载版本信息 =====
load_version() {
  if [ -f "$VERSION_FILE" ]; then
    source "$VERSION_FILE"
  else
    echo "❌ VERSION file not found at $VERSION_FILE"
    exit 1
  fi
}

# ===== 显示版本 =====
show() {
  load_version
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║        PrimiHub 版本管理系统             ║"
  echo "╠══════════════════════════════════════════╣"
  echo "║  平台版本:       v$PRIMIHUB_VERSION"
  echo "║  SDK版本:        $PRIMIHUB_SDK_VERSION"
  echo "║  构建日期:       $BUILD_DATE"
  echo "║  Git提交:        $GIT_COMMIT"
  echo "║  Git分支:        $GIT_BRANCH"
  echo "╠══════════════════════════════════════════╣"
  echo "║  镜像                             标签  ║"
  echo "║  ─────────────────────────────────────── ║"
  echo "║  primihub-platform              $PLATFORM_IMAGE_TAG"
  echo "║  primihub-node                  $NODE_IMAGE_TAG"
  echo "║  primihub-web                   $WEB_IMAGE_TAG"
  echo "║  primihub-meta                  $META_IMAGE_TAG"
  echo "╠══════════════════════════════════════════╣"
  echo "║  基础设施                              ║"
  echo "║  Nacos              $NACOS_VERSION"
  echo "║  MySQL              $MYSQL_VERSION"
  echo "║  Redis              $REDIS_VERSION"
  echo "║  RabbitMQ           $RABBITMQ_VERSION"
  echo "╠══════════════════════════════════════════╣"
  echo "║  数据库架构:  $DB_ARCHITECTURE"
  echo "║  每租户表数:  $DB_TABLES_PER_TENANT + $FUSION_TABLES_PER_TENANT"
  echo "╚══════════════════════════════════════════╝"
  echo ""
}

# ===== 创建新版本 =====
tag() {
  local new_ver="$1"
  if [ -z "$new_ver" ]; then
    echo "用法: $0 tag <版本号>"
    echo "当前版本: $(grep PRIMIHUB_VERSION $VERSION_FILE | cut -d= -f2)"
    exit 1
  fi
  
  load_version
  echo "创建版本 v$new_ver ..."
  
  # 更新 VERSION 文件
  sed -i "s/PRIMIHUB_VERSION=.*/PRIMIHUB_VERSION=$new_ver/" "$VERSION_FILE"
  sed -i "s/PLATFORM_IMAGE_TAG=.*/PLATFORM_IMAGE_TAG=$new_ver/" "$VERSION_FILE"
  sed -i "s/NODE_IMAGE_TAG=.*/NODE_IMAGE_TAG=$new_ver/" "$VERSION_FILE"
  sed -i "s/WEB_IMAGE_TAG=.*/WEB_IMAGE_TAG=$new_ver/" "$VERSION_FILE"
  sed -i "s/META_IMAGE_TAG=.*/META_IMAGE_TAG=$new_ver/" "$VERSION_FILE"
  sed -i "s/BUILD_DATE=.*/BUILD_DATE=$(date +%Y-%m-%d)/" "$VERSION_FILE"
  sed -i "s/GIT_COMMIT=.*/GIT_COMMIT=$(cd "$PROJECT_DIR" && git log --oneline -1 2>/dev/null | awk '{print $1}')/" "$VERSION_FILE"
  
  # Git tag
  cd "$PROJECT_DIR"
  git add VERSION
  git commit -m "release: v$new_ver" --allow-empty
  git tag -a "v$new_ver" -m "PrimiHub Platform v$new_ver"
  
  echo "✅ 版本 v$new_ver 已创建"
  echo "   推送: git push origin v$new_ver"
}

# ===== 标记Docker镜像 =====
docker_tag() {
  load_version
  echo "标记 Docker 镜像 v$PRIMIHUB_VERSION ..."
  
  for img in "primihub-platform" "primihub-node" "primihub-web" "primihub-meta"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${img}:latest$"; then
      docker tag "${img}:latest" "${img}:${PRIMIHUB_VERSION}"
      echo "  ✅ ${img}:${PRIMIHUB_VERSION}"
    else
      echo "  ⚠️  ${img}:latest 不存在"
    fi
  done
}

# ===== 验证镜像 =====
verify_images() {
  load_version
  
  if ! command -v docker &>/dev/null; then
    echo "⚠️  Docker 不可用，跳过本地验证"
    echo "   在部署服务器上运行: $0 verify"
    return
  fi
  
  local failed=0
  echo "验证镜像 v$PRIMIHUB_VERSION ..."
  for tag in "$PLATFORM_IMAGE_TAG" "$NODE_IMAGE_TAG" "$WEB_IMAGE_TAG" "$META_IMAGE_TAG"; do
    for img in "primihub-platform" "primihub-node" "primihub-web" "primihub-meta"; do
      if docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "^${img}:${tag}$"; then
        echo "  ✅ ${img}:${tag}"
      else
        echo "  ❌ ${img}:${tag} 缺失"
        failed=1
      fi
    done
  done
  
  [ $failed -eq 0 ] && echo "全部镜像就绪 ✅" || echo "存在缺失镜像 ❌"
}

# ===== 生成部署配置 =====
generate_config() {
  load_version
  local output="${2:-docker-compose.versioned.yaml}"
  
  cat > "$output" << EOF
# PrimiHub v$PRIMIHUB_VERSION - 版本化 docker-compose
# 自动生成于 $(date)
version: "3.8"

services:
  application0:
    image: primihub-platform:${PLATFORM_IMAGE_TAG}
    environment:
      SPRING_DATASOURCE_DRUID_PRIMARY_URL: "jdbc:mysql://mysql:3306/privacy0?..."
      SPRING_DATASOURCE_DRUID_SECONDARY_URL: "jdbc:mysql://mysql:3306/fusion0?..."
  application1:
    image: primihub-platform:${PLATFORM_IMAGE_TAG}
    environment:
      SPRING_DATASOURCE_DRUID_PRIMARY_URL: "jdbc:mysql://mysql:3306/privacy1?..."
      SPRING_DATASOURCE_DRUID_SECONDARY_URL: "jdbc:mysql://mysql:3306/fusion1?..."
  application2:
    image: primihub-platform:${PLATFORM_IMAGE_TAG}
    environment:
      SPRING_DATASOURCE_DRUID_PRIMARY_URL: "jdbc:mysql://mysql:3306/privacy2?..."
      SPRING_DATASOURCE_DRUID_SECONDARY_URL: "jdbc:mysql://mysql:3306/fusion2?..."
  primihub-node:
    image: primihub-node:${NODE_IMAGE_TAG}
  manage-web:
    image: primihub-web:${WEB_IMAGE_TAG}
  primihub-meta:
    image: primihub-meta:${META_IMAGE_TAG}
EOF
  echo "✅ 配置文件已生成: $output"
}

# ===== 主入口 =====
case "${1:-help}" in
  show)
    show
    ;;
  tag)
    tag "$2"
    ;;
  docker-tag)
    docker_tag
    ;;
  verify)
    verify_images
    ;;
  gen-config)
    generate_config "$2" "$3"
    ;;
  *)
    echo "PrimiHub 版本管理器"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  show               显示版本信息"
    echo "  tag <版本号>       创建新版本 (VERSION + git tag)"
    echo "  docker-tag         标记本地Docker镜像为当前版本"
    echo "  verify             验证所有Docker镜像是否存在"
    echo "  gen-config [文件]   生成版本化 docker-compose 配置"
    echo ""
    echo "示例:"
    echo "  $0 show"
    echo "  $0 tag 2.1.0"
    echo "  $0 docker-tag"
    echo "  $0 verify"
    echo ""
    echo "版本文件: $VERSION_FILE"
    echo "当前版本: $(grep PRIMIHUB_VERSION $VERSION_FILE 2>/dev/null | cut -d= -f2 || echo 'N/A')"
    exit 1
    ;;
esac
