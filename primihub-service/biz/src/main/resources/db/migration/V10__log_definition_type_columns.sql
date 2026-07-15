-- V6__log_definition_type_columns.sql — reconcile the 3 log-definition tables with the code.
-- The LogManagement entities use String logType/scheduleType/computeType, but the schema
-- (from the frozen dumps) has log_type/compute_type as INT and sys_schedule_log_definition
-- is missing schedule_type + module_name entirely — so "新增操作日志定义/调度/计算" all fail
-- (Data truncation / Unknown column). These tables are empty in production (the feature never
-- worked), so it is safe to fix the columns to match the code. NO `USE`; idempotent +
-- MySQL-5.7-compatible (information_schema-guarded; 5.7 has no MODIFY/ADD ... IF (NOT) EXISTS).

-- 1) sys_operation_log_definition.log_type: int -> varchar(64)
SET @t := (SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='sys_operation_log_definition' AND COLUMN_NAME='log_type');
SET @ddl := IF(@t='int',
  'ALTER TABLE `sys_operation_log_definition` MODIFY COLUMN `log_type` varchar(64) DEFAULT NULL COMMENT ''操作类型''',
  'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- 2) sys_compute_log_definition.compute_type: int -> varchar(64)
SET @t := (SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='sys_compute_log_definition' AND COLUMN_NAME='compute_type');
SET @ddl := IF(@t='int',
  'ALTER TABLE `sys_compute_log_definition` MODIFY COLUMN `compute_type` varchar(64) DEFAULT NULL COMMENT ''计算类型''',
  'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
-- sys_compute_log_definition also lacks module_name (the insert mapper writes it)
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='sys_compute_log_definition' AND COLUMN_NAME='module_name');
SET @ddl := IF(@c=0,
  'ALTER TABLE `sys_compute_log_definition` ADD COLUMN `module_name` varchar(128) DEFAULT NULL COMMENT ''模块名''',
  'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- 3) sys_schedule_log_definition: add schedule_type + module_name (code inserts both)
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='sys_schedule_log_definition' AND COLUMN_NAME='schedule_type');
SET @ddl := IF(@c=0,
  'ALTER TABLE `sys_schedule_log_definition` ADD COLUMN `schedule_type` varchar(64) DEFAULT NULL COMMENT ''调度类型''',
  'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='sys_schedule_log_definition' AND COLUMN_NAME='module_name');
SET @ddl := IF(@c=0,
  'ALTER TABLE `sys_schedule_log_definition` ADD COLUMN `module_name` varchar(128) DEFAULT NULL COMMENT ''模块名''',
  'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
