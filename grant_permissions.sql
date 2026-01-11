-- 为超级管理员角色分配新增菜单权限
INSERT IGNORE INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN (
    'Whitelist', 'WhitelistList', 'WhitelistConfig', 'WhitelistAccessLog',
    'Tenant', 'TenantList', 'TenantResource',
    'Evidence', 'EvidenceQuery', 'EvidenceTimestamp', 'EvidenceConfig', 'EvidenceExport', 'EvidenceApi',
    'Monitor', 'MonitorIndex',
    'ApiManage', 'ApiList', 'ApiAuth', 'ApiLog',
    'SystemConfig',
    'Log', 'LogList'
);
