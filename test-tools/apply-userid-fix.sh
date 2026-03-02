#!/bin/bash

# ============================================================================
# PrimiHub - 自动应用userId请求头修复
# ============================================================================
# 功能：
#   1. 将修复脚本复制到所有前端容器
#   2. 修改index.html引用修复脚本
#   3. 重启前端容器使修改生效
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }

echo "============================================"
echo "PrimiHub - 应用userId请求头修复"
echo "============================================"
echo ""

# 检查修复脚本是否存在
if [ ! -f "fix-userid-header.js" ]; then
    log_error "错误：找不到 fix-userid-header.js 文件"
    log_info "请确保在正确的目录中运行此脚本"
    exit 1
fi

log_success "找到修复脚本: fix-userid-header.js"

# 前端容器列表
CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

echo ""
log_info "开始应用修复到所有前端容器..."
echo ""

for container in "${CONTAINERS[@]}"; do
    echo "----------------------------------------"
    log_info "处理容器: $container"
    echo "----------------------------------------"

    # 检查容器是否运行
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_warn "容器 $container 未运行，跳过"
        continue
    fi

    # 步骤1: 复制修复脚本到容器
    log_info "1. 复制修复脚本到容器..."
    docker cp fix-userid-header.js ${container}:/usr/local/nginx/html/static/js/fix-userid-header.js
    if [ $? -eq 0 ]; then
        log_success "修复脚本已复制到容器"
    else
        log_error "复制失败"
        continue
    fi

    # 步骤2: 备份原始index.html
    log_info "2. 备份原始index.html..."
    docker exec ${container} cp /usr/local/nginx/html/index.html /usr/local/nginx/html/index.html.backup 2>/dev/null || true
    log_success "已备份index.html"

    # 步骤3: 检查index.html是否已经包含修复脚本
    log_info "3. 检查是否已应用修复..."
    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html 2>/dev/null; then
        log_warn "修复脚本已存在于index.html，跳过添加"
    else
        log_info "4. 添加修复脚本到index.html..."

        # 创建临时修改脚本
        cat > /tmp/inject-fix-script.sh << 'EOF'
#!/bin/sh
# 在</head>标签前插入脚本引用
sed -i 's|</head>|  <script src="/static/js/fix-userid-header.js"></script>\n</head>|g' /usr/local/nginx/html/index.html
EOF

        # 复制并执行临时脚本
        docker cp /tmp/inject-fix-script.sh ${container}:/tmp/inject-fix-script.sh
        docker exec ${container} sh /tmp/inject-fix-script.sh
        docker exec ${container} rm /tmp/inject-fix-script.sh
        rm /tmp/inject-fix-script.sh

        log_success "修复脚本已添加到index.html"
    fi

    # 步骤5: 验证修改
    log_info "5. 验证修改..."
    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html; then
        log_success "验证成功！修复脚本已正确引用"
    else
        log_error "验证失败！修复脚本未正确添加"
        continue
    fi

    # 步骤6: 清除nginx缓存（如果有）
    log_info "6. 清除nginx缓存..."
    docker exec ${container} sh -c "rm -rf /var/cache/nginx/* 2>/dev/null || true"

    log_success "容器 $container 修复完成！"
    echo ""
done

echo ""
echo "============================================"
log_info "是否重启前端容器使修改生效？"
echo "============================================"
echo ""
echo "选项："
echo "  1) 立即重启所有前端容器 (推荐)"
echo "  2) 稍后手动重启"
echo "  3) 不重启 (刷新浏览器缓存即可)"
echo ""
read -p "请选择 [1-3]: " choice

case $choice in
    1)
        log_info "开始重启前端容器..."
        for container in "${CONTAINERS[@]}"; do
            if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
                log_info "重启 $container..."
                docker restart $container
                log_success "$container 已重启"
            fi
        done
        echo ""
        log_success "所有容器已重启完成！"
        log_info "等待10秒让服务完全启动..."
        sleep 10
        ;;
    2)
        log_info "稍后请手动执行以下命令重启容器："
        echo "  docker-compose restart manage-web0 manage-web1 manage-web2"
        ;;
    3)
        log_info "请在浏览器中按 Ctrl+F5 强制刷新页面"
        ;;
    *)
        log_warn "无效选择，请手动重启容器或刷新浏览器"
        ;;
esac

echo ""
echo "============================================"
echo "修复应用完成！"
echo "============================================"
echo ""
log_success "下一步操作："
echo ""
echo "1. 在浏览器中按 Ctrl+F5 强制刷新页面"
echo "2. 打开浏览器开发者工具 (F12)"
echo "3. 切换到 Console 标签"
echo "4. 访问"我的资源"页面"
echo "5. 查看Console中是否有 [PrimiHub Fix] 相关日志"
echo ""
log_info "预期看到的日志："
echo '  [PrimiHub Fix] ✅ 请求拦截器已成功安装！'
echo '  [PrimiHub Fix] 当前userId: 1'
echo '  [PrimiHub Fix] ✅ XHR添加userId: 1 URL: ...'
echo ""
echo "如果看到以上日志，说明修复已成功应用！"
echo ""
echo "如需回滚，请执行："
echo "  docker exec manage-web0 cp /usr/local/nginx/html/index.html.backup /usr/local/nginx/html/index.html"
echo "  docker restart manage-web0"
echo ""
