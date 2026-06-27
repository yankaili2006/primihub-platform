#!/usr/bin/env bash
# 回滚 demand-menu 热修复：从指定备份目录恢复 sys_auth + sys_ra，并清缓存。
# 用法:  sudo bash rollback.sh [backups/<时间戳>]   (不填则用最新一次备份)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DK="docker"; $DK ps >/dev/null 2>&1 || DK="sudo docker"
find_db(){ $DK ps --format '{{.Names}}' | grep -xiE 'mysql|mariadb' | head -1
  $DK ps --format '{{.Names}}\t{{.Image}}' | awk 'tolower($0)~/mysql|mariadb|percona/{print $1;exit}'
  for x in $($DK ps --format '{{.Names}}'); do $DK exec "$x" sh -c 'command -v mysql>/dev/null 2>&1||command -v mariadb>/dev/null 2>&1' 2>/dev/null && { echo "$x"; break; }; done; }
MYSQL_CONTAINER="${MYSQL_CONTAINER:-$(find_db | head -1)}"
REDIS_CONTAINER="${REDIS_CONTAINER:-$($DK ps --format '{{.Names}}' | grep -xiE 'redis' | head -1)}"
[ -n "$MYSQL_CONTAINER" ] || { echo "未找到数据库容器, 请 MYSQL_CONTAINER=<名字> 重试; 当前容器:"; $DK ps --format '  {{.Names}}\t{{.Image}}'; exit 1; }
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"
REDIS_PASSWORD="${REDIS_PASSWORD:-primihub}"

BK="${1:-$(ls -1dt "$SCRIPT_DIR"/backups/*/ 2>/dev/null | head -1)}"
[ -n "$BK" ] && [ -d "$BK" ] || { echo "未找到备份目录, 用法: rollback.sh backups/<时间戳>"; exit 1; }
echo "从备份恢复: $BK  (mysql=$MYSQL_CONTAINER)"
for f in "$BK"/*.sql; do
  d="$(basename "$f" .sql)"
  echo "  恢复 $d ..."
  $DK exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=utf8mb4 "$d" < "$f" 2>/dev/null \
    && echo "    ok" || echo "    失败"
done
[ -n "$REDIS_CONTAINER" ] && $DK exec "$REDIS_CONTAINER" sh -c "redis-cli -a '$REDIS_PASSWORD' --no-auth-warning DEL sys_auth:bfs_list" >/dev/null 2>&1
echo "回滚完成。用户重新登录刷新。"
