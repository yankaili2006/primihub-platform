#!/bin/bash

# MySQL配置验证脚本

echo "========================================="
echo "PrimiHub MySQL配置验证"
echo "========================================="
echo ""

# 检查配置文件
echo "1. 检查配置文件..."
files=(
    "primihub-service/application/src/main/resources/application-mysql.yaml"
    "primihub-service/application/src/main/resources/schema-mysql.sql"
    "primihub-service/application/src/main/resources/data-mysql.sql"
    "docker-compose-mysql.yml"
)

all_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (缺失)"
        all_exist=false
    fi
done
echo ""

# 检查脚本
echo "2. 检查启动脚本..."
scripts=(
    "scripts/init-mysql.sh"
    "scripts/start-mysql.sh"
    "scripts/start-docker-mysql.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "  ✓ $script (可执行)"
    elif [ -f "$script" ]; then
        echo "  ! $script (存在但不可执行)"
        chmod +x "$script"
        echo "    已添加执行权限"
    else
        echo "  ✗ $script (缺失)"
        all_exist=false
    fi
done
echo ""

# 检查MySQL连接
echo "3. 检查MySQL可用性..."

# 方式1: Docker容器
if docker ps | grep -q primihub-mysql; then
    echo "  ✓ MySQL Docker容器正在运行"
    if docker exec primihub-mysql mysqladmin ping -h localhost -u root -pprimihub2024 &> /dev/null; then
        echo "  ✓ MySQL Docker容器连接正常"

        # 检查数据库是否存在
        if docker exec primihub-mysql mysql -u root -pprimihub2024 -e "USE primihub; SELECT COUNT(*) FROM sys_user;" &> /dev/null; then
            echo "  ✓ 数据库已初始化"
        else
            echo "  ! 数据库未初始化（应用首次启动时会自动初始化）"
        fi
    else
        echo "  ✗ MySQL Docker容器连接失败"
    fi
elif docker ps -a | grep -q primihub-mysql; then
    echo "  ! MySQL Docker容器已停止"
    echo "    运行: docker compose -f docker-compose-mysql.yml start"
else
    echo "  - 未找到MySQL Docker容器"

    # 方式2: 本地MySQL
    if command -v mysql &> /dev/null; then
        echo "  ✓ MySQL客户端已安装"

        if mysql -h localhost -u root -e "SELECT 1" &> /dev/null 2>&1; then
            echo "  ✓ 本地MySQL连接正常（无密码）"
        elif mysql -h localhost -u root -pprimihub2024 -e "SELECT 1" &> /dev/null 2>&1; then
            echo "  ✓ 本地MySQL连接正常（密码: primihub2024）"
        else
            echo "  ! 本地MySQL连接失败，可能需要配置密码"
        fi
    else
        echo "  - MySQL客户端未安装"
    fi
fi
echo ""

# 检查Redis
echo "4. 检查Redis可用性..."
if docker ps | grep -q primihub-redis; then
    echo "  ✓ Redis Docker容器正在运行"
elif docker ps -a | grep -q primihub-redis; then
    echo "  ! Redis Docker容器已停止"
else
    echo "  - 未找到Redis Docker容器"

    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            echo "  ✓ 本地Redis连接正常"
        else
            echo "  ! 本地Redis连接失败"
        fi
    else
        echo "  - Redis客户端未安装"
    fi
fi
echo ""

# 检查Docker
echo "5. 检查Docker环境..."
if command -v docker &> /dev/null; then
    echo "  ✓ Docker已安装 ($(docker --version))"

    if docker compose version &> /dev/null; then
        echo "  ✓ Docker Compose已安装 ($(docker compose version --short))"
    else
        echo "  ✗ Docker Compose未安装或版本过低"
    fi
else
    echo "  - Docker未安装"
fi
echo ""

# 总结
echo "========================================="
echo "验证总结"
echo "========================================="

if [ "$all_exist" = true ]; then
    echo "✓ 所有配置文件和脚本已就绪"
else
    echo "✗ 部分文件缺失，请检查"
    exit 1
fi

echo ""
echo "建议的启动方式："
echo ""

if docker ps | grep -q primihub-mysql; then
    echo "1. MySQL已在运行，直接启动应用："
    echo "   bash scripts/start-mysql.sh"
elif docker compose version &> /dev/null 2>&1; then
    echo "1. 使用Docker启动MySQL（推荐）："
    echo "   bash scripts/start-docker-mysql.sh"
    echo "   bash scripts/start-mysql.sh"
elif command -v mysql &> /dev/null; then
    echo "1. 使用本地MySQL："
    echo "   bash scripts/init-mysql.sh"
    echo "   bash scripts/start-mysql.sh"
else
    echo "请先安装MySQL或Docker"
fi

echo ""
echo "详细文档："
echo "  - MYSQL_QUICKSTART.md - 快速开始指南"
echo "  - MYSQL_SETUP.md - 详细配置文档"
echo "  - MYSQL_MIGRATION_SUMMARY.md - 迁移总结"
echo "========================================="
