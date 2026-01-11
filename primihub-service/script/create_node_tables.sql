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
