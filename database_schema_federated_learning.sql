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
