-- zz-tenant-button-perms.sql
-- 修复：租户管理 > 租户列表 缺少「新增/编辑/删除/冻结租户」按钮。
--
-- 根因：privacy1/2/3.sql 只 seed 了租户的菜单页(authType=2: Tenant/TenantList/
--   TenantResource...)，但**没有 authType=3 的按钮权限**(TenantAdd/TenantEdit/
--   TenantDelete/TenantFreeze)。前端 tenant/list.vue 的按钮用
--   `buttonPermissionList.includes('TenantAdd')` 控制显隐，而 buttonPermissionList
--   只收集用户授权树里 authType===3 的 authCode → 4 个租户按钮永远不出现。
--
-- 本迁移：在每个 privacy 库里、于已存在的 TenantList 菜单下补齐 4 个按钮权限，
--   并授予超级管理员(role_id=1)。幂等(按 auth_code NOT EXISTS 判重)，可重复执行。
--   放在 initsql 目录、zz- 前缀确保在 privacy*.sql 之后加载(全新部署自动生效)；
--   也可直接对已在运行的库执行(执行后需清 Redis 权限缓存并重新登录)。
--
-- 用纯 SQL + 每库重置会话变量(不用存储过程，避免 unqualified 表名跨 USE 解析歧义)。

-- ======================== privacy1 ========================
USE `privacy1`;
SET @tl := (SELECT auth_id   FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
SET @rt := (SELECT r_auth_id FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
SET @tlpath := (SELECT full_path FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
INSERT INTO sys_auth
  (auth_name,auth_code,auth_type,p_auth_id,r_auth_id,full_path,auth_url,data_auth_code,auth_index,auth_depth,is_show,is_editable,is_del)
SELECT * FROM (
  SELECT '新增租户' a,'TenantAdd'   b,3 c,@tl d,@rt e,'' f,'/tenant/addTenant'   g,'own' h,1 i,2 j,1 k,1 l,0 m
  UNION ALL SELECT '编辑租户','TenantEdit',  3,@tl,@rt,'','/tenant/updateTenant','own',2,2,1,1,0
  UNION ALL SELECT '删除租户','TenantDelete',3,@tl,@rt,'','/tenant/deleteTenant','own',3,2,1,1,0
  UNION ALL SELECT '冻结租户','TenantFreeze',3,@tl,@rt,'','/tenant/freezeTenant','own',4,2,1,1,0
) t
WHERE @tl IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code=t.b AND s.is_del=0);
UPDATE sys_auth SET full_path=CONCAT(@tlpath,',',auth_id)
  WHERE auth_type=3 AND is_del=0 AND auth_code IN ('TenantAdd','TenantEdit','TenantDelete','TenantFreeze')
    AND (full_path='' OR full_path IS NULL);
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, a.auth_id, 0 FROM sys_auth a
  WHERE a.is_del=0 AND a.auth_code IN ('TenantAdd','TenantEdit','TenantDelete','TenantFreeze')
    AND NOT EXISTS (SELECT 1 FROM sys_ra r WHERE r.role_id=1 AND r.auth_id=a.auth_id AND r.is_del=0);

-- ======================== privacy2 ========================
USE `privacy2`;
SET @tl := (SELECT auth_id   FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
SET @rt := (SELECT r_auth_id FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
SET @tlpath := (SELECT full_path FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
INSERT INTO sys_auth
  (auth_name,auth_code,auth_type,p_auth_id,r_auth_id,full_path,auth_url,data_auth_code,auth_index,auth_depth,is_show,is_editable,is_del)
SELECT * FROM (
  SELECT '新增租户' a,'TenantAdd'   b,3 c,@tl d,@rt e,'' f,'/tenant/addTenant'   g,'own' h,1 i,2 j,1 k,1 l,0 m
  UNION ALL SELECT '编辑租户','TenantEdit',  3,@tl,@rt,'','/tenant/updateTenant','own',2,2,1,1,0
  UNION ALL SELECT '删除租户','TenantDelete',3,@tl,@rt,'','/tenant/deleteTenant','own',3,2,1,1,0
  UNION ALL SELECT '冻结租户','TenantFreeze',3,@tl,@rt,'','/tenant/freezeTenant','own',4,2,1,1,0
) t
WHERE @tl IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code=t.b AND s.is_del=0);
UPDATE sys_auth SET full_path=CONCAT(@tlpath,',',auth_id)
  WHERE auth_type=3 AND is_del=0 AND auth_code IN ('TenantAdd','TenantEdit','TenantDelete','TenantFreeze')
    AND (full_path='' OR full_path IS NULL);
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, a.auth_id, 0 FROM sys_auth a
  WHERE a.is_del=0 AND a.auth_code IN ('TenantAdd','TenantEdit','TenantDelete','TenantFreeze')
    AND NOT EXISTS (SELECT 1 FROM sys_ra r WHERE r.role_id=1 AND r.auth_id=a.auth_id AND r.is_del=0);

-- ======================== privacy3 ========================
USE `privacy3`;
SET @tl := (SELECT auth_id   FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
SET @rt := (SELECT r_auth_id FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
SET @tlpath := (SELECT full_path FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);
INSERT INTO sys_auth
  (auth_name,auth_code,auth_type,p_auth_id,r_auth_id,full_path,auth_url,data_auth_code,auth_index,auth_depth,is_show,is_editable,is_del)
SELECT * FROM (
  SELECT '新增租户' a,'TenantAdd'   b,3 c,@tl d,@rt e,'' f,'/tenant/addTenant'   g,'own' h,1 i,2 j,1 k,1 l,0 m
  UNION ALL SELECT '编辑租户','TenantEdit',  3,@tl,@rt,'','/tenant/updateTenant','own',2,2,1,1,0
  UNION ALL SELECT '删除租户','TenantDelete',3,@tl,@rt,'','/tenant/deleteTenant','own',3,2,1,1,0
  UNION ALL SELECT '冻结租户','TenantFreeze',3,@tl,@rt,'','/tenant/freezeTenant','own',4,2,1,1,0
) t
WHERE @tl IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code=t.b AND s.is_del=0);
UPDATE sys_auth SET full_path=CONCAT(@tlpath,',',auth_id)
  WHERE auth_type=3 AND is_del=0 AND auth_code IN ('TenantAdd','TenantEdit','TenantDelete','TenantFreeze')
    AND (full_path='' OR full_path IS NULL);
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, a.auth_id, 0 FROM sys_auth a
  WHERE a.is_del=0 AND a.auth_code IN ('TenantAdd','TenantEdit','TenantDelete','TenantFreeze')
    AND NOT EXISTS (SELECT 1 FROM sys_ra r WHERE r.role_id=1 AND r.auth_id=a.auth_id AND r.is_del=0);
