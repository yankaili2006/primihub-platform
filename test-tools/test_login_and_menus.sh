#!/bin/bash

# 测试前端登录和新菜单显示
# 用途：验证新增的9个功能页面菜单是否正常返回

BASE_URL="http://100.64.0.23:30811"
API_URL="${BASE_URL}/prod-api"

echo "=========================================="
echo "PrimiHub 前端登录和菜单测试工具"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试1: 登录
echo "【测试1】用户登录测试"
echo "----------------------------"
echo "正在登录... (admin/123456)"

LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/user/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "userAccount=admin&userPassword=123456")

# 检查登录是否成功
LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('code', -1))" 2>/dev/null)

if [ "$LOGIN_CODE" = "0" ]; then
    echo -e "${GREEN}✓ 登录成功${NC}"

    # 提取token
    TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result'].get('token', ''))" 2>/dev/null)
    echo "Token: ${TOKEN:0:50}..."
else
    echo -e "${RED}✗ 登录失败${NC}"
    echo "响应: $LOGIN_RESPONSE"
    exit 1
fi

echo ""

# 测试2: 检查菜单数量
echo "【测试2】菜单数量统计"
echo "----------------------------"

python3 << 'EOF'
import json
import sys

response = '''LOGIN_RESPONSE_PLACEHOLDER'''
data = json.loads(response)

def count_all_menus(auth_list):
    count = 0
    for auth in auth_list:
        count += 1
        if auth.get('children'):
            count += count_all_menus(auth['children'])
    return count

total = count_all_menus(data['result']['grantAuthRootList'])
print(f"菜单总数: {total}")

if total >= 189:
    print(f"\033[0;32m✓ 菜单数量正常 (预期>=189)\033[0m")
else:
    print(f"\033[0;31m✗ 菜单数量异常 (预期>=189, 实际{total})\033[0m")
EOF

# 替换占位符
sed -i "s|LOGIN_RESPONSE_PLACEHOLDER|$(echo "$LOGIN_RESPONSE" | sed 's/|/\\|/g')|g" /tmp/test_menu_count.py 2>/dev/null || true

echo ""

# 测试3: 检查新增菜单
echo "【测试3】新增菜单检查"
echo "----------------------------"

echo "$LOGIN_RESPONSE" | python3 << 'EOF'
import json
import sys

data = json.load(sys.stdin)

def get_all_menus(auth_list):
    menus = []
    for auth in auth_list:
        menus.append(auth)
        if auth.get('children'):
            menus.extend(get_all_menus(auth['children']))
    return menus

all_menus = get_all_menus(data['result']['grantAuthRootList'])

# 新增菜单列表
new_menus = {
    1142: '联邦学习模型预览',
    1143: '联邦学习模型导入',
    1144: '联邦学习模型导出',
    1145: '联邦建模工作台',
    1146: '联邦查询',
    1147: '联邦查询计费（按次数）',
    1148: '联邦查询计费（按命中）',
    1149: '联邦查询去重计费（固定时间范围）',
    1150: '联邦查询去重计费（滚动时间范围）',
    1151: '联邦查询实时接口校验'
}

found_menus = {}
for menu in all_menus:
    if menu['authId'] in new_menus:
        found_menus[menu['authId']] = menu['authName']

print(f"新增菜单检查结果: {len(found_menus)}/10")
print("")

success_count = 0
for auth_id, expected_name in new_menus.items():
    if auth_id in found_menus:
        print(f"\033[0;32m✓\033[0m {auth_id}: {found_menus[auth_id]}")
        success_count += 1
    else:
        print(f"\033[0;31m✗\033[0m {auth_id}: {expected_name} (未找到)")

print("")
if success_count == 10:
    print(f"\033[0;32m✓ 所有新增菜单都已正确返回！\033[0m")
else:
    print(f"\033[0;31m✗ 缺少 {10 - success_count} 个菜单\033[0m")
EOF

echo ""

# 测试4: 检查菜单结构
echo "【测试4】菜单结构检查"
echo "----------------------------"

echo "$LOGIN_RESPONSE" | python3 << 'EOF'
import json
import sys

data = json.load(sys.stdin)

def find_menu_by_id(auth_list, target_id):
    for auth in auth_list:
        if auth['authId'] == target_id:
            return auth
        if auth.get('children'):
            result = find_menu_by_id(auth['children'], target_id)
            if result:
                return result
    return None

# 检查联邦学习父菜单
fl_parent = find_menu_by_id(data['result']['grantAuthRootList'], 1262)
if fl_parent:
    print(f"✓ 找到联邦学习父菜单 (1262): {fl_parent['authName']}")

    # 检查子菜单
    fl_children = [1142, 1143, 1144, 1145]
    found_children = []

    def get_all_children_ids(menu):
        ids = []
        if menu.get('children'):
            for child in menu['children']:
                ids.append(child['authId'])
                ids.extend(get_all_children_ids(child))
        return ids

    all_children_ids = get_all_children_ids(fl_parent)

    for child_id in fl_children:
        if child_id in all_children_ids:
            found_children.append(child_id)

    if len(found_children) == 4:
        print(f"\033[0;32m  ✓ 联邦学习4个子菜单结构正确\033[0m")
    else:
        print(f"\033[0;31m  ✗ 联邦学习子菜单不完整 ({len(found_children)}/4)\033[0m")
else:
    print("\033[0;31m✗ 未找到联邦学习父菜单 (1262)\033[0m")

print("")

# 检查联邦查询菜单
fq_parent = find_menu_by_id(data['result']['grantAuthRootList'], 1146)
if fq_parent:
    print(f"✓ 找到联邦查询菜单 (1146): {fq_parent['authName']}")

    # 检查子菜单
    fq_children = [1147, 1148, 1149, 1150, 1151]
    found_children = []

    all_children_ids = get_all_children_ids(fq_parent)

    for child_id in fq_children:
        if child_id in all_children_ids:
            found_children.append(child_id)

    if len(found_children) == 5:
        print(f"\033[0;32m  ✓ 联邦查询5个子菜单结构正确\033[0m")
    else:
        print(f"\033[0;31m  ✗ 联邦查询子菜单不完整 ({len(found_children)}/5)\033[0m")
else:
    print("\033[0;31m✗ 未找到联邦查询菜单 (1146)\033[0m")
EOF

echo ""

# 测试5: 测试页面访问
echo "【测试5】页面URL访问测试"
echo "----------------------------"

# 测试几个关键页面
test_urls=(
    "/#/FederatedLearning/modelPreview|联邦学习模型预览"
    "/#/federatedQuery/billingByCount|联邦查询计费（按次数）"
    "/#/federatedQuery/apiValidation|联邦查询实时接口校验"
)

for url_info in "${test_urls[@]}"; do
    IFS='|' read -r url name <<< "$url_info"
    full_url="${BASE_URL}${url}"

    # 检查页面是否可访问（返回200）
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$full_url")

    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✓${NC} $name"
        echo "  URL: $full_url"
    else
        echo -e "${RED}✗${NC} $name (HTTP $status_code)"
        echo "  URL: $full_url"
    fi
done

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo ""
echo "访问地址: ${BASE_URL}"
echo "登录账号: admin / 123456"
echo ""
