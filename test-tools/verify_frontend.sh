#!/bin/bash
# 前端访问验证脚本

echo "========================================="
echo "PrimiHub 前端访问验证"
echo "========================================="

URL="http://100.64.0.23:30811"

echo -e "\n1. 检查前端首页..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 前端首页正常 (HTTP $HTTP_CODE)"
else
    echo "❌ 前端首页异常 (HTTP $HTTP_CODE)"
fi

echo -e "\n2. 检查 JavaScript 文件..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL/static/js/app.ed9419cd.js)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ JavaScript 文件正常 (HTTP $HTTP_CODE)"
else
    echo "❌ JavaScript 文件异常 (HTTP $HTTP_CODE)"
fi

echo -e "\n3. 检查登录API..."
RESPONSE=$(curl -s -X POST $URL/prod-api/user/login -d "userAccount=admin&userPassword=123456")
CODE=$(echo $RESPONSE | python3 -c "import json,sys; print(json.load(sys.stdin).get('code', -1))" 2>/dev/null)
if [ "$CODE" = "0" ]; then
    echo "✅ 登录API正常 (code: $CODE)"
else
    echo "❌ 登录API异常 (code: $CODE)"
fi

echo -e "\n4. 检查 policeDataFusion 组件..."
if docker exec manage-web0 grep -q "policeDataFusion" /usr/share/nginx/html/static/js/app.ed9419cd.js 2>/dev/null; then
    echo "✅ policeDataFusion 组件已编译到前端"
else
    echo "❌ policeDataFusion 组件未找到"
fi

echo -e "\n5. 检查容器状态..."
docker compose ps | grep -E "manage-web0|application0" | while read line; do
    if echo "$line" | grep -q "Up"; then
        echo "✅ $(echo $line | awk '{print $1}') 运行中"
    else
        echo "❌ $(echo $line | awk '{print $1}') 未运行"
    fi
done

echo -e "\n========================================="
echo "验证完成"
echo "========================================="
echo -e "\n如果所有检查都通过，请尝试："
echo "1. 清除浏览器缓存（Ctrl+Shift+Delete）"
echo "2. 硬刷新页面（Ctrl+F5 或 Cmd+Shift+R）"
echo "3. 重新登录系统"
echo "4. 访问: $URL/#/policeDataFusion/intersection"
