#!/usr/bin/env bash
# Runs ON the fresh AnolisOS 8.9 arm64 VM: download Flyway offline package from OSS,
# install docker from the package's static aarch64 bins, docker load, compose up, assert.
set -euo pipefail
PKG_URL="https://primihub.oss-cn-beijing.aliyuncs.com/primihub-offline/arm64/primihub-offline-arm64-v1.8.2.tar.gz"
ROOT=/opt/ph
log(){ echo -e "\033[0;36m>> $*\033[0m"; }

log "prep host (selinux permissive, br_netfilter, ip_forward)"
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
modprobe br_netfilter 2>/dev/null || true
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true

log "download package ($PKG_URL)"
mkdir -p "$ROOT"; cd "$ROOT"
curl -fSL --retry 3 -o pkg.tar.gz "$PKG_URL"
curl -fsSL -o pkg.sha256 "$PKG_URL.sha256" || true
[ -f pkg.sha256 ] && { echo "$(cat pkg.sha256)  pkg.tar.gz" | sha256sum -c - ; }
tar xzf pkg.tar.gz
mv primihub-offline-arm64-* offline
cd offline && ls -1

log "install docker from package docker-bins.tar (aarch64 static)"
mkdir -p /usr/local/bin /usr/local/lib/docker/cli-plugins _bins
tar xf docker-bins.tar -C _bins
for b in docker dockerd containerd containerd-shim-runc-v2 ctr runc docker-init docker-proxy; do
  install -m0755 "_bins/$b" /usr/local/bin/"$b"
done
install -m0755 _bins/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
file /usr/local/bin/dockerd | grep -q aarch64 && echo "dockerd is aarch64 OK"

log "systemd docker.service + start"
cat > /etc/systemd/system/docker.service <<'UNIT'
[Unit]
Description=Docker Application Container Engine
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
systemctl daemon-reload
systemctl enable --now docker
sleep 5
docker version --format 'client {{.Client.Version}} / server {{.Server.Version}}'

log "docker load images.tar (9 images)"
docker load -i images.tar
n=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -c 'primihub/')
echo "primihub images loaded: $n (expect >=9)"; [ "$n" -ge 9 ]

log "compose up from arm64-deploy"
cd arm64-deploy
mkdir -p data/mysql data/log primihub-node data/result
docker compose --env-file .env up -d
echo "VM_DEPLOY_UP_DONE"
