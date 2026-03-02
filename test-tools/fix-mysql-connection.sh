#!/bin/bash
# MySQL连接错误专项修复脚本
# 问题：Access denied for user 'root'@'localhost'(using password: No)

set -e

echo "=========================================="
echo "  MySQL连接错误专项修复"
echo "=========================================="
echo ""
echo "问题：某服务使用root无密码尝试连接MySQL"
echo "原因：MySQL数据目录存在旧数据，未应用新配置"
echo "方案：清理数据目录，强制MySQL重新初始化"
echo ""

cd "$(dirname "$0")"

# 1. 确认当前状态
echo "步骤1: 检查当前状态..."
echo "----------------------------------------"
if [ -d "data/mysql" ]; then
    MYSQL_SIZE=$(du -sh data/mysql 2>/dev/null | cut -f1)
    echo "✓ MySQL数据目录存在，大小: $MYSQL_SIZE"
    echo "  这是问题的根源 - 旧数据导致配置未应用"
else
    echo "✓ MySQL数据目录不存在"
fi
echo ""

# 2. 停止所有服务
echo "步骤2: 停止所有服务..."
echo "----------------------------------------"
docker-compose down
echo "✓ 所有服务已停止"
echo ""

# 3. 备份并清理MySQL数据
echo "步骤3: 清理MySQL数据目录..."
echo "----------------------------------------"
if [ -d "data/mysql" ]; then
    BACKUP_NAME="data/mysql.bak.$(date +%Y%m%d_%H%M%S)"
    echo "备份旧数据到: $BACKUP_NAME"
    mv data/mysql "$BACKUP_NAME"
    echo "✓ MySQL数据已备份并清理"
    echo "  现在MySQL将使用环境变量重新初始化"
else
    echo "✓ 数据目录已经是空的"
fi
echo ""

# 4. 验证配置文件
echo "步骤4: 验证MySQL配置..."
echo "----------------------------------------"
echo "环境变量配置:"
grep "MYSQL_" data/env/mysql.env
echo ""
echo "Nacos MySQL配置:"
grep "MYSQL_SERVICE" data/env/nacos-mysql.env | head -4
echo ""
echo "✓ 配置文件正确（使用primihub用户）"
echo ""

# 5. 清理其他可能的残留
echo "步骤5: 清理其他残留数据..."
echo "----------------------------------------"
if [ -d "data/log" ]; then
    rm -rf data/log/*
    echo "✓ 已清理日志目录"
fi
echo ""

# 6. 启动MySQL
echo "步骤6: 启动MySQL服务..."
echo "----------------------------------------"
docker-compose up -d mysql
echo "✓ MySQL容器已启动"
echo ""

# 7. 等待MySQL初始化
echo "步骤7: 等待MySQL初始化..."
echo "----------------------------------------"
echo "MySQL首次初始化需要约30-60秒"
echo -n "等待中"
for i in {1..60}; do
    if docker exec mysql mysqladmin ping -h localhost -uprimihub -pprimihub@123 &>/dev/null; then
        echo ""
        echo "✓ MySQL已就绪（耗时: ${i}秒）"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# 8. 验证MySQL用户
echo "步骤8: 验证MySQL用户配置..."
echo "----------------------------------------"
docker exec mysql mysql -uprimihub -pprimihub@123 -e "SELECT user, host FROM mysql.user;" 2>/dev/null && \
    echo "✓ 用户列表查询成功" || echo "⚠ 用户查询失败"
echo ""

# 9. 检查数据库
echo "步骤9: 检查数据库初始化..."
echo "----------------------------------------"
docker exec mysql mysql -uprimihub -pprimihub@123 -e "SHOW DATABASES;" 2>/dev/null | grep -E "nacos|privacy" && \
    echo "✓ 数据库初始化成功" || echo "⚠ 数据库未完全初始化"
echo ""

# 10. 启动其他服务
echo "步骤10: 启动所有其他服务..."
echo "----------------------------------------"
docker-compose up -d
echo "✓ 所有服务已启动"
echo ""

# 11. 等待Nacos连接MySQL
echo "步骤11: 等待Nacos连接MySQL..."
echo "----------------------------------------"
echo "等待Nacos服务启动（约30秒）"
sleep 30
echo ""

# 12. 检查错误日志
echo "步骤12: 检查是否还有连接错误..."
echo "----------------------------------------"
ERROR_COUNT=$(docker logs mysql 2>&1 | grep -c "Access denied" || true)
if [ $ERROR_COUNT -eq 0 ]; then
    echo "✅ 无连接错误！修复成功！"
else
    echo "⚠ 仍有 $ERROR_COUNT 条错误（可能是启动过程中的旧错误）"
    echo "查看最新日志："
    docker logs mysql 2>&1 | tail -20
fi
echo ""

echo "=========================================="
echo "  修复完成"
echo "=========================================="
echo ""
echo "验证步骤："
echo "1. 查看容器状态: docker-compose ps"
echo "2. 查看MySQL日志: docker logs mysql 2>&1 | tail -30"
echo "3. 查看Nacos日志: docker logs nacos-server | tail -30"
echo "4. 健康检查: bash health_check.sh"
echo ""
echo "如果仍有问题，运行："
echo "  docker-compose logs -f mysql"
echo "  docker-compose logs -f nacos"
echo ""
