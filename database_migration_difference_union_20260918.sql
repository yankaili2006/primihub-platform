-- 联邦求差/求并 旧部署表结构迁移（2026-09-18，配套执行层实装）
-- 旧版建表缺 mapper 所需列；ascription 曾是 int 与「差集/并集」字符串冲突；
-- difference_direction 用 tinyint(1) 会被 JDBC 映射成 Boolean 破坏前端 ===0 判断。
-- 幂等性：列已存在时单条 ALTER 报错可忽略（或按需拆分执行）。
ALTER TABLE data_difference
  ADD COLUMN output_no_repeat tinyint(1) DEFAULT 0,
  ADD COLUMN output_format varchar(20) DEFAULT NULL,
  ADD COLUMN result_organ_ids varchar(255) DEFAULT NULL,
  ADD COLUMN difference_direction tinyint(4) DEFAULT 0,
  ADD COLUMN tee_organ_id varchar(255) DEFAULT NULL,
  ADD COLUMN remarks varchar(500) DEFAULT NULL,
  ADD COLUMN user_id bigint(20) DEFAULT NULL;
ALTER TABLE data_difference MODIFY COLUMN difference_direction tinyint(4) DEFAULT 0;
ALTER TABLE data_difference_task ADD COLUMN file_rows int(11) DEFAULT NULL AFTER ascription_type;
ALTER TABLE data_difference_task MODIFY COLUMN ascription varchar(50) DEFAULT NULL;
ALTER TABLE data_union
  ADD COLUMN output_no_repeat tinyint(1) DEFAULT 0,
  ADD COLUMN output_format varchar(20) DEFAULT NULL,
  ADD COLUMN result_organ_ids varchar(255) DEFAULT NULL,
  ADD COLUMN tee_organ_id varchar(255) DEFAULT NULL,
  ADD COLUMN remarks varchar(500) DEFAULT NULL,
  ADD COLUMN user_id bigint(20) DEFAULT NULL;
ALTER TABLE data_union_task ADD COLUMN file_rows int(11) DEFAULT NULL AFTER ascription_type;
ALTER TABLE data_union_task MODIFY COLUMN ascription varchar(50) DEFAULT NULL;
