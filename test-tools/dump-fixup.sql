-- Residual schema drift caught by the mapper drift-gate (mapper_check.py) that the
-- V2..V14 migrations never covered. Folded into the base dump alongside the migrations.
-- Applied to the privacy* schema during dump regeneration.

-- data_resource_auth_record: mapper INSERTs these 4 but the table never had them (Unknown-column).
-- Types from PO DataResourceAuthRecord: projectId/userId=Long, recordStatus=Integer, userName=String.
ALTER TABLE data_resource_auth_record
  ADD COLUMN IF NOT EXISTS project_id    bigint(20)   DEFAULT NULL COMMENT '项目ID',
  ADD COLUMN IF NOT EXISTS record_status int(11)      DEFAULT NULL COMMENT '记录状态',
  ADD COLUMN IF NOT EXISTS user_id       bigint(20)   DEFAULT NULL COMMENT '用户ID',
  ADD COLUMN IF NOT EXISTS user_name     varchar(255) DEFAULT NULL COMMENT '用户名';

-- String params inserted into int/tinyint columns -> Data-truncation risk (same class as the
-- log_type int->varchar fix in old V6). Mappers pass String values, so the column must be varchar.
ALTER TABLE sys_compute_log     MODIFY COLUMN compute_type   varchar(64) DEFAULT NULL COMMENT '计算类型';
ALTER TABLE sys_operation_log   MODIFY COLUMN operation_type varchar(64) DEFAULT NULL COMMENT '操作类型';
ALTER TABLE whitelist_access_log MODIFY COLUMN access_result varchar(64) DEFAULT NULL COMMENT '访问结果';
