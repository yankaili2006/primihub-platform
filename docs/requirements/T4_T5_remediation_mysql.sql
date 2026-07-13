-- =====================================================================
-- 隐私计算数据可信共享 —— 缺陷整改 T4(权限种子) + T5(缺失建表) 幂等脚本
-- 目标：已部署的生产库 privacy1 / privacy2 / privacy3（每个都要执行）
-- 方言：MySQL 5.7+/8.0
-- 特性：可重复执行（幂等）。CREATE TABLE IF NOT EXISTS + INSERT ... WHERE NOT EXISTS。
-- 执行后：清 Redis 权限缓存并重新登录，菜单/按钮方可刷新。
--
-- 覆盖缺陷：
--   T5 缺表 -> 500/请求异常：
--     - 操作/调度/计算 日志定义 新增异常（3 张 *_log_definition 表缺失）
--     - 计算日志记录（sys_compute_log 缺失）
--     - 数据需求 新增/查询异常（data_requirement* 缺失）
--     - 共享数据集 新增/查询异常（shared_dataset 缺失且旧表列名与 mapper 不符）
--   T4 权限种子 -> 按钮/菜单不显示：
--     - 白名单无「新增」按钮（种子里错写成 WhitelistCreate，前端要 WhitelistAdd；缺 WhitelistEdit）
--     - 租户无「新增/编辑/删除/冻结」按钮（Tenant* 权限全缺）
--     - 联邦求差「模块不存在」（Difference* 权限未入库）
-- =====================================================================

-- ############################  T5：缺失建表  ############################
-- 列名严格对齐 MyBatis mapper（LogManagement / DataRequirement / SharedDataset）。
-- 注意：shared_dataset 特意不采用 test-tools/init-privacy-db-tables.sql 里的旧最小列版
--       （dataset_name/resource_ids/share_type…），那会触发 "Unknown column" 崩溃。

-- 1) 操作日志定义表
CREATE TABLE IF NOT EXISTS `sys_operation_log_definition` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码（唯一标识）',
  `log_name` VARCHAR(200) NOT NULL COMMENT '日志名称',
  `log_type` VARCHAR(50) NOT NULL COMMENT '日志类型',
  `module_name` VARCHAR(100) DEFAULT NULL COMMENT '模块名称',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用（0-否 1-是）',
  `retention_days` INT(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除（0-否 1-是）',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志定义表';

-- 2) 调度日志定义表
CREATE TABLE IF NOT EXISTS `sys_schedule_log_definition` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码（唯一标识）',
  `log_name` VARCHAR(200) NOT NULL COMMENT '日志名称',
  `schedule_type` VARCHAR(50) NOT NULL COMMENT '调度类型',
  `module_name` VARCHAR(100) DEFAULT NULL COMMENT '模块名称',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用（0-否 1-是）',
  `retention_days` INT(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除（0-否 1-是）',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='调度日志定义表';

-- 3) 计算日志定义表
CREATE TABLE IF NOT EXISTS `sys_compute_log_definition` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码（唯一标识）',
  `log_name` VARCHAR(200) NOT NULL COMMENT '日志名称',
  `compute_type` VARCHAR(50) NOT NULL COMMENT '计算类型',
  `module_name` VARCHAR(100) DEFAULT NULL COMMENT '模块名称',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用（0-否 1-是）',
  `retention_days` INT(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除（0-否 1-是）',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计算日志定义表';

-- 4) 计算日志记录表（列对齐 mapper selectComputeLog*）
CREATE TABLE IF NOT EXISTS `sys_compute_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` VARCHAR(100) NOT NULL COMMENT '日志代码（关联定义表）',
  `task_id` VARCHAR(100) DEFAULT NULL COMMENT '任务ID',
  `task_name` VARCHAR(200) DEFAULT NULL COMMENT '任务名称',
  `compute_type` VARCHAR(50) DEFAULT NULL COMMENT '计算类型',
  `project_id` BIGINT DEFAULT NULL COMMENT '项目ID',
  `project_name` VARCHAR(200) DEFAULT NULL COMMENT '项目名称',
  `user_id` BIGINT DEFAULT NULL COMMENT '用户ID',
  `user_name` VARCHAR(100) DEFAULT NULL COMMENT '用户名',
  `organ_id` BIGINT DEFAULT NULL COMMENT '机构ID',
  `organ_name` VARCHAR(200) DEFAULT NULL COMMENT '机构名称',
  `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
  `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
  `execution_time` BIGINT DEFAULT NULL COMMENT '执行时长（毫秒）',
  `status` TINYINT(1) DEFAULT 0 COMMENT '状态（0-运行中 1-成功 2-失败 3-取消）',
  `result_data` TEXT COMMENT '计算结果数据',
  `error_msg` TEXT COMMENT '错误信息',
  `resource_usage` TEXT COMMENT '资源使用情况',
  `is_del` TINYINT(1) DEFAULT 0 COMMENT '是否删除（0-否 1-是）',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_log_code` (`log_code`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计算日志记录表';

-- 5) 数据需求主表 + 配置表 + 匹配表（列对齐 DataRequirement mapper）
CREATE TABLE IF NOT EXISTS `data_requirement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_code` VARCHAR(64) NOT NULL COMMENT '需求编码',
  `requirement_name` VARCHAR(128) NOT NULL COMMENT '需求名称',
  `requirement_desc` TEXT COMMENT '需求描述',
  `requirement_type` VARCHAR(32) COMMENT '需求类型',
  `data_fields` TEXT COMMENT '所需数据字段(JSON)',
  `data_volume` BIGINT COMMENT '所需数据量',
  `data_format` VARCHAR(32) COMMENT '所需数据格式',
  `priority` TINYINT DEFAULT 0 COMMENT '优先级(0-低 1-中 2-高)',
  `status` TINYINT DEFAULT 0 COMMENT '状态(0-待匹配 1-已匹配 2-已完成 3-已关闭)',
  `user_id` BIGINT NOT NULL COMMENT '创建人用户ID',
  `user_name` VARCHAR(64) COMMENT '创建人用户名',
  `organ_id` BIGINT COMMENT '机构ID',
  `organ_name` VARCHAR(128) COMMENT '机构名称',
  `start_date` DATETIME COMMENT '需求开始日期',
  `end_date` DATETIME COMMENT '需求结束日期',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_code` (`requirement_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求表';

CREATE TABLE IF NOT EXISTS `data_requirement_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_key` VARCHAR(64) NOT NULL COMMENT '配置键',
  `config_value` TEXT NOT NULL COMMENT '配置值',
  `config_desc` VARCHAR(255) COMMENT '配置描述',
  `config_type` VARCHAR(32) COMMENT '配置类型',
  `is_enabled` TINYINT DEFAULT 1 COMMENT '启用标记',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求配置表';

CREATE TABLE IF NOT EXISTS `data_requirement_match` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_id` BIGINT NOT NULL COMMENT '需求ID',
  `resource_id` BIGINT NOT NULL COMMENT '资源ID',
  `match_score` DECIMAL(5,2) DEFAULT 0.00 COMMENT '匹配得分',
  `match_status` TINYINT DEFAULT 0 COMMENT '匹配状态',
  `match_type` VARCHAR(32) COMMENT '匹配类型',
  `match_details` TEXT COMMENT '匹配详情(JSON)',
  `confirm_user_id` BIGINT COMMENT '确认人用户ID',
  `confirm_user_name` VARCHAR(64) COMMENT '确认人用户名',
  `confirm_date` DATETIME COMMENT '确认时间',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_requirement_id` (`requirement_id`),
  KEY `idx_resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求匹配表';

-- 数据需求默认配置（幂等：uk_config_key 冲突则忽略）
INSERT IGNORE INTO `data_requirement_config` (`config_key`,`config_value`,`config_desc`,`config_type`,`is_enabled`) VALUES
('match_threshold','60.00','匹配阈值','匹配规则',1),
('field_match_weight','40','字段匹配权重','评分权重',1),
('volume_match_weight','20','数据量匹配权重','评分权重',1),
('format_match_weight','20','数据格式匹配权重','评分权重',1),
('type_match_weight','20','数据类型匹配权重','评分权重',1),
('auto_match_enabled','true','是否启用自动匹配','系统配置',1),
('max_match_results','50','单次匹配最大结果数','系统配置',1);

-- 6) 共享数据集表（列对齐 SharedDataset mapper / PO；勿用旧最小列版）
CREATE TABLE IF NOT EXISTS `shared_dataset` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `dataset_code` VARCHAR(64) NOT NULL COMMENT '数据集编码',
  `dataset_name` VARCHAR(255) NOT NULL COMMENT '数据集名称',
  `dataset_desc` TEXT COMMENT '数据集描述',
  `data_type` VARCHAR(32) COMMENT '数据类型',
  `data_format` VARCHAR(32) COMMENT '数据格式',
  `data_fields` TEXT COMMENT '数据字段(JSON)',
  `data_volume` BIGINT COMMENT '数据量',
  `share_status` INT DEFAULT 0 COMMENT '共享状态',
  `share_scope` INT DEFAULT 0 COMMENT '共享范围',
  `target_organ_ids` TEXT COMMENT '目标机构ID列表',
  `resource_id` BIGINT COMMENT '关联资源ID',
  `resource_name` VARCHAR(255) COMMENT '关联资源名称',
  `usage_terms` VARCHAR(1000) COMMENT '使用条款',
  `user_id` BIGINT COMMENT '创建人ID',
  `user_name` VARCHAR(64) COMMENT '创建人',
  `organ_id` BIGINT COMMENT '机构ID',
  `organ_name` VARCHAR(128) COMMENT '机构名称',
  `start_date` DATETIME COMMENT '共享开始日期',
  `end_date` DATETIME COMMENT '共享结束日期',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dataset_code` (`dataset_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_share_status` (`share_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='共享数据集表';


-- ############################  T4：权限种子  ############################
-- 说明：按钮权限 auth_type=3；菜单目录 auth_type=1；页面 auth_type=2。
-- 前端 store/permission.js 用「路由 name == auth_code」过滤菜单、用 authType==3 生成按钮列表。
-- 全部授予超级管理员角色 role_id=1。

-- ---- 4.1 白名单：修正错误 auth_code + 补 WhitelistAdd/WhitelistEdit ----
-- 情况一：历史种子把「新增」写成 WhitelistCreate → 改名为 WhitelistAdd（保留原 auth_id 及其已有授权）
UPDATE sys_auth SET auth_code='WhitelistAdd', auth_name='新增白名单'
  WHERE auth_code='WhitelistCreate' AND is_del=0;

-- 情况二：库中本就没有 WhitelistCreate（如线上部署）→ 上面的改名不命中，这里直接新建 WhitelistAdd
-- 二者互斥且都带 NOT EXISTS 守卫，幂等安全；确保任何库都最终拥有 WhitelistAdd
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT '新增白名单','WhitelistAdd',3, w.auth_id, w.r_auth_id, CONCAT(w.full_path,',WhitelistAdd'), '/whitelist/saveOrUpdateWhitelist','own',2,2,1,1,0
FROM (SELECT auth_id, r_auth_id, full_path FROM sys_auth WHERE auth_code='WhitelistList' AND is_del=0 LIMIT 1) w
WHERE NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code='WhitelistAdd' AND s.is_del=0);

-- 补「编辑白名单」按钮（挂在 WhitelistList 下）
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT '编辑白名单','WhitelistEdit',3, w.auth_id, w.r_auth_id, CONCAT(w.full_path,',WhitelistEdit'), '/whitelist/updateWhitelist','own',3,2,0,1,0
FROM (SELECT auth_id, r_auth_id, full_path FROM sys_auth WHERE auth_code='WhitelistList' AND is_del=0 LIMIT 1) w
WHERE NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code='WhitelistEdit' AND s.is_del=0);

-- ---- 4.2 租户：菜单 Tenant / 页面 TenantList / 4 个按钮 ----
-- 父菜单
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT '租户管理','Tenant',1,0,0,'','','own',20,0,1,1,0
WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code='Tenant' AND is_del=0);
SET @tenant_id = (SELECT auth_id FROM sys_auth WHERE auth_code='Tenant' AND is_del=0 LIMIT 1);
UPDATE sys_auth SET r_auth_id=@tenant_id, full_path=CAST(@tenant_id AS CHAR)
  WHERE auth_id=@tenant_id AND (r_auth_id=0 OR r_auth_id IS NULL);

-- 列表页
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT '租户列表','TenantList',2,@tenant_id,@tenant_id,CONCAT(@tenant_id,',TenantList'),'/tenant/findTenantPage','own',1,1,1,1,0
WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code='TenantList' AND is_del=0);
SET @tenant_list_id = (SELECT auth_id FROM sys_auth WHERE auth_code='TenantList' AND is_del=0 LIMIT 1);

-- 4 个按钮
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT * FROM (
  SELECT '新增租户' AS a,'TenantAdd' AS b,3 AS c,@tenant_list_id AS d,@tenant_id AS e,CONCAT(@tenant_id,',',@tenant_list_id,',TenantAdd') AS f,'/tenant/addTenant' AS g,'own' AS h,1 AS i,2 AS j,0 AS k,1 AS l,0 AS m
  UNION ALL SELECT '编辑租户','TenantEdit',3,@tenant_list_id,@tenant_id,CONCAT(@tenant_id,',',@tenant_list_id,',TenantEdit'),'/tenant/updateTenant','own',2,2,0,1,0
  UNION ALL SELECT '删除租户','TenantDelete',3,@tenant_list_id,@tenant_id,CONCAT(@tenant_id,',',@tenant_list_id,',TenantDelete'),'/tenant/deleteTenant','own',3,2,0,1,0
  UNION ALL SELECT '冻结租户','TenantFreeze',3,@tenant_list_id,@tenant_id,CONCAT(@tenant_id,',',@tenant_list_id,',TenantFreeze'),'/tenant/freezeTenant','own',4,2,0,1,0
) t
WHERE NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code=t.b AND s.is_del=0);

-- ---- 4.3 联邦求差：菜单 Difference / 3 页面 ----
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT '联邦求差','Difference',1,0,0,'','','own',30,0,1,1,0
WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code='Difference' AND is_del=0);
SET @diff_id = (SELECT auth_id FROM sys_auth WHERE auth_code='Difference' AND is_del=0 LIMIT 1);
UPDATE sys_auth SET r_auth_id=@diff_id, full_path=CAST(@diff_id AS CHAR)
  WHERE auth_id=@diff_id AND (r_auth_id=0 OR r_auth_id IS NULL);

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT * FROM (
  SELECT '联邦求差列表' AS a,'DifferenceList' AS b,2 AS c,@diff_id AS d,@diff_id AS e,CONCAT(@diff_id,',DifferenceList') AS f,'/data/difference/list' AS g,'own' AS h,1 AS i,1 AS j,1 AS k,1 AS l,0 AS m
  UNION ALL SELECT '联邦求差任务','DifferenceTask',2,@diff_id,@diff_id,CONCAT(@diff_id,',DifferenceTask'),'/data/difference/task','own',2,1,1,1,0
  UNION ALL SELECT '联邦求差详情','DifferenceDetail',2,@diff_id,@diff_id,CONCAT(@diff_id,',DifferenceDetail'),'/data/difference/detail','own',3,1,1,1,0
) t
WHERE NOT EXISTS (SELECT 1 FROM sys_auth s WHERE s.auth_code=t.b AND s.is_del=0);

-- ---- 4.4 统一授予超级管理员（role_id=1）：所有上面新增/修正的权限 ----
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, a.auth_id, 0 FROM sys_auth a
WHERE a.is_del=0
  AND a.auth_code IN (
    'WhitelistAdd','WhitelistEdit',
    'Tenant','TenantList','TenantAdd','TenantEdit','TenantDelete','TenantFreeze',
    'Difference','DifferenceList','DifferenceTask','DifferenceDetail'
  )
  AND NOT EXISTS (SELECT 1 FROM sys_ra r WHERE r.role_id=1 AND r.auth_id=a.auth_id AND r.is_del=0);

-- ---- 校验 ----
SELECT a.auth_code, a.auth_type, a.is_show,
       (SELECT COUNT(*) FROM sys_ra r WHERE r.role_id=1 AND r.auth_id=a.auth_id AND r.is_del=0) AS granted
FROM sys_auth a
WHERE a.is_del=0 AND a.auth_code IN (
  'WhitelistAdd','WhitelistEdit','WhitelistDelete',
  'Tenant','TenantList','TenantAdd','TenantEdit','TenantDelete','TenantFreeze',
  'Difference','DifferenceList','DifferenceTask','DifferenceDetail')
ORDER BY a.auth_code;

SELECT '✅ T4+T5 幂等整改执行完毕。请清 Redis 权限缓存并重新登录。' AS message;
