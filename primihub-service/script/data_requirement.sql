-- 数据需求管理数据库表
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3

-- 1. 数据需求主表
CREATE TABLE IF NOT EXISTS `data_requirement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_code` VARCHAR(64) NOT NULL COMMENT '需求编码',
  `requirement_name` VARCHAR(128) NOT NULL COMMENT '需求名称',
  `requirement_desc` TEXT COMMENT '需求描述',
  `requirement_type` VARCHAR(32) COMMENT '需求类型(模型训练/数据分析/隐私求交/其他)',
  `data_fields` TEXT COMMENT '所需数据字段(JSON格式)',
  `data_volume` BIGINT COMMENT '所需数据量',
  `data_format` VARCHAR(32) COMMENT '所需数据格式(CSV/JSON/Excel/其他)',
  `priority` TINYINT DEFAULT 0 COMMENT '优先级(0-低 1-中 2-高)',
  `status` TINYINT DEFAULT 0 COMMENT '状态(0-待匹配 1-已匹配 2-已完成 3-已关闭)',
  `user_id` BIGINT NOT NULL COMMENT '创建人用户ID',
  `user_name` VARCHAR(64) COMMENT '创建人用户名',
  `organ_id` BIGINT COMMENT '机构ID',
  `organ_name` VARCHAR(128) COMMENT '机构名称',
  `start_date` DATETIME COMMENT '需求开始日期',
  `end_date` DATETIME COMMENT '需求结束日期',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记(0-未删除 1-已删除)',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_code` (`requirement_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_organ_id` (`organ_id`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求表';

-- 2. 数据需求配置表
CREATE TABLE IF NOT EXISTS `data_requirement_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_key` VARCHAR(64) NOT NULL COMMENT '配置键',
  `config_value` TEXT NOT NULL COMMENT '配置值',
  `config_desc` VARCHAR(255) COMMENT '配置描述',
  `config_type` VARCHAR(32) COMMENT '配置类型(系统配置/匹配规则/评分权重/其他)',
  `is_enabled` TINYINT DEFAULT 1 COMMENT '启用标记(0-禁用 1-启用)',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记(0-未删除 1-已删除)',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`),
  KEY `idx_config_type` (`config_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求配置表';

-- 3. 数据需求匹配表
CREATE TABLE IF NOT EXISTS `data_requirement_match` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_id` BIGINT NOT NULL COMMENT '需求ID',
  `resource_id` BIGINT NOT NULL COMMENT '资源ID(来自data_resource表)',
  `match_score` DECIMAL(5,2) DEFAULT 0.00 COMMENT '匹配得分(0.00-100.00)',
  `match_status` TINYINT DEFAULT 0 COMMENT '匹配状态(0-待确认 1-已确认 2-已拒绝)',
  `match_type` VARCHAR(32) COMMENT '匹配类型(自动匹配/手动匹配)',
  `match_details` TEXT COMMENT '匹配详情(JSON格式,包含各项得分明细)',
  `confirm_user_id` BIGINT COMMENT '确认人用户ID',
  `confirm_user_name` VARCHAR(64) COMMENT '确认人用户名',
  `confirm_date` DATETIME COMMENT '确认时间',
  `remark` VARCHAR(500) COMMENT '备注',
  `is_del` TINYINT DEFAULT 0 COMMENT '删除标记(0-未删除 1-已删除)',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_requirement_id` (`requirement_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_match_score` (`match_score`),
  KEY `idx_match_status` (`match_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据需求匹配表';

-- 4. 插入默认配置数据
INSERT INTO `data_requirement_config` (`config_key`, `config_value`, `config_desc`, `config_type`, `is_enabled`) VALUES
('match_threshold', '60.00', '匹配阈值：只有得分高于此值的资源才会被推荐', '匹配规则', 1),
('field_match_weight', '40', '字段匹配权重(满分100)', '评分权重', 1),
('volume_match_weight', '20', '数据量匹配权重(满分100)', '评分权重', 1),
('format_match_weight', '20', '数据格式匹配权重(满分100)', '评分权重', 1),
('type_match_weight', '20', '数据类型匹配权重(满分100)', '评分权重', 1),
('auto_match_enabled', 'true', '是否启用自动匹配功能', '系统配置', 1),
('max_match_results', '50', '单次匹配返回的最大结果数', '系统配置', 1);

-- 5. 验证表创建
SELECT TABLE_NAME, TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN ('data_requirement', 'data_requirement_config', 'data_requirement_match');
