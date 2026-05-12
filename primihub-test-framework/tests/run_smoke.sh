#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"; }
print_ok() { echo -e "${GREEN}[✓]${NC} $1"; }
print_fail() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${YELLOW}[i]${NC} $1"; }

BASE_URL="${API_BASE_URL:-http://localhost:8080}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-123456}"
REPORT_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXIT_CODE=0

print_header "PrimiHub 冒烟测试"
print_info "API: $BASE_URL"
print_info "用户: $ADMIN_USER"
print_info "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

mkdir -p "$REPORT_DIR"

# ─── Test 1: Health Check ───
print_header "1/6 健康检查"
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$BASE_URL/test/healthConnection" 2>/dev/null | grep -q 200; then
    print_ok "服务可达"
else
    print_fail "服务不可达 - 请确认后端已启动"
    EXIT_CODE=1
fi
echo ""

# ─── Test 2: Login ───
print_header "2/6 登录测试"
LOGIN_RESP=$(curl -s -X POST "$BASE_URL/user/login" \
    -d "userAccount=$ADMIN_USER&userPassword=$ADMIN_PASSWORD" 2>/dev/null)

if echo "$LOGIN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
    TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['token'])" 2>/dev/null)
    USER_ID=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['sysUser']['userId'])" 2>/dev/null)
    USER_NAME=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['sysUser']['userName'])" 2>/dev/null)
    print_ok "登录成功 - $USER_NAME (ID: $USER_ID)"
    print_info "Token: ${TOKEN:0:30}..."
else
    print_fail "登录失败"
    EXIT_CODE=1
fi
echo ""

if [ -z "$TOKEN" ]; then
    print_fail "无有效Token，跳过后续测试"
    exit $EXIT_CODE
fi

timestamp_nonce() {
    local ts=$(date +%s%3N)
    local nonce=$((ts % 1000 + 1))
    echo "timestamp=$ts&nonce=$nonce"
}

TS=$(date +%s%3N)
NONCE=$((TS % 1000 + 1))

# ─── Test 3: User Management ───
print_header "3/6 用户管理"
USER_LIST=$(curl -s -G "$BASE_URL/sys/user/findUserPage" \
    --data-urlencode "pageNum=1" --data-urlencode "pageSize=10" \
    --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
    --data-urlencode "token=$TOKEN" 2>/dev/null)
if echo "$USER_LIST" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
    USER_COUNT=$(echo "$USER_LIST" | python3 -c "import sys,json; d=json.load(sys.stdin)['result']; print(len(d.get('list',[])) if isinstance(d,dict) else len(d))" 2>/dev/null)
    print_ok "用户列表 (获取${USER_COUNT}个用户)"
else
    print_fail "用户列表获取失败"
    EXIT_CODE=1
fi

USER_DETAIL=$(curl -s -G "$BASE_URL/sys/user/findUserByAccount" \
    --data-urlencode "userAccount=admin" \
    --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
    --data-urlencode "token=$TOKEN" 2>/dev/null)
if echo "$USER_DETAIL" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
    print_ok "用户查询 (admin)"
else
    print_fail "用户查询失败"
    EXIT_CODE=1
fi
echo ""

# ─── Test 4: Resource Management ───
print_header "4/6 资源管理"
TS=$(date +%s%3N)
NONCE=$((TS % 1000 + 1))
RES_LIST=$(curl -s -G "$BASE_URL/data/resource/getresourcelist" \
    --data-urlencode "pageNo=1" --data-urlencode "pageSize=10" \
    --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
    --data-urlencode "token=$TOKEN" 2>/dev/null)
if echo "$RES_LIST" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
    print_ok "资源列表"
else
    print_fail "资源列表获取失败"
    EXIT_CODE=1
fi
echo ""

# ─── Test 5: System Config ───
print_header "5/6 系统配置"
TS=$(date +%s%3N)
NONCE=$((TS % 1000 + 1))
for api in "getHomepage" "getOrganList"; do
    RESP=$(curl -s -G "$BASE_URL/sys/organ/$api" \
        --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
        --data-urlencode "token=$TOKEN" 2>/dev/null)
    if echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
        print_ok "$api"
    else
        print_fail "$api"
        EXIT_CODE=1
    fi
done

for api in "getNetworkConfig" "getLoginRestriction" "getTimeConfig"; do
    TS=$(date +%s%3N)
    NONCE=$((TS % 1000 + 1))
    RESP=$(curl -s -G "$BASE_URL/systemConfig/$api" \
        --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
        --data-urlencode "token=$TOKEN" 2>/dev/null)
    if echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
        print_ok "$api"
    else
        print_fail "$api"
        EXIT_CODE=1
    fi
done
echo ""

# ─── Test 6: Auth & Roles ───
print_header "6/6 权限与角色"
TS=$(date +%s%3N)
NONCE=$((TS % 1000 + 1))
for api in "getAuthList" "findRolePage"; do
    if [ "$api" = "findRolePage" ]; then
        RESP=$(curl -s -G "$BASE_URL/sys/role/$api" \
            --data-urlencode "pageNum=1" --data-urlencode "pageSize=10" \
            --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
            --data-urlencode "token=$TOKEN" 2>/dev/null)
    else
        RESP=$(curl -s -G "$BASE_URL/sys/oauth/$api" \
            --data-urlencode "timestamp=$TS" --data-urlencode "nonce=$NONCE" \
            --data-urlencode "token=$TOKEN" 2>/dev/null)
    fi
    if echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('code')==0 else 1)" 2>/dev/null; then
        print_ok "$api"
    else
        print_fail "$api"
        EXIT_CODE=1
    fi
done
echo ""

# ─── Summary ───
print_header "冒烟测试完成"
if [ $EXIT_CODE -eq 0 ]; then
    print_ok "全部通过"
else
    print_fail "存在失败项"
fi
print_info "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
exit $EXIT_CODE
