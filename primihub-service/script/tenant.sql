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
