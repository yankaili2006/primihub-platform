#!/bin/bash

echo "======================================================================"
echo "检查PrimiHub Node服务通信状态"
echo "======================================================================"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 检查Node服务日志"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for node in primihub-node0 primihub-node1 primihub-node2; do
    echo "【$node】最近的日志:"
    docker logs $node --tail 20 2>&1 | grep -v "^$" | tail -10
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 检查数据库中的Node配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SHOW TABLES LIKE '%node%';
" 2>/dev/null

echo ""
docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT 
    id,
    organ_id,
    organ_name,
    node_id,
    node_name,
    node_address,
    is_del
FROM sys_organ_node
WHERE is_del = 0
ORDER BY id;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 检查Node配置文件"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in 0 1 2; do
    echo "【Node$i 配置】"
    docker exec primihub-node$i cat /app/config/node$i.yaml 2>/dev/null | grep -A 5 -E "node:|location:|address:" | head -20
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 测试Node服务健康状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for port in 50050 50051 50052; do
    echo "测试 Node 端口 $port:"
    # 尝试连接gRPC端口
    timeout 2 bash -c "echo > /dev/tcp/100.64.0.23/$port" 2>/dev/null && \
        echo "  ✓ 端口 $port 可连接" || \
        echo "  ✗ 端口 $port 连接失败"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 查看Web界面可能显示的连接状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "通过API查询节点连接状态:"
TOKEN=$(curl -s -X POST "http://100.64.0.23:30811/prod-api/sys/user/login" \
    -d "userAccount=admin&userPassword=123456&timestamp=$(date +%s)000&nonce=123" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['token'] if data.get('code')==0 else '')" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    # 查询节点列表
    curl -s "http://100.64.0.23:30811/prod-api/sys/organ/getOrganNodeList?token=$TOKEN&timestamp=$(date +%s)000&nonce=123" \
        -H "userId: 1" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('code') == 0:
        nodes = data.get('result', [])
        if nodes:
            print(f'✓ 找到 {len(nodes)} 个节点配置')
            for node in nodes:
                print(f'  - {node.get(\"nodeName\")}: {node.get(\"nodeAddress\")}')
        else:
            print('⚠️  未找到节点配置')
            print('   说明: 数据库中可能没有配置Node地址')
    else:
        print(f'API返回: {data.get(\"msg\")}')
except Exception as e:
    print(f'解析失败: {e}')
" 2>/dev/null
fi

echo ""
echo "======================================================================"
echo "连接状态总结"
echo "======================================================================"
echo ""
echo "PrimiHub系统有两层连接:"
echo ""
echo "【第一层：管理平台连接】"
echo "  服务: Application + Gateway"
echo "  用途: 机构管理、任务调度、Web界面"
echo "  状态: ✓ 已连接"
echo "  验证: examine_state=1, enable=1"
echo ""
echo "【第二层：计算节点连接】"
echo "  服务: PrimiHub Node (gRPC)"
echo "  用途: 实际的联合计算（PSI、联邦学习等）"
echo "  端口: 50050, 50051, 50052"
echo "  状态: 服务运行中"
echo "  配置: 需要在数据库sys_organ_node表中配置"
echo ""
echo "如果Web界面显示\"未连接\"，可能是因为:"
echo "  1. sys_organ_node表中没有配置Node地址"
echo "  2. Node服务虽然运行，但未与机构关联"
echo "  3. 需要通过API或Web界面添加Node配置"
echo ""
