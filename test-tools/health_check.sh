#!/bin/bash

echo "═══════════════════════════════════════════════════════════════"
echo "    PrimiHub 健康检查"
echo "═══════════════════════════════════════════════════════════════"
echo ""

cd "$(dirname "$0")"

echo "📊 容器状态:"
docker-compose ps | head -15

echo ""
echo "🌐 Web 服务检查:"
for port in 30811 30812 30813; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port)
    if [ "$status" = "200" ]; then
        echo "  ✅ 端口 $port: 正常 (HTTP $status)"
    else
        echo "  ❌ 端口 $port: 异常 (HTTP $status)"
    fi
done

echo ""
echo "🔧 核心服务检查:"
# MySQL
docker exec mysql mysql -uprimihub -pprimihub@123 -e "SELECT 1;" > /dev/null 2>&1 && \
    echo "  ✅ MySQL: 运行正常" || echo "  ❌ MySQL: 连接失败"

# Nacos
curl -s http://localhost:8848/nacos > /dev/null 2>&1 && \
    echo "  ✅ Nacos: 运行正常" || echo "  ❌ Nacos: 访问失败"

# Meta
docker exec primihub-meta0 wget -O - -q http://localhost:8080/fusion/healthConnection > /dev/null 2>&1 && \
    echo "  ✅ Meta服务: 运行正常" || echo "  ❌ Meta服务: 检查失败"

echo ""
echo "💾 数据库列表:"
docker exec mysql mysql -uprimihub -pprimihub@123 -e "SHOW DATABASES;" 2>/dev/null | grep -E "privacy|nacos"

echo ""
echo "📁 数据目录占用:"
du -sh ./data 2>/dev/null || echo "  数据目录检查失败"

echo ""
echo "═══════════════════════════════════════════════════════════════"
