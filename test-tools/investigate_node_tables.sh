#!/bin/bash

echo "======================================================================"
echo "深入调查节点配置表结构"
echo "======================================================================"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 列出所有与node相关的表"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SHOW TABLES LIKE '%node%';
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 检查sys_organ表的完整结构"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
DESC sys_organ;
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 查看sys_organ表的所有字段数据"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT * FROM sys_organ WHERE is_del = 0 LIMIT 2\G
" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 检查是否有fusion_node_info或类似的表"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SHOW TABLES LIKE '%fusion%';
" 2>/dev/null

echo ""
docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SHOW TABLES;
" 2>/dev/null | grep -i -E "node|fusion|resource"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 检查Nacos中的Node配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for tenant in demo0 demo1 demo2; do
    echo "【Nacos租户: $tenant】"
    
    # 查看所有配置
    docker exec nacos-server curl -s \
        "http://localhost:8848/nacos/v1/cs/configs?dataId=&group=DEFAULT_GROUP&tenant=$tenant&pageNo=1&pageSize=100" 2>/dev/null | \
        python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'pageItems' in data:
        configs = data['pageItems']
        print(f'  找到 {len(configs)} 个配置项:')
        for cfg in configs:
            print(f'    - {cfg.get(\"dataId\", \"N/A\")}')
    else:
        print('  无法获取配置列表')
except:
    print('  解析失败')
" 2>/dev/null
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. 查看primihub_components配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for tenant in demo0 demo1 demo2; do
    echo "【$tenant - primihub_components.json】"
    docker exec nacos-server curl -s \
        "http://localhost:8848/nacos/v1/cs/configs?dataId=primihub_components.json&group=DEFAULT_GROUP&tenant=$tenant" 2>/dev/null | \
        python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'node' in data:
        node = data['node']
        print(f'  Node配置:')
        print(f'    - 地址: {node.get(\"address\", \"N/A\")}')
        print(f'    - 端口: {node.get(\"port\", \"N/A\")}')
    else:
        print('  未找到node配置')
except:
    print('  配置不存在或解析失败')
" 2>/dev/null
    echo ""
done

echo "======================================================================"
echo "分析完成"
echo "======================================================================"
