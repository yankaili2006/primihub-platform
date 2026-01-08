#!/bin/bash

# MySQL数据库初始化脚本
# 此脚本用于创建primihub数据库和用户

echo "========================================="
echo "PrimiHub MySQL数据库初始化"
echo "========================================="

# MySQL连接参数
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"

# 数据库配置
DB_NAME="primihub"
DB_USER="primihub"
DB_PASSWORD="primihub2024"

# 检查MySQL是否安装
if ! command -v mysql &> /dev/null; then
    echo "错误: 未找到MySQL客户端"
    echo "请先安装MySQL: sudo apt-get install mysql-client"
    exit 1
fi

# 检查MySQL服务是否运行
if ! mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u root -p${MYSQL_ROOT_PASSWORD} -e "SELECT 1" &> /dev/null; then
    echo "错误: 无法连接到MySQL服务器"
    echo "请确保MySQL正在运行，并且root密码正确"
    echo "使用环境变量设置root密码: export MYSQL_ROOT_PASSWORD='your_password'"
    exit 1
fi

echo "正在连接到MySQL服务器 ${MYSQL_HOST}:${MYSQL_PORT}..."

# 创建数据库
echo "创建数据库: ${DB_NAME}..."
mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

# 创建用户并授权（如果需要）
if [ "${MYSQL_CREATE_USER}" = "true" ]; then
    echo "创建数据库用户: ${DB_USER}..."
    mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
fi

echo "========================================="
echo "数据库初始化完成！"
echo "========================================="
echo "数据库名: ${DB_NAME}"
echo "数据库地址: ${MYSQL_HOST}:${MYSQL_PORT}"
if [ "${MYSQL_CREATE_USER}" = "true" ]; then
    echo "数据库用户: ${DB_USER}"
    echo "数据库密码: ${DB_PASSWORD}"
fi
echo ""
echo "注意: 应用程序启动时会自动执行表结构和数据初始化"
echo "========================================="
