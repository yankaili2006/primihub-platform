-- ========================================
-- 节点管理增强功能权限配置脚本
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
-- PART 2: 创建9个二级菜单权限
-- ========================================

-- 菜单1: 节点建立合作
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点建立合作', 'NodeCooperationEstablish', 2, @settings_id, @settings_id, '/setting/node-cooperation-establish', '', '', 1, 1, 1, 1, 0);

-- 菜单2: 节点取消合作
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点取消合作', 'NodeCooperationCancel', 2, @settings_id, @settings_id, '/setting/node-cooperation-cancel', '', '', 2, 1, 1, 1, 0);

-- 菜单3: 节点列表
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点列表', 'NodeListEnhanced', 2, @settings_id, @settings_id, '/setting/node-list-enhanced', '', '', 3, 1, 1, 1, 0);

-- 菜单4: 节点属性编辑
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点属性编辑', 'NodePropertyEdit', 2, @settings_id, @settings_id, '/setting/node-property-edit', '', '', 4, 1, 1, 1, 0);

-- 菜单5: 节点属性展示
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点属性展示', 'NodePropertyDisplay', 2, @settings_id, @settings_id, '/setting/node-property-display', '', '', 5, 1, 1, 1, 0);

-- 菜单6: 接入方管理
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('接入方管理', 'NodeAccessManagement', 2, @settings_id, @settings_id, '/setting/node-access-management', '', '', 6, 1, 1, 1, 0);

-- 菜单7: 合作方管理
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('合作方管理', 'NodeCooperationManagement', 2, @settings_id, @settings_id, '/setting/node-cooperation-management', '', '', 7, 1, 1, 1, 0);

-- 菜单8: 节点审批工作流
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点审批工作流', 'NodeApprovalWorkflow', 2, @settings_id, @settings_id, '/setting/node-approval-workflow', '', '', 8, 1, 1, 1, 0);

-- 菜单9: 节点数据交换
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('节点数据交换', 'NodeDataExchange', 2, @settings_id, @settings_id, '/setting/node-data-exchange', '', '', 9, 1, 1, 1, 0);

-- ========================================
-- PART 3: 创建按钮权限 (每个菜单3个按钮)
-- ========================================

-- 获取各菜单ID
SELECT auth_id INTO @establish_id FROM sys_auth WHERE auth_code = 'NodeCooperationEstablish' AND is_del = 0;
SELECT auth_id INTO @cancel_id FROM sys_auth WHERE auth_code = 'NodeCooperationCancel' AND is_del = 0;
SELECT auth_id INTO @list_id FROM sys_auth WHERE auth_code = 'NodeListEnhanced' AND is_del = 0;
SELECT auth_id INTO @edit_id FROM sys_auth WHERE auth_code = 'NodePropertyEdit' AND is_del = 0;
SELECT auth_id INTO @display_id FROM sys_auth WHERE auth_code = 'NodePropertyDisplay' AND is_del = 0;
SELECT auth_id INTO @access_id FROM sys_auth WHERE auth_code = 'NodeAccessManagement' AND is_del = 0;
SELECT auth_id INTO @cooperation_id FROM sys_auth WHERE auth_code = 'NodeCooperationManagement' AND is_del = 0;
SELECT auth_id INTO @approval_id FROM sys_auth WHERE auth_code = 'NodeApprovalWorkflow' AND is_del = 0;
SELECT auth_id INTO @exchange_id FROM sys_auth WHERE auth_code = 'NodeDataExchange' AND is_del = 0;

-- 节点建立合作的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('发起合作', 'NodeCooperationEstablishAdd', 3, @establish_id, @establish_id, '/setting/node-cooperation-establish/add', '/node/cooperation/establish', '', 1, 2, 0, 1, 0),
('搜索节点', 'NodeCooperationEstablishSearch', 3, @establish_id, @establish_id, '/setting/node-cooperation-establish/search', '/node/cooperation/search', '', 2, 2, 0, 1, 0),
('批量发起', 'NodeCooperationEstablishBatch', 3, @establish_id, @establish_id, '/setting/node-cooperation-establish/batch', '/node/cooperation/batchEstablish', '', 3, 2, 0, 1, 0);

-- 节点取消合作的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('取消合作', 'NodeCooperationCancelExecute', 3, @cancel_id, @cancel_id, '/setting/node-cooperation-cancel/execute', '/node/cooperation/cancel', '', 1, 2, 0, 1, 0),
('查看详情', 'NodeCooperationCancelView', 3, @cancel_id, @cancel_id, '/setting/node-cooperation-cancel/view', '/node/cooperation/detail', '', 2, 2, 0, 1, 0),
('导出记录', 'NodeCooperationCancelExport', 3, @cancel_id, @cancel_id, '/setting/node-cooperation-cancel/export', '/node/cooperation/export', '', 3, 2, 0, 1, 0);

-- 节点列表的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('导出节点', 'NodeListEnhancedExport', 3, @list_id, @list_id, '/setting/node-list-enhanced/export', '/node/list/export', '', 1, 2, 0, 1, 0),
('批量启用', 'NodeListEnhancedBatchEnable', 3, @list_id, @list_id, '/setting/node-list-enhanced/batchEnable', '/node/list/batchEnable', '', 2, 2, 0, 1, 0),
('批量删除', 'NodeListEnhancedBatchDelete', 3, @list_id, @list_id, '/setting/node-list-enhanced/batchDelete', '/node/list/batchDelete', '', 3, 2, 0, 1, 0);

-- 节点属性编辑的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('保存属性', 'NodePropertyEditSave', 3, @edit_id, @edit_id, '/setting/node-property-edit/save', '/node/property/update', '', 1, 2, 0, 1, 0),
('上传证书', 'NodePropertyEditUpload', 3, @edit_id, @edit_id, '/setting/node-property-edit/upload', '/node/property/uploadCert', '', 2, 2, 0, 1, 0),
('查看历史', 'NodePropertyEditHistory', 3, @edit_id, @edit_id, '/setting/node-property-edit/history', '/node/property/history', '', 3, 2, 0, 1, 0);

-- 节点属性展示的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('下载PDF', 'NodePropertyDisplayDownload', 3, @display_id, @display_id, '/setting/node-property-display/download', '/node/property/downloadPdf', '', 1, 2, 0, 1, 0),
('刷新状态', 'NodePropertyDisplayRefresh', 3, @display_id, @display_id, '/setting/node-property-display/refresh', '/node/property/refreshStatus', '', 2, 2, 0, 1, 0),
('查看详情', 'NodePropertyDisplayDetail', 3, @display_id, @display_id, '/setting/node-property-display/detail', '/node/property/detail', '', 3, 2, 0, 1, 0);

-- 接入方管理的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('批准接入', 'NodeAccessManagementApprove', 3, @access_id, @access_id, '/setting/node-access-management/approve', '/node/access/approve', '', 1, 2, 0, 1, 0),
('拒绝接入', 'NodeAccessManagementReject', 3, @access_id, @access_id, '/setting/node-access-management/reject', '/node/access/reject', '', 2, 2, 0, 1, 0),
('编辑权限', 'NodeAccessManagementEdit', 3, @access_id, @access_id, '/setting/node-access-management/edit', '/node/access/updatePermission', '', 3, 2, 0, 1, 0);

-- 合作方管理的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('新增合作方', 'NodeCooperationManagementAdd', 3, @cooperation_id, @cooperation_id, '/setting/node-cooperation-management/add', '/node/cooperation/add', '', 1, 2, 0, 1, 0),
('编辑合作方', 'NodeCooperationManagementEdit', 3, @cooperation_id, @cooperation_id, '/setting/node-cooperation-management/edit', '/node/cooperation/update', '', 2, 2, 0, 1, 0),
('终止合作', 'NodeCooperationManagementTerminate', 3, @cooperation_id, @cooperation_id, '/setting/node-cooperation-management/terminate', '/node/cooperation/terminate', '', 3, 2, 0, 1, 0);

-- 节点审批工作流的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('审批通过', 'NodeApprovalWorkflowApprove', 3, @approval_id, @approval_id, '/setting/node-approval-workflow/approve', '/node/approval/approve', '', 1, 2, 0, 1, 0),
('审批拒绝', 'NodeApprovalWorkflowReject', 3, @approval_id, @approval_id, '/setting/node-approval-workflow/reject', '/node/approval/reject', '', 2, 2, 0, 1, 0),
('配置工作流', 'NodeApprovalWorkflowConfig', 3, @approval_id, @approval_id, '/setting/node-approval-workflow/config', '/node/approval/config', '', 3, 2, 0, 1, 0);

-- 节点数据交换的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('触发同步', 'NodeDataExchangeTrigger', 3, @exchange_id, @exchange_id, '/setting/node-data-exchange/trigger', '/node/exchange/trigger', '', 1, 2, 0, 1, 0),
('查看日志', 'NodeDataExchangeLog', 3, @exchange_id, @exchange_id, '/setting/node-data-exchange/log', '/node/exchange/log', '', 2, 2, 0, 1, 0),
('导出日志', 'NodeDataExchangeExport', 3, @exchange_id, @exchange_id, '/setting/node-data-exchange/export', '/node/exchange/exportLog', '', 3, 2, 0, 1, 0);

-- ========================================
-- PART 4: 分配权限给超级管理员角色
-- ========================================

-- 分配9个菜单权限给超级管理员
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN (
    'NodeCooperationEstablish',
    'NodeCooperationCancel',
    'NodeListEnhanced',
    'NodePropertyEdit',
    'NodePropertyDisplay',
    'NodeAccessManagement',
    'NodeCooperationManagement',
    'NodeApprovalWorkflow',
    'NodeDataExchange'
)
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = 1
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);

-- 分配27个按钮权限给超级管理员
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code LIKE 'NodeCooperation%'
   OR auth_code LIKE 'NodeList%'
   OR auth_code LIKE 'NodeProperty%'
   OR auth_code LIKE 'NodeAccess%'
   OR auth_code LIKE 'NodeApproval%'
   OR auth_code LIKE 'NodeDataExchange%'
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
    COUNT(ra.id) as assigned_to_admin
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE (
    a.auth_code LIKE 'NodeCooperation%'
    OR a.auth_code LIKE 'NodeList%'
    OR a.auth_code LIKE 'NodeProperty%'
    OR a.auth_code LIKE 'NodeAccess%'
    OR a.auth_code LIKE 'NodeApproval%'
    OR a.auth_code LIKE 'NodeDataExchange%'
)
AND a.is_del = 0
GROUP BY a.auth_id, a.auth_code, a.auth_name, a.auth_type, a.full_path
ORDER BY a.auth_type, a.auth_code;

-- 统计权限数量
SELECT
    '二级菜单' as permission_type,
    COUNT(*) as count
FROM sys_auth
WHERE (
    auth_code LIKE 'NodeCooperation%'
    OR auth_code LIKE 'NodeList%'
    OR auth_code LIKE 'NodeProperty%'
    OR auth_code LIKE 'NodeAccess%'
    OR auth_code LIKE 'NodeApproval%'
    OR auth_code LIKE 'NodeDataExchange%'
)
AND auth_type = 2
AND is_del = 0

UNION ALL

SELECT
    '按钮权限' as permission_type,
    COUNT(*) as count
FROM sys_auth
WHERE (
    auth_code LIKE 'NodeCooperation%'
    OR auth_code LIKE 'NodeList%'
    OR auth_code LIKE 'NodeProperty%'
    OR auth_code LIKE 'NodeAccess%'
    OR auth_code LIKE 'NodeApproval%'
    OR auth_code LIKE 'NodeDataExchange%'
)
AND auth_type = 3
AND is_del = 0;

-- 显示结果说明
SELECT '节点管理增强功能权限配置已成功完成!' as message,
       '已添加 9 个二级菜单权限' as step1,
       '已添加 27 个按钮权限' as step2,
       '已分配所有权限给超级管理员' as step3;
