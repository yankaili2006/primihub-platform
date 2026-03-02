#!/bin/bash
# 修复MySQL健康检查配置

echo "=========================================="
echo "  修复MySQL健康检查配置"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

echo "问题：MySQL健康检查缺少用户名密码"
echo "症状：每5秒出现 'Access denied for user root@localhost'"
echo "影响：无实际影响，只是日志报错"
echo ""

# 备份docker-compose.yaml
echo "1. 备份 docker-compose.yaml..."
cp docker-compose.yaml docker-compose.yaml.bak.$(date +%Y%m%d_%H%M%S)
echo "✓ 已备份"
echo ""

# 修复健康检查配置
echo "2. 修复健康检查配置..."
sed -i 's/\[ "CMD", "mysqladmin" ,"ping", "-h", "localhost" \]/\[ "CMD", "mysqladmin", "ping", "-h", "localhost", "-uprimihub", "-pprimihub@123" \]/g' docker-compose.yaml

# 验证修改
if grep -q "mysqladmin.*primihub" docker-compose.yaml; then
    echo "✓ 配置已修复"
    echo ""
    echo "修复后的配置:"
    grep -A 4 "mysqladmin" docker-compose.yaml | head -5
else
    echo "❌ 修复失败"
    echo "请手动编辑 docker-compose.yaml"
    exit 1
fi
echo ""

# 重启MySQL容器应用新配置
echo "3. 重启MySQL容器应用新配置..."
docker-compose up -d mysql
echo "✓ MySQL已重启"
echo ""

echo "4. 等待15秒后验证..."
sleep 15
echo ""

# 验证错误是否停止
echo "5. 检查新的错误..."
NEW_ERRORS=$(docker logs mysql 2>&1 --since 10s | grep -c "Access denied" || true)
if [ $NEW_ERRORS -eq 0 ]; then
    echo "✅ 修复成功！不再有 'Access denied' 错误"
else
    echo "⚠ 仍有 $NEW_ERRORS 条新错误，可能需要更长时间生效"
fi
echo ""

echo "=========================================="
echo "  修复完成"
echo "=========================================="
echo ""
echo "验证方法："
echo "1. 查看MySQL日志（应该不再有新的Access denied）:"
echo "   docker logs mysql 2>&1 --since 1m | grep 'Access denied'"
echo ""
echo "2. 检查健康状态:"
echo "   docker-compose ps mysql"
echo ""
