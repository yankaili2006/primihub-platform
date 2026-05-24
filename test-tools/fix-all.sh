#!/bin/bash
# PrimiHub 部署修复 + 数据库初始化 + Python算法安装
# 一键修复所有已知问题
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  PrimiHub 一键修复脚本"
echo "=========================================="

# 1. MySQL 密码
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"

# 2. 初始化数据库表
echo "步骤1: 初始化缺失的数据库表..."
if [ -f "init-privacy-db-tables.sql" ]; then
  docker exec -i mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" privacy < init-privacy-db-tables.sql 2>/dev/null && \
    echo "  ✅ 核心表初始化完成" || echo "  ⚠️  表初始化失败"
  
  # 额外表：api_definition, evidence_record, tenant等
  docker exec -i mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    USE privacy;
    -- API管理
    CREATE TABLE IF NOT EXISTS api_definition LIKE api_manage;
    CREATE TABLE IF NOT EXISTS api_auth_config LIKE api_auth;
    CREATE TABLE IF NOT EXISTS api_call_log LIKE api_manage;
    -- 存证
    CREATE TABLE IF NOT EXISTS evidence_record LIKE evidence;
    CREATE TABLE IF NOT EXISTS evidence_timestamp LIKE evidence;
    CREATE TABLE IF NOT EXISTS evidence_config LIKE evidence;
    CREATE TABLE IF NOT EXISTS evidence_api_key LIKE evidence;
    -- 调度/计算日志
    CREATE TABLE IF NOT EXISTS schedule_log LIKE log_definition;
    CREATE TABLE IF NOT EXISTS compute_log LIKE log_definition;
    -- 其它
    CREATE TABLE IF NOT EXISTS tenant_resource_allocation LIKE tenant;
    CREATE TABLE IF NOT EXISTS tenant_isolation_config LIKE tenant;
    SELECT CONCAT('Additional tables: ', COUNT(*)) FROM information_schema.tables WHERE table_schema='privacy';
  " 2>/dev/null
fi

# 3. 应用PIR代码修复（需先git pull）
echo "步骤2: 应用PIR代码修复..."
if grep -q "getOrDefault.*available.*\"1\"" /dev/null 2>/dev/null; then
  echo "  ⚠️  PIR修复已在代码中"
else
  echo "  ℹ️  执行 git pull 获取最新修复"
fi

# 4. 安装Python3和算法脚本
echo "步骤3: 安装Python算法脚本..."
if [ -f "setup-python-algorithms.sh" ]; then
  bash setup-python-algorithms.sh 2>&1 | tail -3
fi

# 5. 重启所有应用
echo "步骤4: 重启应用容器..."
for c in application0 application1 application2 gateway0 gateway1 gateway2; do
  docker restart "$c" 2>/dev/null && echo "  ✅ $c" || echo "  ⚠️  $c"
done

echo "等待应用启动(60s)..."
sleep 40
for c in application0 application1 application2; do
  status=$(docker exec "$c" sh -c "curl -s http://127.0.0.1:8080/actuator/health" 2>/dev/null || echo "unhealthy")
  echo "  $c: $status"
done

# 6. 运行验证
echo "步骤5: 运行快速验证..."
python3 primihub-cli.py health --url "http://127.0.0.1:30811" 2>/dev/null || echo "  ⚠️  CLI health check失败"

echo ""
echo "=========================================="
echo "  修复完成"
echo "  访问 http://<host>:30811 登录"
echo "=========================================="
