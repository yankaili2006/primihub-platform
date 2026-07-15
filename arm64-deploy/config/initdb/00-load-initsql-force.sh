#!/bin/bash
# Robust base-schema loader for the offline package.
#
# WHY: mariadb's default init loads /docker-entrypoint-initdb.d/*.sql WITHOUT --force, so a
# transient error during the concurrent cold-start (app nodes connecting while init runs) can
# abort one file partway — e.g. privacy3 loaded only 25 of ~32 base tables, missing sys_auth,
# which then makes Flyway V2 (button perms) fail and the node crash-loop. Loading with --force
# skips such transient errors so the full schema always lands. A fail-fast guard turns a still-
# incomplete load into a visible init failure instead of a silently-broken DB.
set -u
PW="${MARIADB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"
MYSQL="mysql --force -uroot -p${PW}"
for f in nacos_config privacy1 privacy2 privacy3; do
  src="/initsql/${f}.sql"
  [ -f "$src" ] || { echo ">> skip missing $src"; continue; }
  echo ">> loading (--force) $src"
  $MYSQL < "$src"
done
# fail-fast: base schema must be complete (sys_auth present) on every privacy DB
for db in privacy1 privacy2 privacy3; do
  n=$(mysql -N -uroot -p"${PW}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${db}' AND table_name='sys_auth'" 2>/dev/null)
  if [ "$n" != "1" ]; then echo "FATAL: ${db}.sys_auth missing after load — base schema incomplete"; exit 1; fi
done
echo ">> initsql force-load complete; sys_auth present in privacy1/2/3"
