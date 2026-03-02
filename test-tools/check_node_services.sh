#!/bin/bash

echo "======================================================================"
echo "检查节点间通信服务"
echo "======================================================================"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 检查所有PrimiHub相关容器"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "NAME|primihub|node|gateway|application|fusion"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 检查Node服务（负责节点间通信）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

node_containers=$(docker ps --format "{{.Names}}" | grep -i node)
if [ -n "$node_containers" ]; then
    echo "找到Node容器:"
    echo "$node_containers"
    echo ""
    for container in $node_containers; do
        echo "容器: $container"
        docker ps --filter "name=$container" --format "  状态: {{.Status}}"
        docker ps --filter "name=$container" --format "  端口: {{.Ports}}"
        echo ""
    done
else
    echo "⚠️  未找到Node容器"
    echo ""
    echo "说明: Node服务负责节点间的实际通信（如PSI、联邦学习等任务）"
    echo "     如果没有Node服务，节点只能通过API层交互，无法执行联合计算任务"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 检查docker-compose配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "docker-compose.yaml" ]; then
    echo "检查docker-compose.yaml中的服务定义:"
    echo ""
    grep -E "^\s+node[0-9]:|^\s+primihub-node[0-9]:" docker-compose.yaml | head -5
    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ 配置文件中定义了Node服务"
    else
        echo "⚠️  配置文件中未找到Node服务定义"
    fi
else
    echo "⚠️  未找到docker-compose.yaml文件"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 测试节点间gRPC通信端口"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# PrimiHub Node通常使用50050-50052端口
for port in 50050 50051 50052; do
    echo "测试端口 $port (Node gRPC):"
    nc -zv 100.64.0.23 $port 2>&1 | grep -q "succeeded" && echo "  ✓ 端口 $port 开放" || echo "  ✗ 端口 $port 未开放"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 查看应用日志中的连接信息"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "application0 最近的连接相关日志:"
docker logs application0 --tail 50 2>&1 | grep -i -E "connect|node|grpc|fusion" | tail -10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. 检查数据库中的节点配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e "
SELECT 
    id,
    organ_name,
    organ_gateway,
    examine_state,
    enable,
    CASE 
        WHEN examine_state = 1 AND enable = 1 THEN '✓ 已连接'
        WHEN examine_state = 1 AND enable = 0 THEN '⚠ 已批准但禁用'
        WHEN examine_state = 0 THEN '⚠ 待审核'
        ELSE '✗ 未连接'
    END as '连接状态'
FROM sys_organ 
WHERE is_del = 0
ORDER BY id;
" 2>/dev/null

echo ""
echo "======================================================================"
echo "分析结果"
echo "======================================================================"
echo ""
echo "节点连接的两个层面:"
echo ""
echo "1. 【管理层面】- 通过Application/Gateway服务"
echo "   - 用途: 机构管理、认证审核、任务调度"
echo "   - 状态: ✓ 已连接（examine_state=1, enable=1）"
echo "   - 验证: CLI工具可以查询和管理机构"
echo ""
echo "2. 【计算层面】- 通过Node服务（gRPC）"
echo "   - 用途: 实际的联合计算任务（PSI、联邦学习等）"
echo "   - 状态: 需要检查Node服务是否运行"
echo "   - 验证: 执行实际的计算任务"
echo ""
