#!/bin/bash

# PrimiHub Platform MySQL模式启动脚本

cd "$(dirname "$0")/.."

echo "========================================="
echo "PrimiHub Platform - MySQL模式启动"
echo "========================================="

# 检查MySQL连接
echo "检查MySQL连接..."
if ! mysql -h localhost -u root -e "SELECT 1" &> /dev/null; then
    echo "警告: 无法连接到MySQL，请确保MySQL正在运行"
    echo "你可以运行: sudo systemctl start mysql"
    echo ""
fi

# 设置环境变量
export SPRING_PROFILES_ACTIVE=mysql

# 检查是否需要初始化数据库
if [ "$1" = "--init-db" ]; then
    echo "初始化MySQL数据库..."
    bash scripts/init-mysql.sh
    if [ $? -ne 0 ]; then
        echo "数据库初始化失败"
        exit 1
    fi
fi

# 进入application目录
cd primihub-service/application

# 检查是否已编译
if [ ! -d "target" ]; then
    echo "未找到编译文件，开始编译..."
    cd ../..
    mvn clean package -DskipTests
    cd primihub-service/application
fi

echo ""
echo "启动PrimiHub Platform (MySQL模式)..."
echo "配置文件: application-mysql.yaml"
echo ""

# 启动应用
java -jar target/application-1.0-SNAPSHOT.jar --spring.profiles.active=mysql
