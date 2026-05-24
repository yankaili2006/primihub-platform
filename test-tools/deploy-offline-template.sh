#!/bin/bash
# PrimiHub v2.0.0 离线部署脚本
set -e
cd "$(dirname "$0")"
NET="primihub_default"
PASS="${MYSQL_ROOT_PASSWORD:-root}"

echo "=========================================="
echo "  PrimiHub v2.0.0 离线部署"
echo "=========================================="

# 1. Import images
echo "步骤1: 导入镜像..."
[ -f "import-images.sh" ] && bash import-images.sh

# 2. Create network
docker network create $NET 2>/dev/null || true

# 3. Start infrastructure
echo "步骤2: 启动基础设施..."
docker run -d --name mysql --network $NET -e MYSQL_ROOT_PASSWORD=$PASS -e MYSQL_DATABASE=nacos_config registry.cn-beijing.aliyuncs.com/primihub/mysql:5.7
docker run -d --name redis --network $NET registry.cn-beijing.aliyuncs.com/primihub/redis:7
for i in 0 1 2; do
  docker run -d --name rabbitmq${i} --network $NET registry.cn-beijing.aliyuncs.com/primihub/rabbitmq:3.6.15-management
done

echo "Waiting for MySQL..."
sleep 40

docker run -d --name nacos-server --network $NET \
  -e MYSQL_SERVICE_HOST=mysql -e MYSQL_SERVICE_DB_NAME=nacos_config \
  -e MYSQL_SERVICE_USER=root -e MYSQL_SERVICE_PASSWORD=$PASS \
  -p 8848:8848 registry.cn-beijing.aliyuncs.com/primihub/nacos-server:v2.0.4

echo "Waiting for Nacos..."
sleep 30

# 4. Init databases
echo "步骤3: 初始化数据库..."
for db in privacy0 privacy1 privacy2 fusion0 fusion1 fusion2; do
  docker exec mysql mysql -uroot -p$PASS -e "CREATE DATABASE IF NOT EXISTS $db DEFAULT CHARSET utf8mb4" 2>/dev/null
done
[ -f "initsql/init-privacy-db-tables.sql" ] && \
  docker exec -i mysql mysql -uroot -p$PASS privacy0 < initsql/init-privacy-db-tables.sql 2>/dev/null

# Sync tables to other databases
docker exec mysql mysql -uroot -p$PASS -e "USE privacy0; SHOW TABLES;" 2>/dev/null | grep -v Warning | grep -v Tables_in | while read table; do
  for db in privacy1 privacy2; do
    docker exec mysql mysql -uroot -p$PASS -e "CREATE TABLE IF NOT EXISTS $db.$table LIKE privacy0.$table; INSERT IGNORE INTO $db.$table SELECT * FROM privacy0.$table;" 2>/dev/null
  done
  for db in fusion0 fusion1 fusion2; do
    docker exec mysql mysql -uroot -p$PASS -e "CREATE TABLE IF NOT EXISTS $db.$table LIKE privacy0.$table; INSERT IGNORE INTO $db.$table SELECT * FROM privacy0.$table;" 2>/dev/null
  done
done

# 5. Start services
echo "步骤4: 启动服务..."
for i in 0 1 2; do
  docker run -d --name primihub-meta${i} --network $NET primihub-meta:2.0.0
  docker run -d --name primihub-node${i} --network $NET -p $((50050+i)):50050 primihub-node:2.0.0
  docker run -d --name application${i} --network $NET \
    -e SPRING_DATASOURCE_DRUID_PRIMARY_URL="jdbc:mysql://mysql:3306/privacy${i}?characterEncoding=UTF-8" \
    -e SPRING_DATASOURCE_DRUID_SECONDARY_URL="jdbc:mysql://mysql:3306/fusion${i}?characterEncoding=UTF-8" \
    primihub-platform:2.0.0
  docker run -d --name manage-web${i} --network $NET -p $((30811+i)):80 primihub-web:2.0.0
done

# 6. Install Python algorithms
echo "步骤5: 安装Python算法..."
sleep 20
docker exec application0 sh -c "yum install -y python3 2>&1 | tail -3" 2>/dev/null || true
[ -f "scripts/setup-python-algorithms.sh" ] && bash scripts/setup-python-algorithms.sh

# 7. Verify
echo "步骤6: 验证..."
sleep 40
for app in application0 application1 application2; do
  health=$(docker exec $app sh -c "curl -s -m 5 http://127.0.0.1:8080/actuator/health" 2>/dev/null || echo "N/A")
  db=$(docker logs $app 2>&1 | grep "Init Primary" | tail -1 | grep -o "privacy[0-9]")
  echo "  $app: ${health:-N/A} -> ${db:-N/A}"
done

echo ""
echo "=========================================="
echo "  部署完成"
echo "  前端入口: http://<host_ip>:30811"
echo "=========================================="
