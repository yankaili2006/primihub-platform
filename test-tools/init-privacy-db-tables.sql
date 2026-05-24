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
