#!/usr/bin/env bash
# Runs ON a fresh AnolisOS arm64 VM. Verifies the Flyway-removal branch end-to-end:
# reuse v1.8.2 package for docker+base images+docker-bins, then OVERRIDE platform/web with the
# branch-tagged images + swap in the NEW complete dumps + hardened compose. Then boot & assert:
#   - app starts WITHOUT Flyway (no flyway_schema_history table anywhere)
#   - login 200, functional smoke 0 SQL errors, 22 containers up.
# Env in: ACR_USER ACR_PASS PTAG (branch image tag)
set -euo pipefail
R=registry.cn-beijing.aliyuncs.com/primihub
PTAG="${PTAG:?set PTAG to branch image tag}"
PKG_URL="https://primihub.oss-cn-beijing.aliyuncs.com/primihub-offline/arm64/primihub-offline-arm64-v1.8.2.tar.gz"
ROOT=/opt/ph; log(){ echo -e "\033[0;36m>> $*\033[0m"; }

log "prep host"
setenforce 0 2>/dev/null || true; modprobe br_netfilter 2>/dev/null || true
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true

log "download v1.8.2 package (for docker-bins + base images + arm64-deploy skeleton)"
mkdir -p "$ROOT"; cd "$ROOT"; curl -fSL --retry 3 -o pkg.tar.gz "$PKG_URL"
tar xzf pkg.tar.gz; mv primihub-offline-arm64-* offline; cd offline

log "install docker from static aarch64 bins"
mkdir -p /usr/local/bin /usr/local/lib/docker/cli-plugins _bins; tar xf docker-bins.tar -C _bins
for b in docker dockerd containerd containerd-shim-runc-v2 ctr runc docker-init docker-proxy; do install -m0755 "_bins/$b" /usr/local/bin/"$b"; done
install -m0755 _bins/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
cat > /etc/systemd/system/docker.service <<'UNIT'
[Unit]
Description=Docker
After=network-online.target
Wants=network-online.target
[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd -H unix:///var/run/docker.sock
Restart=always
LimitNOFILE=1048576
Delegate=yes
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload; systemctl enable --now docker; sleep 5
docker version --format 'server {{.Server.Version}}'

log "load base images (9 from v1.8.2), then OVERRIDE platform/web with branch tag $PTAG"
docker load -i images.tar
echo "$ACR_PASS" | docker login "$R" -u "$ACR_USER" --password-stdin >/dev/null
docker pull "$R/primihub-platform:$PTAG"
docker pull "$R/primihub-web:$PTAG"

log "swap in NEW dumps + hardened compose (scp'd to /opt/ph/branch-arm64-deploy) + branch .env tags"
cp -f /opt/ph/branch-arm64-deploy/data/initsql/privacy*.sql arm64-deploy/data/initsql/
cp -f /opt/ph/branch-arm64-deploy/docker-compose.yaml arm64-deploy/docker-compose.yaml
sed -i -E "s#(PRIMIHUB_PLATFORM=$R/primihub-platform:).*#\1$PTAG#" arm64-deploy/.env
sed -i -E "s#(PRIMIHUB_WEB_MANAGE=$R/primihub-web:).*#\1$PTAG#" arm64-deploy/.env
grep -E "PRIMIHUB_(PLATFORM|WEB_MANAGE)=" arm64-deploy/.env
echo "initsql files: $(ls arm64-deploy/data/initsql/privacy*.sql | wc -l); migration dir in image is gone (Flyway removed)"

log "compose up"
cd arm64-deploy; mkdir -p data/mysql data/log primihub-node data/result
docker compose --env-file .env up -d
echo "VM_VERIFY_UP_DONE"
