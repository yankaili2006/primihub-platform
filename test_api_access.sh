#!/bin/bash

# 联邦分析 API 访问测试脚本
# 通过 API 调用模拟前端访问流程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
BASE_URL="${BASE_URL:-http://localhost:8080}"
API_PREFIX="${API_PREFIX:-/dev-api}"
USERNAME="${TEST_USERNAME:-admin}"
PASSWORD="${TEST_PASSWORD:-admin123}"

echo "=========================================="
echo "联邦分析 API 访问测试"
echo "=========================================="
echo ""
echo "配置信息:"
echo "  - 基础URL: $BASE_URL"
echo "  - API前缀: $API_PREFIX"
echo "  - 用户名: $USERNAME"
echo ""

# 临时文件
COOKIE_FILE="/tmp/test_cookies.txt"
RESPONSE_FILE="/tmp/test_response.json"
rm -f "$COOKIE_FILE" "$RESPONSE_FILE"

# 测试结果
LOGIN_SUCCESS=false
PERMISSION_LOADED=false
API_ACCESS_SUCCESS=false

# 步骤1: 登录
echo -e "${BLUE}📝 步骤1: 用户登录...${NC}"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -c "$COOKIE_FILE" \
  --data-urlencode "userAccount=$USERNAME" \
  --data-urlencode "userPassword=$PASSWORD" \
  --data-urlencode "timestamp=$(date +%s)000" \
  --data-urlencode "nonce=$RANDOM" \
  "$BASE_URL$API_PREFIX/sys/user/login" 2>&1)

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

echo "$RESPONSE_BODY" > "$RESPONSE_FILE"

if [ "$HTTP_CODE" = "200" ]; then
    # 解析响应
    CODE=$(echo "$RESPONSE_BODY" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)

    if [ "$CODE" = "0" ]; then
        echo -e "${GREEN}  ✓ 登录成功 (HTTP $HTTP_CODE, code: $CODE)${NC}"
        LOGIN_SUCCESS=true

        # 提取 token
        TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$TOKEN" ]; then
            echo -e "${GREEN}  ✓ Token已获取: ${TOKEN:0:20}...${NC}"
        else
            echo -e "${YELLOW}  ⚠️  未找到token${NC}"
        fi

        # 提取权限列表
        PERMISSION_COUNT=$(echo "$RESPONSE_BODY" | grep -o '"grantAuthRootList":\[' | wc -l)
        if [ "$PERMISSION_COUNT" -gt 0 ]; then
            echo -e "${GREEN}  ✓ 权限数据已返回${NC}"
            PERMISSION_LOADED=true

            # 检查是否包含联邦分析权限
            if echo "$RESPONSE_BODY" | grep -q "FederatedAnalysis"; then
                echo -e "${GREEN}  ✓ 包含联邦分析相关权限${NC}"

                # 提取所有联邦分析权限
                echo "  联邦分析权限列表:"
                echo "$RESPONSE_BODY" | grep -o '"authCode":"[^"]*FederatedAnalysis[^"]*"' | cut -d'"' -f4 | while read -r auth; do
                    echo "    - $auth"
                done
            else
                echo -e "${YELLOW}  ⚠️  未找到联邦分析相关权限${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  权限数据为空${NC}"
        fi

        # 提取用户信息
        USER_NAME=$(echo "$RESPONSE_BODY" | grep -o '"userName":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$USER_NAME" ]; then
            echo -e "${GREEN}  ✓ 用户名: $USER_NAME${NC}"
        fi
    else
        MSG=$(echo "$RESPONSE_BODY" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
        echo -e "${RED}  ❌ 登录失败 (code: $CODE, msg: $MSG)${NC}"
    fi
else
    echo -e "${RED}  ❌ 登录请求失败 (HTTP $HTTP_CODE)${NC}"
    echo "  响应: $RESPONSE_BODY"
fi

echo ""

# 如果登录失败，退出
if [ "$LOGIN_SUCCESS" = false ]; then
    echo -e "${RED}❌ 登录失败，无法继续测试${NC}"
    rm -f "$COOKIE_FILE" "$RESPONSE_FILE"
    exit 1
fi

# 步骤2: 测试联邦分析列表 API
echo -e "${BLUE}📝 步骤2: 访问联邦分析列表 API...${NC}"

API_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X GET \
  -H "Content-Type: application/json" \
  -H "token: $TOKEN" \
  -b "$COOKIE_FILE" \
  "$BASE_URL$API_PREFIX/data/federatedAnalysis/list?pageNum=1&pageSize=10&timestamp=$(date +%s)000&nonce=$RANDOM&token=$TOKEN" 2>&1)

HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$API_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    CODE=$(echo "$RESPONSE_BODY" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)

    if [ "$CODE" = "0" ]; then
        echo -e "${GREEN}  ✓ API调用成功 (HTTP $HTTP_CODE, code: $CODE)${NC}"
        API_ACCESS_SUCCESS=true

        # 检查是否有数据
        if echo "$RESPONSE_BODY" | grep -q '"result"'; then
            echo -e "${GREEN}  ✓ 返回了结果数据${NC}"
        fi
    elif [ "$CODE" = "103" ]; then
        echo -e "${RED}  ❌ 权限被拒绝 (code: 103 - 暂无权限)${NC}"
        MSG=$(echo "$RESPONSE_BODY" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
        echo "  消息: $MSG"
    else
        MSG=$(echo "$RESPONSE_BODY" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
        echo -e "${YELLOW}  ⚠️  API返回错误 (code: $CODE, msg: $MSG)${NC}"
    fi
else
    echo -e "${RED}  ❌ API请求失败 (HTTP $HTTP_CODE)${NC}"
    echo "  响应: $RESPONSE_BODY"
fi

echo ""

# 步骤3: 测试其他联邦分析相关 API
echo -e "${BLUE}📝 步骤3: 测试其他联邦分析 API...${NC}"

# 测试数据源列表 API
echo "  测试: 数据源列表 API"
DS_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X GET \
  -H "token: $TOKEN" \
  -b "$COOKIE_FILE" \
  "$BASE_URL$API_PREFIX/data/federatedAnalysis/datasource/list?pageNum=1&pageSize=10&timestamp=$(date +%s)000&nonce=$RANDOM&token=$TOKEN" 2>&1)

DS_HTTP_CODE=$(echo "$DS_RESPONSE" | tail -n1)
DS_BODY=$(echo "$DS_RESPONSE" | sed '$d')

if [ "$DS_HTTP_CODE" = "200" ]; then
    DS_CODE=$(echo "$DS_BODY" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)
    if [ "$DS_CODE" = "0" ]; then
        echo -e "${GREEN}    ✓ 数据源列表 API 调用成功${NC}"
    elif [ "$DS_CODE" = "103" ]; then
        echo -e "${RED}    ❌ 数据源列表 API 权限被拒绝 (code: 103)${NC}"
    else
        echo -e "${YELLOW}    ⚠️  数据源列表 API 返回错误 (code: $DS_CODE)${NC}"
    fi
else
    echo -e "${RED}    ❌ 数据源列表 API 请求失败 (HTTP $DS_HTTP_CODE)${NC}"
fi

echo ""

# 步骤4: 检查 Cookie 中的 token
echo -e "${BLUE}📝 步骤4: 检查 Cookie 信息...${NC}"
if [ -f "$COOKIE_FILE" ]; then
    echo "  Cookie 文件内容:"
    cat "$COOKIE_FILE" | grep -v "^#" | while read -r line; do
        if [ -n "$line" ]; then
            echo "    $line"
        fi
    done
else
    echo -e "${YELLOW}  ⚠️  Cookie 文件不存在${NC}"
fi

echo ""

# 清理临时文件
rm -f "$COOKIE_FILE" "$RESPONSE_FILE"

# 输出测试结果汇总
echo "=========================================="
echo "📊 测试结果汇总"
echo "=========================================="
echo -e "登录: $([ "$LOGIN_SUCCESS" = true ] && echo -e "${GREEN}✅ 成功${NC}" || echo -e "${RED}❌ 失败${NC}")"
echo -e "权限加载: $([ "$PERMISSION_LOADED" = true ] && echo -e "${GREEN}✅ 成功${NC}" || echo -e "${RED}❌ 失败${NC}")"
echo -e "API访问: $([ "$API_ACCESS_SUCCESS" = true ] && echo -e "${GREEN}✅ 成功${NC}" || echo -e "${RED}❌ 失败${NC}")"
echo "=========================================="

if [ "$LOGIN_SUCCESS" = true ] && [ "$PERMISSION_LOADED" = true ] && [ "$API_ACCESS_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  部分测试失败${NC}"
    echo ""
    echo "分析建议:"
    if [ "$LOGIN_SUCCESS" = false ]; then
        echo "  - 检查用户名和密码是否正确"
        echo "  - 检查后端服务是否正常运行"
    fi
    if [ "$PERMISSION_LOADED" = false ]; then
        echo "  - 检查用户是否有联邦分析权限"
        echo "  - 检查数据库中的权限配置"
    fi
    if [ "$API_ACCESS_SUCCESS" = false ]; then
        echo "  - 检查后端权限验证逻辑"
        echo "  - 检查 token 是否正确传递"
        echo "  - 查看后端日志获取详细错误信息"
    fi
    exit 1
fi
