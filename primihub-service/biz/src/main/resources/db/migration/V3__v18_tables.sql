-- V3__v18_tables.sql — 18 v1.8.0 backend tables (tenant/whitelist/log/node-approval) + seeds.
-- Flyway runs in the connected schema (NO USE statement). Backend mybatis mappers query these
-- tables; the base dump lacked them so fresh deploys errored. CREATE TABLE IF NOT EXISTS + idempotent seeds.

-- ========================================
-- 租户管理模块数据库表结构
-- ========================================

-- 1. 租户表
CREATE TABLE IF NOT EXISTS `tenant` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '租户ID',
  `tenant_code` VARCHAR(50) NOT NULL COMMENT '租户编码',
  `tenant_name` VARCHAR(200) NOT NULL COMMENT '租户名称',
  `contact_person` VARCHAR(100) DEFAULT NULL COMMENT '联系人',
  `contact_phone` VARCHAR(20) DEFAULT NULL COMMENT '联系电话',
  `contact_email` VARCHAR(100) DEFAULT NULL COMMENT '联系邮箱',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `status` TINYINT(1) NOT NULL DEFAULT '1' COMMENT '状态：0-冻结，1-正常',
  `data_isolation` TINYINT(1) NOT NULL DEFAULT '1' COMMENT '数据隔离：0-关闭，1-启用',
  `compute_isolation` TINYINT(1) NOT NULL DEFAULT '1' COMMENT '计算流程隔离：0-关闭，1-启用',
  `resource_count` INT(11) DEFAULT '0' COMMENT '资源数量',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_del` TINYINT(1) NOT NULL DEFAULT '0' COMMENT '是否删除：0-否，1-是',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_code` (`tenant_code`),
  KEY `idx_status` (`status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='租户表';

-- 2. 租户资源分配表
CREATE TABLE IF NOT EXISTS `tenant_resource_allocation` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `tenant_id` BIGINT(20) NOT NULL COMMENT '租户ID',
  `resource_id` BIGINT(20) NOT NULL COMMENT '资源ID',
  `resource_name` VARCHAR(200) DEFAULT NULL COMMENT '资源名称',
  `resource_type` VARCHAR(50) NOT NULL COMMENT '资源类型：DATASET-数据集，COMPUTE-计算资源，STORAGE-存储资源，MODEL-模型',
  `permission_level` VARCHAR(20) NOT NULL DEFAULT 'READ' COMMENT '权限级别：READ-只读，WRITE-读写，ADMIN-管理',
  `quota_amount` DECIMAL(10,2) DEFAULT NULL COMMENT '配额量',
  `quota_unit` VARCHAR(20) DEFAULT NULL COMMENT '配额单位：GB、TB、次、个',
  `used_amount` DECIMAL(10,2) DEFAULT '0.00' COMMENT '已使用量',
  `status` TINYINT(1) NOT NULL DEFAULT '1' COMMENT '状态：0-禁用，1-正常',
  `effective_time` DATETIME DEFAULT NULL COMMENT '生效时间',
  `expiry_time` DATETIME DEFAULT NULL COMMENT '过期时间',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_tenant_id` (`tenant_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_resource_type` (`resource_type`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='租户资源分配表';

-- 3. 租户隔离配置表
CREATE TABLE IF NOT EXISTS `tenant_isolation_config` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '配置ID',
  `tenant_id` BIGINT(20) NOT NULL COMMENT '租户ID',
  `cpu_quota` INT(11) DEFAULT '0' COMMENT 'CPU配额（核）',
  `memory_quota` INT(11) DEFAULT '0' COMMENT '内存配额（GB）',
  `storage_quota` INT(11) DEFAULT '0' COMMENT '存储配额（GB）',
  `dataset_limit` INT(11) DEFAULT '0' COMMENT '数据集数量限制',
  `model_limit` INT(11) DEFAULT '0' COMMENT '模型数量限制',
  `concurrent_tasks` INT(11) DEFAULT '10' COMMENT '并发任务数',
  `network_isolation` TINYINT(1) DEFAULT '0' COMMENT '网络隔离：0-关闭，1-启用',
  `namespace` VARCHAR(100) DEFAULT NULL COMMENT '命名空间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='租户隔离配置表';

-- TODO: 需要根据实际业务需求调整表结构和字段
-- ========================================
-- 白名单管理模块数据库表结构
-- ========================================

-- 1. 白名单表
CREATE TABLE IF NOT EXISTS `whitelist` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '白名单ID',
  `type` VARCHAR(50) NOT NULL COMMENT '类型：IP、DOMAIN、USER_ID',
  `value` VARCHAR(200) NOT NULL COMMENT '值',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `status` TINYINT(1) NOT NULL DEFAULT '1' COMMENT '状态：0-禁用，1-启用',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_user_id` BIGINT(20) DEFAULT NULL COMMENT '创建用户ID',
  `is_del` TINYINT(1) NOT NULL DEFAULT '0' COMMENT '是否删除：0-否，1-是',
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`),
  KEY `idx_value` (`value`),
  KEY `idx_status` (`status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='白名单表';

-- 2. 白名单配置表
CREATE TABLE IF NOT EXISTS `whitelist_config` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '配置ID',
  `config_key` VARCHAR(100) NOT NULL COMMENT '配置键',
  `config_value` TEXT NOT NULL COMMENT '配置值',
  `config_type` VARCHAR(50) DEFAULT NULL COMMENT '配置类型',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `update_user_id` BIGINT(20) DEFAULT NULL COMMENT '更新用户ID',
  `update_user` VARCHAR(100) DEFAULT NULL COMMENT '更新用户名',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='白名单配置表';

-- 3. 白名单访问日志表
CREATE TABLE IF NOT EXISTS `whitelist_access_log` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `whitelist_id` BIGINT(20) DEFAULT NULL COMMENT '白名单ID',
  `access_ip` VARCHAR(50) NOT NULL COMMENT '访问IP',
  `access_url` VARCHAR(500) NOT NULL COMMENT '访问URL',
  `request_method` VARCHAR(10) DEFAULT NULL COMMENT '请求方法',
  `access_result` VARCHAR(20) NOT NULL COMMENT '访问结果：SUCCESS-成功，DENIED-拒绝，ERROR-异常',
  `fail_reason` VARCHAR(500) DEFAULT NULL COMMENT '失败原因',
  `user_id` BIGINT(20) DEFAULT NULL COMMENT '用户ID',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT 'User-Agent',
  `request_params` TEXT DEFAULT NULL COMMENT '请求参数',
  `response_code` INT(11) DEFAULT NULL COMMENT '响应码',
  `response_time` BIGINT(20) DEFAULT NULL COMMENT '响应时间(ms)',
  `access_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '访问时间',
  PRIMARY KEY (`id`),
  KEY `idx_whitelist_id` (`whitelist_id`),
  KEY `idx_access_ip` (`access_ip`),
  KEY `idx_access_result` (`access_result`),
  KEY `idx_access_time` (`access_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='白名单访问日志表';

-- 插入默认配置数据
INSERT INTO `whitelist_config` (`config_key`, `config_value`, `config_type`, `description`) VALUES
('enableWhitelist', 'false', 'boolean', '是否启用白名单功能'),
('defaultPolicy', 'DENY', 'string', '默认策略：ALLOW-允许，DENY-拒绝'),
('enableAccessLog', 'true', 'boolean', '是否记录访问日志'),
('logRetentionDays', '30', 'number', '日志保留天数'),
('ipMatchMode', 'EXACT', 'string', 'IP匹配模式：EXACT-精确，CIDR-CIDR，RANGE-范围'),
('maxFailedAttempts', '5', 'number', '最大失败尝试次数'),
('lockDuration', '30', 'number', '锁定时长（分钟）'),
('enableAlert', 'false', 'boolean', '是否启用告警'),
('alertEmails', '', 'string', '告警邮箱'),
('cacheTime', '300', 'number', '缓存时间（秒）')
ON DUPLICATE KEY UPDATE config_value=VALUES(config_value);
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
INSERT IGNORE INTO `sys_operation_log_definition` (`log_code`, `log_name`, `log_type`, `module_name`, `description`, `is_enabled`, `retention_days`) VALUES
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
INSERT IGNORE INTO `sys_schedule_log_definition` (`log_code`, `log_name`, `schedule_type`, `module_name`, `description`, `is_enabled`, `retention_days`) VALUES
('DATA_SYNC_TASK', '数据同步任务', '数据同步', '数据管理', '定时同步数据任务', 1, 30),
('REPORT_GEN_TASK', '报表生成任务', '报表生成', '报表管理', '定时生成统计报表', 1, 30),
('LOG_CLEAN_TASK', '日志清理任务', '日志清理', '系统管理', '定时清理过期日志', 1, 30),
('BACKUP_TASK', '备份任务', '数据备份', '系统管理', '定时备份数据', 1, 90);

-- 插入初始计算日志定义数据
INSERT IGNORE INTO `sys_compute_log_definition` (`log_code`, `log_name`, `compute_type`, `module_name`, `description`, `is_enabled`, `retention_days`) VALUES
('JOINT_MODELING', '联合建模', '联合建模', '计算任务', '联合建模任务日志', 1, 180),
('PSI_TASK', '安全求交', '安全求交', '计算任务', '安全求交任务日志', 1, 180),
('PIR_TASK', '隐匿查询', '隐匿查询', '计算任务', '隐匿查询任务日志', 1, 180),
('JOINT_PREDICT', '联合预测', '联合预测', '计算任务', '联合预测任务日志', 1, 180);
-- ========================================
-- 节点管理增强功能表创建脚本 (简化版)
-- ========================================

-- 表1: 接入方管理表
CREATE TABLE IF NOT EXISTS `node_access_party` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `organ_id` VARCHAR(255) NOT NULL COMMENT '节点ID(申请方)',
    `organ_name` VARCHAR(255) NOT NULL COMMENT '节点名称',
    `organ_gateway` VARCHAR(500) DEFAULT NULL COMMENT '节点网关地址',
    `apply_reason` TEXT DEFAULT NULL COMMENT '申请理由',
    `access_level` TINYINT NOT NULL DEFAULT 1 COMMENT '接入级别: 1=只读, 2=读写, 3=管理员',
    `ip_whitelist` TEXT DEFAULT NULL COMMENT 'IP白名单(JSON格式)',
    `valid_from` DATETIME DEFAULT NULL COMMENT '有效期开始时间',
    `valid_until` DATETIME DEFAULT NULL COMMENT '有效期结束时间',
    `apply_status` TINYINT NOT NULL DEFAULT 0 COMMENT '申请状态: 0=待审批, 1=已批准, 2=已拒绝',
    `approve_user_id` BIGINT DEFAULT NULL COMMENT '审批人ID',
    `approve_user_name` VARCHAR(100) DEFAULT NULL COMMENT '审批人姓名',
    `approve_comment` TEXT DEFAULT NULL COMMENT '审批意见',
    `approve_date` DATETIME DEFAULT NULL COMMENT '审批时间',
    `is_active` TINYINT NOT NULL DEFAULT 1 COMMENT '是否激活: 0=否, 1=是',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    INDEX `idx_organ_id` (`organ_id`),
    INDEX `idx_apply_status` (`apply_status`),
    INDEX `idx_create_date` (`create_date`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='接入方管理表';

-- 表2: 合作方管理表
CREATE TABLE IF NOT EXISTS `node_cooperation_party` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `partner_organ_id` VARCHAR(255) NOT NULL COMMENT '合作方节点ID',
    `partner_organ_name` VARCHAR(255) NOT NULL COMMENT '合作方节点名称',
    `partner_organ_gateway` VARCHAR(500) DEFAULT NULL COMMENT '合作方网关地址',
    `cooperation_type` VARCHAR(50) DEFAULT 'DATA_SHARE' COMMENT '合作类型',
    `start_date` DATETIME DEFAULT NULL COMMENT '合作开始时间',
    `end_date` DATETIME DEFAULT NULL COMMENT '合作结束时间',
    `cooperation_agreement` VARCHAR(500) DEFAULT NULL COMMENT '合作协议',
    `cooperation_scope` TEXT DEFAULT NULL COMMENT '合作范围',
    `data_exchange_frequency` VARCHAR(100) DEFAULT NULL COMMENT '数据交换频率',
    `sla` VARCHAR(500) DEFAULT NULL COMMENT '服务等级协议',
    `contact_info` VARCHAR(500) DEFAULT NULL COMMENT '联系人信息',
    `remarks` TEXT DEFAULT NULL COMMENT '备注',
    `health_score` INT DEFAULT 100 COMMENT '健康评分(0-100)',
    `cooperation_status` TINYINT NOT NULL DEFAULT 0 COMMENT '合作状态: 0=待确认, 1=进行中, 2=已暂停, 3=已终止, 4=已完成',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    INDEX `idx_partner_organ_id` (`partner_organ_id`),
    INDEX `idx_cooperation_type` (`cooperation_type`),
    INDEX `idx_cooperation_status` (`cooperation_status`),
    INDEX `idx_end_date` (`end_date`),
    INDEX `idx_health_score` (`health_score`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合作方管理表';

-- 表3: 审批工作流表
CREATE TABLE IF NOT EXISTS `node_approval_workflow` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `workflow_no` VARCHAR(100) NOT NULL COMMENT '工作流编号',
    `workflow_type` VARCHAR(50) NOT NULL COMMENT '工作流类型',
    `workflow_status` TINYINT NOT NULL DEFAULT 0 COMMENT '工作流状态: 0=待审批, 1=审批中, 2=已通过, 3=已拒绝, 4=已取消',
    `requester_id` BIGINT DEFAULT NULL COMMENT '申请人ID',
    `requester_name` VARCHAR(100) DEFAULT NULL COMMENT '申请人姓名',
    `request_description` TEXT DEFAULT NULL COMMENT '申请描述',
    `business_id` VARCHAR(100) DEFAULT NULL COMMENT '关联业务ID',
    `priority` TINYINT NOT NULL DEFAULT 3 COMMENT '优先级: 1=紧急, 2=重要, 3=普通',
    `current_step` INT DEFAULT 0 COMMENT '当前步骤',
    `current_approver_id` BIGINT DEFAULT NULL COMMENT '当前审批人ID',
    `current_approver_name` VARCHAR(100) DEFAULT NULL COMMENT '当前审批人姓名',
    `attachments` TEXT DEFAULT NULL COMMENT '附件信息',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uk_workflow_no` (`workflow_no`),
    INDEX `idx_workflow_type` (`workflow_type`),
    INDEX `idx_workflow_status` (`workflow_status`),
    INDEX `idx_requester_id` (`requester_id`),
    INDEX `idx_current_approver_id` (`current_approver_id`),
    INDEX `idx_create_date` (`create_date`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批工作流表';

-- 表4: 审批配置表
CREATE TABLE IF NOT EXISTS `node_approval_config` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `workflow_type` VARCHAR(50) NOT NULL COMMENT '工作流类型',
    `approval_levels` INT NOT NULL DEFAULT 1 COMMENT '审批级数',
    `auto_approval_enabled` TINYINT NOT NULL DEFAULT 0 COMMENT '是否启用自动审批: 0=否, 1=是',
    `timeout_auto_approve` TINYINT NOT NULL DEFAULT 0 COMMENT '超时自动通过: 0=否, 1=是',
    `timeout_hours` INT DEFAULT 24 COMMENT '超时时间(小时)',
    `approval_rules` TEXT DEFAULT NULL COMMENT '审批规则(JSON格式)',
    `description` VARCHAR(500) DEFAULT NULL COMMENT '描述',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用: 0=否, 1=是',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uk_workflow_type` (`workflow_type`),
    INDEX `idx_is_enabled` (`is_enabled`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批配置表';

-- 表5: 审批步骤表
CREATE TABLE IF NOT EXISTS `node_approval_step` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `workflow_id` BIGINT NOT NULL COMMENT '工作流ID',
    `step_order` INT NOT NULL COMMENT '步骤序号',
    `approver_id` BIGINT DEFAULT NULL COMMENT '审批人ID',
    `approver_name` VARCHAR(100) DEFAULT NULL COMMENT '审批人姓名',
    `step_status` TINYINT NOT NULL DEFAULT 0 COMMENT '步骤状态: 0=待审批, 1=已通过, 2=已拒绝',
    `approval_comment` TEXT DEFAULT NULL COMMENT '审批意见',
    `approval_date` DATETIME DEFAULT NULL COMMENT '审批时间',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    INDEX `idx_workflow_id` (`workflow_id`),
    INDEX `idx_approver_id` (`approver_id`),
    INDEX `idx_step_status` (`step_status`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批步骤表';

-- 表6: 数据交换日志表
CREATE TABLE IF NOT EXISTS `node_data_exchange_log` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `exchange_id` VARCHAR(100) NOT NULL COMMENT '交换ID',
    `source_organ_id` VARCHAR(255) NOT NULL COMMENT '源节点ID',
    `source_organ_name` VARCHAR(255) DEFAULT NULL COMMENT '源节点名称',
    `target_organ_id` VARCHAR(255) NOT NULL COMMENT '目标节点ID',
    `target_organ_name` VARCHAR(255) DEFAULT NULL COMMENT '目标节点名称',
    `exchange_type` VARCHAR(50) DEFAULT 'SYNC' COMMENT '交换类型: PUSH=推送, PULL=拉取, SYNC=同步',
    `data_type` VARCHAR(50) DEFAULT 'RESOURCE' COMMENT '数据类型',
    `data_id` VARCHAR(255) DEFAULT NULL COMMENT '数据ID',
    `data_name` VARCHAR(500) DEFAULT NULL COMMENT '数据名称',
    `data_size` BIGINT DEFAULT 0 COMMENT '数据大小(字节)',
    `exchange_status` TINYINT NOT NULL DEFAULT 0 COMMENT '交换状态: 0=准备中, 1=进行中, 2=成功, 3=失败, 4=部分成功',
    `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
    `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
    `duration` INT DEFAULT 0 COMMENT '耗时(秒)',
    `transfer_rate` VARCHAR(50) DEFAULT NULL COMMENT '传输速率',
    `retry_count` INT DEFAULT 0 COMMENT '重试次数',
    `failure_reason` TEXT DEFAULT NULL COMMENT '失败原因',
    `checksum` VARCHAR(255) DEFAULT NULL COMMENT '校验和',
    `remarks` TEXT DEFAULT NULL COMMENT '备注',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uk_exchange_id` (`exchange_id`),
    INDEX `idx_source_organ_id` (`source_organ_id`),
    INDEX `idx_target_organ_id` (`target_organ_id`),
    INDEX `idx_exchange_type` (`exchange_type`),
    INDEX `idx_exchange_status` (`exchange_status`),
    INDEX `idx_start_time` (`start_time`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据交换日志表';

-- 插入默认审批配置
INSERT INTO `node_approval_config` (`workflow_type`, `approval_levels`, `description`, `is_enabled`)
VALUES
('ACCESS_APPLICATION', 1, '接入申请审批', 1),
('COOPERATION_APPLICATION', 1, '合作申请审批', 1),
('DATA_AUTHORIZATION', 1, '数据授权审批', 1),
('OTHER', 1, '其他审批', 1)
ON DUPLICATE KEY UPDATE workflow_type=workflow_type;

-- 显示结果
SELECT '节点管理增强功能表创建完成!' as message;
SELECT table_name, table_comment FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name LIKE 'node_%'
ORDER BY table_name;

