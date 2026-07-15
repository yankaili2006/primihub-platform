-- V3__v18_tables.sql — 18 v1.8.0 backend tables (tenant/whitelist/log/node-approval).
-- Flyway runs in the connected schema (privacy* on arm64, fusion* on prod) — NO `USE`.
-- Table DDL is regenerated from the CODE-ALIGNED production schema (fusion*, built by the
-- v1.8.0 defect-remediation work) so fresh deploys get exactly what the develop mappers expect
-- (e.g. sys_operation_log.response_code/response_msg). On an already-migrated DB every
-- CREATE TABLE IF NOT EXISTS is a clean no-op. Never edit an applied migration — add V4+.

CREATE TABLE IF NOT EXISTS `tenant` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_code` varchar(64) DEFAULT NULL,
  `tenant_name` varchar(255) DEFAULT NULL,
  `contact_person` varchar(128) DEFAULT NULL,
  `contact_phone` varchar(64) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `description` text,
  `status` int(11) DEFAULT '1',
  `data_isolation` int(11) DEFAULT '0',
  `compute_isolation` int(11) DEFAULT '0',
  `resource_count` bigint(20) DEFAULT '0',
  `is_del` tinyint(1) DEFAULT '0',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `tenant_resource_allocation` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `resource_type` varchar(64) DEFAULT NULL,
  `total_quota` bigint(20) DEFAULT NULL,
  `used_quota` bigint(20) DEFAULT '0',
  `reserved_quota` bigint(20) DEFAULT '0',
  `unit` varchar(32) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `tenant_isolation_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `isolation_type` varchar(64) DEFAULT NULL,
  `config_key` varchar(128) DEFAULT NULL,
  `config_value` text,
  `description` text,
  `is_enabled` tinyint(1) DEFAULT '1',
  `is_del` tinyint(1) DEFAULT '0',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `cpu_quota` int(11) DEFAULT '0' COMMENT 'CPU配额（核）',
  `memory_quota` int(11) DEFAULT '0' COMMENT '内存配额（GB）',
  `storage_quota` int(11) DEFAULT '0' COMMENT '存储配额（GB）',
  `dataset_limit` int(11) DEFAULT '0' COMMENT '数据集数量限制',
  `model_limit` int(11) DEFAULT '0' COMMENT '模型数量限制',
  `concurrent_tasks` int(11) DEFAULT '10' COMMENT '并发任务数',
  `network_isolation` tinyint(1) DEFAULT '0' COMMENT '网络隔离',
  `namespace` varchar(100) DEFAULT NULL COMMENT '命名空间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `whitelist` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `type` varchar(64) DEFAULT NULL,
  `value` varchar(512) DEFAULT NULL,
  `description` text,
  `status` int(11) DEFAULT '1',
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `whitelist_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(128) DEFAULT NULL,
  `config_value` text,
  `config_type` varchar(64) DEFAULT NULL,
  `description` text,
  `update_user_id` bigint(20) DEFAULT NULL,
  `update_user` varchar(255) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `whitelist_access_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `whitelist_id` bigint(20) DEFAULT NULL,
  `access_ip` varchar(128) DEFAULT NULL,
  `access_user_id` bigint(20) DEFAULT NULL,
  `access_type` varchar(64) DEFAULT NULL,
  `access_result` int(11) DEFAULT NULL,
  `remark` varchar(512) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `sys_operation_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `log_type` int(11) DEFAULT NULL,
  `module_name` varchar(128) DEFAULT NULL,
  `description` text,
  `is_enabled` tinyint(1) DEFAULT '1',
  `retention_days` int(11) DEFAULT '30',
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `sys_schedule_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `job_name` varchar(255) DEFAULT NULL,
  `description` text,
  `cron_expression` varchar(128) DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT '1',
  `retention_days` int(11) DEFAULT '30',
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `sys_compute_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `compute_type` int(11) DEFAULT NULL,
  `description` text,
  `is_enabled` tinyint(1) DEFAULT '1',
  `retention_days` int(11) DEFAULT '30',
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `sys_operation_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `user_id` bigint(20) DEFAULT NULL COMMENT '操作用户ID',
  `user_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '操作用户名',
  `operation_type` tinyint(4) DEFAULT NULL COMMENT '操作类型：1-新增 2-修改 3-删除 4-登录 5-登出',
  `operation_module` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '操作模块（如：用户管理、项目管理）',
  `operation_desc` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '操作描述',
  `request_method` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '请求方法：POST/PUT/DELETE',
  `request_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '请求URL',
  `request_params` text COLLATE utf8mb4_unicode_ci COMMENT '请求参数（JSON格式）',
  `response_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '响应状态码',
  `response_msg` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '响应消息',
  `operation_time` bigint(20) DEFAULT NULL COMMENT '操作耗时（毫秒）',
  `ip_address` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IP地址',
  `user_agent` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '用户代理',
  `exception_msg` text COLLATE utf8mb4_unicode_ci COMMENT '异常信息',
  `is_success` tinyint(4) DEFAULT '1' COMMENT '是否成功：0-失败 1-成功',
  `is_del` tinyint(4) DEFAULT '0' COMMENT '是否删除：0-否 1-是',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`log_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_operation_type` (`operation_type`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统操作日志表';
CREATE TABLE IF NOT EXISTS `sys_schedule_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(255) DEFAULT NULL,
  `job_group` varchar(128) DEFAULT NULL,
  `trigger_type` varchar(64) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `duration_ms` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `result_message` text,
  `error_message` text,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `sys_compute_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(255) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `compute_type` int(11) DEFAULT NULL,
  `organ_id` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(255) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `duration_ms` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `result_summary` text,
  `error_message` text,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `log_code` varchar(64) DEFAULT NULL,
  `project_id` bigint(20) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `error_msg` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `node_access_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `organ_gateway` varchar(512) DEFAULT NULL,
  `apply_reason` text,
  `access_level` int(11) DEFAULT NULL,
  `ip_whitelist` text,
  `valid_from` datetime DEFAULT NULL,
  `valid_until` datetime DEFAULT NULL,
  `apply_status` int(11) DEFAULT '0',
  `approve_user_id` bigint(20) DEFAULT NULL,
  `approve_user_name` varchar(255) DEFAULT NULL,
  `approve_comment` text,
  `approve_date` datetime DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '0',
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `node_cooperation_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `organ_gateway` varchar(512) DEFAULT NULL,
  `cooperation_type` int(11) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `agreement_file_path` varchar(512) DEFAULT NULL,
  `sla_uptime_target` double DEFAULT NULL,
  `sla_response_time` int(11) DEFAULT NULL,
  `health_score` double DEFAULT NULL,
  `data_sent_count` bigint(20) DEFAULT '0',
  `data_received_count` bigint(20) DEFAULT '0',
  `last_activity_time` datetime DEFAULT NULL,
  `cooperation_status` int(11) DEFAULT '0',
  `initiated_by_us` tinyint(1) DEFAULT '0',
  `created_by` bigint(20) DEFAULT NULL,
  `created_by_name` varchar(255) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `node_approval_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_type` varchar(64) DEFAULT NULL,
  `workflow_title` varchar(255) DEFAULT NULL,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `request_data` text,
  `current_step` int(11) DEFAULT '0',
  `total_steps` int(11) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `requester_id` bigint(20) DEFAULT NULL,
  `requester_name` varchar(255) DEFAULT NULL,
  `requester_comment` text,
  `final_approver_id` bigint(20) DEFAULT NULL,
  `final_approver_name` varchar(255) DEFAULT NULL,
  `final_comment` text,
  `approved_at` datetime DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `node_approval_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `workflow_type` varchar(64) DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT '1',
  `steps_count` int(11) DEFAULT '1',
  `notification_enabled` tinyint(1) DEFAULT '0',
  `notification_emails` text,
  `auto_approve_rules` text,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `node_approval_step` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` bigint(20) DEFAULT NULL,
  `step_number` int(11) DEFAULT NULL,
  `step_name` varchar(255) DEFAULT NULL,
  `approver_id` bigint(20) DEFAULT NULL,
  `approver_name` varchar(255) DEFAULT NULL,
  `approver_role` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `comment` text,
  `approved_at` datetime DEFAULT NULL,
  `attachments` text,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `node_data_exchange_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `exchange_id` varchar(255) DEFAULT NULL,
  `source_organ_id` varchar(255) DEFAULT NULL,
  `source_organ_name` varchar(255) DEFAULT NULL,
  `target_organ_id` varchar(255) DEFAULT NULL,
  `target_organ_name` varchar(255) DEFAULT NULL,
  `exchange_type` varchar(64) DEFAULT NULL,
  `data_type` varchar(64) DEFAULT NULL,
  `data_id` varchar(255) DEFAULT NULL,
  `data_name` varchar(255) DEFAULT NULL,
  `data_size` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `error_msg` text,
  `retry_count` int(11) DEFAULT '0',
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `duration_ms` bigint(20) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- generic default whitelist_config (idempotent; empty in a fresh deploy, no-op if already seeded).
-- NOTE: the *_log_definition / node_approval_config tables are intentionally NOT seeded —
-- they are empty in production (fusion*) and the app functions without reference rows.
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'enableWhitelist','false','boolean','是否启用白名单功能',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='enableWhitelist');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'defaultPolicy','DENY','string','默认策略：ALLOW-允许，DENY-拒绝',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='defaultPolicy');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'enableAccessLog','true','boolean','是否记录访问日志',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='enableAccessLog');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'logRetentionDays','30','number','日志保留天数',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='logRetentionDays');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'ipMatchMode','EXACT','string','IP匹配模式：EXACT-精确，CIDR-CIDR，RANGE-范围',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='ipMatchMode');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'maxFailedAttempts','5','number','最大失败尝试次数',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='maxFailedAttempts');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'lockDuration','30','number','锁定时长（分钟）',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='lockDuration');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'enableAlert','false','boolean','是否启用告警',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='enableAlert');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'alertEmails','','string','告警邮箱',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='alertEmails');
INSERT INTO `whitelist_config` (`config_key`,`config_value`,`config_type`,`description`,`is_del`)
SELECT 'cacheTime','300','number','缓存时间（秒）',0 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `whitelist_config` WHERE `config_key`='cacheTime');
