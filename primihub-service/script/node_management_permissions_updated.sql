-- ========================================
-- 节点管理增强功能权限配置脚本（更新版）
-- 匹配实际前端路由配置
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3
-- ========================================

-- ========================================
-- PART 1: 获取父级菜单ID
-- ========================================

-- 获取"系统设置"一级菜单ID
SELECT auth_id INTO @settings_id FROM sys_auth WHERE auth_code = 'Setting' AND is_del = 0 LIMIT 1;

-- 如果找不到系统设置菜单，创建一个
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT '系统设置', 'Setting', 1, 0, 0, '/setting', '', '', 99, 0, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'Setting' AND is_del = 0);

-- 再次获取系统设置ID（确保有值）
SELECT auth_id INTO @settings_id FROM sys_auth WHERE auth_code = 'Setting' AND is_del = 0 LIMIT 1;

-- ========================================
-- PART 2: 创建4个新的二级菜单权限（与实际路由匹配）
-- ========================================

-- 菜单1: 接入方管理
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('接入方管理', 'AccessManagement', 2, @settings_id, @settings_id, '/setting/accessManagement', '', '', 31, 1, 1, 1, 0)
ON DUPLICATE KEY UPDATE auth_name='接入方管理', full_path='/setting/accessManagement';

-- 菜单2: 合作方管理
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('合作方管理', 'CooperationManagement', 2, @settings_id, @settings_id, '/setting/cooperation', '', '', 32, 1, 1, 1, 0)
ON DUPLICATE KEY UPDATE auth_name='合作方管理', full_path='/setting/cooperation';

-- 菜单3: 审批工作流
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('审批工作流', 'ApprovalWorkflow', 2, @settings_id, @settings_id, '/setting/approval', '', '', 33, 1, 1, 1, 0)
ON DUPLICATE KEY UPDATE auth_name='审批工作流', full_path='/setting/approval';

-- 菜单4: 数据交换日志
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('数据交换日志', 'DataExchangeLog', 2, @settings_id, @settings_id, '/setting/dataExchange', '', '', 34, 1, 1, 1, 0)
ON DUPLICATE KEY UPDATE auth_name='数据交换日志', full_path='/setting/dataExchange';

-- ========================================
-- PART 3: 创建按钮权限
-- ========================================

-- 获取各菜单ID
SELECT auth_id INTO @access_id FROM sys_auth WHERE auth_code = 'AccessManagement' AND is_del = 0 LIMIT 1;
SELECT auth_id INTO @cooperation_id FROM sys_auth WHERE auth_code = 'CooperationManagement' AND is_del = 0 LIMIT 1;
SELECT auth_id INTO @approval_id FROM sys_auth WHERE auth_code = 'ApprovalWorkflow' AND is_del = 0 LIMIT 1;
SELECT auth_id INTO @exchange_id FROM sys_auth WHERE auth_code = 'DataExchangeLog' AND is_del = 0 LIMIT 1;

-- 接入方管理的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('新增接入方', 'AccessManagementAdd', 3, @access_id, @access_id, '/setting/accessManagement/add', '/node/access/addAccessParty', '', 1, 2, 0, 1, 0),
('编辑接入方', 'AccessManagementEdit', 3, @access_id, @access_id, '/setting/accessManagement/edit', '/node/access/updateAccessParty', '', 2, 2, 0, 1, 0),
('删除接入方', 'AccessManagementDelete', 3, @access_id, @access_id, '/setting/accessManagement/delete', '/node/access/deleteAccessParty', '', 3, 2, 0, 1, 0),
('批准接入', 'AccessManagementApprove', 3, @access_id, @access_id, '/setting/accessManagement/approve', '/node/access/approve', '', 4, 2, 0, 1, 0),
('拒绝接入', 'AccessManagementReject', 3, @access_id, @access_id, '/setting/accessManagement/reject', '/node/access/reject', '', 5, 2, 0, 1, 0),
('批量删除', 'AccessManagementBatchDelete', 3, @access_id, @access_id, '/setting/accessManagement/batchDelete', '/node/access/batchDeleteAccessParty', '', 6, 2, 0, 1, 0),
('批量批准', 'AccessManagementBatchApprove', 3, @access_id, @access_id, '/setting/accessManagement/batchApprove', '/node/access/batchApprove', '', 7, 2, 0, 1, 0),
('更新状态', 'AccessManagementUpdateStatus', 3, @access_id, @access_id, '/setting/accessManagement/updateStatus', '/node/access/updateActiveStatus', '', 8, 2, 0, 1, 0)
ON DUPLICATE KEY UPDATE auth_url=VALUES(auth_url);

-- 合作方管理的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('建立合作', 'CooperationEstablish', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/establish', '/node/cooperation/establish', '', 1, 2, 0, 1, 0),
('编辑合作', 'CooperationEdit', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/edit', '/node/cooperation/update', '', 2, 2, 0, 1, 0),
('取消合作', 'CooperationCancel', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/cancel', '/node/cooperation/cancel', '', 3, 2, 0, 1, 0),
('终止合作', 'CooperationTerminate', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/terminate', '/node/cooperation/terminate', '', 4, 2, 0, 1, 0),
('续约合作', 'CooperationRenew', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/renew', '/node/cooperation/renew', '', 5, 2, 0, 1, 0),
('更新状态', 'CooperationUpdateStatus', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/updateStatus', '/node/cooperation/updateCooperationStatus', '', 6, 2, 0, 1, 0),
('批量删除', 'CooperationBatchDelete', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/batchDelete', '/node/cooperation/batchDelete', '', 7, 2, 0, 1, 0),
('搜索节点', 'CooperationSearch', 3, @cooperation_id, @cooperation_id, '/setting/cooperation/search', '/node/cooperation/search', '', 8, 2, 0, 1, 0)
ON DUPLICATE KEY UPDATE auth_url=VALUES(auth_url);

-- 审批工作流的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('创建工作流', 'ApprovalCreate', 3, @approval_id, @approval_id, '/setting/approval/create', '/node/approval/createWorkflow', '', 1, 2, 0, 1, 0),
('审批通过', 'ApprovalApprove', 3, @approval_id, @approval_id, '/setting/approval/approve', '/node/approval/approve', '', 2, 2, 0, 1, 0),
('审批拒绝', 'ApprovalReject', 3, @approval_id, @approval_id, '/setting/approval/reject', '/node/approval/reject', '', 3, 2, 0, 1, 0),
('取消工作流', 'ApprovalCancel', 3, @approval_id, @approval_id, '/setting/approval/cancel', '/node/approval/cancel', '', 4, 2, 0, 1, 0),
('查看详情', 'ApprovalView', 3, @approval_id, @approval_id, '/setting/approval/view', '/node/approval/getWorkflowById', '', 5, 2, 0, 1, 0),
('配置审批', 'ApprovalConfig', 3, @approval_id, @approval_id, '/setting/approval/config', '/node/approval/updateConfig', '', 6, 2, 0, 1, 0),
('更新配置状态', 'ApprovalConfigStatus', 3, @approval_id, @approval_id, '/setting/approval/configStatus', '/node/approval/updateConfigEnabled', '', 7, 2, 0, 1, 0)
ON DUPLICATE KEY UPDATE auth_url=VALUES(auth_url);

-- 数据交换日志的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('触发同步', 'ExchangeTrigger', 3, @exchange_id, @exchange_id, '/setting/dataExchange/trigger', '/node/exchange/trigger', '', 1, 2, 0, 1, 0),
('查看详情', 'ExchangeView', 3, @exchange_id, @exchange_id, '/setting/dataExchange/view', '/node/exchange/getDataExchangeLogById', '', 2, 2, 0, 1, 0),
('删除日志', 'ExchangeDelete', 3, @exchange_id, @exchange_id, '/setting/dataExchange/delete', '/node/exchange/batchDeleteDataExchangeLog', '', 3, 2, 0, 1, 0),
('查看统计', 'ExchangeStatistics', 3, @exchange_id, @exchange_id, '/setting/dataExchange/statistics', '/node/exchange/getExchangeStatistics', '', 4, 2, 0, 1, 0),
('查看失败', 'ExchangeFailed', 3, @exchange_id, @exchange_id, '/setting/dataExchange/failed', '/node/exchange/getFailedExchangeLogs', '', 5, 2, 0, 1, 0),
('最近记录', 'ExchangeRecent', 3, @exchange_id, @exchange_id, '/setting/dataExchange/recent', '/node/exchange/getRecentExchangeLogs', '', 6, 2, 0, 1, 0)
ON DUPLICATE KEY UPDATE auth_url=VALUES(auth_url);

-- ========================================
-- PART 4: 分配权限给超级管理员角色
-- ========================================

-- 分配4个菜单权限给超级管理员
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN (
    'AccessManagement',
    'CooperationManagement',
    'ApprovalWorkflow',
    'DataExchangeLog'
)
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = 1
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);

-- 分配所有按钮权限给超级管理员
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE (
    auth_code LIKE 'AccessManagement%'
    OR auth_code LIKE 'Cooperation%'
    OR auth_code LIKE 'Approval%'
    OR auth_code LIKE 'Exchange%'
)
AND auth_type = 3
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = 1
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);

-- ========================================
-- PART 5: 验证权限配置
-- ========================================

-- 验证菜单权限
SELECT
    a.auth_id,
    a.auth_code,
    a.auth_name,
    a.auth_type,
    a.full_path,
    a.auth_url,
    COUNT(ra.id) as assigned_to_admin
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE (
    a.auth_code LIKE 'AccessManagement%'
    OR a.auth_code LIKE 'CooperationManagement%'
    OR a.auth_code LIKE 'ApprovalWorkflow%'
    OR a.auth_code LIKE 'DataExchangeLog%'
    OR a.auth_code LIKE 'Cooperation%'
    OR a.auth_code LIKE 'Approval%'
    OR a.auth_code LIKE 'Exchange%'
)
AND a.is_del = 0
GROUP BY a.auth_id, a.auth_code, a.auth_name, a.auth_type, a.full_path, a.auth_url
ORDER BY a.auth_type, a.auth_code;

-- 统计权限数量
SELECT
    '二级菜单' as permission_type,
    COUNT(*) as count
FROM sys_auth
WHERE auth_code IN (
    'AccessManagement',
    'CooperationManagement',
    'ApprovalWorkflow',
    'DataExchangeLog'
)
AND auth_type = 2
AND is_del = 0

UNION ALL

SELECT
    '按钮权限' as permission_type,
    COUNT(*) as count
FROM sys_auth
WHERE (
    auth_code LIKE 'AccessManagement%'
    OR auth_code LIKE 'Cooperation%'
    OR auth_code LIKE 'Approval%'
    OR auth_code LIKE 'Exchange%'
)
AND auth_type = 3
AND is_del = 0;

-- 显示结果说明
SELECT '节点管理增强功能权限配置已成功完成!' as message,
       '已添加 4 个二级菜单权限' as step1,
       '已添加 29 个按钮权限' as step2,
       '已分配所有权限给超级管理员' as step3;
