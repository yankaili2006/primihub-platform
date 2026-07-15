-- V2__button_perms.sql — comprehensive frontend button permissions (authType=3) + grant to super-admin.
-- Flyway runs this in the connected schema (privacy* on arm64, fusion* on prod) — NO `USE`.
-- Fixes v1.8.0 buttons not rendering: frontend buttonPermissionList = authType===3 authCodes in the
-- user's auth tree; deployment base dump seeds only menu/page-unlock (authType=2). Idempotent.
DROP TEMPORARY TABLE IF EXISTS _btn_map;
CREATE TEMPORARY TABLE _btn_map(nm VARCHAR(64),code VARCHAR(64),url VARCHAR(255),pcode VARCHAR(64),idx INT,
  pid BIGINT DEFAULT NULL, prid BIGINT DEFAULT NULL, pfull VARCHAR(255) DEFAULT NULL);
INSERT INTO _btn_map(nm,code,url,pcode,idx) VALUES
 ('删除资源','ResourceDelete','/data/resource/deldataresource','ResourceList',11),
 ('编辑资源','ResourceEdit','/data/resource/saveorupdateresource','ResourceList',12),
 ('联合资源详情','UnionResourceDetail','/data/resource/getResourceDetail','ResourceList',13),
 ('创建模型','ModelCreate','/model/create','ModelList',11),
 ('项目详情','ProjectDetail','/project/getProjectDetails','ProjectList',11),
 ('冻结用户','UserFreeze','/sys/user/freezeUser','DM01',15),
 ('新增白名单','WhitelistAdd','/whitelist/addWhitelist','WhitelistList',11),
 ('编辑白名单','WhitelistEdit','/whitelist/updateWhitelist','WhitelistList',12),
 ('编辑白名单配置','WhitelistConfigEdit','/whitelist/saveWhitelistConfig','WhitelistConfig',11),
 ('新增租户','TenantAdd','/tenant/addTenant','TenantList',11),
 ('编辑租户','TenantEdit','/tenant/updateTenant','TenantList',12),
 ('删除租户','TenantDelete','/tenant/deleteTenant','TenantList',13),
 ('冻结租户','TenantFreeze','/tenant/freezeTenant','TenantList',14);
-- resolve parent menu into the temp table (sys_auth only in subquery -> allowed under the UPDATE)
UPDATE _btn_map m SET
  m.pid  =(SELECT auth_id   FROM sys_auth p WHERE p.auth_code=m.pcode AND p.is_del=0 LIMIT 1),
  m.prid =(SELECT r_auth_id FROM sys_auth p WHERE p.auth_code=m.pcode AND p.is_del=0 LIMIT 1),
  m.pfull=(SELECT full_path FROM sys_auth p WHERE p.auth_code=m.pcode AND p.is_del=0 LIMIT 1);
-- insert missing authType=3 buttons under resolved parent menu
INSERT INTO sys_auth (auth_name,auth_code,auth_type,p_auth_id,r_auth_id,full_path,auth_url,data_auth_code,auth_index,auth_depth,is_show,is_editable,is_del)
SELECT m.nm, m.code, 3, m.pid, m.prid, '', m.url, 'own', m.idx, 2, 1, 1, 0
FROM _btn_map m
WHERE m.pid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code=m.code AND s.auth_type=3 AND s.is_del=0);
-- set full_path via join to temp (no sys_auth self-subquery -> avoids MySQL error 1093)
UPDATE sys_auth b JOIN _btn_map m ON b.auth_code=m.code AND b.auth_type=3 AND b.is_del=0
  SET b.full_path = CONCAT(m.pfull, ',', b.auth_id)
  WHERE (b.full_path='' OR b.full_path IS NULL) AND m.pfull IS NOT NULL;
DROP TEMPORARY TABLE IF EXISTS _btn_map;
-- grant ALL 32 frontend button codes to super-admin role 1 (idempotent)
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, a.auth_id, 0 FROM sys_auth a
 WHERE a.is_del=0 AND a.auth_type=3 AND a.auth_code IN (
  'copyModelTask','deleteModelTask','ModelCreate','ModelEdit','ModelResultDownload','ModelRun',
  'ModelTaskHistory','ModelView','openProject','PrivateSearchButton','ProjectCreate','ProjectDelete',
  'ProjectDetail','ResourceDelete','ResourceEdit','RoleAdd','RoleDelete','RoleEdit','TenantAdd',
  'TenantDelete','TenantEdit','TenantFreeze','UnionResourceDetail','UserAdd','UserDelete','UserEdit',
  'UserFreeze','UserPasswordReset','WhitelistAdd','WhitelistConfigEdit','WhitelistDelete','WhitelistEdit')
 AND NOT EXISTS (SELECT 1 FROM sys_ra r WHERE r.role_id=1 AND r.auth_id=a.auth_id AND r.is_del=0);
