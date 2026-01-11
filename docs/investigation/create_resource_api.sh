#!/bin/bash

# 数据资源创建API脚本
# 用法: ./create_resource_api.sh

API_BASE="http://100.64.0.23:30811/prod-api"
TOKEN="SU2026011119425868F77BF514722324D1A684973415FB86"
USER_ID="1"

# 生成timestamp和nonce
TIMESTAMP=$(date +%s)000
NONCE=$((RANDOM % 1000))

echo "=== 创建数据资源 ==="
echo "使用文件ID: 1"
echo ""

# 方式1: 使用已存在的文件创建资源（resourceSource=1）
cat > /tmp/resource_payload.json << EOF
{
  "resourceName": "用户数据资源-$(date +%H%M%S)",
  "resourceDesc": "通过API创建的用户数据资源（包含用户ID、年龄、性别、城市、收入、教育程度）",
  "resourceAuthType": 1,
  "resourceSource": 1,
  "tags": ["用户数据", "API测试"],
  "fileId": 1,
  "fieldList": [
    {
      "fieldName": "user_id",
      "fieldAs": "用户ID",
      "fieldType": "String",
      "fieldDesc": "用户唯一标识",
      "relevance": 1,
      "grouping": 0,
      "protectionStatus": 0
    },
    {
      "fieldName": "age",
      "fieldAs": "年龄",
      "fieldType": "Integer",
      "fieldDesc": "用户年龄",
      "relevance": 0,
      "grouping": 1,
      "protectionStatus": 0
    },
    {
      "fieldName": "gender",
      "fieldAs": "性别",
      "fieldType": "Integer",
      "fieldDesc": "性别：0女1男",
      "relevance": 0,
      "grouping": 1,
      "protectionStatus": 0
    },
    {
      "fieldName": "city",
      "fieldAs": "城市",
      "fieldType": "String",
      "fieldDesc": "所在城市",
      "relevance": 0,
      "grouping": 1,
      "protectionStatus": 0
    },
    {
      "fieldName": "income",
      "fieldAs": "收入",
      "fieldType": "Double",
      "fieldDesc": "月收入",
      "relevance": 0,
      "grouping": 0,
      "protectionStatus": 1
    },
    {
      "fieldName": "education",
      "fieldAs": "教育程度",
      "fieldType": "Integer",
      "fieldDesc": "教育程度等级",
      "relevance": 0,
      "grouping": 1,
      "protectionStatus": 0
    }
  ],
  "timestamp": ${TIMESTAMP},
  "nonce": ${NONCE},
  "token": "${TOKEN}"
}
EOF

echo "请求负载已生成: /tmp/resource_payload.json"
echo ""
echo "发送请求..."

RESPONSE=$(curl -s -X POST "${API_BASE}/data/resource/saveorupdateresource" \
  -H "Content-Type: application/json" \
  -H "userId: ${USER_ID}" \
  -d @/tmp/resource_payload.json)

echo "响应:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# 检查是否成功
if echo "$RESPONSE" | grep -q '"code":0'; then
  echo "✓ 资源创建成功！"
  RESOURCE_ID=$(echo "$RESPONSE" | grep -o '"resourceId":"[^"]*"' | cut -d'"' -f4)
  echo "资源ID: $RESOURCE_ID"
else
  echo "✗ 资源创建失败"
  echo "错误信息: $(echo "$RESPONSE" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)"
fi
