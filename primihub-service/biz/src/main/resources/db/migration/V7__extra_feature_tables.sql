-- V7__extra_feature_tables.sql — 求差/求并/联邦学习/单方计算 的表(散落在仓库根 database_schema_*.sql,
-- 从未进 Flyway/部署)。runtime 实测缺 federated_learning/data_difference/data_union/single_party 等 ->
-- 对应模块 'Table doesn't exist'。合并 3 个 schema 文件(全幂等 CREATE IF NOT EXISTS)。

-- ===== from database_schema_federated_learning.sql =====
-- ========================================
-- 联邦学习功能数据库表
-- ========================================

-- 联邦学习主表
CREATE TABLE IF NOT EXISTS `federated_learning` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '联邦学习主键',
  `task_type` TINYINT(4) NOT NULL COMMENT '任务类型 1:建模 2:预测',
  `algorithm_type` TINYINT(4) NOT NULL COMMENT '算法类型 1:线性回归 2:逻辑回归 3:XGBoost',
  `federated_type` TINYINT(4) NOT NULL DEFAULT 2 COMMENT '联邦类型 1:横向 2:纵向',
  `task_name` VARCHAR(255) NOT NULL COMMENT '任务名称',
  `project_id` BIGINT(20) DEFAULT NULL COMMENT '项目ID',
  `own_organ_id` VARCHAR(50) NOT NULL COMMENT '本机构id',
  `own_resource_id` VARCHAR(50) NOT NULL COMMENT '本机构资源id',
  `own_features` TEXT COMMENT '本机构特征字段（逗号分隔）',
  `label_feature` VARCHAR(255) DEFAULT NULL COMMENT '标签字段（仅标签方有值）',
  `is_label_owner` TINYINT(4) DEFAULT 0 COMMENT '是否为标签方 0否 1是',
  `participant_organ_ids` VARCHAR(255) NOT NULL COMMENT '参与机构ids（逗号分隔）',
  `participant_resource_ids` TEXT COMMENT '参与机构资源ids（JSON格式）',
  `training_params` TEXT COMMENT '训练参数（JSON格式）',
  `model_id` VARCHAR(100) DEFAULT NULL COMMENT '模型ID（预测时使用）',
  `model_path` VARCHAR(500) DEFAULT NULL COMMENT '模型存储路径',
  `result_path` VARCHAR(500) DEFAULT NULL COMMENT '结果存储路径',
  `remarks` TEXT COMMENT '备注',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `is_del` TINYINT(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_own_organ_id` (`own_organ_id`),
  KEY `idx_task_type` (`task_type`),
  KEY `idx_algorithm_type` (`algorithm_type`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_create_date` (`create_date`),
  KEY `idx_model_id` (`model_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦学习主表';

-- 联邦学习任务表
CREATE TABLE IF NOT EXISTS `federated_learning_task` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '联邦学习任务id',
  `fl_id` BIGINT(20) NOT NULL COMMENT '联邦学习id',
  `task_id` VARCHAR(100) NOT NULL COMMENT '对外展示的任务uuid',
  `task_state` TINYINT(4) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `current_round` INT(11) DEFAULT 0 COMMENT '当前轮次',
  `total_rounds` INT(11) DEFAULT 0 COMMENT '总轮次',
  `accuracy` DOUBLE DEFAULT NULL COMMENT '训练准确率',
  `loss` DOUBLE DEFAULT NULL COMMENT '训练损失',
  `metrics` TEXT COMMENT '模型评估指标（JSON格式）',
  `result_rows` INT(11) DEFAULT 0 COMMENT '预测结果行数',
  `result_file_path` VARCHAR(500) DEFAULT NULL COMMENT '结果文件路径',
  `execution_log` TEXT COMMENT '执行日志',
  `is_del` TINYINT(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_fl_id` (`fl_id`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='联邦学习任务表';

-- 添加示例训练参数说明
-- training_params JSON格式示例:
-- {
--   "learningRate": 0.01,
--   "batchSize": 32,
--   "epochs": 10,
--   "numTrees": 100,              // XGBoost特有
--   "maxDepth": 6,                // XGBoost特有
--   "regularization": 0.01,
--   "useDifferentialPrivacy": false,
--   "epsilon": 1.0                // 差分隐私参数
-- }

-- 添加示例评估指标说明
-- metrics JSON格式示例:
-- {
--   "precision": 0.85,
--   "recall": 0.82,
--   "f1Score": 0.83,
--   "auc": 0.90,
--   "rmse": 0.25,                // 回归任务
--   "mae": 0.18,                 // 回归任务
--   "r2Score": 0.88              // 回归任务
-- }

-- ===== from database_schema_difference_union.sql =====
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

-- ===== from database_schema_single_party.sql =====
-- 单方算法表结构

-- 单方算法主表
CREATE TABLE IF NOT EXISTS `single_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `algorithm_type` int(11) NOT NULL COMMENT '算法类型 1:数据统计 2:数据清洗 3:数据缩放 4:特征编码 5:特征分箱 6:特征筛选 7:特征衍生 8:LR算法 9:XGB算法 10:Python脚本',
  `task_name` varchar(255) NOT NULL COMMENT '任务名称',
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目ID',
  `resource_id` varchar(100) NOT NULL COMMENT '资源ID',
  `selected_features` text COMMENT '选择的特征字段（逗号分隔）',
  `algorithm_params` text COMMENT '算法参数（JSON格式）',
  `result_path` varchar(500) DEFAULT NULL COMMENT '结果存储路径',
  `remarks` varchar(500) DEFAULT NULL COMMENT '备注',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `is_del` int(11) DEFAULT '0' COMMENT '是否删除 0否 1是',
  `create_date` datetime DEFAULT NULL COMMENT '创建时间',
  `update_date` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_algorithm_type` (`algorithm_type`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='单方算法表';

-- 单方算法任务表
CREATE TABLE IF NOT EXISTS `single_party_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `sp_id` bigint(20) NOT NULL COMMENT '单方算法ID',
  `task_id` varchar(100) NOT NULL COMMENT '任务UUID',
  `task_state` int(11) DEFAULT '0' COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `result_rows` int(11) DEFAULT NULL COMMENT '结果行数',
  `result_file_path` varchar(500) DEFAULT NULL COMMENT '结果文件路径',
  `execution_log` text COMMENT '执行日志',
  `is_del` int(11) DEFAULT '0' COMMENT '是否删除 0否 1是',
  `create_date` datetime DEFAULT NULL COMMENT '创建时间',
  `update_date` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_sp_id` (`sp_id`),
  KEY `idx_task_state` (`task_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='单方算法任务表';

