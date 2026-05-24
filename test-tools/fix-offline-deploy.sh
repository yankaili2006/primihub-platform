#!/bin/bash
# 修复离线部署 - 新架构 (privacy0/1/2)
# 覆盖: 数据库初始化、数据源URL修复、Python算法、容器配置

set -e

echo "=========================================="
echo "   修复离线部署配置 (新架构)"
echo "=========================================="
echo ""

cd "$(dirname "$0")"
MYSQL_PASS="${MYSQL_PASS:-root}"

# ===== 前置检查 =====
DISK_AVAIL_GB=$(($(df / | tail -1 | awk '{print $4}') / 1024 / 1024))
echo "磁盘: ${DISK_AVAIL_GB}GB"
if [ "$DISK_AVAIL_GB" -lt 10 ]; then
    echo "⚠️ 磁盘不足，建议扩容至 30GB"
fi

# ===== 1. 初始化数据库表 =====
echo ""
echo "步骤1: 初始化 privacy0/1/2 数据库表..."
INIT_SQL="init-privacy-db-tables.sql"
if [ -f "$INIT_SQL" ]; then
  for db in privacy0 privacy1 privacy2; do
    echo -n "  $db: "
    docker exec -i mysql mysql -uroot -p"$MYSQL_PASS" "$db" < "$INIT_SQL" 2>/dev/null && \
      echo "✓" || echo "⚠ 失败"
  done
else
  echo "  ⚠ 未找到 $INIT_SQL"
fi

# ===== 2. 同步 fusion 从库 =====
echo ""
echo "步骤2: 同步 fusion0/1/2 从库..."
for src in privacy0 privacy1 privacy2; do
  dst="${src/privacy/fusion}"
  echo -n "  $src → $dst: "
  docker exec mysql sh -c "mysql -uroot -proot -e \"USE $src; SHOW TABLES;\"" 2>/dev/null | grep -v Warning | grep -v Tables_in | while read table; do
    docker exec mysql sh -c "mysql -uroot -proot -e \"CREATE TABLE IF NOT EXISTS $dst.$table LIKE $src.$table; INSERT IGNORE INTO $dst.$table SELECT * FROM $src.$table;\"" 2>/dev/null
  done
  echo "✓"
done

# ===== 3. 安装 Python3 和算法 =====
echo ""
echo "步骤3: 安装 Python3 和算法脚本..."
if [ -f "setup-python-algorithms.sh" ]; then
  bash setup-python-algorithms.sh 2>&1 | tail -3
  echo "✓"
else
  echo "  ⚠ 未找到 setup-python-algorithms.sh"
fi

# ===== 4. 修复应用容器数据源配置 =====
echo ""
echo "步骤4: 修复应用数据源配置 (环境变量)..."

cat > /tmp/update_env.sh << 'UEOF'
#!/bin/sh
# 为容器设置正确的数据源环境变量
for pair in "application0 privacy0 fusion0" \
            "application1 privacy1 fusion1" \
            "application2 privacy2 fusion2"; do
  name=$(echo $pair | cut -d' ' -f1)
  primary=$(echo $pair | cut -d' ' -f2)
  secondary=$(echo $pair | cut -d' ' -f3)
  
  PRIMARY_URL="jdbc:mysql://mysql:3306/${primary}?characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=Asia/Shanghai&useSSL=false"
  SECONDARY_URL="jdbc:mysql://mysql:3306/${secondary}?characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=Asia/Shanghai&useSSL=false"
  
  if docker ps --format "{{.Names}}" | grep -q "^$name$"; then
    docker update "$name" \
      -e SPRING_DATASOURCE_DRUID_PRIMARY_URL="$PRIMARY_URL" \
      -e SPRING_DATASOURCE_DRUID_SECONDARY_URL="$SECONDARY_URL" 2>/dev/null
    echo "  $name → $primary + $secondary"
  fi
done
UEOF

# ===== 5. 重启应用 =====
echo ""
echo "步骤5: 重启应用容器..."
for c in application0 application1 application2 gateway0 gateway1 gateway2; do
  docker restart "$c" 2>/dev/null && echo -n " ✓ $c" || echo -n " ⚠ $c"
done
echo ""

echo ""
echo "等待应用启动(60s)..."
sleep 40
for app in application0 application1 application2; do
  health=$(docker exec "$app" sh -c "curl -s -m 5 http://127.0.0.1:8080/actuator/health" 2>/dev/null || echo "unhealthy")
  db=$(docker logs "$app" 2>&1 | grep "Init Primary" | tail -1 | grep -o "privacy[0-9]")
  echo "  $app: $health → ${db:-N/A}"
done

# ===== 6. 修复前端权限 =====
echo ""
echo "步骤6: 修复前端路由权限..."
FIX_SQL="../fix_missing_auth_entries.sql"
if [ -f "$FIX_SQL" ]; then
  for db in privacy0 privacy1 privacy2; do
    docker exec -i mysql mysql -uroot -p"$MYSQL_PASS" "$db" < "$FIX_SQL" 2>/dev/null && echo "  ✓ $db" || echo "  ⚠ $db"
  done
fi

# ===== 7. 验证 =====
echo ""
echo "步骤7: 快速验证..."
python3 primihub-cli.py health --url "http://127.0.0.1:30811" 2>/dev/null || echo "  ⚠ CLI不可用"

echo ""
echo "=========================================="
echo "   修复完成"
echo "=========================================="
echo ""
echo "验证:"
echo "  docker logs application0 | grep 'Init Primary'"
echo "  预期输出: URL: jdbc:mysql://mysql:3306/privacy0?..."
echo ""
echo "访问:"
echo "  机构1: http://${HOST_IP:-localhost}:30811"
echo "  机构2: http://${HOST_IP:-localhost}:30812"
echo "  机构3: http://${HOST_IP:-localhost}:30813"
echo ""
