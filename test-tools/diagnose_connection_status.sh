#!/bin/bash

echo "======================================================================"
echo "节点连接状态详细诊断"
echo "======================================================================"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 检查数据库中的详细状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT 
    id,
    organ_id,
    organ_name,
    organ_gateway,
    examine_state,
    enable,
    apply_id,
    public_key IS NOT NULL as 'has_public_key',
    is_del,
    create_date
FROM sys_organ 
ORDER BY id;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 测试节点间网络连通性"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for port in 30811 30812 30813; do
    echo "测试端口 $port:"
    status=$(curl -s -o /dev/null -w "%{http_code}" http://100.64.0.23:${port}/prod-api/healthConnection 2>/dev/null)
    if [ "$status" = "200" ]; then
        echo "  ✓ 端口 $port 可访问 (HTTP $status)"
    else
        echo "  ✗ 端口 $port 不可访问 (HTTP $status)"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 检查应用容器状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker ps --filter "name=application" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 调用连接测试API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 登录获取token
TOKEN=$(curl -s -X POST "http://100.64.0.23:30811/prod-api/sys/user/login" \
    -d "userAccount=admin&userPassword=123456&timestamp=$(date +%s)000&nonce=123" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['token'] if data.get('code')==0 else '')" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    echo "✓ 登录成功"
    echo ""
    
    # 测试各个节点的连接状态API
    for port in 30811 30812 30813; do
        echo "节点 $port 的机构信息:"
        curl -s "http://100.64.0.23:${port}/prod-api/sys/organ/getOrganList?token=$TOKEN&pageNo=1&pageSize=10&timestamp=$(date +%s)000&nonce=123" \
            -H "userId: 1" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('code') == 0:
        organs = data.get('result', {}).get('data', [])
        print(f'  找到 {len(organs)} 个机构')
        for org in organs:
            enable_status = '启用' if org.get('enable') == 1 else '禁用'
            examine_status = '已批准' if org.get('examineState') == 1 else ('待审核' if org.get('examineState') == 0 else '已拒绝')
            print(f'  - {org.get(\"organName\")}: {examine_status}, {enable_status}')
    else:
        print(f'  ✗ 查询失败: {data.get(\"msg\")}')
except Exception as e:
    print(f'  ✗ 解析失败: {e}')
" 2>/dev/null
        echo ""
    done
else
    echo "✗ 登录失败"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 检查网关服务状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker ps --filter "name=gateway" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. 检查Fusion服务状态（节点间通信）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker ps --filter "name=fusion" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "======================================================================"
echo "诊断完成"
echo "======================================================================"
echo ""
echo "请告诉我："
echo "1. 你在哪里看到\"未连接\"状态？（Web界面？CLI输出？日志？）"
echo "2. 具体显示的错误信息是什么？"
echo "3. 你期望看到什么样的\"已连接\"状态？"
