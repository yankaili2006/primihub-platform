-- ========================================
-- 联邦求差和联邦求并功能数据库表
-- ========================================

-- 联邦求差主表
CREATE TABLE IF NOT EXISTS `data_difference` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '求差主键',
  `own_organ_id` VARCHAR(50) NOT NULL COMMENT '本机构id',
  `own_resource_id` VARCHAR(50) NOT NULL COMMENT '本机构资源id',
  `own_keyword` VARCHAR(255) NOT NULL COMMENT '本机构资源关键字',
  `other_organ_id` VARCHAR(50) NOT NULL COMMENT '其他机构id',
  `other_resource_id` VARCHAR(50) NOT NULL COMMENT '其他机构资源id',
  `other_keyword` VARCHAR(255) NOT NULL COMMENT '其他机构资源关键字',
  `output_file_path_type` TINYINT(4) DEFAULT 0 COMMENT '文件路径输出类型 0默认 自动生成',
  `output_no_repeat` TINYINT(4) DEFAULT 0 COMMENT '输出内容是否不去重 默认0 不去重 1去重',
  `tag` TINYINT(4) DEFAULT 0 COMMENT '实现方法 0:ECDH 1:KKRT 2:TEE',
  `result_name` VARCHAR(255) NOT NULL COMMENT '结果名称',
  `output_format` VARCHAR(50) DEFAULT 'csv' COMMENT '输出格式',
  `result_organ_ids` VARCHAR(255) NOT NULL COMMENT '结果获取方 多机构逗号间隔',
  `difference_direction` TINYINT(4) DEFAULT 0 COMMENT '求差方向 0:本机构-其他机构 1:其他机构-本机构',
  `remarks` TEXT COMMENT '备注',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `tee_organ_id` VARCHAR(50) DEFAULT NULL COMMENT 'TEE机构ID',
  `is_del` TINYINT(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_own_organ_id` (`own_organ_id`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦求差主表';

-- 联邦求差任务表
CREATE TABLE IF NOT EXISTS `data_difference_task` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '求差任务id',
  `difference_id` BIGINT(20) NOT NULL COMMENT '求差id',
  `task_id` VARCHAR(100) NOT NULL COMMENT '对外展示的任务uuid',
  `task_state` TINYINT(4) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `ascription` VARCHAR(255) DEFAULT NULL COMMENT '结果归属',
  `ascription_type` TINYINT(4) DEFAULT 0 COMMENT '结果归属类型 0一方 1双方',
  `file_rows` INT(11) DEFAULT 0 COMMENT '结果文件行数',
  `file_path` VARCHAR(500) DEFAULT NULL COMMENT '文件路径',
  `file_content` TEXT DEFAULT NULL COMMENT '文件内容',
  `is_del` TINYINT(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_difference_id` (`difference_id`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦求差任务表';

-- 联邦求并主表
CREATE TABLE IF NOT EXISTS `data_union` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '求并主键',
  `own_organ_id` VARCHAR(50) NOT NULL COMMENT '本机构id',
  `own_resource_id` VARCHAR(50) NOT NULL COMMENT '本机构资源id',
  `own_keyword` VARCHAR(255) NOT NULL COMMENT '本机构资源关键字',
  `other_organ_id` VARCHAR(50) NOT NULL COMMENT '其他机构id',
  `other_resource_id` VARCHAR(50) NOT NULL COMMENT '其他机构资源id',
  `other_keyword` VARCHAR(255) NOT NULL COMMENT '其他机构资源关键字',
  `output_file_path_type` TINYINT(4) DEFAULT 0 COMMENT '文件路径输出类型 0默认 自动生成',
  `output_no_repeat` TINYINT(4) DEFAULT 0 COMMENT '输出内容是否不去重 默认0 不去重 1去重',
  `tag` TINYINT(4) DEFAULT 0 COMMENT '实现方法 0:ECDH 1:KKRT 2:TEE',
  `result_name` VARCHAR(255) NOT NULL COMMENT '结果名称',
  `output_format` VARCHAR(50) DEFAULT 'csv' COMMENT '输出格式',
  `result_organ_ids` VARCHAR(255) NOT NULL COMMENT '结果获取方 多机构逗号间隔',
  `remarks` TEXT COMMENT '备注',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `tee_organ_id` VARCHAR(50) DEFAULT NULL COMMENT 'TEE机构ID',
  `is_del` TINYINT(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_own_organ_id` (`own_organ_id`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦求并主表';

-- 联邦求并任务表
CREATE TABLE IF NOT EXISTS `data_union_task` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '求并任务id',
  `union_id` BIGINT(20) NOT NULL COMMENT '求并id',
  `task_id` VARCHAR(100) NOT NULL COMMENT '对外展示的任务uuid',
  `task_state` TINYINT(4) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `ascription` VARCHAR(255) DEFAULT NULL COMMENT '结果归属',
  `ascription_type` TINYINT(4) DEFAULT 0 COMMENT '结果归属类型 0一方 1双方',
  `file_rows` INT(11) DEFAULT 0 COMMENT '结果文件行数',
  `file_path` VARCHAR(500) DEFAULT NULL COMMENT '文件路径',
  `file_content` TEXT DEFAULT NULL COMMENT '文件内容',
  `is_del` TINYINT(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_union_id` (`union_id`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦求并任务表';
