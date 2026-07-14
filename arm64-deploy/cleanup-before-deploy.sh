#!/usr/bin/env bash
# cleanup-before-deploy.sh (arm64-deploy) — 在 `docker compose up` / deploy 前清理上一次部署的残留
#
# 解决的常见问题：
#   1) 固定 container_name 冲突 -> `docker compose up` 报
#      `Conflict. The container name "/loki" is already in use ...`
#      （上一次半截部署留下的同名容器，compose 无法再创建同名的）
#   2) 旧网络标签冲突 -> `up` 仅几百毫秒退出、容器一个都没起
#      ("network xxx_default already exists but has incorrect label")
#   3)（不带 --keep-data 时）data/mysql 残留旧数据 -> MySQL 跳过 initsql、数据库不完整
#
# 用法:
#   bash cleanup-before-deploy.sh              # 完整清理(含删 data/mysql，强制重新 initsql) —— 全新安装用
#   bash cleanup-before-deploy.sh --keep-data  # 只清容器/网络/卷，保留 data/mysql —— 保数据的重部署用
#
# 注意: data/mysql 由容器内用户写入，删除可能需要 root，必要时 `sudo bash cleanup-before-deploy.sh`。

set -uo pipefail
cd "$(dirname "$0")"

KEEP_DATA=0
[ "${1:-}" = "--keep-data" ] && KEEP_DATA=1

DC="docker compose"
docker compose version >/dev/null 2>&1 || DC="docker-compose"

# 与 docker-compose.yaml 里的 22 个固定 container_name 一一对应
CONTAINERS=(
  mysql redis nacos-server
  rabbitmq0 rabbitmq1 rabbitmq2
  primihub-meta0 primihub-meta1 primihub-meta2
  application0 application1 application2
  gateway0 gateway1 gateway2
  manage-web0 manage-web1 manage-web2
  primihub-node0 primihub-node1 primihub-node2
  loki
)

echo "[1/6] $DC down (含孤儿容器 + 命名卷)..."
$DC --env-file .env down --remove-orphans -v 2>/dev/null || true

echo "[2/6] 强制删除残留的固定名容器 (compose 项目名不同也能清干净)..."
docker rm -f "${CONTAINERS[@]}" >/dev/null 2>&1 || true

echo "[3/6] 删除标签冲突的旧网络..."
NETS="arm64-deploy_default primihub_default"
NETS="$NETS $(docker network ls --format '{{.Name}}' 2>/dev/null | grep -E '_default$' | grep -iE 'primihub|arm64-deploy' || true)"
for net in $NETS; do
  docker network rm "$net" >/dev/null 2>&1 && echo "      - removed network: $net" || true
done

echo "[4/6] 删除残留命名卷..."
for vol in $(docker volume ls --format '{{.Name}}' 2>/dev/null | grep -iE 'primihub|arm64-deploy' || true); do
  docker volume rm "$vol" >/dev/null 2>&1 && echo "      - removed volume: $vol" || true
done

echo "[5/6] 清理运行时产物 (log / result)..."
rm -rf data/log/* data/result/* >/dev/null 2>&1 || true

if [ "$KEEP_DATA" -eq 1 ]; then
  echo "[6/6] --keep-data: 保留 data/mysql (不重新初始化数据库)"
else
  echo "[6/6] 删除 MySQL 数据目录 data/mysql/* (强制重新执行 initsql)..."
  rm -rf data/mysql/* data/mysql/.[!.]* >/dev/null 2>&1 \
    || echo "      ⚠ 删除 data/mysql 失败，可能需要 sudo:  sudo rm -rf data/mysql/*"
fi

echo ""
echo "✅ 清理完成。现在可以执行:  docker compose --env-file .env up -d   (或 bash deploy.sh / load-and-deploy.sh)"
