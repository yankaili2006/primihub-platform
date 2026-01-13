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
