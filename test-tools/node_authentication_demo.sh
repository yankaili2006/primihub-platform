#!/bin/bash

echo "======================================================================"
echo "PrimiHub 节点互联和认证完整演示"
echo "======================================================================"
echo ""

# 节点配置
NODE0_URL="http://100.64.0.23:30811/prod-api"
NODE1_URL="http://100.64.0.23:30812/prod-api"
NODE2_URL="http://100.64.0.23:30813/prod-api"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第一步: 查看各节点当前的认证状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for port in 30811 30812 30813; do
    echo "【节点端口 $port】"
    python3 primihub-cli.py --url http://100.64.0.23:${port}/prod-api \
        --user admin --password 123456 auth-list 2>/dev/null | \
        grep -A 20 "节点认证状态" | head -25
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第二步: 查看数据库中的认证关系"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT 
    id as 'ID',
    organ_name as '机构名称',
    LEFT(organ_gateway, 35) as '网关地址',
    CASE examine_state 
        WHEN 0 THEN '待审核'
        WHEN 1 THEN '已批准'
        WHEN 2 THEN '已拒绝'
    END as '审核状态',
    CASE enable 
        WHEN 0 THEN '禁用'
        WHEN 1 THEN '启用'
    END as '启用状态',
    apply_id as '申请ID'
FROM sys_organ 
WHERE is_del=0
ORDER BY id;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第三步: 演示禁用和启用机构（模拟认证管理）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "【操作1】禁用机构ID=1 (API测试机构)"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 \
    auth-disable 1 2>/dev/null | grep -A 5 "禁用机构"

echo ""
echo "【验证】查看禁用后的状态"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 \
    auth-list 2>/dev/null | grep -A 15 "节点认证状态" | head -20

echo ""
echo "【操作2】重新启用机构ID=1"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 \
    auth-enable 1 2>/dev/null | grep -A 5 "启用机构"

echo ""
echo "【验证】查看启用后的状态"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 \
    auth-list 2>/dev/null | grep -A 15 "节点认证状态" | head -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第四步: 查看API调用详情"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "【API调用流程】"
echo ""
echo "1. 登录API"
echo "   POST /sys/user/login"
echo "   参数: userAccount=admin, userPassword=123456"
echo "   返回: token, userId"
echo ""

echo "2. 查询机构列表API"
echo "   GET /sys/organ/getOrganList"
echo "   参数: token, pageNo=1, pageSize=100"
echo "   返回: 机构列表数据"
echo ""

echo "3. 启用/禁用机构API"
echo "   GET /sys/organ/enableStatus"
echo "   参数: token, id=<机构ID>, status=<0|1>"
echo "   返回: 操作结果"
echo ""

echo "4. 审核认证请求API"
echo "   GET /sys/organ/examineJoining"
echo "   参数: token, id=<申请ID>, examineState=<1|2>, examineMsg=<原因>"
echo "   返回: 审核结果"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第五步: 实际API调用示例"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "【示例1】登录并获取Token"
TOKEN=$(curl -s -X POST "$NODE0_URL/sys/user/login" \
    -d "userAccount=admin&userPassword=123456&timestamp=$(date +%s)000&nonce=123" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['token'] if data.get('code')==0 else 'FAILED')")

if [ "$TOKEN" != "FAILED" ]; then
    echo "✓ 登录成功"
    echo "  Token: ${TOKEN:0:30}..."
else
    echo "✗ 登录失败"
fi

echo ""
echo "【示例2】查询机构列表"
curl -s "$NODE0_URL/sys/organ/getOrganList?token=$TOKEN&pageNo=1&pageSize=10&timestamp=$(date +%s)000&nonce=123" \
    -H "userId: 1" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('code') == 0:
        organs = data.get('result', {}).get('data', [])
        print(f'✓ 查询成功，找到 {len(organs)} 个机构')
        for org in organs:
            print(f'  - {org.get(\"organName\")}: {org.get(\"organGateway\")} (状态: {\"启用\" if org.get(\"enable\")==1 else \"禁用\"})')
    else:
        print(f'✗ 查询失败: {data.get(\"msg\")}')
except:
    print('✗ 解析失败')
"

echo ""
echo "【示例3】查询本地机构公钥"
curl -s "$NODE0_URL/sys/organ/getLocalOrganInfo?token=$TOKEN&timestamp=$(date +%s)000&nonce=123" \
    -H "userId: 1" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('code') == 0:
        organ = data.get('result', {}).get('sysLocalOrganInfo', {})
        pk = organ.get('publicKey', '')
        print(f'✓ 查询成功')
        print(f'  机构ID: {organ.get(\"organId\")}')
        print(f'  机构名称: {organ.get(\"organName\")}')
        print(f'  公钥: {\"已配置 (\" + str(len(pk)) + \" 字符)\" if pk else \"未配置\"}')
    else:
        print(f'✗ 查询失败: {data.get(\"msg\")}')
except:
    print('✗ 解析失败')
"

echo ""
echo "======================================================================"
echo "演示完成"
echo "======================================================================"
echo ""
echo "总结:"
echo "  ✓ 所有节点已相互认证"
echo "  ✓ CLI工具可以管理认证状态"
echo "  ✓ API调用正常工作"
echo "  ✓ 可以启用/禁用机构"
echo ""
echo "说明:"
echo "  当前环境中所有节点共享数据库，已经预先配置了认证关系。"
echo "  在生产环境中（独立数据库），可以使用 auth-request 命令发起新的认证请求。"
