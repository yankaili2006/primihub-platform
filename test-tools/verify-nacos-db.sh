#!/bin/bash
# 验证Nacos数据库是否正确初始化

echo "=========================================="
echo "  Nacos数据库状态检查"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# 检查MySQL容器是否运行
if ! docker ps | grep -q mysql; then
    echo "❌ MySQL容器未运行"
    echo "请先启动: docker-compose up -d mysql"
    exit 1
fi

echo "✓ MySQL容器正在运行"
echo ""

# 等待MySQL就绪
echo "等待MySQL就绪..."
for i in {1..10}; do
    if docker exec mysql mysqladmin ping -h localhost -uprimihub -pprimihub@123 &>/dev/null; then
        echo "✓ MySQL已就绪"
        break
    fi
    sleep 1
done
echo ""

# 1. 检查数据库是否存在
echo "1. 检查数据库列表:"
echo "----------------------------------------"
docker exec mysql mysql -uprimihub -pprimihub@123 -e "SHOW DATABASES;" 2>/dev/null || {
    echo "❌ 无法连接MySQL或查询数据库"
    exit 1
}
echo ""

# 2. 检查nacos_config数据库
echo "2. 检查 nacos_config 数据库:"
echo "----------------------------------------"
if docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE nacos_config; SHOW TABLES;" &>/dev/null; then
    TABLE_COUNT=$(docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE nacos_config; SHOW TABLES;" 2>/dev/null | wc -l)
    echo "✓ nacos_config 数据库存在"
    echo "  表数量: $((TABLE_COUNT - 1))"
    
    # 列出表
    echo ""
    echo "  表列表:"
    docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE nacos_config; SHOW TABLES;" 2>/dev/null
else
    echo "❌ nacos_config 数据库不存在或无法访问"
    echo "【这就是问题所在！】"
fi
echo ""

# 3. 检查关键表
echo "3. 检查Nacos关键表:"
echo "----------------------------------------"
REQUIRED_TABLES=("config_info" "config_info_aggr" "config_info_beta" "his_config_info" "tenant_info")
MISSING_TABLES=()

for table in "${REQUIRED_TABLES[@]}"; do
    if docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE nacos_config; DESC $table;" &>/dev/null; then
        echo "✓ $table 表存在"
    else
        echo "❌ $table 表不存在"
        MISSING_TABLES+=("$table")
    fi
done
echo ""

# 4. 检查配置数据
echo "4. 检查Nacos配置数据:"
echo "----------------------------------------"
if docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE nacos_config; SELECT COUNT(*) FROM config_info;" &>/dev/null; then
    CONFIG_COUNT=$(docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE nacos_config; SELECT COUNT(*) FROM config_info;" 2>/dev/null | tail -1)
    echo "✓ config_info 表中有 $CONFIG_COUNT 条配置"
    
    if [ "$CONFIG_COUNT" -eq 0 ]; then
        echo "⚠ 配置为空，nacos_config.sql 可能未正确导入"
    fi
else
    echo "❌ 无法查询 config_info 表"
fi
echo ""

# 5. 检查privacy数据库
echo "5. 检查业务数据库:"
echo "----------------------------------------"
for db in privacy1 privacy2 privacy3; do
    if docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE $db; SHOW TABLES;" &>/dev/null; then
        TABLE_COUNT=$(docker exec mysql mysql -uprimihub -pprimihub@123 -e "USE $db; SHOW TABLES;" 2>/dev/null | wc -l)
        echo "✓ $db 数据库存在，表数量: $((TABLE_COUNT - 1))"
    else
        echo "❌ $db 数据库不存在"
    fi
done
echo ""

# 6. 总结
echo "=========================================="
echo "  诊断结果"
echo "=========================================="
echo ""

if [ ${#MISSING_TABLES[@]} -eq 0 ] && [ "$CONFIG_COUNT" -gt 0 ]; then
    echo "✅ Nacos数据库状态正常"
    echo "   问题可能不在数据库初始化"
    echo ""
    echo "建议检查:"
    echo "  1. Nacos日志: docker logs nacos-server"
    echo "  2. 网络连接: docker exec nacos-server ping mysql"
else
    echo "❌ Nacos数据库初始化不完整"
    echo ""
    echo "【问题确认】:"
    if [ ${#MISSING_TABLES[@]} -gt 0 ]; then
        echo "  - 缺少 ${#MISSING_TABLES[@]} 个关键表"
    fi
    if [ "$CONFIG_COUNT" -eq 0 ]; then
        echo "  - 配置表为空"
    fi
    echo ""
    echo "【解决方案】:"
    echo "  执行修复脚本重新初始化MySQL:"
    echo "  bash fix-mysql-initialization.sh"
fi
echo ""
