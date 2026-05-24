#!/bin/bash
# PrimiHub v2.0.0 离线部署
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

# 2. Network
docker network create $NET 2>/dev/null || true

# 3. Infrastructure (注意: Nacos 必须命名为 nacos)
echo "步骤2: 启动基础设施..."
docker run -d --name mysql --network $NET -e MYSQL_ROOT_PASSWORD=$PASS -e MYSQL_DATABASE=nacos_config registry.cn-beijing.aliyuncs.com/primihub/mysql:5.7
docker run -d --name redis --network $NET registry.cn-beijing.aliyuncs.com/primihub/redis:7
for i in 0 1 2; do
  docker run -d --name rabbitmq${i} --network $NET registry.cn-beijing.aliyuncs.com/primihub/rabbitmq:3.6.15-management
done
echo "等待 MySQL..."
sleep 40

docker run -d --name nacos --network $NET --network-alias nacos \
  -e MYSQL_SERVICE_HOST=mysql -e MYSQL_SERVICE_DB_NAME=nacos_config \
  -e MYSQL_SERVICE_USER=root -e MYSQL_SERVICE_PASSWORD=$PASS \
  registry.cn-beijing.aliyuncs.com/primihub/nacos-server:v2.0.4
echo "等待 Nacos..."
sleep 30

# 4. Init databases
echo "步骤3: 初始化数据库..."
for db in privacy0 privacy1 privacy2 fusion0 fusion1 fusion2; do
  docker exec mysql mysql -uroot -p$PASS -e "CREATE DATABASE IF NOT EXISTS $db DEFAULT CHARSET utf8mb4" 2>/dev/null
done
[ -f "initsql/init-privacy-db-tables.sql" ] && \
  docker exec -i mysql mysql -uroot -p$PASS privacy0 < initsql/init-privacy-db-tables.sql 2>/dev/null

# Sync all tables to other databases
docker exec mysql mysql -uroot -p$PASS -e "USE privacy0; SHOW TABLES;" 2>/dev/null | grep -v Warning | grep -v Tables_in | while read table; do
  for db in privacy1 privacy2 fusion0 fusion1 fusion2; do
    docker exec mysql mysql -uroot -p$PASS -e "CREATE TABLE IF NOT EXISTS $db.$table LIKE privacy0.$table; INSERT IGNORE INTO $db.$table SELECT * FROM privacy0.$table;" 2>/dev/null
  done
done

# 5. Start services
echo "步骤4: 启动服务..."
for i in 0 1 2; do
  docker run -d --name primihub-meta${i} --network $NET primihub-meta:2.0.0
  docker run -d --name primihub-node${i} --network $NET primihub-node:2.0.0
  docker run -d --name application${i} --network $NET \
    -e SPRING_DATASOURCE_DRUID_PRIMARY_URL="jdbc:mysql://mysql:3306/privacy${i}?characterEncoding=UTF-8" \
    -e SPRING_DATASOURCE_DRUID_SECONDARY_URL="jdbc:mysql://mysql:3306/fusion${i}?characterEncoding=UTF-8" \
    primihub-platform:2.0.0 \
    --spring.cloud.nacos.discovery.server-addr=nacos:8848 \
    --spring.cloud.nacos.config.server-addr=nacos:8848
  docker run -d --name manage-web${i} --network $NET -p $((30811+i)):80 primihub-web:2.0.0
done

# 6. Install Python
echo "步骤5: 安装Python..."
sleep 20
docker exec application0 sh -c "yum install -y python3 2>&1 | tail -3" 2>/dev/null || true
[ -f "scripts/setup-python-algorithms.sh" ] && bash scripts/setup-python-algorithms.sh

# 7. Verify
echo "步骤6: 验证..."
sleep 50
for app in application0 application1 application2; do
  health=$(docker exec $app sh -c "curl -s -m 5 http://127.0.0.1:8080/actuator/health" 2>/dev/null || echo "N/A")
  db=$(docker logs $app 2>&1 | grep "Init Primary" | tail -1 | grep -o "privacy[0-9]")
  echo "  $app: ${health:-N/A} -> ${db:-N/A}"
done

echo "=========================================="
echo "  部署完成"
echo "  前端: http://<host_ip>:30811"
echo "  验证: docker logs application0 | grep Init"
echo "=========================================="
