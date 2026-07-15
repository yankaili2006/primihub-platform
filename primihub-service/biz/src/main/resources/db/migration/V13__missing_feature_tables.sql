-- V13__missing_feature_tables.sql — 11 tables referenced by backend mappers but created
-- nowhere (contract-check [C] failures on develop). DDL from the code-aligned production
-- schema (fusion*). NO `USE`; idempotent CREATE TABLE IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS `data_resource_auth_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(255) DEFAULT NULL,
  `auth_organ_id` varchar(255) DEFAULT NULL,
  `auth_organ_name` varchar(255) DEFAULT NULL,
  `auth_type` int(11) DEFAULT NULL,
  `grouping` int(11) DEFAULT NULL,
  `relevance` int(11) DEFAULT NULL,
  `protection_status` int(11) DEFAULT NULL,
  `auth_status` int(11) DEFAULT '0',
  `apply_user_id` bigint(20) DEFAULT NULL,
  `apply_user_name` varchar(255) DEFAULT NULL,
  `approve_user_id` bigint(20) DEFAULT NULL,
  `approve_user_name` varchar(255) DEFAULT NULL,
  `approve_comment` text,
  `approve_date` datetime DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT '0',
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `federated_stats_task_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` bigint(20) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) DEFAULT NULL,
  `stats_type` int(11) DEFAULT NULL,
  `algorithm_type` int(11) DEFAULT NULL,
  `task_state` int(11) DEFAULT '0',
  `task_param` text,
  `result_type` int(11) DEFAULT NULL,
  `result_data` text,
  `result_file` varchar(512) DEFAULT NULL,
  `result_summary` text,
  `row_count` bigint(20) DEFAULT NULL,
  `error_message` text,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fl_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` varchar(64) DEFAULT NULL,
  `workflow_name` varchar(255) DEFAULT NULL,
  `participants` text,
  `dataset_id` varchar(141) DEFAULT NULL,
  `dataset_name` varchar(255) DEFAULT NULL,
  `rounds` int(11) DEFAULT '100',
  `learning_rate` double DEFAULT '0.01',
  `nodes` mediumtext,
  `status` tinyint(4) DEFAULT '0',
  `result_summary` varchar(1000) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(64) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_wf` (`workflow_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦建模工作流';

CREATE TABLE IF NOT EXISTS `fl_workflow_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` varchar(64) DEFAULT NULL,
  `log_level` varchar(16) DEFAULT 'info',
  `log_content` varchar(2000) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_wf` (`workflow_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦建模工作流日志';

CREATE TABLE IF NOT EXISTS `project_ledger_export` (
  `export_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `export_type` varchar(16) DEFAULT NULL,
  `export_format` varchar(16) DEFAULT NULL,
  `project_count` int(11) DEFAULT '0',
  `project_ids` varchar(4000) DEFAULT NULL,
  `export_status` tinyint(4) DEFAULT '1',
  `export_user_id` bigint(20) DEFAULT NULL,
  `export_user_name` varchar(64) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_content` mediumtext,
  `error_msg` varchar(500) DEFAULT NULL,
  `export_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`export_id`),
  KEY `idx_user` (`export_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目台账导出记录';

CREATE TABLE IF NOT EXISTS `project_permission` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `project_id` varchar(141) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `permission_type` varchar(32) DEFAULT NULL,
  `permission_status` tinyint(4) DEFAULT '0',
  `template_id` bigint(20) DEFAULT NULL,
  `resource_ids` varchar(2000) DEFAULT NULL,
  `grant_date` datetime DEFAULT NULL,
  `expire_date` datetime DEFAULT NULL,
  `grant_user_id` bigint(20) DEFAULT NULL,
  `grant_user_name` varchar(64) DEFAULT NULL,
  `revoke_user_id` bigint(20) DEFAULT NULL,
  `revoke_user_name` varchar(64) DEFAULT NULL,
  `remark` varchar(500) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`permission_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目权限';

CREATE TABLE IF NOT EXISTS `project_permission_template` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) DEFAULT NULL,
  `template_desc` varchar(500) DEFAULT NULL,
  `permissions` varchar(255) DEFAULT NULL,
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目权限模板';

CREATE TABLE IF NOT EXISTS `project_result` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `project_id` varchar(141) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `task_id` varchar(141) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `result_type` varchar(32) DEFAULT NULL,
  `result_name` varchar(255) DEFAULT NULL,
  `result_desc` varchar(500) DEFAULT NULL,
  `save_status` tinyint(4) DEFAULT '0',
  `file_size` bigint(20) DEFAULT NULL,
  `file_md5` varchar(64) DEFAULT NULL,
  `save_path` varchar(500) DEFAULT NULL,
  `save_directory` varchar(255) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `save_format` varchar(32) DEFAULT NULL,
  `file_content` mediumtext,
  `remark` varchar(500) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `save_date` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`save_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目结果保存';

CREATE TABLE IF NOT EXISTS `project_result_config` (
  `id` bigint(20) NOT NULL,
  `default_path` varchar(255) DEFAULT '/data/results',
  `auto_save` tinyint(4) DEFAULT '0',
  `retention_days` int(11) DEFAULT '30',
  `max_storage_gb` int(11) DEFAULT '100',
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目结果保存配置';

CREATE TABLE IF NOT EXISTS `sp_ext_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(141) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `task_category` varchar(16) DEFAULT NULL,
  `log_level` varchar(16) DEFAULT 'INFO',
  `log_content` varchar(2000) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='单方作业学习日志';

CREATE TABLE IF NOT EXISTS `sp_ext_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(141) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `task_category` varchar(16) DEFAULT 'PREPROCESS',
  `algorithm_type` int(11) DEFAULT NULL,
  `sub_type` varchar(32) DEFAULT NULL,
  `resource_id` varchar(141) DEFAULT NULL,
  `resource_name` varchar(255) DEFAULT NULL,
  `params` text,
  `task_state` tinyint(4) DEFAULT '0',
  `progress` int(11) DEFAULT '0',
  `result_content` mediumtext,
  `result_path` varchar(500) DEFAULT NULL,
  `error_msg` varchar(1000) DEFAULT NULL,
  `remark` varchar(500) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(64) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_cat` (`task_category`),
  KEY `idx_state` (`task_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='单方作业预处理/脚本任务';

