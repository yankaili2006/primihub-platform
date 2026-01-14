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
