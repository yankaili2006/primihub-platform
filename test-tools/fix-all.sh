#!/bin/bash
# PrimiHub 部署修复 + 数据库初始化 + Python算法安装
# 新架构: privacy0/1/2 (非 privacy)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

MYSQL_PASS="${MYSQL_ROOT_PASSWORD:-root}"

echo "=========================================="
echo "  PrimiHub 新架构一键修复"
echo "=========================================="
echo "  数据库: privacy0/1/2 + fusion0/1/2"
echo "=========================================="
echo ""

# 1. 初始化所有数据库
echo "步骤1: 初始化数据库表..."
INIT_SQL="init-privacy-db-tables.sql"
if [ -f "$INIT_SQL" ]; then
  for db in privacy0 privacy1 privacy2; do
    echo -n "  $db: "
    docker exec -i mysql mysql -uroot -p"$MYSQL_PASS" "$db" < "$INIT_SQL" 2>/dev/null && \
      echo "$(docker exec mysql sh -c "mysql -uroot -proot -e \"USE $db; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db';\"" 2>/dev/null | grep -v Warning | grep -v COUNT) 表" || echo "失败"
  done
fi

# 2. 同步数据库表（主库→从库）
echo "步骤2: 同步 fusion 从库..."
for src in privacy0 privacy1 privacy2; do
  dst="${src/privacy/fusion}"
  echo -n "  $src → $dst: "
  docker exec mysql sh -c "mysql -uroot -proot -e \"USE $src; SHOW TABLES;\"" 2>/dev/null | grep -v Warning | grep -v Tables_in | while read table; do
    docker exec mysql sh -c "mysql -uroot -proot -e \"CREATE TABLE IF NOT EXISTS $dst.$table LIKE $src.$table; INSERT IGNORE INTO $dst.$table SELECT * FROM $src.$table;\"" 2>/dev/null
  done
  echo "$(docker exec mysql sh -c "mysql -uroot -proot -e \"USE $dst; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$dst';\"" 2>/dev/null | grep -v Warning | grep -v COUNT) 表"
done

# 3. Python算法
echo "步骤3: 安装Python算法..."
if [ -f "setup-python-algorithms.sh" ]; then
  bash setup-python-algorithms.sh 2>&1 | tail -2
fi

# 4. 启动应用（必须设置环境变量！）
echo "步骤4: 启动应用容器..."
for pair in "application0 privacy0 fusion0 demo0 rabbitmq0" \
            "application1 privacy1 fusion1 demo1 rabbitmq1" \
            "application2 privacy2 fusion2 demo2 rabbitmq2"; do
  read -r name primary secondary namespace rmq <<< "$pair"
  echo -n "  $name ($primary+$secondary): "
  
  # 检查是否已在运行
  if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "^$name$"; then
    # 已有容器 - 设置环境变量后重启
    docker update "$name" \
      -e SPRING_DATASOURCE_DRUID_PRIMARY_URL="jdbc:mysql://mysql:3306/$primary?characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=Asia/Shanghai&useSSL=false" \
      -e SPRING_DATASOURCE_DRUID_SECONDARY_URL="jdbc:mysql://mysql:3306/$secondary?characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=Asia/Shanghai&useSSL=false" 2>/dev/null
    docker restart "$name" 2>/dev/null && echo "已重启" || echo "失败"
  else
    echo "不存在，跳过"
  fi
done

echo ""
echo "等待应用启动(60s)..."
sleep 40
for app in application0 application1 application2; do
  status=$(docker exec "$app" sh -c "curl -s -m 5 http://127.0.0.1:8080/actuator/health" 2>/dev/null || echo "unhealthy")
  db=$(docker logs "$app" 2>&1 | grep "Init Primary" | tail -1 | grep -o "privacy[0-9]")
  if [ -z "$db" ]; then db="N/A"; fi
  echo "  $app: $status → $db"
done

# 5. 验证
echo "步骤5: 验证API..."
LOGIN=$(docker exec application0 sh -c "curl -s -m 10 http://127.0.0.1:8080/user/login -d 'userAccount=admin&userPassword=123456'" 2>/dev/null)
TOKEN=$(echo "$LOGIN" | sed 's/.*"token":"\([^"]*\)".*/\1/')
if [ -n "$TOKEN" ]; then
  for ep in "psi/getPsiTaskList?pageNo=1&pageSize=10" "federatedStatistics/types" "tenant/findTenantPage?pageNo=1&pageSize=10" "node/approval/getAllConfigs" "evidence/findEvidencePage?pageNo=1&pageSize=10" "apiManage/findApiPage?pageNo=1&pageSize=10"; do
    code=$(docker exec application0 sh -c "curl -s -m 5 \"http://127.0.0.1:8080/$ep\" -H \"token: $TOKEN\" -H \"userId: 1\"" 2>/dev/null | grep -o '"code":[0-9,-]*' | head -1)
    echo "  $ep: $code"
  done
fi

echo ""
echo "=========================================="
echo "  修复完成"
echo "  验证: docker logs application0 | grep 'Init Primary'"
echo "  预期: URL: jdbc:mysql://mysql:3306/privacy0?..."
echo "=========================================="
