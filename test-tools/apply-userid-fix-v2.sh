#!/bin/bash

###############################################################################
# PrimiHub - 应用userId修复脚本 V2
# 覆盖所有需要userId的API
###############################################################################

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }

echo "============================================"
echo "PrimiHub - 应用userId修复 V2"
echo "============================================"
echo ""
echo "V2版本改进："
echo "  ✓ 修复文件权限问题（403错误）"
echo "  ✓ 扩展API匹配规则"
echo "  ✓ 覆盖所有业务API（resource/model/reasoning/project等）"
echo "  ✓ 排除公共API（login/oauth/captcha等）"
echo ""

# 检查V2脚本是否存在
if [ ! -f "fix-userid-header-v2.js" ]; then
    echo "错误：找不到 fix-userid-header-v2.js"
    exit 1
fi

log_success "找到V2修复脚本"
echo ""

# 容器列表
CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

echo "[1/3] 应用V2修复脚本到所有容器..."
echo ""

for container in "${CONTAINERS[@]}"; do
    echo "处理容器: $container"

    # 检查容器是否运行
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "  ⚠ 容器未运行，跳过"
        continue
    fi

    # 1. 复制V2脚本
    log_info "  复制V2修复脚本..."
    docker cp fix-userid-header-v2.js ${container}:/usr/local/nginx/html/static/js/fix-userid-header.js

    # 2. 修复文件权限（解决403错误）
    log_info "  修复文件权限..."
    docker exec ${container} chmod 644 /usr/local/nginx/html/static/js/fix-userid-header.js

    # 3. 验证文件权限
    PERMS=$(docker exec ${container} stat -c "%a" /usr/local/nginx/html/static/js/fix-userid-header.js 2>/dev/null || echo "000")
    if [ "$PERMS" = "644" ]; then
        log_success "  权限已设置为 644"
    else
        echo "  ⚠ 权限设置可能不正确: $PERMS"
    fi

    # 4. 检查index.html是否已引用
    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html 2>/dev/null; then
        log_success "  index.html 已包含修复脚本引用"
    else
        log_info "  添加修复脚本引用到index.html..."

        # 创建临时脚本
        cat > /tmp/inject-fix-script-$$.sh << 'EOF'
#!/bin/sh
sed -i 's|</head>|  <script src="/static/js/fix-userid-header.js"></script>\n</head>|g' /usr/local/nginx/html/index.html
EOF

        # 复制并执行
        docker cp /tmp/inject-fix-script-$$.sh ${container}:/tmp/inject-fix-script.sh
        docker exec ${container} sh /tmp/inject-fix-script.sh
        docker exec ${container} rm /tmp/inject-fix-script.sh
        rm /tmp/inject-fix-script-$$.sh

        log_success "  index.html 已更新"
    fi

    log_success "  容器 $container 完成"
    echo ""
done

echo ""
echo "[2/3] 验证修复..."
echo ""

# 验证第一个容器
if docker ps --format '{{.Names}}' | grep -q "^manage-web0$"; then
    log_info "检查 manage-web0..."

    # 检查文件
    if docker exec manage-web0 test -f /usr/local/nginx/html/static/js/fix-userid-header.js; then
        SIZE=$(docker exec manage-web0 stat -c "%s" /usr/local/nginx/html/static/js/fix-userid-header.js)
        PERMS=$(docker exec manage-web0 stat -c "%a" /usr/local/nginx/html/static/js/fix-userid-header.js)
        log_success "  修复脚本: 存在 (大小: ${SIZE} bytes, 权限: ${PERMS})"
    else
        echo "  ✗ 修复脚本文件不存在"
    fi

    # 检查index.html
    if docker exec manage-web0 grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html; then
        log_success "  index.html: 正确引用修复脚本"
    else
        echo "  ✗ index.html 未引用修复脚本"
    fi

    # 检查版本
    if docker exec manage-web0 grep -q "Fix V2" /usr/local/nginx/html/static/js/fix-userid-header.js; then
        log_success "  版本: V2 (扩展API匹配)"
    else
        echo "  ⚠ 可能是旧版本"
    fi
fi

echo ""
echo "[3/3] 清除浏览器缓存提示"
echo ""

echo "============================================"
echo "✅ V2修复脚本已成功应用！"
echo "============================================"
echo ""
echo "重要提示："
echo ""
echo "1. 清除浏览器缓存"
echo "   - 按 Ctrl+Shift+Delete"
echo "   - 或强制刷新: Ctrl+F5"
echo ""
echo "2. 重新登录系统"
echo "   - 退出当前登录"
echo "   - 重新登录"
echo ""
echo "3. 验证修复"
echo "   - 按 F12 打开开发者工具"
echo "   - Console 应该看到:"
echo '     [PrimiHub Fix V2] ✅ 请求拦截器已成功安装！'
echo '     [PrimiHub Fix V2] 当前userId: 1'
echo ""
echo "4. 测试所有菜单"
echo "   - 我的资源 ✓"
echo "   - 模型管理 ✓"
echo "   - 推理服务 ✓"
echo "   - 项目管理 ✓"
echo "   - PSI/PIR ✓"
echo ""
echo "如果看到 [PrimiHub Fix V2] 日志，说明修复已生效！"
echo ""
echo "如需回滚到V1或移除修复："
echo "  ./rollback-userid-fix.sh"
echo ""
