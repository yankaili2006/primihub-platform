#!/bin/bash

echo "=========================================="
echo "测试"我的资源"API - userId请求头验证"
echo "=========================================="
echo ""

# 从用户输入获取token（从浏览器中复制）
echo "请按以下步骤获取token："
echo "1. 登录系统后，按F12打开浏览器开发者工具"
echo "2. 切换到Console标签"
echo "3. 输入: localStorage.getItem('token')"
echo "4. 复制显示的token值（不含引号）"
echo ""
read -p "请输入您的token: " USER_TOKEN

if [ -z "$USER_TOKEN" ]; then
    echo "错误：token不能为空"
    exit 1
fi

echo ""
echo "=========================================="
echo "测试1: 不带userId请求头（会失败）"
echo "=========================================="
curl -s -X GET "http://localhost:30811/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=" \
  -H "Content-Type: application/json" \
  -H "token: $USER_TOKEN" \
  -H "timestamp: 1234567890" \
  -H "nonce: 123" \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "=========================================="
echo "测试2: 带userId=1请求头（应该成功）"
echo "=========================================="
curl -s -X GET "http://localhost:30811/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=" \
  -H "Content-Type: application/json" \
  -H "userId: 1" \
  -H "token: $USER_TOKEN" \
  -H "timestamp: 1234567890" \
  -H "nonce: 123" \
  -w "\nHTTP Status: %{http_code}\n" | jq '.' 2>/dev/null || cat

echo ""
echo "=========================================="
echo "测试3: 带userId=2请求头（尝试其他用户ID）"
echo "=========================================="
curl -s -X GET "http://localhost:30811/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=" \
  -H "Content-Type: application/json" \
  -H "userId: 2" \
  -H "token: $USER_TOKEN" \
  -H "timestamp: 1234567890" \
  -H "nonce: 123" \
  -w "\nHTTP Status: %{http_code}\n" | jq '.' 2>/dev/null || cat

echo ""
echo "=========================================="
echo "结论"
echo "=========================================="
echo "如果测试2或测试3返回200状态码和数据，说明："
echo "1. 后端API工作正常"
echo "2. 问题确实是前端缺少userId请求头"
echo "3. 需要修复前端请求拦截器或Gateway配置"
echo ""
