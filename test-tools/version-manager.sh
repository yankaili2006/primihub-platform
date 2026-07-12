#!/bin/bash
# PrimiHub 版本管理工具
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$PROJECT_DIR/VERSION"

load_version() {
  if [ -f "$VERSION_FILE" ]; then
    source "$VERSION_FILE"
  else
    PRIMIHUB_VERSION="2.0.0"
    BUILD_DATE=$(date +%Y-%m-%d)
    GIT_COMMIT=$(cd "$PROJECT_DIR" && git log --oneline -1 2>/dev/null | awk '{print $1}')
    GIT_BRANCH=$(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  fi
}

save_version() {
  cat > "$VERSION_FILE" << EOF
PRIMIHUB_VERSION=$PRIMIHUB_VERSION
PRIMIHUB_SDK_VERSION=$PRIMIHUB_SDK_VERSION
BUILD_DATE=$BUILD_DATE
GIT_COMMIT=$GIT_COMMIT
GIT_BRANCH=$GIT_BRANCH
DB_ARCHITECTURE=privacy0/1/2 (multi-tenant)
DB_TABLES_PER_TENANT=67+74 per tenant
EOF
  echo "✓ Version $PRIMIHUB_VERSION saved"
}

show_version() {
  load_version
  echo "=========================================="
  echo "  PrimiHub Platform 版本信息"
  echo "=========================================="
  echo "  版本:      $PRIMIHUB_VERSION"
  echo "  SDK版本:   $PRIMIHUB_SDK_VERSION"
  echo "  构建日期:  $BUILD_DATE"
  echo "  Git提交:   $GIT_COMMIT"
  echo "  Git分支:   $GIT_BRANCH"
  echo "  架构:      $DB_ARCHITECTURE"
  echo "  数据库表:  $DB_TABLES_PER_TENANT"
  echo "=========================================="
}

tag_version() {
  local ver="$1"
  if [ -z "$ver" ]; then
    echo "用法: $0 tag <版本号> [描述]"
    echo "示例: $0 tag 2.0.1"
    exit 1
  fi
  
  load_version
  PRIMIHUB_VERSION="$ver"
  BUILD_DATE=$(date +%Y-%m-%d)
  GIT_COMMIT=$(cd "$PROJECT_DIR" && git log --oneline -1 2>/dev/null | awk '{print $1}')
  save_version
  
  # Git tag
  cd "$PROJECT_DIR"
  git add VERSION
  git commit -m "release: v$ver" --allow-empty
  git tag -a "v$ver" -m "PrimiHub Platform v$ver"
  echo "✓ Git tag v$ver created"
  echo "  推送: git push origin v$ver"
}

docker_tag() {
  load_version
  local ver="$PRIMIHUB_VERSION"
  
  # Tag Docker image
  for tag in "$ver" "latest"; do
    docker tag primihub-platform:latest "primihub-platform:$tag" 2>/dev/null && \
      echo "✓ Tagged primihub-platform:$tag" || echo "⚠  Docker tag失败"
  done
}

build_image() {
  load_version
  cd "$PROJECT_DIR"
  
  echo "构建 primihub-platform:$PRIMIHUB_VERSION ..."
  
  # Build JAR
  cd primihub-service
  mvn clean package -DskipTests -Dmaven.test.skip=true -q
  cd ..
  
  # Build Docker image
  docker build -t "primihub-platform:$PRIMIHUB_VERSION" -f Dockerfile .
  docker tag "primihub-platform:$PRIMIHUB_VERSION" primihub-platform:latest
  
  echo "✓ Docker镜像构建完成: primihub-platform:$PRIMIHUB_VERSION"
  echo "  大小: $(docker images primihub-platform:$PRIMIHUB_VERSION --format '{{.Size}}')"
}

case "${1:-show}" in
  show)
    show_version
    ;;
  tag)
    tag_version "$2"
    ;;
  docker-tag)
    docker_tag
    ;;
  build)
    build_image
    ;;
  *)
    echo "用法: $0 {show|tag|docker-tag|build}"
    echo ""
    echo "  show        显示版本信息"
    echo "  tag <ver>   创建新版本 (git tag + VERSION)"
    echo "  docker-tag  给Docker镜像打版本标签"
    echo "  build       构建JAR + Docker镜像"
    exit 1
    ;;
esac
