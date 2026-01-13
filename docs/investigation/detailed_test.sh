#!/bin/bash

echo "========================================="
echo "深度gRPC连接测试"
echo "========================================="
echo ""

# 1. 检查配置
echo "1. 检查Nacos配置..."
TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuYWNvcyIsImV4cCI6MTc2ODE1NzAzNH0.786HNv8aBFpTc0bKAkXZR2BlZ3GbQeX457HClWL8bJQ"
curl -s "http://100.64.0.23:8848/nacos/v1/cs/configs?dataId=base.json&group=DEFAULT_GROUP&tenant=demo1&accessToken=${TOKEN}" | python3 -c "
import sys, json
d = json.loads(sys.stdin.read())
gc = d.get('grpcClient', {})
print(f\"  gRPC地址: {gc.get('address')}:{gc.get('port')}\")
print(f\"  使用TLS: {gc.get('useTls')}\")
"

# 2. 检查Node服务
echo ""
echo "2. 检查Node服务状态..."
for i in 0 1 2; do
  STATUS=$(docker ps --filter "name=primihub-node${i}" --format "{{.Status}}")
  IP=$(docker inspect primihub-node${i} --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
  echo "  primihub-node${i}: ${STATUS} (IP: ${IP})"
done

# 3. 检查Application服务
echo ""
echo "3. 检查Application服务..."
APP_STATUS=$(docker ps --filter "name=application1" --format "{{.Status}}")
APP_IP=$(docker inspect application1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "  application1: ${APP_STATUS} (IP: ${APP_IP})"

# 4. 测试创建资源并捕获详细日志
echo ""
echo "4. 测试创建资源..."

# 启动日志监控
docker logs application1 -f --tail 0 > /tmp/create_test_log.txt 2>&1 &
LOG_PID=$!
sleep 2

# 发送请求
TIMESTAMP=$(date +%s)000
NONCE=$((RANDOM % 1000))

cat > /tmp/test_resource.json << EOF
{
  "resourceName": "测试资源-$(date +%H%M%S)",
  "resourceDesc": "深度测试",
  "resourceAuthType": 1,
  "resourceSource": 1,
  "tags": ["测试"],
  "fileId": 1,
  "fieldList": [
    {
      "fieldName": "id",
      "fieldAs": "ID",
      "fieldType": "String",
      "fieldDesc": "ID",
      "relevance": 1,
      "grouping": 0,
      "protectionStatus": 0
    }
  ],
  "timestamp": ${TIMESTAMP},
  "nonce": ${NONCE},
  "token": "SU2026011119425868F77BF514722324D1A684973415FB86"
}
EOF

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://100.64.0.23:30811/prod-api/data/resource/saveorupdateresource" \
  -H "Content-Type: application/json" \
  -H "userId: 1" \
  -d @/tmp/test_resource.json)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

sleep 5
kill $LOG_PID 2>/dev/null
wait $LOG_PID 2>/dev/null

echo "  HTTP状态码: $HTTP_CODE"
echo "  响应: $BODY"

# 5. 分析日志
echo ""
echo "5. 分析日志..."
if [ -s /tmp/create_test_log.txt ]; then
  echo "捕获到的日志:"
  cat /tmp/create_test_log.txt
else
  echo "  没有捕获到新日志"
  echo ""
  echo "  最近的错误日志:"
  docker logs application1 --since 2m 2>&1 | grep -E "ERROR|Exception|dataServiceGrpc" | tail -10
fi

# 6. 检查数据库
echo ""
echo "6. 检查数据库中的资源..."
docker exec mysql mysql -uroot -proot privacy1 -e \
  "SELECT resource_id, resource_name, create_date FROM data_resource ORDER BY resource_id DESC LIMIT 3" 2>&1 | grep -v "Warning"

echo ""
echo "========================================="
echo "测试完成"
echo "========================================="
