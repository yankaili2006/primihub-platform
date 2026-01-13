-- 日志管理模块数据库表

-- 1. 操作日志定义表
CREATE TABLE IF NOT EXISTS `sys_operation_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` varchar(100) NOT NULL COMMENT '日志代码（唯一标识）',
  `log_name` varchar(200) NOT NULL COMMENT '日志名称',
  `log_type` varchar(50) NOT NULL COMMENT '日志类型（登录/登出/增删改查/导入导出等）',
  `module_name` varchar(100) DEFAULT NULL COMMENT '模块名称',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用（0-否，1-是）',
  `retention_days` int(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除（0-否，1-是）',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志定义表';

-- 2. 调度日志定义表
CREATE TABLE IF NOT EXISTS `sys_schedule_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` varchar(100) NOT NULL COMMENT '日志代码（唯一标识）',
  `log_name` varchar(200) NOT NULL COMMENT '日志名称',
  `schedule_type` varchar(50) NOT NULL COMMENT '调度类型（定时任务/数据同步/批量处理等）',
  `module_name` varchar(100) DEFAULT NULL COMMENT '模块名称',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用（0-否，1-是）',
  `retention_days` int(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除（0-否，1-是）',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='调度日志定义表';

-- 3. 计算日志定义表
CREATE TABLE IF NOT EXISTS `sys_compute_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` varchar(100) NOT NULL COMMENT '日志代码（唯一标识）',
  `log_name` varchar(200) NOT NULL COMMENT '日志名称',
  `compute_type` varchar(50) NOT NULL COMMENT '计算类型（联合建模/安全求交/隐匿查询/联合预测等）',
  `module_name` varchar(100) DEFAULT NULL COMMENT '模块名称',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `is_enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用（0-否，1-是）',
  `retention_days` int(11) DEFAULT 30 COMMENT '保留天数',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除（0-否，1-是）',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_code` (`log_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计算日志定义表';

-- 4. 操作日志记录表
CREATE TABLE IF NOT EXISTS `sys_operation_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` varchar(100) NOT NULL COMMENT '日志代码（关联定义表）',
  `user_id` bigint(20) DEFAULT NULL COMMENT '操作用户ID',
  `user_name` varchar(100) DEFAULT NULL COMMENT '操作用户名',
  `organ_id` bigint(20) DEFAULT NULL COMMENT '机构ID',
  `organ_name` varchar(200) DEFAULT NULL COMMENT '机构名称',
  `operation_type` varchar(50) DEFAULT NULL COMMENT '操作类型',
  `operation_module` varchar(100) DEFAULT NULL COMMENT '操作模块',
  `operation_desc` varchar(500) DEFAULT NULL COMMENT '操作描述',
  `request_method` varchar(10) DEFAULT NULL COMMENT '请求方法（GET/POST等）',
  `request_url` varchar(500) DEFAULT NULL COMMENT '请求URL',
  `request_params` text DEFAULT NULL COMMENT '请求参数',
  `response_result` text DEFAULT NULL COMMENT '响应结果',
  `ip_address` varchar(50) DEFAULT NULL COMMENT 'IP地址',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态（0-失败，1-成功）',
  `error_msg` text DEFAULT NULL COMMENT '错误信息',
  `execution_time` bigint(20) DEFAULT NULL COMMENT '执行时长（毫秒）',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除（0-否，1-是）',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_log_code` (`log_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志记录表';

-- 5. 调度日志记录表
CREATE TABLE IF NOT EXISTS `sys_schedule_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` varchar(100) NOT NULL COMMENT '日志代码（关联定义表）',
  `schedule_name` varchar(200) DEFAULT NULL COMMENT '调度任务名称',
  `schedule_type` varchar(50) DEFAULT NULL COMMENT '调度类型',
  `schedule_cron` varchar(100) DEFAULT NULL COMMENT 'Cron表达式',
  `execute_server` varchar(100) DEFAULT NULL COMMENT '执行服务器',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `execution_time` bigint(20) DEFAULT NULL COMMENT '执行时长（毫秒）',
  `status` tinyint(1) DEFAULT 0 COMMENT '状态（0-运行中，1-成功，2-失败）',
  `result_message` text DEFAULT NULL COMMENT '结果信息',
  `error_msg` text DEFAULT NULL COMMENT '错误信息',
  `retry_count` int(11) DEFAULT 0 COMMENT '重试次数',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除（0-否，1-是）',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_log_code` (`log_code`),
  KEY `idx_create_date` (`create_date`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='调度日志记录表';

-- 6. 计算日志记录表
CREATE TABLE IF NOT EXISTS `sys_compute_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_code` varchar(100) NOT NULL COMMENT '日志代码（关联定义表）',
  `task_id` varchar(100) DEFAULT NULL COMMENT '任务ID',
  `task_name` varchar(200) DEFAULT NULL COMMENT '任务名称',
  `compute_type` varchar(50) DEFAULT NULL COMMENT '计算类型',
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目ID',
  `project_name` varchar(200) DEFAULT NULL COMMENT '项目名称',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `user_name` varchar(100) DEFAULT NULL COMMENT '用户名',
  `organ_id` bigint(20) DEFAULT NULL COMMENT '机构ID',
  `organ_name` varchar(200) DEFAULT NULL COMMENT '机构名称',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `execution_time` bigint(20) DEFAULT NULL COMMENT '执行时长（毫秒）',
  `status` tinyint(1) DEFAULT 0 COMMENT '状态（0-运行中，1-成功，2-失败，3-取消）',
  `result_data` text DEFAULT NULL COMMENT '计算结果数据',
  `error_msg` text DEFAULT NULL COMMENT '错误信息',
  `resource_usage` text DEFAULT NULL COMMENT '资源使用情况（CPU/内存/网络等）',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除（0-否，1-是）',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_log_code` (`log_code`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_date` (`create_date`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计算日志记录表';

-- 插入初始操作日志定义数据
INSERT INTO `sys_operation_log_definition` (`log_code`, `log_name`, `log_type`, `module_name`, `description`, `is_enabled`, `retention_days`) VALUES
('USER_LOGIN', '用户登录', '登录', '用户管理', '记录用户登录操作', 1, 90),
('USER_LOGOUT', '用户登出', '登出', '用户管理', '记录用户登出操作', 1, 90),
('USER_CREATE', '创建用户', '新增', '用户管理', '记录创建用户操作', 1, 365),
('USER_UPDATE', '更新用户', '修改', '用户管理', '记录更新用户信息操作', 1, 365),
('USER_DELETE', '删除用户', '删除', '用户管理', '记录删除用户操作', 1, 365),
('ROLE_CREATE', '创建角色', '新增', '角色管理', '记录创建角色操作', 1, 365),
('ROLE_UPDATE', '更新角色', '修改', '角色管理', '记录更新角色操作', 1, 365),
('ROLE_DELETE', '删除角色', '删除', '角色管理', '记录删除角色操作', 1, 365),
('DATA_EXPORT', '数据导出', '导出', '数据管理', '记录数据导出操作', 1, 180),
('DATA_IMPORT', '数据导入', '导入', '数据管理', '记录数据导入操作', 1, 180);

-- 插入初始调度日志定义数据
INSERT INTO `sys_schedule_log_definition` (`log_code`, `log_name`, `schedule_type`, `module_name`, `description`, `is_enabled`, `retention_days`) VALUES
('DATA_SYNC_TASK', '数据同步任务', '数据同步', '数据管理', '定时同步数据任务', 1, 30),
('REPORT_GEN_TASK', '报表生成任务', '报表生成', '报表管理', '定时生成统计报表', 1, 30),
('LOG_CLEAN_TASK', '日志清理任务', '日志清理', '系统管理', '定时清理过期日志', 1, 30),
('BACKUP_TASK', '备份任务', '数据备份', '系统管理', '定时备份数据', 1, 90);

-- 插入初始计算日志定义数据
INSERT INTO `sys_compute_log_definition` (`log_code`, `log_name`, `compute_type`, `module_name`, `description`, `is_enabled`, `retention_days`) VALUES
('JOINT_MODELING', '联合建模', '联合建模', '计算任务', '联合建模任务日志', 1, 180),
('PSI_TASK', '安全求交', '安全求交', '计算任务', '安全求交任务日志', 1, 180),
('PIR_TASK', '隐匿查询', '隐匿查询', '计算任务', '隐匿查询任务日志', 1, 180),
('JOINT_PREDICT', '联合预测', '联合预测', '计算任务', '联合预测任务日志', 1, 180);
