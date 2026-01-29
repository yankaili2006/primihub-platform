#!/bin/bash

# PrimiHub Platform Docker MySQL环境快速启动脚本

# 切换到项目根目录
cd "$(dirname "$0")/.."

echo "========================================="
echo "PrimiHub Platform - Docker MySQL环境启动"
echo "========================================="

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装"
    echo "请先安装Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查Docker Compose是否可用
if ! docker compose version &> /dev/null; then
    echo "错误: Docker Compose未安装或版本过低"
    echo "请安装Docker Compose V2: https://docs.docker.com/compose/install/"
    exit 1
fi

# 启动服务
echo "启动MySQL和Redis服务..."
docker compose -f docker-compose-mysql.yml up -d

# 等待MySQL启动
echo "等待MySQL服务启动..."
for i in {1..30}; do
    if docker exec primihub-mysql mysqladmin ping -h localhost -u root -pprimihub2024 &> /dev/null; then
        echo "MySQL服务已就绪！"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "错误: MySQL启动超时"
        docker compose -f docker-compose-mysql.yml logs mysql
        exit 1
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "========================================="
echo "服务启动成功！"
echo "========================================="
echo "MySQL:"
echo "  地址: localhost:3306"
echo "  数据库: primihub"
echo "  用户名: root / primihub"
echo "  密码: primihub2024"
echo ""
echo "Redis:"
echo "  地址: localhost:6379"
echo ""
echo "查看日志: docker compose -f docker-compose-mysql.yml logs -f"
echo "停止服务: docker compose -f docker-compose-mysql.yml down"
echo "========================================="
echo ""
echo "现在可以启动PrimiHub Platform:"
echo "  bash scripts/start-mysql.sh"
echo "或者:"
echo "  cd primihub-service/application"
echo "  mvn spring-boot:run -Dspring-boot.run.profiles=mysql"
