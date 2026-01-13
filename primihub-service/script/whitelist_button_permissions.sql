-- ========================================
-- 白名单管理按钮权限补充脚本
-- 需要在3个数据库中执行：privacy1, privacy2, privacy3
-- ========================================

-- 获取白名单列表菜单的ID
SELECT auth_id INTO @whitelist_list_id FROM sys_auth WHERE auth_code = 'WhitelistList' AND is_del = 0;

-- 插入白名单列表的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('添加白名单', 'WhitelistAdd', 3, @whitelist_list_id, @whitelist_list_id, '/whitelist/list/add', '/whitelist/addWhitelist', '', 1, 2, 0, 1, 0),
('编辑白名单', 'WhitelistEdit', 3, @whitelist_list_id, @whitelist_list_id, '/whitelist/list/edit', '/whitelist/updateWhitelist', '', 2, 2, 0, 1, 0),
('删除白名单', 'WhitelistDelete', 3, @whitelist_list_id, @whitelist_list_id, '/whitelist/list/delete', '/whitelist/deleteWhitelist', '', 3, 2, 0, 1, 0);

-- 为超级管理员角色（role_id=1）分配白名单按钮权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('WhitelistAdd', 'WhitelistEdit', 'WhitelistDelete')
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = 1
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);

-- 获取白名单配置菜单的ID
SELECT auth_id INTO @whitelist_config_id FROM sys_auth WHERE auth_code = 'WhitelistConfig' AND is_del = 0;

-- 插入白名单配置的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('添加配置', 'WhitelistConfigAdd', 3, @whitelist_config_id, @whitelist_config_id, '/whitelist/config/add', '/whitelist/addWhitelistConfig', '', 1, 2, 0, 1, 0),
('编辑配置', 'WhitelistConfigEdit', 3, @whitelist_config_id, @whitelist_config_id, '/whitelist/config/edit', '/whitelist/updateWhitelistConfig', '', 2, 2, 0, 1, 0),
('删除配置', 'WhitelistConfigDelete', 3, @whitelist_config_id, @whitelist_config_id, '/whitelist/config/delete', '/whitelist/deleteWhitelistConfig', '', 3, 2, 0, 1, 0);

-- 为超级管理员角色（role_id=1）分配白名单配置按钮权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('WhitelistConfigAdd', 'WhitelistConfigEdit', 'WhitelistConfigDelete')
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = 1
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);

-- 获取访问日志菜单的ID
SELECT auth_id INTO @whitelist_log_id FROM sys_auth WHERE auth_code = 'WhitelistAccessLog' AND is_del = 0;

-- 插入访问日志的按钮权限
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('清理日志', 'WhitelistLogClean', 3, @whitelist_log_id, @whitelist_log_id, '/whitelist/accessLog/clean', '/whitelist/cleanWhitelistAccessLog', '', 1, 2, 0, 1, 0),
('导出日志', 'WhitelistLogExport', 3, @whitelist_log_id, @whitelist_log_id, '/whitelist/accessLog/export', '/whitelist/exportWhitelistAccessLog', '', 2, 2, 0, 1, 0);

-- 为超级管理员角色（role_id=1）分配访问日志按钮权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('WhitelistLogClean', 'WhitelistLogExport')
AND is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra
    WHERE role_id = 1
    AND auth_id = sys_auth.auth_id
    AND is_del = 0
);

-- 验证权限是否插入成功
SELECT
    a.auth_id,
    a.auth_code,
    a.auth_name,
    a.auth_type,
    a.auth_url,
    COUNT(ra.id) as role_assigned
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE a.auth_code LIKE 'Whitelist%'
AND a.is_del = 0
GROUP BY a.auth_id, a.auth_code, a.auth_name, a.auth_type, a.auth_url
ORDER BY a.auth_type, a.auth_index;

-- 显示结果说明
SELECT '白名单按钮权限已成功添加!' as message;
