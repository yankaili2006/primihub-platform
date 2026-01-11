-- 日志管理权限配置
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3

-- 1. 插入一级菜单：日志管理
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del)
VALUES ('Log', '日志管理', 1, '', 0, 15, 0);

SET @log_id = LAST_INSERT_ID();

-- 2. 插入二级菜单
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('LogList', '任务日志', 2, '/data/task/getTaskList', @log_id, 1, 0),
('OperationLogDefinition', '操作日志定义', 2, '/log/findOperationLogDefinitionPage', @log_id, 2, 0),
('ScheduleLogDefinition', '调度日志定义', 2, '/log/findScheduleLogDefinitionPage', @log_id, 3, 0),
('ComputeLogDefinition', '计算日志定义', 2, '/log/findComputeLogDefinitionPage', @log_id, 4, 0),
('OperationLog', '操作日志记录', 2, '/log/findOperationLogPage', @log_id, 5, 0),
('ScheduleLog', '调度日志记录', 2, '/log/findScheduleLogPage', @log_id, 6, 0),
('ComputeLog', '计算日志记录', 2, '/log/findComputeLogPage', @log_id, 7, 0);

-- 3. 为超级管理员角色（role_id=1）分配所有日志管理权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('Log', 'LogList', 'OperationLogDefinition', 'ScheduleLogDefinition',
                    'ComputeLogDefinition', 'OperationLog', 'ScheduleLog', 'ComputeLog')
AND is_del = 0;

-- 4. 验证权限是否插入成功
SELECT auth_code, auth_name, auth_type, auth_url FROM sys_auth
WHERE auth_code IN ('Log', 'LogList', 'OperationLogDefinition', 'ScheduleLogDefinition',
                    'ComputeLogDefinition', 'OperationLog', 'ScheduleLog', 'ComputeLog')
ORDER BY parent_auth_id, auth_sort;
