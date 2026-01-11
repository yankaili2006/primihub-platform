-- 数据需求管理权限配置
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3

-- 获取资源管理菜单的ID
SELECT auth_id INTO @resource_id FROM sys_auth WHERE auth_code = 'ResourceMenu' AND is_del = 0;

-- 插入数据需求管理相关的二级菜单权限
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('DataRequirementList', '数据需求列表', 2, '/dataRequirement/findDataRequirementPage', @resource_id, 10, 0),
('DataRequirementAdd', '新增数据需求', 3, '/dataRequirement/addDataRequirement', @resource_id, 11, 0),
('DataRequirementEdit', '编辑数据需求', 3, '/dataRequirement/updateDataRequirement', @resource_id, 12, 0),
('DataRequirementDelete', '删除数据需求', 3, '/dataRequirement/deleteDataRequirement', @resource_id, 13, 0),
('DataRequirementDetail', '数据需求详情', 3, '/dataRequirement/getDataRequirementById', @resource_id, 14, 0),
('DataRequirementConfig', '数据需求配置', 2, '/dataRequirement/findConfigPage', @resource_id, 15, 0),
('DataRequirementConfigAdd', '添加配置', 3, '/dataRequirement/addConfig', @resource_id, 16, 0),
('DataRequirementConfigEdit', '编辑配置', 3, '/dataRequirement/updateConfig', @resource_id, 17, 0),
('DataRequirementConfigDelete', '删除配置', 3, '/dataRequirement/deleteConfig', @resource_id, 18, 0),
('DataRequirementMatch', '匹配数据需求所需数据', 2, '/dataRequirement/matchDataRequirements', @resource_id, 19, 0),
('DataRequirementMatchQuery', '查询匹配结果', 3, '/dataRequirement/findMatchedResources', @resource_id, 20, 0),
('DataRequirementMatchConfirm', '确认匹配', 3, '/dataRequirement/confirmMatch', @resource_id, 21, 0),
('DataRequirementMatchReject', '拒绝匹配', 3, '/dataRequirement/rejectMatch', @resource_id, 22, 0);

-- 为超级管理员角色（role_id=1）分配所有数据需求管理权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('DataRequirementList', 'DataRequirementAdd', 'DataRequirementEdit', 'DataRequirementDelete', 'DataRequirementDetail',
                    'DataRequirementConfig', 'DataRequirementConfigAdd', 'DataRequirementConfigEdit', 'DataRequirementConfigDelete',
                    'DataRequirementMatch', 'DataRequirementMatchQuery', 'DataRequirementMatchConfirm', 'DataRequirementMatchReject')
AND is_del = 0;

-- 验证权限是否插入成功
SELECT a.auth_code, a.auth_name, a.auth_type, a.auth_url, a.auth_sort
FROM sys_auth a
WHERE a.auth_code LIKE 'DataRequirement%'
AND a.is_del = 0
ORDER BY a.auth_sort;

-- 验证超级管理员是否已分配权限
SELECT a.auth_code, a.auth_name, COUNT(ra.id) as assigned_count
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE a.auth_code LIKE 'DataRequirement%'
AND a.is_del = 0
GROUP BY a.auth_code, a.auth_name
ORDER BY a.auth_sort;
