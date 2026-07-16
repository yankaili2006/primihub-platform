#!/usr/bin/env bash
# Build the primihub arm64 offline package on ANY arm64 server.
# Self-contained: sources arm64-deploy from THIS git repo (complete dumps + hardened compose),
# fetches the static docker aarch64 bins from OSS, pulls all images from ACR, then
# `docker save` + tar (+ optional OSS upload). No dependency on a prior /opt/ph deploy.
#
# Prereqs on the build host: git, docker (arm64 native), curl, python3 (only if uploading).
# Required env: ACR_USER ACR_PASS
# Optional env:
#   PTAG        platform/web image tag           (default: develop)
#   META_TAG NODE_TAG                             (default: 2026.07.15)
#   TS          package version stamp            (default: today's date)
#   WORK        build workdir                    (default: /tmp/ph-build)
#   DOCKER_BINS_URL  static docker bins tarball   (default: OSS cache)
#   OSS_ID OSS_SECRET  set to also upload to OSS  (optional)
set -euo pipefail
R=registry.cn-beijing.aliyuncs.com/primihub
REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
PTAG="${PTAG:-develop}"
META_TAG="${META_TAG:-2026.07.15}"
NODE_TAG="${NODE_TAG:-2026.07.15}"
TS="${TS:-$(date +%Y%m%d)}"
WORK="${WORK:-/tmp/ph-build}"
PKG="primihub-offline-arm64-$TS"
DEST="$WORK/$PKG"
DOCKER_BINS_URL="${DOCKER_BINS_URL:-https://primihub.oss-cn-beijing.aliyuncs.com/primihub-offline/arm64/docker-bins.tar}"
log(){ echo -e "\033[0;36m>> $*\033[0m"; }

[ "$(uname -m)" = "aarch64" ] || echo "WARN: not aarch64 ($(uname -m)) — docker save --platform still needed for arm64 images"

log "assemble $DEST from repo arm64-deploy ($REPO)"
rm -rf "$DEST"; mkdir -p "$DEST"
cp -a "$REPO/arm64-deploy" "$DEST/arm64-deploy"
rm -rf "$DEST/arm64-deploy/scripts"   # ship data/config/compose, not the build scripts
# pin image tags in .env
sed -i -E "s#(PRIMIHUB_PLATFORM=$R/primihub-platform:).*#\1$PTAG#"       "$DEST/arm64-deploy/.env"
sed -i -E "s#(PRIMIHUB_WEB_MANAGE=$R/primihub-web:).*#\1$PTAG#"          "$DEST/arm64-deploy/.env"
sed -i -E "s#(PRIMIHUB_META=$R/primihub-meta:).*#\1$META_TAG#"           "$DEST/arm64-deploy/.env"
sed -i -E "s#(PRIMIHUB_NODE=$R/primihub-node:).*#\1$NODE_TAG#"           "$DEST/arm64-deploy/.env"
grep -E "PRIMIHUB_(PLATFORM|WEB_MANAGE|META|NODE)=" "$DEST/arm64-deploy/.env"
echo "initsql dumps: $(ls "$DEST"/arm64-deploy/data/initsql/privacy*.sql | wc -l) (complete schema, Flyway removed)"

log "fetch static docker aarch64 bins"
if [ -f "$WORK/docker-bins.tar" ]; then cp "$WORK/docker-bins.tar" "$DEST/"; else curl -fSL --retry 3 -o "$DEST/docker-bins.tar" "$DOCKER_BINS_URL"; fi
tar tf "$DEST/docker-bins.tar" | grep -q dockerd && echo "docker-bins OK"

log "ACR login + pull 9 images (arm64)"
echo "$ACR_PASS" | docker login "$R" -u "$ACR_USER" --password-stdin >/dev/null
IMAGES=(
  "$R/primihub-platform:$PTAG" "$R/primihub-web:$PTAG"
  "$R/primihub-meta:$META_TAG" "$R/primihub-node:$NODE_TAG"
  "$R/mariadb:10.11-arm64" "$R/redis:7-arm64" "$R/nacos-server:v2.4.3-arm64"
  "$R/rabbitmq:3.6.15-management-arm64" "$R/loki:2.9.0-arm64"
)
for i in "${IMAGES[@]}"; do docker pull --platform linux/arm64 "$i"; done

log "docker save -> images.tar"
docker save "${IMAGES[@]}" -o "$DEST/images.tar"
ls -lh "$DEST/images.tar"

log "tar + sha256"
cd "$WORK"; tar czf "$PKG.tar.gz" "$PKG"
sha256sum "$PKG.tar.gz" | awk '{print $1}' > "$PKG.tar.gz.sha256"
ls -lh "$PKG.tar.gz"; echo "sha256: $(cat "$PKG.tar.gz.sha256")"

if [ -n "${OSS_ID:-}" ] && [ -n "${OSS_SECRET:-}" ]; then
  log "upload to OSS (public-read)"
  pip3 install -q oss2 2>/dev/null || pip3 install -q oss2 -i https://mirrors.aliyun.com/pypi/simple/
  OSS_ID="$OSS_ID" OSS_SECRET="$OSS_SECRET" PKG="$PKG" python3 - <<'PY'
import os, oss2
b=oss2.Bucket(oss2.Auth(os.environ['OSS_ID'],os.environ['OSS_SECRET']),
              'https://oss-cn-beijing.aliyuncs.com','primihub')
for fn in [os.environ['PKG']+'.tar.gz', os.environ['PKG']+'.tar.gz.sha256']:
    b.put_object_from_file('primihub-offline/arm64/'+fn, fn, headers={'x-oss-object-acl':'public-read'})
    print('uploaded', fn)
PY
else
  echo "(OSS_ID/OSS_SECRET not set — skipping upload; package at $WORK/$PKG.tar.gz)"
fi
echo "BUILD_DONE $PKG"
