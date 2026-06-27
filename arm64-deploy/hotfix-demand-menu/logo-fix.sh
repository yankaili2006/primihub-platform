#!/usr/bin/env bash
# =============================================================================
# Logo 热修复：把侧边栏老 logo(logo-DataItem.png) 替换为 PrimiHub logo。
# 离线、幂等。优先持久化(改 compose 加 bind-mount + 重建 nginx)，
# 无 compose 时退化为 docker cp(即时生效, 容器重建后需重跑)。
#
# 用法:  sudo bash logo-fix.sh
# 可选:  COMPOSE_DIR=/root/primihub  LOGO=assets/logo-primihub.png  NO_RECREATE=1
# =============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO="${LOGO:-$SCRIPT_DIR/assets/logo-primihub.png}"
red(){ printf '\033[31m%s\033[0m\n' "$*"; }; grn(){ printf '\033[32m%s\033[0m\n' "$*"; }; ylw(){ printf '\033[33m%s\033[0m\n' "$*"; }
[ -f "$LOGO" ] || { red "缺少 logo: $LOGO"; exit 1; }
command -v docker >/dev/null || { red "未找到 docker"; exit 1; }

WEBS="$(docker ps --format '{{.Names}}' | grep -iE 'manage-web' || docker ps --format '{{.Names}}\t{{.Image}}'|awk 'tolower($2)~/platform|nginx/{print $1}')"
[ -z "$WEBS" ] && { red "未找到 manage-web* 前端容器"; exit 1; }
FIRST="$(echo "$WEBS"|head -1)"
grn "前端容器: $(echo $WEBS|tr '\n' ' ')"

# 定位 compose 目录：前端容器 /docker-entrypoint.sh 的宿主源 → 上两级
ENT="$(docker inspect "$FIRST" --format '{{range .Mounts}}{{if eq .Destination "/docker-entrypoint.sh"}}{{.Source}}{{end}}{{end}}' 2>/dev/null)"
CD="${COMPOSE_DIR:-}"
[ -z "$CD" ] && [ -n "$ENT" ] && CD="$(dirname "$(dirname "$ENT")")"
COMPOSE=""
[ -n "$CD" ] && for f in "$CD/docker-compose.yaml" "$CD/docker-compose.yml"; do [ -f "$f" ] && COMPOSE="$f" && break; done

# 容器内所有 logo-DataItem*.png 目标路径(用第一个容器探测, 各节点一致)
TARGETS="$(docker exec "$FIRST" sh -c 'ls /usr/local/nginx/html/images/logo-DataItem*.png /usr/local/nginx/html/static/img/logo-DataItem*.png 2>/dev/null')"
[ -z "$TARGETS" ] && ylw "未找到 logo-DataItem*.png(前端可能已是新版)"

if [ -n "$COMPOSE" ]; then
  grn "compose = $COMPOSE  (持久化模式)"
  mkdir -p "$CD/config"; cp "$LOGO" "$CD/config/logo-primihub.png"
  if grep -q "logo-primihub.png" "$COMPOSE"; then
    ylw "compose 已含 logo 挂载(跳过插入)"
  else
    cp "$COMPOSE" "$COMPOSE.bak.$(date +%Y%m%d_%H%M%S)"
    ins=""; for t in $TARGETS; do ins="$ins\n      - \"./config/logo-primihub.png:$t\""; done
    sed -i "s#\(- \"\./config/nginx-entrypoint.sh:/docker-entrypoint.sh\"\)#\1$ins#g" "$COMPOSE"
    grep -q "logo-primihub.png" "$COMPOSE" && grn "已写入持久化挂载(备份 $COMPOSE.bak.*)" || ylw "自动改 compose 失败, 改用 docker cp"
  fi
  # 重建前端服务使挂载生效(service 名= compose 中 container_name 为 manage-web* 的块的 key)
  if [ "${NO_RECREATE:-0}" != "1" ] && grep -q "logo-primihub.png" "$COMPOSE"; then
    SVCS="$(awk '/^  [A-Za-z0-9_-]+:[[:space:]]*$/{s=$1} /container_name:[[:space:]]*manage-web/{gsub(":","",s);print s}' "$COMPOSE"|tr '\n' ' ')"
    ylw "重建前端服务: $SVCS"
    if ( cd "$CD" && docker compose up -d $SVCS ) >/tmp/_logo_recreate.log 2>&1; then
      grn "前端已重建(logo 挂载生效)"
    else
      ylw "自动重建失败, 请手动: cd $CD && docker compose up -d $SVCS"; tail -3 /tmp/_logo_recreate.log 2>/dev/null
    fi
  fi
fi

# 即时覆盖(无 compose 时的主路径; 有挂载时这步可能报 busy, 忽略)
for c in $WEBS; do for t in $TARGETS; do
  docker cp "$LOGO" "$c:$t" 2>/dev/null && echo "  [$c] cp -> $t" || true
done; done

echo; grn "✅ Logo 已替换为 PrimiHub。浏览器强刷(Ctrl+F5)或重新登录查看。"
[ -z "$COMPOSE" ] && ylw "未定位 compose: 仅即时生效, 容器重建后请重跑 logo-fix.sh(或手动加 bind-mount 持久化)。"

exit 0
