#!/bin/bash

# 联邦分析 API 本地测试脚本
# 在部署服务器上直接测试 API 访问

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数 - 使用 localhost
BASE_URL="http://localhost:30811"
API_PREFIX="/prod-api"
USERNAME="${TEST_USERNAME:-admin}"
PASSWORD="${TEST_PASSWORD:-primihub123}"

echo "=========================================="
echo "联邦分析 API 本地测试"
echo "=========================================="
echo ""
echo "配置信息:"
echo "  - 基础URL: $BASE_URL"
echo "  - API前缀: $API_PREFIX"
echo "  - 用户名: $USERNAME"
echo ""

# 临时文件
COOKIE_FILE="/tmp/test_cookies_$(date +%s).txt"
RESPONSE_FILE="/tmp/test_response_$(date +%s).json"
rm -f "$COOKIE_FILE" "$RESPONSE_FILE"

# 测试结果
LOGIN_SUCCESS=false
PERMISSION_LOADED=false
HAS_FEDERATED_ANALYSIS_PERM=false
API_ACCESS_SUCCESS=false

# 步骤1: 登录
echo -e "${BLUE}📝 步骤1: 用户登录...${NC}"

# 构建登录请求数据
TIMESTAMP=$(date +%s)000
NONCE=$RANDOM

LOGIN_DATA="userAccount=${USERNAME}&userPassword=${PASSWORD}&timestamp=${TIMESTAMP}&nonce=${NONCE}"

echo "  发送登录请求..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -c "$COOKIE_FILE" \
  -d "$LOGIN_DATA" \
  "$BASE_URL$API_PREFIX/sys/user/login" 2>&1)

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

echo "$RESPONSE_BODY" > "$RESPONSE_FILE"

echo "  HTTP状态码: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    # 解析响应
    CODE=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('code', -1))" 2>/dev/null || echo "-1")

    if [ "$CODE" = "0" ]; then
        echo -e "${GREEN}  ✓ 登录成功 (code: $CODE)${NC}"
        LOGIN_SUCCESS=true

        # 提取 token
        TOKEN=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('token', ''))" 2>/dev/null || echo "")

        if [ -n "$TOKEN" ]; then
            echo -e "${GREEN}  ✓ Token已获取: ${TOKEN:0:30}...${NC}"
        else
            echo -e "${YELLOW}  ⚠️  未找到token${NC}"
        fi

        # 提取权限列表
        PERMISSION_JSON=$(echo "$RESPONSE_BODY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
perms = data.get('result', {}).get('grantAuthRootList', [])
print(json.dumps(perms, ensure_ascii=False))
" 2>/dev/null || echo "[]")

        PERMISSION_COUNT=$(echo "$PERMISSION_JSON" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

        if [ "$PERMISSION_COUNT" -gt 0 ]; then
            echo -e "${GREEN}  ✓ 权限数据已返回，共 $PERMISSION_COUNT 条权限${NC}"
            PERMISSION_LOADED=true

            # 检查是否包含联邦分析权限
            FEDERATED_PERMS=$(echo "$PERMISSION_JSON" | python3 -c "
import sys, json
perms = json.load(sys.stdin)
fed_perms = [p for p in perms if 'FederatedAnalysis' in p.get('authCode', '')]
for p in fed_perms:
    print(f\"    - {p.get('authCode')}: {p.get('authName', 'N/A')}\")
if fed_perms:
    exit(0)
else:
    exit(1)
" 2>/dev/null)

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}  ✓ 包含联邦分析相关权限:${NC}"
                echo "$FEDERATED_PERMS"
                HAS_FEDERATED_ANALYSIS_PERM=true
            else
                echo -e "${YELLOW}  ⚠️  未找到联邦分析相关权限${NC}"
                echo "  所有权限列表:"
                echo "$PERMISSION_JSON" | python3 -c "
import sys, json
perms = json.load(sys.stdin)
for p in perms[:10]:  # 只显示前10个
    print(f\"    - {p.get('authCode')}: {p.get('authName', 'N/A')}\")
if len(perms) > 10:
    print(f\"    ... 还有 {len(perms) - 10} 条权限\")
" 2>/dev/null || echo "    (无法解析权限列表)"
            fi
        else
            echo -e "${YELLOW}  ⚠️  权限数据为空${NC}"
        fi

        # 提取用户信息
        USER_NAME=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('sysUser', {}).get('userName', ''))" 2>/dev/null || echo "")

        if [ -n "$USER_NAME" ]; then
            echo -e "${GREEN}  ✓ 用户名: $USER_NAME${NC}"
        fi
    else
        MSG=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('msg', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
        echo -e "${RED}  ❌ 登录失败 (code: $CODE, msg: $MSG)${NC}"
        echo "  完整响应: $RESPONSE_BODY"
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

TIMESTAMP=$(date +%s)000
NONCE=$RANDOM

API_URL="$BASE_URL$API_PREFIX/data/federatedAnalysis/list?pageNum=1&pageSize=10&timestamp=${TIMESTAMP}&nonce=${NONCE}&token=${TOKEN}"

echo "  请求URL: $API_URL"

API_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X GET \
  -H "Content-Type: application/json" \
  -H "token: $TOKEN" \
  -b "$COOKIE_FILE" \
  "$API_URL" 2>&1)

HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$API_RESPONSE" | sed '$d')

echo "  HTTP状态码: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    CODE=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('code', -1))" 2>/dev/null || echo "-1")

    if [ "$CODE" = "0" ]; then
      echo -e "${GREEN}  ✓ API调用成功 (code: $CODE)${NC}"
        API_ACCESS_SUCCESS=true

        # 检查是否有数据
        HAS_RESULT=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print('yes' if 'result' in data else 'no')" 2>/dev/null || echo "no")

        if [ "$HAS_RESULT" = "yes" ]; then
            echo -e "${GREEN}  ✓ 返回了结果数据${NC}"
        fi
    elif [ "$CODE" = "103" ]; then
        echo -e "${RED}  ❌ 权限被拒绝 (code: 103 - 暂无权限)${NC}"
        MSG=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); priet('msg', ''))" 2>/dev/null || echo "")
        echo "  消息: $MSG"
        echo "  完整响应: $RESPONSE_BODY"
    else
        MSG=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('msg', ''))" 2>/dev/null || echo "")
        echo -e "${YELLOW}  ⚠️  API返回错误 (code: $CODE, msg: $MSG)${NC}"
        echo "  完整响应: $RESPONSE_BODY"
    fi
else
    echo -e "${RED}  ❌ API请求失败 (HTTP $HTTP_CODE)${NC}"
    echo "  响应: $RESPONSE_BODY"
fi

echo ""

# 步骤3: 检查 Cookie
echo -e "${BLUE}📝 步骤3: 检查 Cookie 信息...${NC}"
if [ -f "$COOKIE_FILE" ]; then
    echo "  Cookie 内容:"
    cat "$COOKIE_FILE" | grep -v "^#" | grep -v "^$" | while read -r line; do
        echo "    $line"
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
echo -e "✅ 登录: $([ "$LOGIN_SUCCESS" = true ] && echo -e "${GREEN}成功${NC}" || echo -e "${RED}失败${NC}")"
echo -e "✅ 权限加载: $([ "$PERMISSION_LOADED" = true ] && echo -e "${GREEN}成功${NC}" || echo -e "${RED}失败${NC}" -e "✅ 联邦分析权限: $([ "$HAS_FEDERATED_ANALYSIS_PERM" = true ] && echo -e "${GREEN}存在${NC}" || echo -e "${RED}不存在${NC}")"
echo -e "✅ API访问: $([ "$API_ACCESS_SUCCESS" = true ] && echo -e "${GREEN}成功${NC}" || echo -e "${RED}失败${NC}")"
echo "=========================================="

if [ "$LOGIN_SUCCESS" = true ] && [ "$PERMISSION_LOADED" = true ] && [ "$API_ACCESS_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    echo ""
    echo "结论: 后端 API 权限验证正常，问题可能在前端路由生成逻辑。"
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
        echo "  - 检查用户是否有权限"
        echo "  - 检查数据库中的权限配置"
    fi
    if [ "$HAS_FEDERATED_ANALYSIS_PERM" = false ]; then
        echo "  - 用户没有联邦分析权限，需要在数据库中配置"
        echo "  - 运行权限初始化脚本: ~/primihub-platform/init_permissions.sql"
    fi
    if [ "$API_ACCESS_SUCCESS" = false ]; then
        echo "  - 检查后端权限验证逻辑"
        echo "  - 检查 token 是否正确传递"
        echo "  - 查看后端日志: docker logs appl
    fi
    exit 1
fi
