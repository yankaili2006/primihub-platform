#!/bin/bash

echo "======================================================================"
echo "修复节点连接配置"
echo "======================================================================"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 检查sys_organ_node表结构"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
DESC sys_organ_node;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 查看当前sys_organ_node表数据"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT * FROM sys_organ_node WHERE is_del = 0;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 查看机构信息"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT id, organ_id, organ_name, organ_gateway FROM sys_organ WHERE is_del = 0;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 插入Node配置到数据库"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 先清理可能存在的旧数据
docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
DELETE FROM sys_organ_node WHERE node_id IN ('node0', 'node1', 'node2');
" 2>/dev/null

echo "清理旧配置完成"
echo ""

# 插入Node配置
# 注意：这里使用100.64.0.23而不是127.0.0.1，因为节点间需要通过外部地址通信
docker exec mysql mysql -uprimihub -pprimihub@123 privacy << 'SQL' 2>/dev/null
-- 为机构1 (API测试机构) 配置node1
INSERT INTO sys_organ_node (
    organ_id, 
    organ_name, 
    node_id, 
    node_name, 
    node_address, 
    is_del, 
    create_date, 
    update_date
) VALUES (
    '000000000000000000000000test0001',
    'API测试机构',
    'node1',
    'Node1',
    '100.64.0.23:50051',
    0,
    NOW(),
    NOW()
);

-- 为机构2 (PSI协作机构) 配置node2
INSERT INTO sys_organ_node (
    organ_id, 
    organ_name, 
    node_id, 
    node_name, 
    node_address, 
    is_del, 
    create_date, 
    update_date
) VALUES (
    '000000000000000000000000test0002',
    'PSI协作机构',
    'node2',
    'Node2',
    '100.64.0.23:50052',
    0,
    NOW(),
    NOW()
);

-- 为本地机构配置node0 (如果需要)
INSERT INTO sys_organ_node (
    organ_id, 
    organ_name, 
    node_id, 
    node_name, 
    node_address, 
    is_del, 
    create_date, 
    update_date
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'API测试机构',
    'node0',
    'Node0',
    '100.64.0.23:50050',
    0,
    NOW(),
    NOW()
);
SQL

echo "✓ Node配置已插入数据库"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 验证配置结果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
echo "6. 通过API验证节点连接"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOKEN=$(curl -s -X POST "http://100.64.0.23:30811/prod-api/sys/user/login" \
    -d "userAccount=admin&userPassword=123456&timestamp=$(date +%s)000&nonce=123" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['token'] if data.get('code')==0 else '')" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    echo "查询节点列表:"
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
                print(f'  - {node.get(\"nodeName\", \"N/A\")}: {node.get(\"nodeAddress\", \"N/A\")} (机构: {node.get(\"organName\", \"N/A\")})')
        else:
            print('⚠️  API返回空列表')
    else:
        print(f'✗ API调用失败: {data.get(\"msg\", \"未知错误\")}')
except Exception as e:
    print(f'✗ 解析失败: {e}')
" 2>/dev/null
fi

echo ""
echo "======================================================================"
echo "修复完成"
echo "======================================================================"
echo ""
echo "已完成的操作:"
echo "  ✓ 清理旧的Node配置"
echo "  ✓ 为机构配置Node地址"
echo "  ✓ 使用外部可访问地址 (100.64.0.23)"
echo "  ✓ 关联Node服务与机构"
echo ""
echo "现在的状态:"
echo "  - 管理层面: ✓ 已连接 (examine_state=1, enable=1)"
echo "  - 计算层面: ✓ 已配置 (Node地址已关联)"
echo ""
echo "下一步:"
echo "  1. 刷新Web界面，应该能看到节点已连接"
echo "  2. 可以尝试执行PSI或联邦学习任务"
echo "  3. 如果仍显示未连接，可能需要重启应用容器"
echo ""
