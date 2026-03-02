#!/bin/bash

echo "============================================"
echo "诊断和修复"我的资源"页面404/400错误"
echo "============================================"
echo ""

# 问题诊断
echo "问题分析："
echo "----------------------------------------"
echo "1. 错误类型: 实际是 400 Bad Request (不是404)"
echo "2. 错误原因: 后端API需要userId请求头，但前端未传递"
echo "3. 影响API: /data/resource/getdataresourcelist"
echo ""

# 检查当前状态
echo "检查当前系统状态..."
echo "----------------------------------------"

# 检查容器状态
echo "✓ 检查容器运行状态:"
docker ps --filter "name=application0" --format "  - {{.Names}}: {{.Status}}"
docker ps --filter "name=gateway0" --format "  - {{.Names}}: {{.Status}}"
echo ""

# 检查最近的错误
echo "✓ 检查最近的错误日志:"
ERROR_COUNT=$(docker logs application0 2>&1 | grep "Missing request header 'userId'" | wc -l)
echo "  - userId缺失错误数: $ERROR_COUNT"
echo ""

# 解决方案
echo "============================================"
echo "解决方案"
echo "============================================"
echo ""

echo "方案1: 检查用户登录状态"
echo "----------------------------------------"
echo "问题可能是用户登录状态丢失或token失效"
echo ""
echo "操作步骤："
echo "1. 退出当前登录"
echo "2. 清除浏览器缓存和cookies"
echo "3. 重新登录系统"
echo ""
read -p "是否需要查看当前登录用户信息? (y/n): " check_user

if [ "$check_user" = "y" ]; then
    echo ""
    echo "查询数据库中的用户信息..."
    docker exec mysql mysql -uroot -pprimihub123 primihub -e "
    SELECT user_id, user_name, user_account, state
    FROM sys_local_user
    ORDER BY create_date DESC
    LIMIT 5;" 2>/dev/null
    echo ""
fi

echo ""
echo "方案2: 检查Gateway网关配置"
echo "----------------------------------------"
echo "Gateway应该自动添加userId请求头"
echo ""

# 检查gateway日志
echo "检查Gateway是否正确转发请求头..."
GATEWAY_LOGS=$(docker logs gateway0 2>&1 | grep -E "(userId|resource)" | tail -5)
if [ -n "$GATEWAY_LOGS" ]; then
    echo "最近的Gateway日志:"
    echo "$GATEWAY_LOGS"
else
    echo "未发现相关日志"
fi
echo ""

echo ""
echo "方案3: 测试API调用"
echo "----------------------------------------"
echo "使用正确的请求头测试API"
echo ""
read -p "请输入您的token (从浏览器中复制): " user_token
read -p "请输入您的userId (通常是1或2): " user_id

if [ -n "$user_token" ] && [ -n "$user_id" ]; then
    echo ""
    echo "测试API调用..."

    # 获取容器IP
    GATEWAY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gateway0)

    echo "调用地址: http://$GATEWAY_IP:8099/resource/getdataresourcelist"

    # 测试调用
    curl -s -X GET "http://$GATEWAY_IP:8099/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=" \
         -H "userId: $user_id" \
         -H "Content-Type: application/json" | jq '.' 2>/dev/null || echo "API调用失败或返回非JSON数据"
    echo ""
fi

echo ""
echo "方案4: 修复前端请求拦截器"
echo "----------------------------------------"
echo "问题可能在于前端请求拦截器未正确添加userId"
echo ""
echo "需要检查的文件:"
echo "  - manage-web0 容器中的前端代码"
echo "  - request.js 或 axios配置文件"
echo ""

# 检查前端容器
echo "检查前端容器配置..."
docker exec manage-web0 ls -la /usr/share/nginx/html/static/js/ 2>/dev/null | head -10 || echo "无法访问前端文件"

echo ""
echo "============================================"
echo "快速修复步骤"
echo "============================================"
echo ""
echo "1. 退出登录，清除浏览器缓存"
echo "2. 重新登录系统"
echo "3. 如果问题依然存在，执行以下命令查看详细日志:"
echo ""
echo "   docker logs application0 2>&1 | grep -A10 'Missing request header'"
echo ""
echo "4. 检查浏览器开发者工具的Network标签:"
echo "   - 查看请求头中是否包含 userId"
echo "   - 查看 token 是否有效"
echo ""
echo "5. 如果需要重置系统，执行:"
echo "   docker-compose restart gateway0 application0"
echo ""

# 提供一个临时修复建议
echo "============================================"
echo "临时解决方案"
echo "============================================"
echo ""
echo "如果您想立即测试，可以使用以下命令行工具:"
echo ""
echo "curl -X GET 'http://localhost:30811/prod-api/data/resource/getdataresourcelist?pageNo=1&pageSize=10&resourceName=&resourceId=0&userName=&resourceSource=&selectTag=0&derivation=0&resourceAuthType=&fileContainsY=' \\"
echo "  -H 'userId: 1' \\"
echo "  -H 'token: YOUR_TOKEN_HERE'"
echo ""

echo "诊断完成！"
