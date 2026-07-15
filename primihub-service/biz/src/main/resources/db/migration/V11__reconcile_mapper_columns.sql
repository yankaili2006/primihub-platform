-- V7__reconcile_mapper_columns.sql — add every column the MyBatis mappers INSERT/UPDATE
-- that the deployed schema is missing (found by static mapper-vs-live-schema analysis).
-- Root cause: several v1.8.0 feature tables (log-management, tenant-resource, whitelist
-- access-log) were built against schemas that don't match the current mappers, and were
-- always empty in prod so the mismatch was never hit. Column types inferred from the entity
-- POJOs. NO `USE`; idempotent + MySQL-5.7-compatible (information_schema-guarded).

-- ---- sys_compute_log ----
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_compute_log' AND COLUMN_NAME='resource_usage');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_compute_log` ADD COLUMN `resource_usage` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_compute_log' AND COLUMN_NAME='result_data');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_compute_log` ADD COLUMN `result_data` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- sys_operation_log ----
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='error_msg');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `error_msg` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='execution_time');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `execution_time` bigint DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='log_code');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `log_code` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='organ_id');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `organ_id` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='organ_name');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `organ_name` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='response_result');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `response_result` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='status');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_operation_log` ADD COLUMN `status` int DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- sys_schedule_log ----
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='error_msg');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `error_msg` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='execute_server');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `execute_server` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='execution_time');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `execution_time` bigint DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='log_code');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `log_code` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='retry_count');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `retry_count` int DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='schedule_cron');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `schedule_cron` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='schedule_name');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `schedule_name` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_schedule_log' AND COLUMN_NAME='schedule_type');
SET @ddl := IF(@c=0, 'ALTER TABLE `sys_schedule_log` ADD COLUMN `schedule_type` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- tenant_resource_allocation ----
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='effective_time');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `effective_time` datetime DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='expiry_time');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `expiry_time` datetime DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='permission_level');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `permission_level` int DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='quota_amount');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `quota_amount` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='quota_unit');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `quota_unit` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='remark');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `remark` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='resource_id');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `resource_id` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='resource_name');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `resource_name` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tenant_resource_allocation' AND COLUMN_NAME='status');
SET @ddl := IF(@c=0, 'ALTER TABLE `tenant_resource_allocation` ADD COLUMN `status` int DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- whitelist_access_log ----
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='access_time');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `access_time` datetime DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='access_url');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `access_url` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='fail_reason');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `fail_reason` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='request_method');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `request_method` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='request_params');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `request_params` varchar(1024) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='response_code');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `response_code` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='response_time');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `response_time` bigint DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='user_agent');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `user_agent` varchar(255) DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='whitelist_access_log' AND COLUMN_NAME='user_id');
SET @ddl := IF(@c=0, 'ALTER TABLE `whitelist_access_log` ADD COLUMN `user_id` bigint DEFAULT NULL', 'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

