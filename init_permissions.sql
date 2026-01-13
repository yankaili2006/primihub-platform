-- 初始化新增菜单权限数据
-- 注意：auth_url 应该配置为后端API路径，而不是前端路由路径
-- 1. 白名单管理 (Whitelist)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('白名单管理', 'Whitelist', 1, 0, LAST_INSERT_ID(), '/whitelist', '', '', 7, 0, 1, 1, 0);

SET @whitelist_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('白名单列表', 'WhitelistList', 2, @whitelist_id, @whitelist_id, '/whitelist/list', '/whitelist/findWhitelistPage', '', 1, 1, 1, 1, 0),
('白名单配置', 'WhitelistConfig', 2, @whitelist_id, @whitelist_id, '/whitelist/config', '/whitelist/findWhitelistConfigList', '', 2, 1, 1, 1, 0),
('访问日志记录', 'WhitelistAccessLog', 2, @whitelist_id, @whitelist_id, '/whitelist/accessLog', '/whitelist/findWhitelistAccessLogPage', '', 3, 1, 1, 1, 0);

-- 2. 租户管理 (Tenant)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('租户管理', 'Tenant', 1, 0, LAST_INSERT_ID(), '/tenant', '', '', 8, 0, 1, 1, 0);

SET @tenant_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('租户列表', 'TenantList', 2, @tenant_id, @tenant_id, '/tenant/list', '/tenant/findTenantPage', '', 1, 1, 1, 1, 0),
('资源分配', 'TenantResource', 2, @tenant_id, @tenant_id, '/tenant/resource/:id', '/tenant/findTenantResourcePage', '', 2, 1, 0, 1, 0);

-- 3. 存证管理 (Evidence)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('存证管理', 'Evidence', 1, 0, LAST_INSERT_ID(), '/evidence', '', '', 9, 0, 1, 1, 0);

SET @evidence_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('存证查询', 'EvidenceQuery', 2, @evidence_id, @evidence_id, '/evidence/query', '/evidence/findEvidencePage', '', 1, 1, 1, 1, 0),
('时间戳管理', 'EvidenceTimestamp', 2, @evidence_id, @evidence_id, '/evidence/timestamp', '/evidence/findTimestampPage', '', 2, 1, 1, 1, 0),
('存证配置', 'EvidenceConfig', 2, @evidence_id, @evidence_id, '/evidence/config', '/evidence/getEvidenceConfig', '', 3, 1, 1, 1, 0),
('存证加密导出', 'EvidenceExport', 2, @evidence_id, @evidence_id, '/evidence/export', '/evidence/exportEvidence', '', 4, 1, 1, 1, 0),
('存证接口对接', 'EvidenceApi', 2, @evidence_id, @evidence_id, '/evidence/api', '/evidence/getApiList', '', 5, 1, 1, 1, 0);

-- 4. 监控管理 (Monitor)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('监控管理', 'Monitor', 1, 0, LAST_INSERT_ID(), '/monitor', '', '', 10, 0, 1, 1, 0);

SET @monitor_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('监控管理', 'MonitorIndex', 2, @monitor_id, @monitor_id, '/monitor/index', '/monitor/getSystemMonitor', '', 1, 1, 1, 1, 0);

-- 5. 接口管理 (ApiManage)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('接口管理', 'ApiManage', 1, 0, LAST_INSERT_ID(), '/api', '', '', 11, 0, 1, 1, 0);

SET @api_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('接口列表', 'ApiList', 2, @api_id, @api_id, '/api/list', '/api/list', '', 1, 1, 1, 1, 0),
('接口授权', 'ApiAuth', 2, @api_id, @api_id, '/api/auth', '/api/auth', '', 2, 1, 1, 1, 0),
('接口日志', 'ApiLog', 2, @api_id, @api_id, '/api/log', '/api/log', '', 3, 1, 1, 1, 0);

-- 6. 系统设置 - 系统配置 (SystemConfig)
-- 首先获取Setting的auth_id
SELECT @setting_id := auth_id FROM sys_auth WHERE auth_code = 'Setting';

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('系统配置', 'SystemConfig', 2, @setting_id, @setting_id, '/setting/system', '/setting/system', '', 4, 1, 1, 1, 0);

-- 日志管理 (Log)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('日志管理', 'Log', 1, 0, LAST_INSERT_ID(), '/log', '/log', '', 12, 0, 1, 1, 0);

SET @log_id = LAST_INSERT_ID();

INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('日志管理', 'LogList', 2, @log_id, @log_id, '/log/index', '/log/index', '', 1, 1, 1, 1, 0);
