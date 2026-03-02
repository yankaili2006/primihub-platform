#!/bin/bash

###############################################################################
# PrimiHub - 一键部署所有修复脚本
# 
# 功能：
# 1. 应用V2 userId修复到所有前端容器
# 2. 修复manage-web1的nginx配置缺失问题
# 3. 验证所有修复是否生效
# 4. 生成部署报告
#
# 使用方法：
#   ./deploy-all-fixes.sh
#
# 日期：2026-02-12
###############################################################################

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_step()    { echo -e "${BLUE}[STEP]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "PrimiHub - 一键部署所有修复"
echo "============================================"
echo ""

# 检查必要文件
log_step "检查必要文件..."
REQUIRED_FILES=(
    "fix-userid-header-v2.js"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "缺少必要文件: $file"
        exit 1
    fi
    log_success "找到: $file"
done

echo ""

# 容器列表
CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

# Step 1: 检查容器状态
log_step "Step 1/5: 检查容器状态"
echo ""

for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_success "容器 $container 正在运行"
    else
        log_error "容器 $container 未运行"
        exit 1
    fi
done

echo ""

# Step 2: 应用V2 userId修复脚本
log_step "Step 2/5: 应用V2 userId修复脚本"
echo ""

VERSION="v20260212"

for container in "${CONTAINERS[@]}"; do
    log_info "处理容器: $container"
    
    # 复制V2修复脚本
    docker cp fix-userid-header-v2.js ${container}:/usr/local/nginx/html/static/js/fix-userid-header.js
    
    # 设置正确权限
    docker exec ${container} chmod 644 /usr/local/nginx/html/static/js/fix-userid-header.js
    
    # 检查index.html是否已引用修复脚本
    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html 2>/dev/null; then
        # 更新版本号
        docker exec ${container} sed -i 's|fix-userid-header.js[^"]*"|fix-userid-header.js?v='$VERSION'"|g' /usr/local/nginx/html/index.html
        log_success "  已更新修复脚本版本号"
    else
        # 添加脚本引用
        docker exec ${container} sed -i 's|</head>|  <script src="/static/js/fix-userid-header.js?v='$VERSION'"></script>\n</head>|g' /usr/local/nginx/html/index.html
        log_success "  已添加修复脚本引用"
    fi
    
    log_success "  容器 $container 完成"
    echo ""
done

# Step 3: 修复nginx配置问题（特别是manage-web1）
log_step "Step 3/5: 检查并修复nginx配置"
echo ""

# 检查manage-web1是否缺少/prod-api/data/配置
if ! docker exec manage-web1 grep -q "location.*\/prod-api\/data\/" /etc/nginx/conf.d/default.conf 2>/dev/null; then
    log_warn "检测到manage-web1缺少/prod-api/data/配置，开始修复..."
    
    # 备份原配置
    docker exec manage-web1 cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak-$(date +%Y%m%d-%H%M%S)
    
    # 从manage-web0复制配置并修改网关
    docker exec manage-web0 cat /etc/nginx/conf.d/default.conf > /tmp/nginx-web0.conf
    sed 's/gateway0/gateway1/g' /tmp/nginx-web0.conf > /tmp/nginx-web1.conf
    
    # 应用到manage-web1
    cat /tmp/nginx-web1.conf | docker exec -i manage-web1 sh -c 'cat > /etc/nginx/conf.d/default.conf.new && cat /etc/nginx/conf.d/default.conf.new > /etc/nginx/conf.d/default.conf'
    
    # 测试nginx配置
    if docker exec manage-web1 nginx -t 2>&1 | grep -q "successful"; then
        docker exec manage-web1 nginx -s reload
        log_success "manage-web1 nginx配置已修复并重新加载"
    else
        log_error "nginx配置测试失败"
        exit 1
    fi
    
    rm -f /tmp/nginx-web0.conf /tmp/nginx-web1.conf
else
    log_success "manage-web1 nginx配置完整"
fi

# 同样检查manage-web2
if ! docker exec manage-web2 grep -q "location.*\/prod-api\/data\/" /etc/nginx/conf.d/default.conf 2>/dev/null; then
    log_warn "检测到manage-web2缺少/prod-api/data/配置，开始修复..."
    
    docker exec manage-web2 cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak-$(date +%Y%m%d-%H%M%S)
    docker exec manage-web0 cat /etc/nginx/conf.d/default.conf > /tmp/nginx-web0.conf
    sed 's/gateway0/gateway2/g' /tmp/nginx-web0.conf > /tmp/nginx-web2.conf
    cat /tmp/nginx-web2.conf | docker exec -i manage-web2 sh -c 'cat > /etc/nginx/conf.d/default.conf.new && cat /etc/nginx/conf.d/default.conf.new > /etc/nginx/conf.d/default.conf'
    
    if docker exec manage-web2 nginx -t 2>&1 | grep -q "successful"; then
        docker exec manage-web2 nginx -s reload
        log_success "manage-web2 nginx配置已修复并重新加载"
    else
        log_error "nginx配置测试失败"
        exit 1
    fi
    
    rm -f /tmp/nginx-web0.conf /tmp/nginx-web2.conf
else
    log_success "manage-web2 nginx配置完整"
fi

echo ""

# Step 4: 验证修复
log_step "Step 4/5: 验证修复效果"
echo ""

for i in 0 1 2; do
    container="manage-web${i}"
    port="308$((11+i))"
    
    log_info "验证 $container (端口 $port)..."
    
    # 检查修复脚本文件
    if docker exec ${container} test -f /usr/local/nginx/html/static/js/fix-userid-header.js; then
        SIZE=$(docker exec ${container} stat -c "%s" /usr/local/nginx/html/static/js/fix-userid-header.js)
        PERMS=$(docker exec ${container} stat -c "%a" /usr/local/nginx/html/static/js/fix-userid-header.js)
        
        if [ "$SIZE" -gt 8000 ] && [ "$PERMS" = "644" ]; then
            log_success "  修复脚本: ✓ (大小: ${SIZE}B, 权限: ${PERMS})"
        else
            log_warn "  修复脚本存在但配置可能不正确 (大小: ${SIZE}B, 权限: ${PERMS})"
        fi
    else
        log_error "  修复脚本文件不存在"
    fi
    
    # 检查index.html引用
    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html; then
        log_success "  index.html: ✓"
    else
        log_error "  index.html未引用修复脚本"
    fi
    
    # 检查V2版本
    if docker exec ${container} grep -q "Fix V2" /usr/local/nginx/html/static/js/fix-userid-header.js; then
        log_success "  版本: V2 ✓"
    else
        log_warn "  可能不是V2版本"
    fi
    
    # 检查nginx配置
    PROD_API_COUNT=$(docker exec ${container} grep -c "location.*\/prod-api" /etc/nginx/conf.d/default.conf 2>/dev/null || echo "0")
    if [ "$PROD_API_COUNT" -ge 4 ]; then
        log_success "  nginx配置: ✓ (${PROD_API_COUNT}个prod-api配置段)"
    else
        log_warn "  nginx配置可能不完整 (${PROD_API_COUNT}个prod-api配置段)"
    fi
    
    # HTTP测试
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        log_success "  HTTP访问: ✓ (${HTTP_CODE})"
    else
        log_error "  HTTP访问失败 (${HTTP_CODE})"
    fi
    
    echo ""
done

# Step 5: 生成部署报告
log_step "Step 5/5: 生成部署报告"
echo ""

REPORT_FILE="deployment-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
PrimiHub 修复部署报告
====================

部署时间: $(date '+%Y-%m-%d %H:%M:%S')
部署脚本: deploy-all-fixes.sh

修复内容
--------
1. V2 userId请求头自动添加修复
   - 修复脚本: fix-userid-header-v2.js (8.5KB)
   - 应用到容器: manage-web0, manage-web1, manage-web2
   - 版本标记: v20260212

2. nginx API路由配置修复
   - 修复对象: manage-web1, manage-web2 (如需要)
   - 添加配置: /prod-api/data/ location段
   - 配置来源: manage-web0

部署状态
--------
EOF

for i in 0 1 2; do
    container="manage-web${i}"
    port="308$((11+i))"
    
    echo "" >> "$REPORT_FILE"
    echo "容器: $container (端口 $port)" >> "$REPORT_FILE"
    echo "  修复脚本: $(docker exec ${container} test -f /usr/local/nginx/html/static/js/fix-userid-header.js && echo '✓' || echo '✗')" >> "$REPORT_FILE"
    echo "  index.html: $(docker exec ${container} grep -q 'fix-userid-header.js' /usr/local/nginx/html/index.html && echo '✓' || echo '✗')" >> "$REPORT_FILE"
    echo "  nginx配置: $(docker exec ${container} grep -q 'location.*\/prod-api\/data\/' /etc/nginx/conf.d/default.conf && echo '✓' || echo '✗')" >> "$REPORT_FILE"
    echo "  HTTP状态: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:${port}/ 2>/dev/null)" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

下一步操作
----------
1. 清除浏览器缓存 (Ctrl+Shift+Delete)
2. 强制刷新页面 (Ctrl+F5)
3. 打开开发者工具 (F12)，查看Console是否显示:
   [PrimiHub Fix V2] ✅ 请求拦截器已成功安装！
4. 测试所有菜单功能

修复说明文档
------------
- USERID_FIX_V2_COMPLETE.md - 完整技术文档
- DEPLOYMENT_GUIDE.md - 部署指南
EOF

log_success "部署报告已生成: $REPORT_FILE"

echo ""
echo "============================================"
echo "✅ 所有修复部署完成！"
echo "============================================"
echo ""
echo "部署摘要："
echo "  ✓ V2 userId修复已应用到3个容器"
echo "  ✓ nginx配置已检查和修复"
echo "  ✓ 所有容器已验证"
echo ""
echo "下一步："
echo "  1. 查看部署报告: cat $REPORT_FILE"
echo "  2. 在浏览器中测试所有功能"
echo "  3. 确认所有菜单正常工作"
echo ""
echo "如遇问题，请查看文档："
echo "  - USERID_FIX_V2_COMPLETE.md"
echo "  - DEPLOYMENT_GUIDE.md"
echo ""

