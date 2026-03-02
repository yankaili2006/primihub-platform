#!/bin/bash

###############################################################################
# PrimiHub - userId修复验证脚本
###############################################################################

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
log_fail()    { echo -e "${RED}[✗]${NC} $1"; }

echo "============================================"
echo "PrimiHub - userId修复验证"
echo "============================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# 检查项1: 容器运行状态
echo "[检查 1/6] 容器运行状态"
echo "----------------------------------------"

CONTAINERS=("manage-web0" "manage-web1" "manage-web2")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_success "容器 $container 正在运行"
        ((PASS_COUNT++))
    else
        log_fail "容器 $container 未运行"
        ((FAIL_COUNT++))
    fi
done
echo ""

# 检查项2: 修复脚本文件存在性
echo "[检查 2/6] 修复脚本文件"
echo "----------------------------------------"

for container in "${CONTAINERS[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        continue
    fi

    if docker exec $container test -f /usr/local/nginx/html/static/js/fix-userid-header.js 2>/dev/null; then
        log_success "$container: 修复脚本文件存在"
        ((PASS_COUNT++))
    else
        log_fail "$container: 修复脚本文件不存在"
        ((FAIL_COUNT++))
    fi
done
echo ""

# 检查项3: index.html引用
echo "[检查 3/6] index.html引用修复脚本"
echo "----------------------------------------"

for container in "${CONTAINERS[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        continue
    fi

    if docker exec $container grep -q "fix-userid-header.js" /usr/local/nginx/html/index.html 2>/dev/null; then
        log_success "$container: index.html 正确引用修复脚本"
        ((PASS_COUNT++))
    else
        log_fail "$container: index.html 未引用修复脚本"
        ((FAIL_COUNT++))
    fi
done
echo ""

# 检查项4: 源代码修改
echo "[检查 4/6] 源代码修改状态"
echo "----------------------------------------"

SOURCE_FILE="/mnt/data1/github/primihub-platform/primihub-webconsole/src/utils/request.js"

if [ -f "$SOURCE_FILE" ]; then
    if grep -q "从 localStorage 读取" "$SOURCE_FILE"; then
        log_success "源代码已修改（request.js包含userId fallback逻辑）"
        ((PASS_COUNT++))
    else
        log_warn "源代码可能未修改"
        ((WARN_COUNT++))
    fi
else
    log_warn "找不到源代码文件: $SOURCE_FILE"
    ((WARN_COUNT++))
fi
echo ""

# 检查项5: 后端日志
echo "[检查 5/6] 后端错误日志"
echo "----------------------------------------"

RECENT_ERRORS=$(docker logs application0 2>&1 | grep "Missing request header 'userId'" | tail -5 | wc -l)

if [ "$RECENT_ERRORS" -eq 0 ]; then
    log_success "没有最近的userId缺失错误"
    ((PASS_COUNT++))
else
    log_warn "发现 $RECENT_ERRORS 条最近的userId缺失错误"
    echo "  最近的错误："
    docker logs application0 2>&1 | grep "Missing request header 'userId'" | tail -3 | sed 's/^/  /'
    ((WARN_COUNT++))
fi
echo ""

# 检查项6: API测试（可选）
echo "[检查 6/6] API功能测试（可选）"
echo "----------------------------------------"

read -p "是否测试API功能？需要提供token (y/n): " test_api

if [ "$test_api" = "y" ]; then
    echo ""
    echo "请从浏览器获取token："
    echo "1. 登录系统"
    echo "2. 按F12打开开发者工具"
    echo "3. Console中输入: localStorage.getItem('token')"
    echo "4. 复制token值（不含引号）"
    echo ""
    read -p "请输入token: " USER_TOKEN

    if [ -n "$USER_TOKEN" ]; then
        echo ""
        echo "测试API调用..."

        # 测试不带userId
        echo "测试1: 不带userId（应该失败）"
        RESPONSE1=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET \
            "http://localhost:30811/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=" \
            -H "Content-Type: application/json" \
            -H "token: $USER_TOKEN" \
            -H "timestamp: 1234567890" \
            -H "nonce: 123")

        HTTP_CODE1=$(echo "$RESPONSE1" | grep "HTTP_CODE:" | cut -d':' -f2)

        if [ "$HTTP_CODE1" = "400" ]; then
            log_success "不带userId正确返回400"
            ((PASS_COUNT++))
        else
            log_warn "不带userId返回: $HTTP_CODE1"
            ((WARN_COUNT++))
        fi

        # 测试带userId
        echo "测试2: 带userId=1（应该成功）"
        RESPONSE2=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET \
            "http://localhost:30811/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=" \
            -H "Content-Type: application/json" \
            -H "userId: 1" \
            -H "token: $USER_TOKEN" \
            -H "timestamp: 1234567890" \
            -H "nonce: 123")

        HTTP_CODE2=$(echo "$RESPONSE2" | grep "HTTP_CODE:" | cut -d':' -f2)

        if [ "$HTTP_CODE2" = "200" ]; then
            log_success "带userId正确返回200"
            ((PASS_COUNT++))
        else
            log_fail "带userId返回: $HTTP_CODE2"
            ((FAIL_COUNT++))
        fi
    fi
else
    log_info "跳过API测试"
fi

echo ""
echo "============================================"
echo "验证结果汇总"
echo "============================================"
echo ""

TOTAL_CHECKS=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

echo "总计检查项: $TOTAL_CHECKS"
echo -e "${GREEN}通过: $PASS_COUNT${NC}"
echo -e "${YELLOW}警告: $WARN_COUNT${NC}"
echo -e "${RED}失败: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    log_success "所有关键检查项通过！"
    echo ""
    echo "修复状态: ✅ 正常"
    echo ""
    echo "下一步："
    echo "1. 在浏览器中访问系统"
    echo "2. 按 Ctrl+F5 强制刷新"
    echo "3. 点击"我的资源"验证功能"
    echo ""
    exit 0
else
    log_error "发现 $FAIL_COUNT 个问题"
    echo ""
    echo "修复状态: ❌ 异常"
    echo ""
    echo "建议操作："
    echo "1. 重新运行修复脚本："
    echo "   ./apply-userid-fix.sh"
    echo ""
    echo "2. 检查容器日志："
    echo "   docker logs manage-web0"
    echo ""
    echo "3. 查看详细文档："
    echo "   cat USERID_FIX_COMPLETE.md"
    echo ""
    exit 1
fi
