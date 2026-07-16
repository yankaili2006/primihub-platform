#!/usr/bin/env bash
# Reproducibly regenerate arm64-deploy/data/initsql/privacy{1,2,3}.sql = the COMPLETE schema.
# Flyway was removed; the base dump now owns the full schema. This script documents how the
# complete dump was produced from the old base + the (now-deleted) V2..V14 migration content,
# plus test-tools/dump-fixup.sql for drift the migrations never covered.
#
# NOTE: the V2..V14 migration files were deleted when Flyway was removed. To re-run this from
# scratch, recover them from git history (the commit before Flyway removal) into $MIG.
# Kept for provenance / future one-off schema edits (edit dump-fixup.sql, re-run, commit dumps).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
INIT="$ROOT/arm64-deploy/data/initsql"
FIXUP="$ROOT/test-tools/dump-fixup.sql"
MIG="${MIG:-/tmp/flyway-migrations}"   # dir holding V*.sql recovered from history (optional)

docker rm -f regen-maria >/dev/null 2>&1 || true
docker run -d --name regen-maria -e MYSQL_ROOT_PASSWORD=root mariadb:10.11 >/dev/null
for i in $(seq 1 60); do docker exec regen-maria mariadb -uroot -proot -e "SELECT 1" >/dev/null 2>&1 && break; sleep 2; done

for N in 1 2 3; do
  docker cp "$INIT/privacy$N.sql" regen-maria:/tmp/base.sql
  docker exec regen-maria sh -c 'mariadb -uroot -proot --force < /tmp/base.sql' 2>&1 | grep -iE error | grep -viE "GRANT|matching row|user table" || true
  if [ -d "$MIG" ]; then
    for f in $(ls "$MIG"/V*.sql 2>/dev/null | sort -V); do
      docker cp "$f" regen-maria:/tmp/m.sql; docker exec regen-maria sh -c 'mariadb -uroot -proot privacy'$N' < /tmp/m.sql' 2>&1 | grep -i error || true
    done
  fi
  docker cp "$FIXUP" regen-maria:/tmp/fixup.sql
  docker exec regen-maria sh -c 'mariadb -uroot -proot privacy'$N' < /tmp/fixup.sql' 2>&1 | grep -i error || true
  {
    echo "-- Complete schema (base + folded migrations + dump-fixup, Flyway removed). MariaDB 10.11."
    echo "SET FOREIGN_KEY_CHECKS=0;"
    docker exec regen-maria mariadb-dump -uroot -proot --databases "privacy$N" "fusion$N" \
      --add-drop-database --skip-lock-tables --single-transaction --default-character-set=utf8
    echo "SET FOREIGN_KEY_CHECKS=1;"
    grep -hE "GRANT ALL ON \*\.\* TO 'primihub'" "$INIT/privacy$N.sql" | head -1
  } > "$INIT/privacy$N.sql"
  echo "regenerated privacy$N.sql: $(docker exec regen-maria mariadb -uroot -proot -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='privacy$N'") tables"
  docker exec regen-maria mariadb -uroot -proot -e "DROP DATABASE privacy$N; DROP DATABASE fusion$N" 2>/dev/null || true
done
docker rm -f regen-maria >/dev/null 2>&1 || true
