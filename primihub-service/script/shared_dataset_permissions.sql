-- 共享数据集管理权限配置
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3

-- 获取资源管理菜单的ID
SET @resource_id = (SELECT auth_id FROM sys_auth WHERE auth_code = 'ResourceMenu' AND is_del = 0 LIMIT 1);

-- 如果找不到资源管理菜单，尝试其他方式
SELECT @resource_id;

-- 插入共享数据集管理相关的二级菜单权限
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('SharedDatasetList', '共享数据集列表', 2, '/sharedDataset/findSharedDatasetPage', @resource_id, 25, 0),
('SharedDatasetAdd', '新增共享数据集', 3, '/sharedDataset/addSharedDataset', @resource_id, 26, 0),
('SharedDatasetEdit', '编辑共享数据集', 3, '/sharedDataset/updateSharedDataset', @resource_id, 27, 0),
('SharedDatasetDelete', '删除共享数据集', 3, '/sharedDataset/deleteSharedDataset', @resource_id, 28, 0),
('SharedDatasetDetail', '共享数据集详情', 3, '/sharedDataset/getSharedDatasetById', @resource_id, 29, 0),
('SharedDatasetStatus', '更新共享数据集状态', 3, '/sharedDataset/updateSharedDatasetStatus', @resource_id, 30, 0),
('SharedDatasetResources', '获取可共享资源', 3, '/sharedDataset/getShareableResources', @resource_id, 31, 0);

-- 为超级管理员角色（role_id=1）分配所有共享数据集管理权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('SharedDatasetList', 'SharedDatasetAdd', 'SharedDatasetEdit', 'SharedDatasetDelete',
                    'SharedDatasetDetail', 'SharedDatasetStatus', 'SharedDatasetResources')
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra WHERE role_id = 1 AND auth_id = sys_auth.auth_id AND is_del = 0
);

-- 验证权限是否插入成功
SELECT a.auth_code, a.auth_name, a.auth_type, a.auth_url, a.auth_sort
FROM sys_auth a
WHERE a.auth_code LIKE 'SharedDataset%'
AND a.is_del = 0
ORDER BY a.auth_sort;

-- 验证超级管理员是否已分配权限
SELECT a.auth_code, a.auth_name, COUNT(ra.id) as assigned_count
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE a.auth_code LIKE 'SharedDataset%'
AND a.is_del = 0
GROUP BY a.auth_code, a.auth_name
ORDER BY a.auth_sort;
