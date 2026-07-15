-- V14__sys_organ_identity.sql — sys_organ.identity: the D20 createOrganNode mapper inserts it
-- (SysOrgan.identity is Integer default 1), but neither the base dump, V12 (organ_tree_columns),
-- nor the fusion* schema ever added it -> "Unknown column 'identity'" on 创建机构.
-- Idempotent + MySQL-5.7-compatible (information_schema-guarded). NO `USE`.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='sys_organ' AND COLUMN_NAME='identity');
SET @ddl := IF(@c=0,
  'ALTER TABLE `sys_organ` ADD COLUMN `identity` int(11) DEFAULT 1 COMMENT ''机构身份(D20)''',
  'SELECT 1');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;
