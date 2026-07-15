-- =====================================================================
-- fix-d03-tenant-buttons-2026-07.sql
-- D03: 租户列表页无「新增」按钮 —— 族 B(RBAC 按钮权限种子缺失), runbook 标「类Fix2」。
--
-- 现象(docx #003): 租户管理>>租户列表, 进行租户新增, 页面无新增按钮, 无法新增。
-- 根因(同 Fix2 白名单): 前端按 buttonPermissionList.includes('TenantXxx') 的 v-if 渲染
--   增删改按钮; 部署库 sys_auth 只有租户「页面级」节点, 缺按钮级 auth_type=3 节点
--   + 未授权 super admin(role_id=1) → 按钮不渲染。(注: API 本身不受此限, 只是前端隐藏按钮。)
--
-- ⚠️ 状态: **离线产出, 未在真实 DB/前端验证**(平台当前不可达)。见下方 ASSUMPTIONS。
-- ✅ 安全性: 自发现租户「页面级」节点; 若找不到则整体 no-op, 绝不误插/误改无关行。
--            即使按钮 auth_code 猜错, 也只是按钮仍不渲染(补丁无害), 不会破坏任何数据。
--
-- 幂等: sys_auth 用 ON DUPLICATE KEY, sys_ra 用 NOT EXISTS。可重复运行。
--
-- ─────────────────────────────────────────────────────────────────────
-- ASSUMPTIONS —— apply 前对真库/前端各验一次(有平台时 30 秒可确认):
--  (1) 前端渲染按钮用的 code = 'TenantAdd' / 'TenantEdit' / 'TenantDelete'
--      (类比白名单 'WhitelistAdd/Edit/Delete')。验证: 看租户页 .vue 的
--      v-if="buttonPermissionList.includes('...')" 实际字符串; 不同则改下方 VALUES 的 auth_code。
--  (2) 租户「页面级」节点(auth_type=2)可由 auth_code∈{TenantList,Tenant,TenantManage}
--      或 auth_url LIKE '%tenant%' 命中。验证: SELECT auth_id,auth_code,auth_url,full_path
--      FROM fusion0.sys_auth WHERE auth_type=2 AND auth_url LIKE '%tenant%';
--  auth_url 已从 skill crud.py SPECS['03'] 确认无误:
--      新增=/tenant/addTenant  编辑=/tenant/updateTenant  删除=/tenant/deleteTenant
--
-- 冲突预检(可选, 确认 9520-9522 未被占用):
--   SELECT auth_id,auth_code FROM fusion0.sys_auth WHERE auth_id IN (9520,9521,9522);
--   (若已被无关节点占用, 改本文件里的 9520/9521/9522 到空闲段。)
--
-- 数据源(见 Fix5): 按钮种子写「读」库。Fix5 后 primary=fusion, sys_* 读走 fusion{N},
--   故种子写 fusion{N}(渲染据此)+ privacy{N}(写侧对齐)。
--
-- 应用后必须清 auth 树缓存, 重新登录才见按钮:
--   docker exec redis redis-cli -a primihub --no-auth-warning DEL sys_auth:bfs_list
-- =====================================================================

DELIMITER $$
DROP PROCEDURE IF EXISTS _phf_seed_tenant_btn $$
CREATE PROCEDURE _phf_seed_tenant_btn(IN db VARCHAR(64))
BEGIN
  DECLARE has_tbl INT DEFAULT 0;
  SELECT COUNT(*) INTO has_tbl FROM information_schema.tables
    WHERE table_schema = db AND table_name = 'sys_auth';

  IF has_tbl > 0 THEN
    -- 自发现租户页面级节点 → @p(auth_id) / @rr(root r_auth_id) / @fp(full_path)
    SET @p := NULL; SET @rr := NULL; SET @fp := NULL;
    SET @qsel := CONCAT(
      'SELECT auth_id, r_auth_id, full_path INTO @p, @rr, @fp FROM `', db, '`.sys_auth ',
      'WHERE is_del = 0 AND auth_type = 2 AND (',
      "  auth_code IN ('TenantList','Tenant','TenantManage')",
      "  OR auth_url LIKE '%tenant/list%' OR auth_url LIKE '%/tenant%'",
      ') ORDER BY auth_id LIMIT 1');
    PREPARE s1 FROM @qsel; EXECUTE s1; DEALLOCATE PREPARE s1;

    IF @p IS NOT NULL THEN
      -- 3 个按钮级节点(auth_type=3), 挂在发现到的页面节点下; full_path = 页节点 full_path + 按钮id
      SET @qins := CONCAT(
        'INSERT INTO `', db, '`.sys_auth ',
        '(auth_id,auth_name,auth_code,auth_type,p_auth_id,r_auth_id,full_path,auth_url,',
        ' data_auth_code,auth_index,auth_depth,is_show,is_editable,is_del,c_time,u_time) VALUES ',
        "(9520,'租户新增','TenantAdd',3,@p,@rr,CONCAT(@fp,',9520'),'/tenant/addTenant','own',1,2,1,0,0,NOW(3),NOW(3)),",
        "(9521,'租户编辑','TenantEdit',3,@p,@rr,CONCAT(@fp,',9521'),'/tenant/updateTenant','own',2,2,1,0,0,NOW(3),NOW(3)),",
        "(9522,'租户删除','TenantDelete',3,@p,@rr,CONCAT(@fp,',9522'),'/tenant/deleteTenant','own',3,2,1,0,0,NOW(3),NOW(3)) ",
        'ON DUPLICATE KEY UPDATE auth_code=VALUES(auth_code),auth_type=VALUES(auth_type),',
        ' p_auth_id=VALUES(p_auth_id),r_auth_id=VALUES(r_auth_id),full_path=VALUES(full_path),',
        ' is_del=0,u_time=NOW(3)');
      PREPARE s2 FROM @qins; EXECUTE s2; DEALLOCATE PREPARE s2;

      -- 授权 super admin(role_id=1), 幂等
      SET @qra := CONCAT(
        'INSERT INTO `', db, '`.sys_ra (role_id,auth_id,is_del,c_time,u_time) ',
        'SELECT 1, x.aid, 0, NOW(3), NOW(3) FROM ',
        '(SELECT 9520 aid UNION SELECT 9521 UNION SELECT 9522) x ',
        'WHERE NOT EXISTS (SELECT 1 FROM `', db, '`.sys_ra r ',
        ' WHERE r.role_id=1 AND r.auth_id=x.aid AND r.is_del=0)');
      PREPARE s3 FROM @qra; EXECUTE s3; DEALLOCATE PREPARE s3;
    END IF;
  END IF;
END $$
DELIMITER ;

-- 三机构读侧 fusion{N} + 写侧 privacy{N}(缺表/缺页节点者自动跳过)
CALL _phf_seed_tenant_btn('fusion0');  CALL _phf_seed_tenant_btn('privacy0');
CALL _phf_seed_tenant_btn('fusion1');  CALL _phf_seed_tenant_btn('privacy1');
CALL _phf_seed_tenant_btn('fusion2');  CALL _phf_seed_tenant_btn('privacy2');

DROP PROCEDURE IF EXISTS _phf_seed_tenant_btn;

-- 回滚: 按 auth_id 删种子
--   DELETE FROM <db>.sys_ra   WHERE auth_id IN (9520,9521,9522) AND role_id=1;
--   DELETE FROM <db>.sys_auth WHERE auth_id IN (9520,9521,9522);
