-- PrimiHub 隐私计算平台 - 缺失数据库表初始化
-- 目标数据库: privacy0, privacy1, privacy2 (应用数据库)
--            fusion0, fusion1, fusion2 (元数据数据库)
-- 
-- 注意: 不要创建 privacy 数据库，该名称已被 Nacos 配置弃用
-- 真实连接串: jdbc:mysql://mysql:3306/privacy0 (tenant demo0)
--            jdbc:mysql://mysql:3306/privacy1 (tenant demo1)
--            jdbc:mysql://mysql:3306/privacy2 (tenant demo2)
--
-- 执行方式:
--   for db in privacy0 privacy1 privacy2; do
--     mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS \$db DEFAULT CHARSET utf8mb4"
--     mysql -uroot -proot \$db < init-privacy-db-tables.sql
--   done
-- =============================================

-- PrimiHub 隐私计算平台 - 缺失数据库表初始化
-- 目标数据库: privacy (primary)
-- 在 docker-compose up 之后执行: mysql -uroot -proot privacy < init-privacy-db-tables.sql

USE privacy;

-- =============================================
-- 1. sys_operation_log (操作日志)
-- =============================================
DROP TABLE IF EXISTS sys_operation_log;
CREATE TABLE sys_operation_log (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  log_code VARCHAR(64) DEFAULT NULL,
  user_id BIGINT(20) DEFAULT NULL,
  user_name VARCHAR(64) DEFAULT NULL,
  user_account VARCHAR(64) DEFAULT NULL,
  organ_id VARCHAR(64) DEFAULT NULL,
  organ_name VARCHAR(128) DEFAULT NULL,
  operation_type VARCHAR(64) DEFAULT NULL,
  operation_module VARCHAR(64) DEFAULT NULL,
  operation_desc VARCHAR(500) DEFAULT NULL,
  request_method VARCHAR(10) DEFAULT NULL,
  request_url VARCHAR(255) DEFAULT NULL,
  request_params TEXT DEFAULT NULL,
  response_code INT(11) DEFAULT NULL,
  response_msg VARCHAR(500) DEFAULT NULL,
  response_result TEXT DEFAULT NULL,
  ip_address VARCHAR(64) DEFAULT NULL,
  status INT(11) DEFAULT NULL,
  error_msg TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  exception_msg TEXT DEFAULT NULL,
  execution_time BIGINT(20) DEFAULT NULL,
  cost_time BIGINT(20) DEFAULT NULL,
  method VARCHAR(10) DEFAULT NULL,
  params TEXT DEFAULT NULL,
  ip VARCHAR(64) DEFAULT NULL,
  result TEXT DEFAULT NULL,
  user_agent VARCHAR(500) DEFAULT NULL,
  is_success TINYINT(4) DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  c_time DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
  u_time DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  operation_time DATETIME(3) DEFAULT NULL,
  create_date DATETIME DEFAULT NULL,
  PRIMARY KEY (id) USING BTREE,
  KEY idx_user_id (user_id) USING BTREE,
  KEY idx_operation_type (operation_type) USING BTREE,
  KEY idx_c_time (c_time) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 2. sys_config (系统配置)
-- =============================================
DROP TABLE IF EXISTS sys_config;
CREATE TABLE sys_config (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  config_group VARCHAR(255) DEFAULT NULL,
  config_key VARCHAR(255) NOT NULL,
  config_value TEXT DEFAULT NULL,
  config_desc VARCHAR(500) DEFAULT NULL,
  is_encrypted TINYINT(4) DEFAULT 0,
  created_by BIGINT(20) DEFAULT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_group_key (config_group, config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Default config values
INSERT IGNORE INTO sys_config (config_group, config_key, config_value, config_desc) VALUES
  ('network', 'domain', '', '网络域名'),
  ('network', 'apiGateway', '', 'API网关地址'),
  ('network', 'httpProxyPort', '7890', 'HTTP代理端口'),
  ('network', 'corsEnabled', 'true', '跨域启用'),
  ('network', 'requestTimeout', '30000', '请求超时(ms)'),
  ('security', 'firstLoginPolicy', 'enabled', '首次登录策略'),
  ('security', 'maxLoginAttempts', '5', '最大登录尝试'),
  ('security', 'lockoutDuration', '30', '锁定时长(分钟)'),
  ('security', 'passwordChangeRequired', 'true', '强制修改密码'),
  ('ftp', 'ftpHost', '', 'FTP服务器'),
  ('ftp', 'ftpPort', '21', 'FTP端口'),
  ('ftp', 'ftpUsername', '', 'FTP用户名'),
  ('ftp', 'ftpPassword', '', 'FTP密码'),
  ('ftp', 'ftpPath', '/', 'FTP路径'),
  ('time', 'timeSyncEnabled', 'true', '时间同步启用'),
  ('time', 'ntpServer', 'ntp.aliyun.com', 'NTP服务器'),
  ('time', 'syncInterval', '3600', '同步间隔(秒)');

-- =============================================
-- 3. federated_stats_task (联邦统计任务)
-- =============================================
CREATE TABLE IF NOT EXISTS federated_stats_task (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  task_name VARCHAR(255) DEFAULT NULL,
  project_id BIGINT(20) DEFAULT NULL,
  stats_type VARCHAR(50) DEFAULT NULL,
  algorithm_type VARCHAR(50) DEFAULT NULL,
  task_state INT(11) DEFAULT 0,
  task_param TEXT DEFAULT NULL,
  result_summary TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  created_by BIGINT(20) DEFAULT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS federated_stats_result (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  task_id BIGINT(20) DEFAULT NULL,
  result_type VARCHAR(50) DEFAULT NULL,
  result_data LONGTEXT DEFAULT NULL,
  result_file VARCHAR(500) DEFAULT NULL,
  row_count INT(11) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS federated_stats_config (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  config_name VARCHAR(255) DEFAULT NULL,
  storage_type VARCHAR(50) DEFAULT NULL,
  storage_path VARCHAR(500) DEFAULT NULL,
  connection_json TEXT DEFAULT NULL,
  is_default INT(11) DEFAULT 0,
  created_by BIGINT(20) DEFAULT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 4. federated_analysis_task (联邦分析任务)
-- =============================================
CREATE TABLE IF NOT EXISTS federated_analysis_task (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  task_name VARCHAR(255) DEFAULT NULL,
  project_id BIGINT(20) DEFAULT NULL,
  source_sql TEXT DEFAULT NULL,
  rewritten_sql TEXT DEFAULT NULL,
  task_state INT(11) DEFAULT 0,
  task_param TEXT DEFAULT NULL,
  result_summary TEXT DEFAULT NULL,
  result_row_count INT(11) DEFAULT 0,
  error_message TEXT DEFAULT NULL,
  created_by BIGINT(20) DEFAULT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS federated_analysis_result (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  task_id BIGINT(20) DEFAULT NULL,
  result_type VARCHAR(50) DEFAULT NULL,
  result_data LONGTEXT DEFAULT NULL,
  result_file VARCHAR(500) DEFAULT NULL,
  column_metadata TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  row_count INT(11) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 5. federated_learning (联邦学习)
-- =============================================
CREATE TABLE IF NOT EXISTS federated_learning (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  task_name VARCHAR(255) DEFAULT NULL,
  task_type INT(11) DEFAULT NULL COMMENT '1:建模 2:预测',
  algorithm_type INT(11) DEFAULT NULL COMMENT '1:线性回归 2:逻辑回归 3:XGBoost',
  federated_type INT(11) DEFAULT NULL COMMENT '1:横向 2:纵向',
  project_id BIGINT(20) DEFAULT NULL,
  own_organ_id VARCHAR(64) DEFAULT NULL,
  own_resource_id VARCHAR(64) DEFAULT NULL,
  own_features VARCHAR(500) DEFAULT NULL,
  label_feature VARCHAR(255) DEFAULT NULL,
  is_label_owner INT(11) DEFAULT 0,
  participant_organ_ids TEXT DEFAULT NULL,
  participant_resource_ids TEXT DEFAULT NULL,
  training_params TEXT DEFAULT NULL,
  model_id VARCHAR(64) DEFAULT NULL,
  model_path VARCHAR(500) DEFAULT NULL,
  result_path VARCHAR(500) DEFAULT NULL,
  remarks VARCHAR(500) DEFAULT NULL,
  user_id BIGINT(20) DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS federated_learning_task (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  fl_id BIGINT(20) DEFAULT NULL,
  task_id VARCHAR(64) DEFAULT NULL,
  task_state INT(11) DEFAULT 0 COMMENT '0:待执行 1:已完成 2:运行中 3:失败',
  current_round INT(11) DEFAULT 0,
  total_rounds INT(11) DEFAULT 0,
  accuracy DECIMAL(10,6) DEFAULT NULL,
  loss DECIMAL(10,6) DEFAULT NULL,
  metrics TEXT DEFAULT NULL,
  result_file_path VARCHAR(500) DEFAULT NULL,
  result_rows INT(11) DEFAULT 0,
  execution_log TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_task_id (task_id),
  KEY idx_fl_id (fl_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 6. single_party (单方数据处理)
-- =============================================
CREATE TABLE IF NOT EXISTS single_party (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  task_name VARCHAR(255) DEFAULT NULL,
  algorithm_type INT(11) DEFAULT NULL,
  resource_id VARCHAR(64) DEFAULT NULL,
  project_id BIGINT(20) DEFAULT NULL,
  selected_features TEXT DEFAULT NULL,
  algorithm_params TEXT DEFAULT NULL,
  result_path VARCHAR(500) DEFAULT NULL,
  remarks VARCHAR(500) DEFAULT NULL,
  user_id BIGINT(20) DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS single_party_task (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  sp_id BIGINT(20) DEFAULT NULL,
  task_id VARCHAR(64) DEFAULT NULL,
  task_state INT(11) DEFAULT 0 COMMENT '0:待执行 1:已完成 2:运行中 3:失败',
  result_file_path VARCHAR(500) DEFAULT NULL,
  result_rows INT(11) DEFAULT 0,
  result_summary TEXT DEFAULT NULL,
  execution_log TEXT DEFAULT NULL,
  error_message TEXT DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_date DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_task_id (task_id),
  KEY idx_sp_id (sp_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 7. whitelist (白名单)
-- =============================================
CREATE TABLE IF NOT EXISTS whitelist (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  type VARCHAR(64) DEFAULT NULL,
  value VARCHAR(255) DEFAULT NULL,
  description VARCHAR(500) DEFAULT NULL,
  status INT(11) DEFAULT 1,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  create_user_id BIGINT(20) DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS whitelist_config (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  config_key VARCHAR(255) DEFAULT NULL,
  config_value TEXT DEFAULT NULL,
  config_type VARCHAR(64) DEFAULT NULL,
  description VARCHAR(500) DEFAULT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  update_user_id BIGINT(20) DEFAULT NULL,
  update_user VARCHAR(64) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS whitelist_access_log (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  whitelist_id BIGINT(20) DEFAULT NULL,
  access_ip VARCHAR(64) DEFAULT NULL,
  access_url VARCHAR(500) DEFAULT NULL,
  request_method VARCHAR(10) DEFAULT NULL,
  access_result VARCHAR(32) DEFAULT NULL,
  fail_reason VARCHAR(500) DEFAULT NULL,
  user_id BIGINT(20) DEFAULT NULL,
  user_agent VARCHAR(500) DEFAULT NULL,
  request_params TEXT DEFAULT NULL,
  response_code INT(11) DEFAULT NULL,
  response_time BIGINT(20) DEFAULT NULL,
  access_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 8. sys_user_whitelist (用户白名单)
-- =============================================
CREATE TABLE IF NOT EXISTS sys_user_whitelist (
  whitelist_id BIGINT(20) NOT NULL AUTO_INCREMENT,
  whitelist_type INT(11) DEFAULT NULL,
  whitelist_value VARCHAR(255) DEFAULT NULL,
  whitelist_desc VARCHAR(500) DEFAULT NULL,
  status INT(11) DEFAULT 1,
  creator_name VARCHAR(64) DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  c_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  u_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (whitelist_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT CONCAT('Tables initialized: ', COUNT(*)) AS result FROM information_schema.tables WHERE table_schema = 'privacy';

-- =============================================
-- 9. api_manage (接口管理)
-- =============================================
CREATE TABLE IF NOT EXISTS api_manage (
  id BIGINT(20) NOT NULL AUTO_INCREMENT,
  api_name VARCHAR(255) DEFAULT NULL,
  api_path VARCHAR(500) DEFAULT NULL,
  api_type INT(11) DEFAULT NULL,
  api_desc TEXT DEFAULT NULL,
  api_status INT(11) DEFAULT 1,
  api_category VARCHAR(64) DEFAULT NULL,
  api_method VARCHAR(10) DEFAULT NULL,
  api_version VARCHAR(32) DEFAULT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  create_user_id BIGINT(20) DEFAULT NULL,
  update_user_id BIGINT(20) DEFAULT NULL,
  is_del TINYINT(4) DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- Table: tenant
CREATE TABLE `tenant` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_name` varchar(255) DEFAULT NULL,
  `tenant_code` varchar(64) DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `contact_name` varchar(64) DEFAULT NULL,
  `contact_phone` varchar(32) DEFAULT NULL,
  `expire_date` datetime DEFAULT NULL,
  `description` text,
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: tenant_resource
CREATE TABLE `tenant_resource` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `resource_id` varchar(64) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: evidence
CREATE TABLE `evidence` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `evidence_content` text,
  `evidence_hash` varchar(128) DEFAULT NULL,
  `evidence_type` varchar(32) DEFAULT NULL,
  `chain_id` int(11) DEFAULT NULL,
  `chain_tx_id` varchar(255) DEFAULT NULL,
  `chain_block_height` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: log_definition
CREATE TABLE `log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_type` varchar(32) DEFAULT NULL COMMENT 'operation/schedule/compute',
  `log_name` varchar(255) DEFAULT NULL,
  `log_desc` text,
  `retention_days` int(11) DEFAULT '90',
  `status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: monitor_alert
CREATE TABLE `monitor_alert` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `alert_name` varchar(255) DEFAULT NULL,
  `monitor_type` varchar(32) DEFAULT NULL,
  `threshold` decimal(10,2) DEFAULT NULL,
  `alert_level` int(11) DEFAULT '0',
  `enabled` tinyint(4) DEFAULT '1',
  `notify_channels` varchar(255) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_workflow
CREATE TABLE `node_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_name` varchar(255) DEFAULT NULL,
  `workflow_type` int(11) DEFAULT NULL,
  `requester_organ_id` varchar(64) DEFAULT NULL,
  `target_organ_id` varchar(64) DEFAULT NULL,
  `workflow_state` int(11) DEFAULT '0',
  `config_json` text,
  `approver_organ_ids` text,
  `description` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: data_requirement
CREATE TABLE `data_requirement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `requirement_name` varchar(255) DEFAULT NULL,
  `description` text,
  `data_resource_ids` text,
  `status` int(11) DEFAULT '0',
  `requester_organ_id` varchar(64) DEFAULT NULL,
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: shared_dataset
CREATE TABLE `shared_dataset` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `dataset_name` varchar(255) DEFAULT NULL,
  `resource_ids` text,
  `organ_ids` text,
  `share_type` int(11) DEFAULT '0',
  `status` int(11) DEFAULT '1',
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: police_fusion_key
CREATE TABLE `police_fusion_key` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `key_name` varchar(255) DEFAULT NULL,
  `key_type` varchar(32) DEFAULT NULL,
  `public_key` text,
  `private_key` text,
  `status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: police_fusion_api
CREATE TABLE `police_fusion_api` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_name` varchar(255) DEFAULT NULL,
  `api_url` varchar(500) DEFAULT NULL,
  `api_type` varchar(32) DEFAULT NULL,
  `api_key_id` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: electronic_cert_key
CREATE TABLE `electronic_cert_key` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `key_name` varchar(255) DEFAULT NULL,
  `key_type` varchar(32) DEFAULT NULL,
  `algorithm` varchar(32) DEFAULT NULL,
  `key_value` text,
  `status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: api_manage
CREATE TABLE `api_manage` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_name` varchar(255) DEFAULT NULL,
  `api_path` varchar(500) DEFAULT NULL,
  `api_type` int(11) DEFAULT NULL,
  `api_desc` text,
  `api_status` int(11) DEFAULT '1',
  `api_category` varchar(64) DEFAULT NULL,
  `api_method` varchar(10) DEFAULT NULL,
  `api_version` varchar(32) DEFAULT NULL,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_user_id` bigint(20) DEFAULT NULL,
  `update_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: api_auth
CREATE TABLE `api_auth` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `auth_name` varchar(255) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `api_ids` text,
  `auth_token` varchar(500) DEFAULT NULL,
  `expire_date` datetime DEFAULT NULL,
  `auth_status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: api_definition
CREATE TABLE `api_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_name` varchar(255) DEFAULT NULL,
  `api_path` varchar(500) DEFAULT NULL,
  `api_method` varchar(10) DEFAULT NULL,
  `protocol` varchar(32) DEFAULT NULL,
  `content_type` varchar(64) DEFAULT NULL,
  `description` text,
  `request_example` text,
  `response_example` text,
  `status` int(11) DEFAULT '1',
  `is_require_auth` int(11) DEFAULT '1',
  `rate_limit` int(11) DEFAULT '0',
  `timeout` int(11) DEFAULT '30000',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: api_auth_config
CREATE TABLE `api_auth_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_id` bigint(20) DEFAULT NULL,
  `auth_name` varchar(255) DEFAULT NULL,
  `app_key` varchar(128) DEFAULT NULL,
  `app_secret` varchar(128) DEFAULT NULL,
  `auth_type` varchar(32) DEFAULT NULL,
  `allowed_ips` text,
  `expire_time` datetime DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `description` text,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: api_call_log
CREATE TABLE `api_call_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_id` bigint(20) DEFAULT NULL,
  `auth_id` bigint(20) DEFAULT NULL,
  `request_path` varchar(500) DEFAULT NULL,
  `request_method` varchar(10) DEFAULT NULL,
  `request_params` text,
  `request_headers` text,
  `response_code` int(11) DEFAULT NULL,
  `response_body` longtext,
  `client_ip` varchar(64) DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `is_success` int(11) DEFAULT NULL,
  `error_message` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: evidence_record
CREATE TABLE `evidence_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `evidence_hash` varchar(128) DEFAULT NULL,
  `evidence_data` longtext,
  `evidence_type` varchar(32) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `file_type` varchar(32) DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `block_height` bigint(20) DEFAULT NULL,
  `block_hash` varchar(128) DEFAULT NULL,
  `tx_hash` varchar(128) DEFAULT NULL,
  `chain_type` varchar(32) DEFAULT NULL,
  `description` text,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: evidence_timestamp
CREATE TABLE `evidence_timestamp` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `evidence_id` bigint(20) DEFAULT NULL,
  `timestamp_value` varchar(255) DEFAULT NULL,
  `timestamp_hash` varchar(128) DEFAULT NULL,
  `timestamp_source` varchar(64) DEFAULT NULL,
  `nonce` varchar(64) DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: evidence_config
CREATE TABLE `evidence_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(255) DEFAULT NULL,
  `config_value` text,
  `config_desc` varchar(500) DEFAULT NULL,
  `is_encrypted` int(11) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: evidence_api_key
CREATE TABLE `evidence_api_key` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_key` varchar(128) DEFAULT NULL,
  `secret_key` varchar(128) DEFAULT NULL,
  `status` int(11) DEFAULT '1',
  `expiry_date` datetime DEFAULT NULL,
  `description` text,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: tenant
CREATE TABLE `tenant` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_code` varchar(64) DEFAULT NULL,
  `tenant_name` varchar(255) DEFAULT NULL,
  `contact_person` varchar(64) DEFAULT NULL,
  `contact_phone` varchar(32) DEFAULT NULL,
  `contact_email` varchar(128) DEFAULT NULL,
  `description` text,
  `status` int(11) DEFAULT '1',
  `data_isolation` int(11) DEFAULT '0',
  `compute_isolation` int(11) DEFAULT '0',
  `resource_count` int(11) DEFAULT '0',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: tenant_isolation_config
CREATE TABLE `tenant_isolation_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `config_type` varchar(64) DEFAULT NULL,
  `config_value` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: tenant_resource_allocation
CREATE TABLE `tenant_resource_allocation` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `resource_type` varchar(64) DEFAULT NULL,
  `resource_quota` int(11) DEFAULT '0',
  `resource_used` int(11) DEFAULT '0',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: data_requirement
CREATE TABLE `data_requirement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `requirement_code` varchar(64) DEFAULT NULL,
  `requirement_name` varchar(255) DEFAULT NULL,
  `requirement_desc` text,
  `requirement_type` int(11) DEFAULT NULL,
  `data_fields` text,
  `data_volume` bigint(20) DEFAULT NULL,
  `data_format` varchar(64) DEFAULT NULL,
  `priority` int(11) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(64) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `organ_name` varchar(128) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `remark` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: data_requirement_config
CREATE TABLE `data_requirement_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(255) DEFAULT NULL,
  `config_value` text,
  `config_desc` varchar(500) DEFAULT NULL,
  `config_type` varchar(64) DEFAULT NULL,
  `is_enabled` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: data_requirement_match
CREATE TABLE `data_requirement_match` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `requirement_id` bigint(20) DEFAULT NULL,
  `resource_id` varchar(64) DEFAULT NULL,
  `match_score` decimal(5,2) DEFAULT NULL,
  `match_status` int(11) DEFAULT '0',
  `match_type` int(11) DEFAULT NULL,
  `match_details` text,
  `confirm_user_id` bigint(20) DEFAULT NULL,
  `confirm_user_name` varchar(64) DEFAULT NULL,
  `confirm_date` datetime DEFAULT NULL,
  `remark` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_data_exchange_log
CREATE TABLE `node_data_exchange_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `exchange_id` varchar(64) DEFAULT NULL,
  `source_organ_id` varchar(64) DEFAULT NULL,
  `source_organ_name` varchar(128) DEFAULT NULL,
  `target_organ_id` varchar(64) DEFAULT NULL,
  `target_organ_name` varchar(128) DEFAULT NULL,
  `exchange_type` varchar(32) DEFAULT NULL,
  `data_type` varchar(32) DEFAULT NULL,
  `data_id` varchar(64) DEFAULT NULL,
  `data_name` varchar(255) DEFAULT NULL,
  `data_size` bigint(20) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `error_msg` text,
  `retry_count` int(11) DEFAULT '0',
  `started_at` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_approval_config
CREATE TABLE `node_approval_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_type` int(11) DEFAULT NULL,
  `is_enabled` int(11) DEFAULT '1',
  `steps_count` int(11) DEFAULT '1',
  `auto_approve_rules` text,
  `notification_enabled` int(11) DEFAULT '1',
  `notification_emails` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_approval_step
CREATE TABLE `node_approval_step` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` bigint(20) DEFAULT NULL,
  `step_number` int(11) DEFAULT NULL,
  `step_name` varchar(255) DEFAULT NULL,
  `approver_id` bigint(20) DEFAULT NULL,
  `approver_name` varchar(64) DEFAULT NULL,
  `approver_role` varchar(64) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `comment` text,
  `attachments` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_approval_workflow
CREATE TABLE `node_approval_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_type` int(11) DEFAULT NULL,
  `workflow_title` varchar(255) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `organ_name` varchar(128) DEFAULT NULL,
  `request_data` text,
  `current_step` int(11) DEFAULT '1',
  `total_steps` int(11) DEFAULT '1',
  `status` int(11) DEFAULT '0',
  `requester_id` bigint(20) DEFAULT NULL,
  `requester_name` varchar(64) DEFAULT NULL,
  `requester_comment` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_cooperation_party
CREATE TABLE `node_cooperation_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(64) DEFAULT NULL,
  `party_type` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `coop_start_time` datetime DEFAULT NULL,
  `coop_end_time` datetime DEFAULT NULL,
  `description` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: node_access_party
CREATE TABLE `node_access_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(64) DEFAULT NULL,
  `access_type` int(11) DEFAULT NULL,
  `access_key` varchar(128) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `description` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: sys_schedule_log
CREATE TABLE `sys_schedule_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `schedule_name` varchar(255) DEFAULT NULL,
  `schedule_type` varchar(64) DEFAULT NULL,
  `schedule_cron` varchar(128) DEFAULT NULL,
  `execute_server` varchar(128) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `result_message` text,
  `error_msg` text,
  `retry_count` int(11) DEFAULT '0',
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: sys_schedule_log_definition
CREATE TABLE `sys_schedule_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `schedule_type` varchar(64) DEFAULT NULL,
  `cron_expression` varchar(128) DEFAULT NULL,
  `description` text,
  `retention_days` int(11) DEFAULT '90',
  `status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: sys_compute_log
CREATE TABLE `sys_compute_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `task_id` varchar(64) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `compute_type` varchar(64) DEFAULT NULL,
  `project_id` bigint(20) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(64) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `organ_name` varchar(128) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `result_data` text,
  `error_msg` text,
  `resource_usage` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: sys_compute_log_definition
CREATE TABLE `sys_compute_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `compute_type` varchar(64) DEFAULT NULL,
  `description` text,
  `retention_days` int(11) DEFAULT '90',
  `status` int(11) DEFAULT '1',
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: federated_query_task
CREATE TABLE `federated_query_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id_name` varchar(64) DEFAULT NULL,
  `query_type` int(11) DEFAULT NULL,
  `query_params` text,
  `query_sql` text,
  `task_state` int(11) DEFAULT '0',
  `result_summary` text,
  `error_message` text,
  `created_by` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: federated_query_log
CREATE TABLE `federated_query_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` bigint(20) DEFAULT NULL,
  `query_content` text,
  `result_count` int(11) DEFAULT '0',
  `execution_time` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: federated_billing_record
CREATE TABLE `federated_billing_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `billing_code` varchar(64) DEFAULT NULL,
  `task_id` varchar(64) DEFAULT NULL,
  `billing_type` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT '0.00',
  `billing_status` int(11) DEFAULT '0',
  `remark` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: scene_api_config
CREATE TABLE `scene_api_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `scene_id` bigint(20) DEFAULT NULL,
  `api_name` varchar(255) DEFAULT NULL,
  `api_url` varchar(500) DEFAULT NULL,
  `api_method` varchar(10) DEFAULT NULL,
  `api_params` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: scene_key_config
CREATE TABLE `scene_key_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `scene_id` bigint(20) DEFAULT NULL,
  `key_name` varchar(255) DEFAULT NULL,
  `key_type` varchar(32) DEFAULT NULL,
  `algorithm` varchar(32) DEFAULT NULL,
  `public_key` text,
  `private_key` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

-- Table: scene_task
CREATE TABLE `scene_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_name` varchar(255) DEFAULT NULL,
  `scene_type` varchar(64) DEFAULT NULL,
  `task_params` text,
  `task_state` int(11) DEFAULT '0',
  `task_result` text,
  `error_message` text,
  `is_del` tinyint(4) DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

SELECT CONCAT('Tables initialized: ', COUNT(*)) AS result FROM information_schema.tables WHERE table_schema = 'privacy';
