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

# ---------------------------------------------------------------------------
# demand 菜单死链修正 (根治): menu-gen 里未命中 namemap 的 type=2 菜单 auth_url
# 回退成 /demand/mXX/fYYY，前端无对应命名路由 → 侧边栏点开报"该功能模块系统不存在"。
# 这里在灌库后按名称语义把它们重映射到真实前端路由（与 pcloud
# docs/patches/fix-menu-urls.sql 一致），并隐藏调试用「前端可用页面解锁」菜单。
# 幂等：只命中仍是 /demand 死链的行，已修库上 = no-op。init 阶段执行，后端首次
# 缓存 sys_auth 时读到的即为修正后菜单，无需清 redis。
# ---------------------------------------------------------------------------
for db in privacy1 privacy2 privacy3; do
  echo ">> fixing dead-link demand menus in ${db}"
  $MYSQL "${db}" <<'MENUFIX'
UPDATE `sys_auth` SET `auth_url`='/whitelist'         WHERE `auth_url` LIKE '/demand/%' AND `is_show`=1 AND `auth_type`=2 AND `auth_name` LIKE '%白名单%';
UPDATE `sys_auth` SET `auth_url`='/tenant'            WHERE `auth_url` LIKE '/demand/%' AND `is_show`=1 AND `auth_type`=2 AND `auth_name` LIKE '%租户%';
UPDATE `sys_auth` SET `auth_url`='/resource'          WHERE `auth_url` LIKE '/demand/%' AND `is_show`=1 AND `auth_type`=2 AND (`auth_name` LIKE '%数据源%' OR `auth_name` LIKE '%数据集%');
UPDATE `sys_auth` SET `auth_url`='/federatedQuery'    WHERE `auth_url` LIKE '/demand/%' AND `is_show`=1 AND `auth_type`=2 AND `auth_name` LIKE '%联邦查询%';
UPDATE `sys_auth` SET `auth_url`='/federatedAnalysis' WHERE `auth_url` LIKE '/demand/%' AND `is_show`=1 AND `auth_type`=2 AND `auth_name` LIKE '%联邦分析%';
UPDATE `sys_auth` SET `auth_url`='/setting/center'    WHERE `auth_id` IN (20903,20905);
UPDATE `sys_auth` SET `auth_name`='联邦求差日志记录', `auth_url`='/Difference/list' WHERE `auth_id`=21320;
UPDATE `sys_auth` SET `is_show`=0 WHERE `auth_id`=26000 OR `full_path` LIKE '26000,%';
MENUFIX
  dead=$(mysql -N -uroot -p"${PW}" "${db}" -e "SELECT COUNT(*) FROM sys_auth WHERE auth_url LIKE '/demand/%' AND is_show=1 AND auth_type=2" 2>/dev/null)
  echo ">> ${db}: remaining dead-link type2 menus = ${dead} (expect 0)"
done
echo ">> demand menu url fix complete"
