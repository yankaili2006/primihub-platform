#!/bin/bash

###############################################################################
# PrimiHub - API功能测试脚本
# 
# 功能：测试所有三个节点的API是否正常工作
# 
# 使用方法：
#   ./test-all-apis.sh
#
# 日期：2026-02-12
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }

echo "============================================"
echo "PrimiHub - API功能测试"
echo "============================================"
echo ""

# 测试统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local url="$2"
    local expected_code="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "$expected_code" ]; then
        log_success "$test_name - HTTP $HTTP_CODE"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "$test_name - HTTP $HTTP_CODE (预期: $expected_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo "测试1: 首页访问测试"
echo "-------------------"
run_test "30811 首页" "http://localhost:30811/" "200"
run_test "30812 首页" "http://localhost:30812/" "200"
run_test "30813 首页" "http://localhost:30813/" "200"
echo ""

echo "测试2: 修复脚本加载测试"
echo "-------------------"
run_test "30811 修复脚本" "http://localhost:30811/static/js/fix-userid-header.js?v=20260212" "200"
run_test "30812 修复脚本" "http://localhost:30812/static/js/fix-userid-header.js?v=20260212" "200"
run_test "30813 修复脚本" "http://localhost:30813/static/js/fix-userid-header.js?v=20260212" "200"
echo ""

echo "测试3: 静态资源测试"
echo "-------------------"
run_test "30811 CSS" "http://localhost:30811/static/css/app.1437949b.css" "200"
run_test "30812 CSS" "http://localhost:30812/static/css/app.1437949b.css" "200"
run_test "30813 CSS" "http://localhost:30813/static/css/app.1437949b.css" "200"
echo ""

echo "测试4: 公共API测试（不需要认证）"
echo "-------------------"
# 这些API预期返回200（成功）或401/400（缺少认证参数，但路由正确）
run_test "30811 首页数据" "http://localhost:30811/prod-api/data/organ/getHomepage" "200" || \
run_test "30811 首页数据" "http://localhost:30811/prod-api/data/organ/getHomepage" "400" || \
run_test "30811 首页数据" "http://localhost:30811/prod-api/data/organ/getHomepage" "401"

run_test "30812 首页数据" "http://localhost:30812/prod-api/data/organ/getHomepage" "200" || \
run_test "30812 首页数据" "http://localhost:30812/prod-api/data/organ/getHomepage" "400" || \
run_test "30812 首页数据" "http://localhost:30812/prod-api/data/organ/getHomepage" "401"

run_test "30813 首页数据" "http://localhost:30813/prod-api/data/organ/getHomepage" "200" || \
run_test "30813 首页数据" "http://localhost:30813/prod-api/data/organ/getHomepage" "400" || \
run_test "30813 首页数据" "http://localhost:30813/prod-api/data/organ/getHomepage" "401"
echo ""

echo "测试5: 业务API路由测试（预期400/401，不是404）"
echo "-------------------"
log_info "这些API需要认证，返回400/401是正常的，404表示路由错误"

# 测试 /prod-api/data/ 路径
for port in 30811 30812 30813; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "404" ]; then
        log_error "${port} 资源列表API - 路由错误 (404)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    elif [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "200" ]; then
        log_success "${port} 资源列表API - 路由正确 (${HTTP_CODE})"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_warn "${port} 资源列表API - 未知状态 (${HTTP_CODE})"
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

# 测试 /prod-api/data/project/ 路径（特别是30812）
for port in 30811 30812 30813; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}/prod-api/data/project/getProjectList?pageNo=1&pageSize=10" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "404" ]; then
        log_error "${port} 项目列表API - 路由错误 (404)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    elif [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "200" ]; then
        log_success "${port} 项目列表API - 路由正确 (${HTTP_CODE})"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_warn "${port} 项目列表API - 未知状态 (${HTTP_CODE})"
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""

echo "测试6: 容器配置验证"
echo "-------------------"

for i in 0 1 2; do
    container="manage-web${i}"
    
    # 检查修复脚本
    if docker exec ${container} test -f /usr/local/nginx/html/static/js/fix-userid-header.js 2>/dev/null; then
        log_success "${container} 修复脚本存在"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "${container} 修复脚本不存在"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # 检查nginx配置
    PROD_API_COUNT=$(docker exec ${container} grep -c "location.*\/prod-api" /etc/nginx/conf.d/default.conf 2>/dev/null || echo "0")
    if [ "$PROD_API_COUNT" -ge 4 ]; then
        log_success "${container} nginx配置完整 (${PROD_API_COUNT}个配置段)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "${container} nginx配置不完整 (${PROD_API_COUNT}个配置段)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "============================================"
echo "测试结果汇总"
echo "============================================"
echo ""
echo "总测试数: $TOTAL_TESTS"
echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ 所有测试通过！${NC}"
    echo ""
    echo "系统状态："
    echo "  ✓ 所有节点运行正常"
    echo "  ✓ 修复脚本已正确部署"
    echo "  ✓ nginx配置完整"
    echo "  ✓ API路由正确"
    echo ""
    exit 0
else
    echo -e "${RED}❌ 部分测试失败${NC}"
    echo ""
    echo "建议操作："
    echo "  1. 运行: ./deploy-all-fixes.sh"
    echo "  2. 查看日志: docker logs manage-web1 2>&1 | tail -50"
    echo "  3. 重新测试: ./test-all-apis.sh"
    echo ""
    exit 1
fi
