#!/bin/bash

###############################################################################
# PrimiHub - 回滚userId修复脚本
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }

echo "============================================"
echo "PrimiHub - 回滚userId修复"
echo "============================================"
echo ""

CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

echo "此操作将移除所有userId自动添加的修复"
echo ""
read -p "确认回滚？(y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "已取消"
    exit 0
fi

echo ""
log_info "开始回滚..."
echo ""

for container in "${CONTAINERS[@]}"; do
    echo "处理容器: $container"

    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_warn "  容器未运行，跳过"
        continue
    fi

    # 1. 从index.html移除脚本引用
    log_info "  从index.html移除修复脚本引用..."
    docker exec ${container} sed -i '/fix-userid-header.js/d' /usr/local/nginx/html/index.html 2>/dev/null || true

    # 2. 删除修复脚本文件
    log_info "  删除修复脚本文件..."
    docker exec ${container} rm -f /usr/local/nginx/html/static/js/fix-userid-header.js 2>/dev/null || true

    # 3. 验证
    if docker exec ${container} test -f /usr/local/nginx/html/static/js/fix-userid-header.js 2>/dev/null; then
        echo "  ✗ 文件仍然存在"
    else
        log_success "  修复脚本已移除"
    fi

    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html 2>/dev/null; then
        echo "  ✗ index.html仍包含引用"
    else
        log_success "  index.html引用已移除"
    fi

    log_success "  容器 $container 完成"
    echo ""
done

echo ""
echo "============================================"
echo "✅ 回滚完成"
echo "============================================"
echo ""
echo "下一步操作："
echo ""
echo "1. 清除浏览器缓存（Ctrl+Shift+Delete）"
echo "2. 强制刷新页面（Ctrl+F5）"
echo "3. 重新登录系统"
echo ""
echo "注意："
echo "  - 回滚后，原来的400错误可能会重新出现"
echo "  - 如需重新应用修复："
echo "    ./apply-userid-fix-v2.sh"
echo ""
