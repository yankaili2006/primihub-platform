#!/usr/bin/env bash
# Runs ON the ARM VM: build the 20260717 offline package (new platform image + 8 already-loaded
# images), reusing docker-bins.tar + arm64-deploy from the 20260716 deploy, and upload to OSS.
# Env in: ACR_USER ACR_PASS OSS_ID OSS_SECRET
set -euo pipefail
R=registry.cn-beijing.aliyuncs.com/primihub
TS="${TS:-20260718}"
PKG="primihub-offline-arm64-$TS"
SRC=/opt/ph/offline
DEST=/opt/ph/$PKG
PTAG="${PTAG:-2026.07.18}"
log(){ echo -e ">> $*"; }

log "ACR login + pull platform:$PTAG (arm64 native)"
echo "$ACR_PASS" | docker login "$R" -u "$ACR_USER" --password-stdin >/dev/null
docker pull "$R/primihub-platform:$PTAG"
docker pull "$R/primihub-web:$PTAG"

log "assemble $DEST (reuse docker-bins.tar; FRESH arm64-deploy from develop; bump .env PLATFORM tag)"
rm -rf "$DEST"; mkdir -p "$DEST"
cp "$SRC/docker-bins.tar" "$DEST/"
# arm64-deploy comes from the current develop checkout (scp'd to /opt/ph/arm64-deploy-fresh), not the stale VM copy
cp -a /opt/ph/arm64-deploy-fresh "$DEST/arm64-deploy"
sed -i -E "s#(PRIMIHUB_PLATFORM=$R/primihub-platform:).*#\1$PTAG#" "$DEST/arm64-deploy/.env"
sed -i -E "s#(PRIMIHUB_WEB_MANAGE=$R/primihub-web:).*#\1$PTAG#" "$DEST/arm64-deploy/.env"
grep -E "PRIMIHUB_(PLATFORM|WEB_MANAGE|META|NODE)=" "$DEST/arm64-deploy/.env"
ls "$DEST/arm64-deploy/data/initsql/" | grep -i zz && { echo "ERROR zz present"; exit 1; } || echo "initsql zz-free OK"

log "docker save 9 images -> images.tar"
IMAGES=(
  "$R/primihub-platform:$PTAG"
  "$R/primihub-web:$PTAG" "$R/primihub-meta:2026.07.15" "$R/primihub-node:2026.07.15"
  "$R/mariadb:10.11-arm64" "$R/redis:7-arm64" "$R/nacos-server:v2.4.3-arm64"
  "$R/rabbitmq:3.6.15-management-arm64" "$R/loki:2.9.0-arm64"
)
docker save "${IMAGES[@]}" -o "$DEST/images.tar"
ls -lh "$DEST/images.tar"

log "tar + sha256"
cd /opt/ph
tar czf "$PKG.tar.gz" "$PKG"
sha256sum "$PKG.tar.gz" | awk '{print $1}' > "$PKG.tar.gz.sha256"
ls -lh "$PKG.tar.gz"; cat "$PKG.tar.gz.sha256"

log "upload to OSS via oss2 (internal endpoint, public-read) — ossutil has no reliable arm64 binary"
pip3 install -q oss2 -i https://mirrors.aliyun.com/pypi/simple/ 2>/dev/null || pip3 install -q oss2
OSS_ID="$OSS_ID" OSS_SECRET="$OSS_SECRET" PKG="$PKG" python3 - <<'PY'
import os, oss2
b = oss2.Bucket(oss2.Auth(os.environ['OSS_ID'], os.environ['OSS_SECRET']),
                'https://oss-cn-beijing-internal.aliyuncs.com', 'primihub')
pkg = os.environ['PKG']
for fn in [pkg+'.tar.gz', pkg+'.tar.gz.sha256']:
    key = 'primihub-offline/arm64/'+fn
    b.put_object_from_file(key, fn, headers={'x-oss-object-acl':'public-read'})
    print('uploaded', key)
PY
echo "VM_BUILD_UPLOAD_DONE $PKG"
