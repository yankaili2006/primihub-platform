#!/usr/bin/env bash
# 回滚 demand-menu 热修复：从指定备份目录恢复 sys_auth + sys_ra，并清缓存。
# 用法:  sudo bash rollback.sh [backups/<时间戳>]   (不填则用最新一次备份)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -x mysql || docker ps --format '{{.Names}}\t{{.Image}}' | awk 'tolower($0)~/mysql|mariadb/{print $1;exit}')}"
REDIS_CONTAINER="${REDIS_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -x redis || true)}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"
REDIS_PASSWORD="${REDIS_PASSWORD:-primihub}"

BK="${1:-$(ls -1dt "$SCRIPT_DIR"/backups/*/ 2>/dev/null | head -1)}"
[ -n "$BK" ] && [ -d "$BK" ] || { echo "未找到备份目录, 用法: rollback.sh backups/<时间戳>"; exit 1; }
echo "从备份恢复: $BK  (mysql=$MYSQL_CONTAINER)"
for f in "$BK"/*.sql; do
  d="$(basename "$f" .sql)"
  echo "  恢复 $d ..."
  docker exec -i "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=utf8mb4 "$d" < "$f" 2>/dev/null \
    && echo "    ok" || echo "    失败"
done
[ -n "$REDIS_CONTAINER" ] && docker exec "$REDIS_CONTAINER" sh -c "redis-cli -a '$REDIS_PASSWORD' --no-auth-warning DEL sys_auth:bfs_list" >/dev/null 2>&1
echo "回滚完成。用户重新登录刷新。"
