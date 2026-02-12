#!/bin/bash

###############################################################################
# PrimiHub 前端 - 快速应用userId修复（无需重新构建）
###############################################################################

set -e

echo "============================================"
echo "PrimiHub 前端 - 快速应用userId修复"
echo "============================================"
echo ""
echo "此脚本将直接复制修复脚本到运行中的容器"
echo "无需重新构建前端，立即生效！"
echo ""

# 检查修复脚本是否存在
SCRIPT_DIR="/mnt/data1/github/primihub-deploy/docker-all-in-one"
FIX_SCRIPT="$SCRIPT_DIR/fix-userid-header.js"

if [ ! -f "$FIX_SCRIPT" ]; then
    echo "错误：找不到修复脚本 fix-userid-header.js"
    echo "位置: $FIX_SCRIPT"
    exit 1
fi

echo "✓ 找到修复脚本"
echo ""

# 容器列表
CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

echo "[1/2] 应用修复到所有前端容器..."
echo ""

for container in "${CONTAINERS[@]}"; do
    echo "处理容器: $container"

    # 检查容器是否运行
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "  ⚠ 容器未运行，跳过"
        continue
    fi

    # 复制修复脚本
    echo "  - 复制修复脚本..."
    docker cp "$FIX_SCRIPT" ${container}:/usr/local/nginx/html/static/js/fix-userid-header.js

    # 检查index.html是否已经包含修复脚本
    if docker exec ${container} grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html 2>/dev/null; then
        echo "  ✓ index.html 已包含修复脚本引用"
    else
        echo "  - 修改index.html添加修复脚本引用..."

        # 创建临时修改脚本
        cat > /tmp/inject-fix-script-$$.sh << 'EOF'
#!/bin/sh
sed -i 's|</head>|  <script src="/static/js/fix-userid-header.js"></script>\n</head>|g' /usr/local/nginx/html/index.html
EOF

        # 复制并执行
        docker cp /tmp/inject-fix-script-$$.sh ${container}:/tmp/inject-fix-script.sh
        docker exec ${container} sh /tmp/inject-fix-script.sh
        docker exec ${container} rm /tmp/inject-fix-script.sh
        rm /tmp/inject-fix-script-$$.sh

        echo "  ✓ index.html 已更新"
    fi

    echo "  ✓ 容器 $container 修复完成"
    echo ""
done

echo "[2/2] 验证修复..."
echo ""

# 验证第一个容器
if docker ps --format '{{.Names}}' | grep -q "^manage-web0$"; then
    echo "检查 manage-web0 的配置..."

    # 检查文件是否存在
    if docker exec manage-web0 test -f /usr/local/nginx/html/static/js/fix-userid-header.js; then
        echo "  ✓ 修复脚本文件存在"
    else
        echo "  ✗ 修复脚本文件不存在"
    fi

    # 检查index.html引用
    if docker exec manage-web0 grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html; then
        echo "  ✓ index.html 正确引用修复脚本"
    else
        echo "  ✗ index.html 未引用修复脚本"
    fi
fi

echo ""
echo "============================================"
echo "✓ 修复应用完成！"
echo "============================================"
echo ""
echo "下一步操作："
echo ""
echo "1. 在浏览器中访问系统"
echo "2. 按 Ctrl+F5 强制刷新页面"
echo "3. 按 F12 打开开发者工具"
echo "4. 切换到 Console 标签"
echo "5. 应该看到以下日志："
echo "   [PrimiHub Fix] 初始化userId请求头自动添加模块..."
echo "   [PrimiHub Fix] ✅ 请求拦截器已成功安装！"
echo ""
echo "6. 点击"我的资源""
echo "7. 在 Network 标签中查看请求头是否包含 userId"
echo ""
echo "如果浏览器缓存问题导致修复未生效，请："
echo "  - 清除浏览器缓存（Ctrl+Shift+Delete）"
echo "  - 或重启前端容器："
echo "    docker-compose restart manage-web0 manage-web1 manage-web2"
echo ""
