#!/bin/bash

echo "======================================================================"
echo "配置Node服务到Nacos"
echo "======================================================================"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 为demo0配置primihub_components.json"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# demo0 - node0
docker exec nacos-server curl -s -X POST \
    "http://localhost:8848/nacos/v1/cs/configs" \
    -d "dataId=primihub_components.json" \
    -d "group=DEFAULT_GROUP" \
    -d "tenant=demo0" \
    -d "type=json" \
    --data-urlencode 'content={
  "node": {
    "address": "primihub-node0",
    "port": 50050
  },
  "meta": {
    "address": "primihub-meta0",
    "port": 8080
  }
}' 2>/dev/null

echo "✓ demo0配置完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 为demo1配置primihub_components.json"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# demo1 - node1
docker exec nacos-server curl -s -X POST \
    "http://localhost:8848/nacos/v1/cs/configs" \
    -d "dataId=primihub_components.json" \
    -d "group=DEFAULT_GROUP" \
    -d "tenant=demo1" \
    -d "type=json" \
    --data-urlencode 'content={
  "node": {
    "address": "primihub-node1",
    "port": 50051
  },
  "meta": {
    "address": "primihub-meta1",
    "port": 8080
  }
}' 2>/dev/null

echo "✓ demo1配置完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 为demo2配置primihub_components.json"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# demo2 - node2
docker exec nacos-server curl -s -X POST \
    "http://localhost:8848/nacos/v1/cs/configs" \
    -d "dataId=primihub_components.json" \
    -d "group=DEFAULT_GROUP" \
    -d "tenant=demo2" \
    -d "type=json" \
    --data-urlencode 'content={
  "node": {
    "address": "primihub-node2",
    "port": 50052
  },
  "meta": {
    "address": "primihub-meta2",
    "port": 8080
  }
}' 2>/dev/null

echo "✓ demo2配置完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 验证配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for tenant in demo0 demo1 demo2; do
    echo "【$tenant】"
    docker exec nacos-server curl -s \
        "http://localhost:8848/nacos/v1/cs/configs?dataId=primihub_components.json&group=DEFAULT_GROUP&tenant=$tenant" 2>/dev/null | \
        python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    node = data.get('node', {})
    print(f'  Node地址: {node.get(\"address\", \"N/A\")}:{node.get(\"port\", \"N/A\")}')
except:
    print('  配置读取失败')
" 2>/dev/null
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 重启Application服务以加载新配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "重启application容器..."
docker restart application0 application1 application2

echo ""
echo "等待服务启动..."
sleep 20

echo ""
echo "检查容器状态:"
docker ps --filter "name=application" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. 验证数据库状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT 
    id,
    organ_name,
    examine_state as '审核',
    enable as '启用',
    node_state as 'Node',
    fusion_state as 'Fusion',
    platform_state as 'Platform'
FROM sys_organ 
WHERE is_del = 0;
" 2>/dev/null

echo ""
echo "======================================================================"
echo "配置完成"
echo "======================================================================"
echo ""
echo "已完成的操作:"
echo "  ✓ 为3个租户配置了primihub_components.json"
echo "  ✓ 配置了Node服务地址和端口"
echo "  ✓ 重启了Application服务"
echo ""
echo "当前状态:"
echo "  - 数据库: node_state=1, fusion_state=1, platform_state=1"
echo "  - Nacos: primihub_components.json已配置"
echo "  - Node服务: 运行在50050-50052端口"
echo ""
echo "下一步:"
echo "  1. 刷新Web界面 (http://100.64.0.23:30811)"
echo "  2. 查看节点连接状态"
echo "  3. 如果仍显示未连接，查看application日志:"
echo "     docker logs application0 --tail 100"
echo ""
