-- V4__scene_imported_data.sql — 场景定制(电子证件/警务融合)机构数据接入的真实落库表。
-- 背景: /electronicCert/import 此前仅 createTask 记录任务、不真正落数据; /export 亦无数据可导。
-- 本表持久化每次导入的真实数据行(JSON), 供导出/后续隐私比对使用。
-- Flyway 在已连接 schema 内执行(无 USE 语句); CREATE TABLE IF NOT EXISTS 幂等。
CREATE TABLE IF NOT EXISTS `scene_imported_data` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `scene_type` VARCHAR(64) NOT NULL COMMENT '场景类型: electronic_cert / police_fusion',
  `task_id` BIGINT(20) DEFAULT NULL COMMENT '关联 scene_task.id',
  `batch_no` VARCHAR(64) DEFAULT NULL COMMENT '导入批次号',
  `row_index` INT(11) DEFAULT NULL COMMENT '批次内行号(从0起)',
  `row_json` TEXT COMMENT '单行数据(JSON)',
  `created_by` BIGINT(20) DEFAULT NULL COMMENT '导入人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '导入时间',
  PRIMARY KEY (`id`),
  KEY `idx_scene_type` (`scene_type`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_batch_no` (`batch_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='场景机构数据接入-真实数据行';
