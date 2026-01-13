-- ========================================
-- 节点管理增强功能数据库迁移脚本
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3
-- ========================================

-- ========================================
-- PART 1: 扩展现有 sys_organ 表 (向后兼容)
-- ========================================

-- 添加节点描述和标签
ALTER TABLE `sys_organ` ADD COLUMN `description` TEXT COMMENT '节点描述' AFTER `u_time`;
ALTER TABLE `sys_organ` ADD COLUMN `tags` VARCHAR(500) DEFAULT NULL COMMENT '标签(逗号分隔)' AFTER `description`;

-- 添加联系人信息
ALTER TABLE `sys_organ` ADD COLUMN `contact_name` VARCHAR(100) DEFAULT NULL COMMENT '联系人姓名' AFTER `tags`;
ALTER TABLE `sys_organ` ADD COLUMN `contact_email` VARCHAR(100) DEFAULT NULL COMMENT '联系邮箱' AFTER `contact_name`;
ALTER TABLE `sys_organ` ADD COLUMN `contact_phone` VARCHAR(50) DEFAULT NULL COMMENT '联系电话' AFTER `contact_email`;

-- 添加节点能力和证书
ALTER TABLE `sys_organ` ADD COLUMN `capabilities` TEXT DEFAULT NULL COMMENT '节点能力(JSON格式)' AFTER `contact_phone`;
ALTER TABLE `sys_organ` ADD COLUMN `cert_file_path` VARCHAR(500) DEFAULT NULL COMMENT '证书文件路径' AFTER `capabilities`;

-- 添加取消合作相关字段
ALTER TABLE `sys_organ` ADD COLUMN `cancel_reason` TEXT DEFAULT NULL COMMENT '取消合作原因' AFTER `cert_file_path`;
ALTER TABLE `sys_organ` ADD COLUMN `cancel_time` DATETIME DEFAULT NULL COMMENT '取消合作时间' AFTER `cancel_reason`;
ALTER TABLE `sys_organ` ADD COLUMN `cancel_user_id` BIGINT DEFAULT NULL COMMENT '取消操作人ID' AFTER `cancel_time`;

-- 添加索引以提高查询性能
ALTER TABLE `sys_organ` ADD INDEX `idx_contact_email` (`contact_email`);
ALTER TABLE `sys_organ` ADD INDEX `idx_cancel_time` (`cancel_time`);

-- ========================================
-- PART 2: 创建新表
-- ========================================

-- 表1: 接入方管理表 (管理申请接入我方的节点)
DROP TABLE IF EXISTS `node_access_party`;
CREATE TABLE `node_access_party` (
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

-- 表2: 合作方管理表 (管理我方主动合作的节点)
DROP TABLE IF EXISTS `node_cooperation_party`;
CREATE TABLE `node_cooperation_party` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `organ_id` VARCHAR(255) NOT NULL COMMENT '合作方节点ID',
    `organ_name` VARCHAR(255) NOT NULL COMMENT '合作方节点名称',
    `organ_gateway` VARCHAR(500) DEFAULT NULL COMMENT '合作方网关地址',
    `cooperation_type` VARCHAR(50) DEFAULT NULL COMMENT '合作类型: project(项目合作), resource_sharing(资源共享), compute(算力), data_exchange(数据交换)',
    `start_date` DATETIME DEFAULT NULL COMMENT '合作开始时间',
    `end_date` DATETIME DEFAULT NULL COMMENT '合作结束时间',
    `agreement_file_path` VARCHAR(500) DEFAULT NULL COMMENT '合作协议文件路径',
    `sla_uptime_target` DECIMAL(5,2) DEFAULT 99.9 COMMENT 'SLA在线率目标(%)',
    `sla_response_time` INT DEFAULT 3000 COMMENT 'SLA响应时间(毫秒)',
    `health_score` INT DEFAULT 100 COMMENT '健康评分(0-100)',
    `data_sent_count` BIGINT DEFAULT 0 COMMENT '已发送数据量',
    `data_received_count` BIGINT DEFAULT 0 COMMENT '已接收数据量',
    `last_activity_time` DATETIME DEFAULT NULL COMMENT '最后活动时间',
    `cooperation_status` TINYINT NOT NULL DEFAULT 0 COMMENT '合作状态: 0=待确认, 1=进行中, 2=已过期, 3=已终止',
    `initiated_by_us` TINYINT NOT NULL DEFAULT 1 COMMENT '是否我方发起: 0=否, 1=是',
    `created_by` BIGINT DEFAULT NULL COMMENT '创建人ID',
    `created_by_name` VARCHAR(100) DEFAULT NULL COMMENT '创建人姓名',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    INDEX `idx_organ_id` (`organ_id`),
    INDEX `idx_cooperation_type` (`cooperation_type`),
    INDEX `idx_cooperation_status` (`cooperation_status`),
    INDEX `idx_end_date` (`end_date`),
    INDEX `idx_health_score` (`health_score`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合作方管理表';

-- 表3: 审批工作流表
DROP TABLE IF EXISTS `node_approval_workflow`;
CREATE TABLE `node_approval_workflow` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `workflow_type` VARCHAR(50) NOT NULL COMMENT '工作流类型: cooperation(合作申请), property_change(属性变更), data_exchange(数据交换), access_permission(访问权限)',
    `workflow_title` VARCHAR(200) NOT NULL COMMENT '工作流标题',
    `organ_id` VARCHAR(255) DEFAULT NULL COMMENT '关联节点ID',
    `organ_name` VARCHAR(255) DEFAULT NULL COMMENT '关联节点名称',
    `request_data` TEXT DEFAULT NULL COMMENT '请求数据(JSON格式)',
    `current_step` INT NOT NULL DEFAULT 1 COMMENT '当前审批步骤',
    `total_steps` INT NOT NULL DEFAULT 1 COMMENT '总审批步骤数',
    `status` TINYINT NOT NULL DEFAULT 0 COMMENT '工作流状态: 0=待审批, 1=已批准, 2=已拒绝, 3=已取消',
    `requester_id` BIGINT DEFAULT NULL COMMENT '申请人ID',
    `requester_name` VARCHAR(100) DEFAULT NULL COMMENT '申请人姓名',
    `requester_comment` TEXT DEFAULT NULL COMMENT '申请说明',
    `final_approver_id` BIGINT DEFAULT NULL COMMENT '最终审批人ID',
    `final_approver_name` VARCHAR(100) DEFAULT NULL COMMENT '最终审批人姓名',
    `final_comment` TEXT DEFAULT NULL COMMENT '最终审批意见',
    `approved_at` DATETIME DEFAULT NULL COMMENT '最终审批时间',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    INDEX `idx_workflow_type` (`workflow_type`),
    INDEX `idx_organ_id` (`organ_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_requester_id` (`requester_id`),
    INDEX `idx_create_date` (`create_date`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批工作流表';

-- 表4: 审批步骤表
DROP TABLE IF EXISTS `node_approval_step`;
CREATE TABLE `node_approval_step` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `workflow_id` BIGINT NOT NULL COMMENT '工作流ID',
    `step_number` INT NOT NULL COMMENT '步骤序号',
    `step_name` VARCHAR(100) NOT NULL COMMENT '步骤名称',
    `approver_id` BIGINT DEFAULT NULL COMMENT '审批人ID',
    `approver_name` VARCHAR(100) DEFAULT NULL COMMENT '审批人姓名',
    `approver_role` VARCHAR(50) DEFAULT NULL COMMENT '审批人角色',
    `status` TINYINT NOT NULL DEFAULT 0 COMMENT '步骤状态: 0=待审批, 1=已批准, 2=已拒绝',
    `comment` TEXT DEFAULT NULL COMMENT '审批意见',
    `attachments` TEXT DEFAULT NULL COMMENT '附件(JSON格式)',
    `approved_at` DATETIME DEFAULT NULL COMMENT '审批时间',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    INDEX `idx_workflow_id` (`workflow_id`),
    INDEX `idx_step_number` (`step_number`),
    INDEX `idx_approver_id` (`approver_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批步骤表';

-- 表5: 审批配置表
DROP TABLE IF EXISTS `node_approval_config`;
CREATE TABLE `node_approval_config` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `workflow_type` VARCHAR(50) NOT NULL UNIQUE COMMENT '工作流类型',
    `is_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用审批: 0=否, 1=是',
    `steps_count` INT NOT NULL DEFAULT 1 COMMENT '审批步骤数',
    `auto_approve_rules` TEXT DEFAULT NULL COMMENT '自动审批规则(JSON格式)',
    `notification_enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用通知: 0=否, 1=是',
    `notification_emails` TEXT DEFAULT NULL COMMENT '通知邮箱列表(逗号分隔)',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uk_workflow_type` (`workflow_type`),
    INDEX `idx_is_enabled` (`is_enabled`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批配置表';

-- 表6: 节点数据交换日志表
DROP TABLE IF EXISTS `node_data_exchange_log`;
CREATE TABLE `node_data_exchange_log` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `exchange_id` VARCHAR(255) NOT NULL UNIQUE COMMENT '交换ID(UUID)',
    `source_organ_id` VARCHAR(255) NOT NULL COMMENT '源节点ID',
    `source_organ_name` VARCHAR(255) DEFAULT NULL COMMENT '源节点名称',
    `target_organ_id` VARCHAR(255) NOT NULL COMMENT '目标节点ID',
    `target_organ_name` VARCHAR(255) DEFAULT NULL COMMENT '目标节点名称',
    `exchange_type` VARCHAR(50) NOT NULL COMMENT '交换类型: project_sync(项目同步), model_sync(模型同步), resource_copy(资源复制)',
    `data_type` VARCHAR(50) DEFAULT NULL COMMENT '数据类型: project, model, resource',
    `data_id` VARCHAR(255) DEFAULT NULL COMMENT '数据ID',
    `data_name` VARCHAR(255) DEFAULT NULL COMMENT '数据名称',
    `data_size` BIGINT DEFAULT 0 COMMENT '数据大小(字节)',
    `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态: 0=待处理, 1=成功, 2=失败, 3=部分成功',
    `error_msg` TEXT DEFAULT NULL COMMENT '错误信息',
    `retry_count` INT NOT NULL DEFAULT 0 COMMENT '重试次数',
    `started_at` DATETIME DEFAULT NULL COMMENT '开始时间',
    `completed_at` DATETIME DEFAULT NULL COMMENT '完成时间',
    `duration_ms` BIGINT DEFAULT NULL COMMENT '持续时间(毫秒)',
    `is_del` TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0=否, 1=是',
    `create_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `uk_exchange_id` (`exchange_id`),
    INDEX `idx_source_organ_id` (`source_organ_id`),
    INDEX `idx_target_organ_id` (`target_organ_id`),
    INDEX `idx_exchange_type` (`exchange_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_create_date` (`create_date`),
    INDEX `idx_is_del` (`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='节点数据交换日志表';

-- ========================================
-- PART 3: 插入默认配置数据
-- ========================================

-- 插入4种工作流类型的默认配置
INSERT INTO `node_approval_config` (`workflow_type`, `is_enabled`, `steps_count`, `auto_approve_rules`, `notification_enabled`, `notification_emails`)
VALUES
('cooperation', 1, 1, '{"auto_approve_threshold": 0}', 1, NULL),
('property_change', 1, 2, '{"auto_approve_threshold": 0}', 1, NULL),
('data_exchange', 1, 1, '{"auto_approve_threshold": 1000000}', 1, NULL),
('access_permission', 1, 1, '{"auto_approve_threshold": 1}', 1, NULL);

-- ========================================
-- PART 4: 验证表创建
-- ========================================

-- 验证 sys_organ 表的新增字段
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'sys_organ'
AND COLUMN_NAME IN ('description', 'tags', 'contact_name', 'contact_email', 'contact_phone',
                     'capabilities', 'cert_file_path', 'cancel_reason', 'cancel_time', 'cancel_user_id')
ORDER BY ORDINAL_POSITION;

-- 验证新表创建
SELECT
    TABLE_NAME,
    TABLE_COMMENT,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN ('node_access_party', 'node_cooperation_party', 'node_approval_workflow',
                    'node_approval_step', 'node_approval_config', 'node_data_exchange_log')
ORDER BY TABLE_NAME;

-- 验证审批配置数据
SELECT * FROM node_approval_config WHERE is_del = 0;

-- 显示结果说明
SELECT '节点管理增强功能数据库迁移已成功完成!' as message,
       '已添加 10 个字段到 sys_organ 表' as step1,
       '已创建 6 个新表' as step2,
       '已插入 4 条默认审批配置' as step3;
