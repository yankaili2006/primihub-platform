#!/usr/bin/env bash
# =============================================================================
# 隐私计算平台 — demand.csv 功能点菜单 + 前端页面解锁  增量热修复
# 适用于已部署的离线环境(docker-compose: mysql/mariadb + redis 容器)。
# 纯离线、幂等、可回滚。不拉取任何镜像，只改数据库 + 清后端菜单缓存。
#
# 用法:   sudo bash install.sh
# 可选环境变量(一般不用改, 默认即离线包默认值):
#   MYSQL_CONTAINER=mysql   MYSQL_ROOT_PASSWORD=root
#   REDIS_CONTAINER=redis   REDIS_PASSWORD=primihub
#   DBS="privacy1 privacy2 privacy3"   (留空=自动探测所有含 sys_auth 的库)
# =============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/sql"
TS="$(date +%Y%m%d_%H%M%S)"
BK_DIR="$SCRIPT_DIR/backups/$TS"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-}"
REDIS_CONTAINER="${REDIS_CONTAINER:-}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"
REDIS_PASSWORD="${REDIS_PASSWORD:-primihub}"
CACHE_KEY="sys_auth:bfs_list"

red(){ printf '\033[31m%s\033[0m\n' "$*"; }; grn(){ printf '\033[32m%s\033[0m\n' "$*"; }
ylw(){ printf '\033[33m%s\033[0m\n' "$*"; }; die(){ red "ERROR: $*"; exit 1; }

command -v docker >/dev/null || die "未找到 docker"

# ---- 1. 定位 mysql / redis 容器 -------------------------------------------
detect(){ # $1 keyword
  docker ps --format '{{.Names}}\t{{.Image}}' | awk -v k="$1" 'tolower($0) ~ k {print $1; exit}'
}
[ -z "$MYSQL_CONTAINER" ] && MYSQL_CONTAINER="$(docker ps --format '{{.Names}}' | grep -x mysql || true)"
[ -z "$MYSQL_CONTAINER" ] && MYSQL_CONTAINER="$(detect 'mysql|mariadb')"
[ -z "$MYSQL_CONTAINER" ] && die "未找到 mysql/mariadb 容器, 请用 MYSQL_CONTAINER=<名字> 指定"
[ -z "$REDIS_CONTAINER" ] && REDIS_CONTAINER="$(docker ps --format '{{.Names}}' | grep -x redis || true)"
[ -z "$REDIS_CONTAINER" ] && REDIS_CONTAINER="$(detect 'redis')"
grn "mysql 容器 = $MYSQL_CONTAINER ; redis 容器 = ${REDIS_CONTAINER:-<未找到, 将跳过清缓存>}"

MYSQL(){ docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=utf8mb4 "$@" 2>/dev/null; }
echo "SELECT 1;" | MYSQL >/dev/null || die "无法用 root 连接 mysql (检查 MYSQL_ROOT_PASSWORD)"

# ---- 2. 确定目标库 ---------------------------------------------------------
DBS="${DBS:-}"
if [ -z "$DBS" ]; then
  for d in $(echo "SHOW DATABASES;" | MYSQL -N | grep -iE 'privacy'); do
    n=$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$d' AND table_name='sys_auth';" | MYSQL -N)
    [ "$n" = "1" ] && DBS="$DBS $d"
  done
fi
DBS="$(echo $DBS | xargs)"
[ -z "$DBS" ] && die "未探测到含 sys_auth 的隐私库, 请用 DBS=\"privacy1 ...\" 指定"
grn "目标数据库: $DBS"

# ---- 3. 备份 + 应用 --------------------------------------------------------
mkdir -p "$BK_DIR"
for d in $DBS; do
  ylw "[$d] 备份 sys_auth + sys_ra -> backups/$TS/${d}.sql"
  docker exec "$MYSQL_CONTAINER" sh -c "mysqldump -uroot -p'$MYSQL_ROOT_PASSWORD' --default-character-set=utf8mb4 $d sys_auth sys_ra" > "$BK_DIR/${d}.sql" 2>/dev/null
  [ -s "$BK_DIR/${d}.sql" ] || die "[$d] 备份失败, 中止 (未做任何修改)"
done
for d in $DBS; do
  ylw "[$d] 应用 01_demand_menu.sql (224 功能点)"
  MYSQL "$d" < "$SQL_DIR/01_demand_menu.sql" || die "[$d] 应用 01 失败, 可用 rollback.sh 回滚"
  ylw "[$d] 应用 02_unlock_pages.sql (前端页面解锁 + auth_code 扩列)"
  MYSQL "$d" < "$SQL_DIR/02_unlock_pages.sql" || die "[$d] 应用 02 失败, 可用 rollback.sh 回滚"
done

# ---- 4. 清后端菜单缓存 -----------------------------------------------------
if [ -n "$REDIS_CONTAINER" ]; then
  ylw "清 redis 缓存 key: $CACHE_KEY"
  docker exec "$REDIS_CONTAINER" sh -c "redis-cli -a '$REDIS_PASSWORD' --no-auth-warning DEL $CACHE_KEY" >/dev/null 2>&1 \
    || docker exec "$REDIS_CONTAINER" redis-cli DEL "$CACHE_KEY" >/dev/null 2>&1 \
    || ylw "  清缓存失败(可忽略): 请手动 DEL $CACHE_KEY 或重启 application 容器"
fi

# ---- 5. 校验 ---------------------------------------------------------------
echo; grn "================= 校验 ================="
ok=1
for d in $DBS; do
  read tot demand unlock < <(MYSQL -N "$d" -e "SELECT (SELECT COUNT(*) FROM sys_auth WHERE is_del=0),(SELECT COUNT(*) FROM sys_auth WHERE auth_depth=2 AND r_auth_id=2000 AND is_del=0),(SELECT COUNT(*) FROM sys_auth WHERE p_auth_id=26000 AND is_del=0)")
  printf "  %-12s total=%s  demand_leaves=%s(期望224)  unlock_codes=%s(期望255)\n" "$d" "$tot" "$demand" "$unlock"
  [ "$demand" = "224" ] && [ "$unlock" = "255" ] || ok=0
done
# ---- 6. Logo 替换 (PrimiHub) ----------------------------------------------
if [ -f "$SCRIPT_DIR/logo-fix.sh" ] && [ "${SKIP_LOGO:-0}" != "1" ]; then
  echo; ylw "===== 应用 Logo 修复 (PrimiHub) ====="
  bash "$SCRIPT_DIR/logo-fix.sh" || ylw "logo 修复未完全成功(不影响菜单), 可单独重跑 logo-fix.sh"
fi

echo
if [ "$ok" = "1" ]; then
  grn "✅ 修复完成。备份: $BK_DIR"
  grn "   用户需【重新登录】(admin/123456) 刷新侧边栏; 若菜单未变, 重启 application 容器或再次清缓存。"
else
  red "⚠ 校验数字不符, 请检查上面输出; 可用 rollback.sh 回滚到 $BK_DIR"
fi
