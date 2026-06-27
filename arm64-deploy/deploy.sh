#!/usr/bin/env bash
# =============================================================================
# 隐私计算平台 — arm64 离线一键部署
#   1) docker compose 拉起全栈 (mysql 首启自动灌 initsql: 224功能点菜单 + 页面解锁)
#   2) 前端 logo 经 compose bind-mount 自动替换为 PrimiHub
#   3) 等待服务就绪 → 登录可用
#   4) 浏览器模拟登录验证: 校验功能菜单(18模块/224功能点) + 侧边栏页面解锁
#   5) 校验 logo 已替换
# 纯离线(镜像需已导入或可访问镜像库)。可重复执行。
#
# 用法:  bash deploy.sh            # 直接用本地镜像启动并验证
#        PULL=1 bash deploy.sh     # 先 docker compose pull 再启动(需镜像库可达)
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")"
PORTS="${PORTS:-30811 30812 30813}"
COMPOSE="docker compose --env-file .env"
red(){ printf '\033[31m%s\033[0m\n' "$*"; }; grn(){ printf '\033[32m%s\033[0m\n' "$*"; }; ylw(){ printf '\033[33m%s\033[0m\n' "$*"; }

# 离线安装 docker (无 docker 且包内带 docker-bins.tar 时, 适配无公网/CentOS8 EOL)
if ! command -v docker >/dev/null 2>&1 && [ -f docker-bins.tar ]; then
  grn "== 离线安装 docker (docker-bins.tar) =="
  tar xf docker-bins.tar -C /usr/local/bin
  mkdir -p /usr/local/lib/docker/cli-plugins
  [ -f /usr/local/bin/docker-compose ] && mv -f /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose || true
  chmod +x /usr/local/bin/* /usr/local/lib/docker/cli-plugins/docker-compose 2>/dev/null || true
  cat >/etc/systemd/system/docker.service <<'UNIT'
[Unit]
Description=Docker Engine
After=network-online.target
[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd
Restart=always
Delegate=yes
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
UNIT
  systemctl daemon-reload && systemctl enable --now docker && sleep 5
  export PATH=$PATH:/usr/local/bin
fi
command -v docker >/dev/null || { red "未找到 docker (且无 docker-bins.tar)"; exit 1; }
docker compose version >/dev/null 2>&1 || COMPOSE="docker-compose --env-file .env"

grn "== 0. 主机调优 (arm64 redis COW / overcommit) =="
sysctl -w vm.overcommit_memory=1 >/dev/null 2>&1 || true
grep -q "vm.overcommit_memory" /etc/sysctl.conf 2>/dev/null || echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf

grn "== 1. 准备运行目录 =="
mkdir -p data/mysql data/log primihub-node data/result

if [ "${PULL:-0}" = "1" ]; then grn "== 拉取镜像 =="; $COMPOSE pull; fi

grn "== 2. 启动全栈 (docker compose up -d) =="
$COMPOSE up -d

grn "== 3. 等待服务就绪 (登录可用, 最多 ~40 分钟; mysql 首启灌库较慢) =="
login_ok=0
for r in $(seq 1 80); do
  sleep 30
  up=$(docker ps --format '{{.Names}}' | wc -l | tr -d ' ')
  ok=0
  for p in $PORTS; do
    pk=$(curl -s -m8 "http://127.0.0.1:$p/prod-api/sys/common/getValidatePublicKey" 2>/dev/null | grep -c publicKey)
    [ "$pk" = "1" ] && ok=$((ok+1))
  done
  echo "[round $r] containers_up=$up  api_ready=$ok/$(echo $PORTS|wc -w)"
  [ "$ok" = "$(echo $PORTS|wc -w)" ] && { login_ok=1; break; }
done
[ "$login_ok" = "1" ] || { red "服务未就绪, 见 docker compose ps / logs"; $COMPOSE ps; exit 2; }

grn "== 4. 浏览器模拟登录验证 (功能菜单 + 页面解锁) =="
allpass=1
for p in $PORTS; do
  echo "---- 端口 $p ----"
  python3 scripts/verify_menus.py "http://127.0.0.1:$p" admin 123456 || allpass=0
done

grn "== 5. 校验 logo 已替换为 PrimiHub =="
EXP=$(wc -c < config/logo-primihub.png | tr -d ' ')
for p in $PORTS; do
  got=$(curl -s -m8 "http://127.0.0.1:$p/images/logo-DataItem.png" | wc -c | tr -d ' ')
  if [ "$got" = "$EXP" ]; then grn "  端口 $p logo OK ($got bytes)"; else ylw "  端口 $p logo 未生效 ($got != $EXP), 可 docker compose up -d 重建 nginx*"; allpass=0; fi
done

echo
if [ "$allpass" = "1" ]; then grn "✅ 部署完成且验证通过。访问 http://<IP>:30811 (admin/123456)";
else red "⚠ 部署完成但部分验证未过, 见上面输出"; exit 3; fi
