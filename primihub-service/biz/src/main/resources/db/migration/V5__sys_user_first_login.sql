-- V5__sys_user_first_login.sql — base sys_user is missing `first_login`, which the develop
-- SysUser insert mapper writes (`insert into sys_user(... first_login) values(... 1)`).
-- The frozen privacy* base dump predates that column, so add-user fails with
-- "Unknown column 'first_login'". Flyway runs in the connected schema (privacy* on arm64,
-- fusion* on prod) — NO `USE`. Idempotent + MySQL-5.7-compatible (no ADD COLUMN IF NOT EXISTS
-- on 5.7): guard via information_schema so re-apply / fusion* (already has it) is a no-op.
SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_user'
                   AND COLUMN_NAME = 'first_login');
SET @ddl := IF(@has_col = 0,
  'ALTER TABLE `sys_user` ADD COLUMN `first_login` tinyint(1) DEFAULT ''1'' COMMENT ''是否首次登录(0=否 1=是)''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
