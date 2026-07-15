-- =====================================================================
-- fix-zz-crud-2026-07.sql — CRUD 增删改硬化迁移
-- 固化「用户/角色/租户 增删改」相关平台修复（详见 platform-fixes-runbook.md）。
--
-- 安装：放到部署 kit 根目录（与其它 fix-*.sql 同级）。deploy.sh 调用 migrate-db.sh，
--       它 `for sql_file in fix-*.sql`（字母序）逐个 `mysql < file` 应用。文件名
--       fix-zz- 保证在 fix-v1.6.0-sync-permissions.sql（建/灌 fusion{N}.sys_*）之后跑，
--       此时 privacy{N} 与 fusion{N} 的 sys_*/tenant 表都已存在。
--
-- 覆盖：Fix 3 sys_user.first_login；Fix 4 tenant_isolation_config 配额列；
--       Fix 2 白名单按钮级权限节点 WhitelistAdd/Edit/Delete + 授权 super admin。
--
-- 幂等 & 健壮：列的增加走存储过程 _phf_add_col（先判表存在+列不存在再 ALTER），
--       所以任何语句都不会报错、不会因 `mysql < file` 首个错误而中断后续；权限种子
--       用 ON DUPLICATE KEY / NOT EXISTS。全新部署与重复运行都安全。
-- =====================================================================

-- 存储过程需要一个当前库来承载（它们内部用全限定名操作各库，最后即删）。
-- fusion0 由 init SQL 建好、必然存在。
USE fusion0;

DROP PROCEDURE IF EXISTS _phf_add_col;
DELIMITER $$
CREATE PROCEDURE _phf_add_col(IN db VARCHAR(64), IN tbl VARCHAR(64), IN col VARCHAR(64), IN defn TEXT)
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables  WHERE table_schema=db AND table_name=tbl)
 AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=db AND table_name=tbl AND column_name=col) THEN
    SET @s = CONCAT('ALTER TABLE `',db,'`.`',tbl,'` ADD COLUMN `',col,'` ',defn);
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
DELIMITER ;

-- ---- Fix 3: sys_user.first_login（privacy{N} 写侧 + fusion{N} 读侧）----
CALL _phf_add_col('privacy0','sys_user','first_login',"TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)'");
CALL _phf_add_col('fusion0','sys_user','first_login',"TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)'");
CALL _phf_add_col('privacy1','sys_user','first_login',"TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)'");
CALL _phf_add_col('fusion1','sys_user','first_login',"TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)'");
CALL _phf_add_col('privacy2','sys_user','first_login',"TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)'");
CALL _phf_add_col('fusion2','sys_user','first_login',"TINYINT(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)'");

-- ---- Fix 4: tenant_isolation_config 配额列（canonical: script/tenant.sql）----
-- 每库 8 列；用循环式 CALL（每列独立判存在）
DROP PROCEDURE IF EXISTS _phf_tenant_cols;
DELIMITER $$
CREATE PROCEDURE _phf_tenant_cols(IN db VARCHAR(64))
BEGIN
  CALL _phf_add_col(db,'tenant_isolation_config','cpu_quota',"INT(11) DEFAULT 0 COMMENT 'CPU配额（核）'");
  CALL _phf_add_col(db,'tenant_isolation_config','memory_quota',"INT(11) DEFAULT 0 COMMENT '内存配额（GB）'");
  CALL _phf_add_col(db,'tenant_isolation_config','storage_quota',"INT(11) DEFAULT 0 COMMENT '存储配额（GB）'");
  CALL _phf_add_col(db,'tenant_isolation_config','dataset_limit',"INT(11) DEFAULT 0 COMMENT '数据集数量限制'");
  CALL _phf_add_col(db,'tenant_isolation_config','model_limit',"INT(11) DEFAULT 0 COMMENT '模型数量限制'");
  CALL _phf_add_col(db,'tenant_isolation_config','concurrent_tasks',"INT(11) DEFAULT 10 COMMENT '并发任务数'");
  CALL _phf_add_col(db,'tenant_isolation_config','network_isolation',"TINYINT(1) DEFAULT 0 COMMENT '网络隔离'");
  CALL _phf_add_col(db,'tenant_isolation_config','namespace',"VARCHAR(100) DEFAULT NULL COMMENT '命名空间'");
END$$
DELIMITER ;
CALL _phf_tenant_cols('privacy0'); CALL _phf_tenant_cols('fusion0');
CALL _phf_tenant_cols('privacy1'); CALL _phf_tenant_cols('fusion1');
CALL _phf_tenant_cols('privacy2'); CALL _phf_tenant_cols('fusion2');

DROP PROCEDURE IF EXISTS _phf_tenant_cols;

-- ---- Fix 2: 白名单按钮级权限节点 + 授权 super admin(role_id=1) ----
-- 节点挂在页面节点 1112(WhitelistList) 下；种子写 fusion{N}(读侧,按钮据此渲染) + privacy{N}(写侧)。
-- 幂等：sys_auth 用 ON DUPLICATE KEY，sys_ra 用 NOT EXISTS。
-- 用存储过程对每库统一 seed，避免某库缺表时中断后续。
DROP PROCEDURE IF EXISTS _phf_wl_perm;
DELIMITER $$
CREATE PROCEDURE _phf_wl_perm(IN db VARCHAR(64))
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema=db AND table_name='sys_auth') THEN
    SET @a = CONCAT('INSERT INTO `',db,'`.sys_auth (auth_id,auth_name,auth_code,auth_type,p_auth_id,r_auth_id,full_path,auth_url,data_auth_code,auth_index,auth_depth,is_show,is_editable,is_del,c_time,u_time) VALUES ',
      '(9510,''白名单新增'',''WhitelistAdd'',3,1112,1111,''1111,1112,9510'',''/whitelist/addWhitelist'',''own'',1,2,1,0,0,NOW(3),NOW(3)),',
      '(9511,''白名单编辑'',''WhitelistEdit'',3,1112,1111,''1111,1112,9511'',''/whitelist/updateWhitelist'',''own'',2,2,1,0,0,NOW(3),NOW(3)),',
      '(9512,''白名单删除'',''WhitelistDelete'',3,1112,1111,''1111,1112,9512'',''/whitelist/deleteWhitelist'',''own'',3,2,1,0,0,NOW(3),NOW(3)) ',
      'ON DUPLICATE KEY UPDATE auth_code=VALUES(auth_code),auth_type=VALUES(auth_type),p_auth_id=VALUES(p_auth_id),is_del=0');
    PREPARE s1 FROM @a; EXECUTE s1; DEALLOCATE PREPARE s1;
    SET @r = CONCAT('INSERT INTO `',db,'`.sys_ra (role_id,auth_id,is_del,c_time,u_time) ',
      'SELECT 1,x.aid,0,NOW(3),NOW(3) FROM (SELECT 9510 aid UNION SELECT 9511 UNION SELECT 9512) x ',
      'WHERE NOT EXISTS (SELECT 1 FROM `',db,'`.sys_ra r WHERE r.role_id=1 AND r.auth_id=x.aid AND r.is_del=0)');
    PREPARE s2 FROM @r; EXECUTE s2; DEALLOCATE PREPARE s2;
  END IF;
END$$
DELIMITER ;
CALL _phf_wl_perm('fusion0');  CALL _phf_wl_perm('privacy0');
CALL _phf_wl_perm('fusion1');  CALL _phf_wl_perm('privacy1');
CALL _phf_wl_perm('fusion2');  CALL _phf_wl_perm('privacy2');
DROP PROCEDURE IF EXISTS _phf_wl_perm;

-- ---- Fix (Group D #10): sys_compute_log schema drift（mapper 选了表里没有的列 → 查询失败/导出0字节）----
DROP PROCEDURE IF EXISTS _phf_clog;
DELIMITER $$
CREATE PROCEDURE _phf_clog(IN db VARCHAR(64))
BEGIN
  CALL _phf_add_col(db,'sys_compute_log','log_code',"VARCHAR(64) DEFAULT NULL");
  CALL _phf_add_col(db,'sys_compute_log','project_id',"BIGINT(20) DEFAULT NULL");
  CALL _phf_add_col(db,'sys_compute_log','project_name',"VARCHAR(255) DEFAULT NULL");
  CALL _phf_add_col(db,'sys_compute_log','organ_name',"VARCHAR(255) DEFAULT NULL");
  CALL _phf_add_col(db,'sys_compute_log','execution_time',"BIGINT(20) DEFAULT NULL");
  CALL _phf_add_col(db,'sys_compute_log','error_msg',"VARCHAR(1000) DEFAULT NULL");
END$$
DELIMITER ;
CALL _phf_clog('privacy0'); CALL _phf_clog('fusion0');
CALL _phf_clog('privacy1'); CALL _phf_clog('fusion1');
CALL _phf_clog('privacy2'); CALL _phf_clog('fusion2');
DROP PROCEDURE IF EXISTS _phf_clog;
DROP PROCEDURE IF EXISTS _phf_add_col;

-- ---- Fix (bug ②): 对齐 privacy{N}.data_requirement 列类型到代码/fusion ----
-- init SQL 把 privacy{N}.data_requirement 的 requirement_type 建成 INT、organ_id 建成
-- VARCHAR，与 PO(requirementType:String, organId:Long) 及 fusion{N}(正确) 不符。
-- 该表在 privacy{N} 上应用不写(Fix5 后 primary=fusion)，故为空、MODIFY 安全且幂等。
DROP PROCEDURE IF EXISTS _phf_align_datareq;
DELIMITER $$
CREATE PROCEDURE _phf_align_datareq(IN db VARCHAR(64))
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema=db AND table_name='data_requirement') THEN
    SET @s = CONCAT('ALTER TABLE `',db,'`.data_requirement ',
      'MODIFY requirement_name varchar(128), MODIFY requirement_type varchar(32), ',
      'MODIFY data_format varchar(32), MODIFY priority tinyint(4), MODIFY status tinyint(4), ',
      'MODIFY user_name varchar(64), MODIFY organ_id bigint(20), MODIFY organ_name varchar(128), ',
      'MODIFY remark varchar(500), MODIFY is_del tinyint(4)');
    PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  END IF;
END$$
DELIMITER ;
CALL _phf_align_datareq('privacy0'); CALL _phf_align_datareq('privacy1'); CALL _phf_align_datareq('privacy2');
DROP PROCEDURE IF EXISTS _phf_align_datareq;

-- ---- Fix (Group G 假请求成功): 共享数据集 shared_dataset 真实建表 ----
-- 原 SharedDatasetService 是 static 内存 mock（5 条硬编码示例 + 增删改不落库、报"请求成功"）。
-- 改为真 DB 持久化需要这张表（读写侧 = fusion{N}，Fix5 后 primary=secondary=fusion）。
DROP PROCEDURE IF EXISTS _phf_shared_dataset;
DELIMITER $
CREATE PROCEDURE _phf_shared_dataset(IN db VARCHAR(64))
BEGIN
  SET @s = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.shared_dataset (',
    '`id` bigint(20) NOT NULL AUTO_INCREMENT,',
    '`dataset_code` varchar(64) DEFAULT NULL,`dataset_name` varchar(128) DEFAULT NULL,',
    '`dataset_desc` varchar(500) DEFAULT NULL,`data_type` varchar(32) DEFAULT NULL,',
    '`data_format` varchar(32) DEFAULT NULL,`data_fields` varchar(1000) DEFAULT NULL,',
    '`data_volume` bigint(20) DEFAULT NULL,`share_status` tinyint(4) DEFAULT 0,',
    '`share_scope` tinyint(4) DEFAULT 0,`target_organ_ids` varchar(500) DEFAULT NULL,',
    '`resource_id` bigint(20) DEFAULT NULL,`resource_name` varchar(128) DEFAULT NULL,',
    '`usage_terms` varchar(500) DEFAULT NULL,`user_id` bigint(20) DEFAULT NULL,',
    '`user_name` varchar(64) DEFAULT NULL,`organ_id` bigint(20) DEFAULT NULL,',
    '`organ_name` varchar(128) DEFAULT NULL,`start_date` datetime DEFAULT NULL,',
    '`end_date` datetime DEFAULT NULL,`remark` varchar(500) DEFAULT NULL,',
    '`is_del` tinyint(4) DEFAULT 0,`create_date` datetime DEFAULT CURRENT_TIMESTAMP,',
    '`update_date` datetime DEFAULT CURRENT_TIMESTAMP,',
    'PRIMARY KEY (`id`),KEY `idx_code` (`dataset_code`),KEY `idx_organ` (`organ_id`)',
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''共享数据集''');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
END$
DELIMITER ;
CALL _phf_shared_dataset('fusion0'); CALL _phf_shared_dataset('fusion1'); CALL _phf_shared_dataset('fusion2');
DROP PROCEDURE IF EXISTS _phf_shared_dataset;

-- ---- Fix (Group H 项目台账): project_ledger_export 导出记录表 ----
-- 项目台账列表/详情是对 data_project 的聚合只读视图(无需新表)；导出历史需这张记录表。
DROP PROCEDURE IF EXISTS _phf_ledger_export;
DELIMITER $
CREATE PROCEDURE _phf_ledger_export(IN db VARCHAR(64))
BEGIN
  SET @s = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.project_ledger_export (',
    '`export_id` bigint(20) NOT NULL AUTO_INCREMENT,',
    '`export_type` varchar(16) DEFAULT NULL,`export_format` varchar(16) DEFAULT NULL,',
    '`project_count` int(11) DEFAULT 0,`project_ids` varchar(4000) DEFAULT NULL,',
    '`export_status` tinyint(4) DEFAULT 1,`export_user_id` bigint(20) DEFAULT NULL,',
    '`export_user_name` varchar(64) DEFAULT NULL,`file_name` varchar(255) DEFAULT NULL,',
    '`file_content` mediumtext,`error_msg` varchar(500) DEFAULT NULL,',
    '`export_date` datetime DEFAULT CURRENT_TIMESTAMP,`is_del` tinyint(4) DEFAULT 0,',
    'PRIMARY KEY (`export_id`),KEY `idx_user` (`export_user_id`)',
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''项目台账导出记录''');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
END$
DELIMITER ;
CALL _phf_ledger_export('fusion0'); CALL _phf_ledger_export('fusion1'); CALL _phf_ledger_export('fusion2');
DROP PROCEDURE IF EXISTS _phf_ledger_export;

-- ---- Fix (Group H 项目结果管理): project_result + project_result_config 建表 ----
-- /project/result/* 原后端全缺整页 404。结果保存是真实实体存储 + 一份保存配置。
DROP PROCEDURE IF EXISTS _phf_project_result;
DELIMITER $
CREATE PROCEDURE _phf_project_result(IN db VARCHAR(64))
BEGIN
  SET @s = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.project_result (',
    '`id` bigint(20) NOT NULL AUTO_INCREMENT,',
    '`project_id` varchar(141) DEFAULT NULL,`project_name` varchar(255) DEFAULT NULL,',
    '`task_id` varchar(141) DEFAULT NULL,`task_name` varchar(255) DEFAULT NULL,',
    '`result_type` varchar(32) DEFAULT NULL,`result_name` varchar(255) DEFAULT NULL,',
    '`result_desc` varchar(500) DEFAULT NULL,`save_status` tinyint(4) DEFAULT 0,',
    '`file_size` bigint(20) DEFAULT NULL,`file_md5` varchar(64) DEFAULT NULL,',
    '`save_path` varchar(500) DEFAULT NULL,`save_directory` varchar(255) DEFAULT NULL,',
    '`file_name` varchar(255) DEFAULT NULL,`save_format` varchar(32) DEFAULT NULL,',
    '`file_content` mediumtext,`remark` varchar(500) DEFAULT NULL,',
    '`user_id` bigint(20) DEFAULT NULL,`organ_id` varchar(64) DEFAULT NULL,',
    '`create_date` datetime DEFAULT CURRENT_TIMESTAMP,`save_date` datetime DEFAULT NULL,',
    '`is_del` tinyint(4) DEFAULT 0,',
    'PRIMARY KEY (`id`),KEY `idx_project` (`project_id`),KEY `idx_status` (`save_status`)',
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''项目结果保存''');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  SET @c = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.project_result_config (',
    '`id` bigint(20) NOT NULL,`default_path` varchar(255) DEFAULT ''/data/results'',',
    '`auto_save` tinyint(4) DEFAULT 0,`retention_days` int(11) DEFAULT 30,',
    '`max_storage_gb` int(11) DEFAULT 100,`update_date` datetime DEFAULT CURRENT_TIMESTAMP,',
    'PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''项目结果保存配置''');
  PREPARE st2 FROM @c; EXECUTE st2; DEALLOCATE PREPARE st2;
END$
DELIMITER ;
CALL _phf_project_result('fusion0'); CALL _phf_project_result('fusion1'); CALL _phf_project_result('fusion2');
DROP PROCEDURE IF EXISTS _phf_project_result;

-- ---- Fix (Group H 项目权限): project_permission + project_permission_template 建表 ----
-- /project/permission/* 原后端全缺整页 404。权限记录(授权/审批/撤销) + 权限模板两个实体。
DROP PROCEDURE IF EXISTS _phf_project_permission;
DELIMITER $
CREATE PROCEDURE _phf_project_permission(IN db VARCHAR(64))
BEGIN
  SET @s = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.project_permission (',
    '`id` bigint(20) NOT NULL AUTO_INCREMENT,',
    '`project_id` varchar(141) DEFAULT NULL,`project_name` varchar(255) DEFAULT NULL,',
    '`organ_id` varchar(64) DEFAULT NULL,`organ_name` varchar(255) DEFAULT NULL,',
    '`permission_type` varchar(32) DEFAULT NULL,`permission_status` tinyint(4) DEFAULT 0,',
    '`template_id` bigint(20) DEFAULT NULL,`resource_ids` varchar(2000) DEFAULT NULL,',
    '`grant_date` datetime DEFAULT NULL,`expire_date` datetime DEFAULT NULL,',
    '`grant_user_id` bigint(20) DEFAULT NULL,`grant_user_name` varchar(64) DEFAULT NULL,',
    '`revoke_user_id` bigint(20) DEFAULT NULL,`revoke_user_name` varchar(64) DEFAULT NULL,',
    '`remark` varchar(500) DEFAULT NULL,`is_del` tinyint(4) DEFAULT 0,',
    '`create_date` datetime DEFAULT CURRENT_TIMESTAMP,`update_date` datetime DEFAULT CURRENT_TIMESTAMP,',
    'PRIMARY KEY (`id`),KEY `idx_project` (`project_id`),KEY `idx_status` (`permission_status`)',
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''项目权限''');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  SET @t = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.project_permission_template (',
    '`id` bigint(20) NOT NULL AUTO_INCREMENT,`template_name` varchar(255) DEFAULT NULL,',
    '`template_desc` varchar(500) DEFAULT NULL,`permissions` varchar(255) DEFAULT NULL,',
    '`create_user_id` bigint(20) DEFAULT NULL,`is_del` tinyint(4) DEFAULT 0,',
    '`create_date` datetime DEFAULT CURRENT_TIMESTAMP,`update_date` datetime DEFAULT CURRENT_TIMESTAMP,',
    'PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''项目权限模板''');
  PREPARE st2 FROM @t; EXECUTE st2; DEALLOCATE PREPARE st2;
END$
DELIMITER ;
CALL _phf_project_permission('fusion0'); CALL _phf_project_permission('fusion1'); CALL _phf_project_permission('fusion2');
DROP PROCEDURE IF EXISTS _phf_project_permission;

-- ---- Fix (Group H 单方作业): sp_ext_task + sp_ext_log 建表 ----
-- 单方作业 MAIN 任务(createTask/getTaskList/...)后端已有(用 single_party/single_party_task)。
-- 缺的是 preprocess/script/log 三块 → 整页部分 404。这里补它们用的独立表(不碰已有 single_party_task)。
DROP PROCEDURE IF EXISTS _phf_sp_ext;
DELIMITER $$
CREATE PROCEDURE _phf_sp_ext(IN db VARCHAR(64))
BEGIN
  SET @s = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.sp_ext_task (',
    '`id` bigint(20) NOT NULL AUTO_INCREMENT,`task_id` varchar(141) DEFAULT NULL,',
    '`task_name` varchar(255) DEFAULT NULL,`task_category` varchar(16) DEFAULT ''PREPROCESS'',',
    '`algorithm_type` int(11) DEFAULT NULL,`sub_type` varchar(32) DEFAULT NULL,',
    '`resource_id` varchar(141) DEFAULT NULL,`resource_name` varchar(255) DEFAULT NULL,',
    '`params` text,`task_state` tinyint(4) DEFAULT 0,`progress` int(11) DEFAULT 0,',
    '`result_content` mediumtext,`result_path` varchar(500) DEFAULT NULL,',
    '`error_msg` varchar(1000) DEFAULT NULL,`remark` varchar(500) DEFAULT NULL,',
    '`user_id` bigint(20) DEFAULT NULL,`user_name` varchar(64) DEFAULT NULL,',
    '`organ_id` varchar(64) DEFAULT NULL,`create_date` datetime DEFAULT CURRENT_TIMESTAMP,',
    '`start_time` datetime DEFAULT NULL,`end_time` datetime DEFAULT NULL,`is_del` tinyint(4) DEFAULT 0,',
    'PRIMARY KEY (`id`),KEY `idx_task` (`task_id`),KEY `idx_cat` (`task_category`),KEY `idx_state` (`task_state`)',
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''单方作业预处理/脚本任务''');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
  SET @l = CONCAT('CREATE TABLE IF NOT EXISTS `',db,'`.sp_ext_log (',
    '`id` bigint(20) NOT NULL AUTO_INCREMENT,`task_id` varchar(141) DEFAULT NULL,',
    '`task_name` varchar(255) DEFAULT NULL,`task_category` varchar(16) DEFAULT NULL,',
    '`log_level` varchar(16) DEFAULT ''INFO'',`log_content` varchar(2000) DEFAULT NULL,',
    '`create_date` datetime DEFAULT CURRENT_TIMESTAMP,`is_del` tinyint(4) DEFAULT 0,',
    'PRIMARY KEY (`id`),KEY `idx_task` (`task_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT=''单方作业学习日志''');
  PREPARE st2 FROM @l; EXECUTE st2; DEALLOCATE PREPARE st2;
END$$
DELIMITER ;
CALL _phf_sp_ext('fusion0'); CALL _phf_sp_ext('fusion1'); CALL _phf_sp_ext('fusion2');
DROP PROCEDURE IF EXISTS _phf_sp_ext;
