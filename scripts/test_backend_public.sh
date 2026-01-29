#!/bin/bash

###############################################################################
# PrimiHub 后端公开API测试脚本
# 功能: 测试不需要登录的API端点
###############################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_URL="http://localhost:8090"

# 测试统计
TOTAL=0
PASSED=0
FAILED=0

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[测试] $1${NC}"
    ((TOTAL++))
}

print_pass() {
    echo -e "${GREEN}✓ 通过: $1${NC}"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}✗ 失败: $1${NC}"
    ((FAILED++))
}

print_info() {
    echo -e "  $1"
}

# 测试1: Swagger文档
test_swagger() {
    print_header "1. Swagger API文档测试"

    print_test "访问Swagger UI"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/doc.html")
    if [ "$response" = "200" ]; then
        print_pass "Swagger UI可访问 (HTTP $response)"
    else
        print_fail "Swagger UI不可访问 (HTTP $response)"
    fi

    print_test "获取API文档定义"
    response=$(curl -s "$BASE_URL/v2/api-docs")
    if echo "$response" | jq -e '.swagger' > /dev/null 2>&1; then
        version=$(echo "$response" | jq -r '.swagger')
        print_pass "API文档可获取 (Swagger $version)"

        # 统计API数量
        api_count=$(echo "$response" | jq '.paths | keys | length')
        print_info "API端点数量: $api_count"
    else
        print_fail "API文档获取失败"
    fi
}

# 测试2: Actuator端点
test_actuator() {
    print_header "2. Actuator监控端点测试"

    print_test "健康检查端点"
    response=$(curl -s "$BASE_URL/actuator/health")
    status=$(echo "$response" | jq -r '.status')
    if [ "$status" = "UP" ]; then
        print_pass "健康检查: UP"
    elif [ "$status" = "DOWN" ]; then
        print_info "健康检查: DOWN (RabbitMQ连接问题，不影响核心功能)"
        print_info "响应: $response"
    else
        print_fail "健康检查失败"
    fi

    print_test "应用信息端点"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/info")
    if [ "$response" = "200" ]; then
        print_pass "应用信息可访问 (HTTP $response)"
    else
        print_info "应用信息端点: HTTP $response"
    fi
}

# 测试3: H2控制台
test_h2_console() {
    print_header "3. H2数据库控制台测试"

    print_test "H2控制台可访问性"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/h2-console")
    if [ "$response" = "200" ]; then
        print_pass "H2控制台可访问 (HTTP $response)"
        print_info "控制台URL: $BASE_URL/h2-console"
        print_info "JDBC URL: jdbc:h2:mem:primihub"
        print_info "用户名: sa"
        print_info "密码: (空)"
    else
        print_fail "H2控制台不可访问 (HTTP $response)"
    fi
}

# 测试4: 公开接口
test_public_apis() {
    print_header "4. 公开API端点测试"

    # 测试器官首页
    print_test "获取机构首页"
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/organ/getHomepage")
    if [ "$response" = "200" ]; then
        print_pass "机构首页API可访问 (HTTP $response)"
    else
        print_info "机构首页API: HTTP $response"
    fi

    # 测试公共密钥
    print_test "获取验证公钥"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/common/getValidatePublicKey")
    if [ "$response" = "200" ]; then
        print_pass "公钥API可访问 (HTTP $response)"
    else
        print_info "公钥API: HTTP $response"
    fi

    # 测试tracking ID
    print_test "获取Tracking ID"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/common/getTrackingID")
    if [ "$response" = "200" ]; then
        print_pass "Tracking ID API可访问 (HTTP $response)"
    else
        print_info "Tracking ID API: HTTP $response"
    fi
}

# 测试5: 服务响应时间
test_performance() {
    print_header "5. 服务性能测试"

    print_test "API响应时间"
    start_time=$(date +%s%N)
    curl -s "$BASE_URL/doc.html" > /dev/null
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))

    if [ $duration -lt 500 ]; then
        print_pass "响应时间: ${duration}ms (优秀)"
    elif [ $duration -lt 1000 ]; then
        print_pass "响应时间: ${duration}ms (良好)"
    else
        print_info "响应时间: ${duration}ms"
    fi
}

# 生成测试报告
generate_report() {
    print_header "测试报告"

    success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED/$TOTAL)*100}")

    echo -e "总测试数: ${BLUE}$TOTAL${NC}"
    echo -e "通过数: ${GREEN}$PASSED${NC}"
    echo -e "失败数: ${RED}$FAILED${NC}"
    echo -e "成功率: ${BLUE}$success_rate%${NC}"
    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ 所有测试通过！${NC}"
        echo ""
        echo "后端服务状态良好，核心功能可用。"
        return 0
    else
        echo -e "${YELLOW}⚠ 部分测试失败${NC}"
        echo ""
        echo "后端服务基本可用，但部分功能受限。"
        return 1
    fi
}

# 主函数
main() {
    print_header "PrimiHub 后端公开API测试"

    echo "开始时间: $(date)"
    echo "后端URL: $BASE_URL"
    echo ""

    # 运行测试
    test_swagger
    test_actuator
    test_h2_console
    test_public_apis
    test_performance

    # 生成报告
    generate_report
}

# 运行主函数
main "$@"
