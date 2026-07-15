-- V12__organ_tree_columns.sql — D20 内部机构树: sys_organ 增父/序列列(MariaDB 幂等)
ALTER TABLE sys_organ ADD COLUMN IF NOT EXISTS p_organ_id VARCHAR(255) DEFAULT NULL COMMENT '父机构id(内部机构树)';
ALTER TABLE sys_organ ADD COLUMN IF NOT EXISTS organ_index INT DEFAULT 0 COMMENT '同级顺序';
