-- 新增模块权限配置
-- 需要在所有数据库执行：privacy1, privacy2, privacy3

-- 获取各顶级菜单ID
SELECT auth_id INTO @systemSettingId FROM sys_auth WHERE auth_code = 'SystemSettingsMenu' AND is_del = 0;
SELECT auth_id INTO @federatedQueryMenuId FROM sys_auth WHERE auth_code = 'FederatedQueryMenu' AND is_del = 0;
SELECT auth_id INTO @federatedStatsMenuId FROM sys_auth WHERE auth_code = 'FederatedStatsMenu' AND is_del = 0;
SELECT auth_id INTO @federatedAnalysisMenuId FROM sys_auth WHERE auth_code = 'FederatedAnalysisMenu' AND is_del = 0;
SELECT auth_id INTO @dataManageMenuId FROM sys_auth WHERE auth_code = 'DataManageMenu' AND is_del = 0;

-- ========== 1. 存证管理 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('EvidenceQuery', '存证查询', 2, '/evidence/findEvidencePage', @systemSettingId, 100, 0),
('EvidenceCreate', '创建存证', 3, '/evidence/createEvidence', @systemSettingId, 101, 0),
('EvidenceVerify', '验证存证', 3, '/evidence/verifyEvidence', @systemSettingId, 102, 0),
('EvidenceTimestamp', '时间戳管理', 2, '/evidence/findTimestampPage', @systemSettingId, 103, 0),
('EvidenceConfig', '存证配置', 2, '/evidence/getEvidenceConfig', @systemSettingId, 104, 0),
('EvidenceExport', '存证导出', 3, '/evidence/exportEvidence', @systemSettingId, 105, 0),
('EvidenceApiKey', 'API密钥管理', 2, '/evidence/getApiKey', @systemSettingId, 106, 0);

-- ========== 2. 监控管理 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('MonitorView', '监控查看', 2, '/monitor/getSystemMonitor', @systemSettingId, 110, 0),
('MonitorAlertConfig', '告警配置', 2, '/monitor/getAlertConfig', @systemSettingId, 111, 0),
('MonitorAlertHistory', '告警历史', 2, '/monitor/getAlertHistory', @systemSettingId, 112, 0);

-- ========== 3. 接口管理 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('ApiManageList', '接口列表', 2, '/apiManage/findApiPage', @systemSettingId, 120, 0),
('ApiManageAdd', '新增接口', 3, '/apiManage/addApi', @systemSettingId, 121, 0),
('ApiManageEdit', '编辑接口', 3, '/apiManage/updateApi', @systemSettingId, 122, 0),
('ApiManageDelete', '删除接口', 3, '/apiManage/deleteApi', @systemSettingId, 123, 0),
('ApiManageAuth', '接口授权', 2, '/apiManage/findApiAuthPage', @systemSettingId, 124, 0),
('ApiManageLog', '接口日志', 2, '/apiManage/findApiLogPage', @systemSettingId, 125, 0);

-- ========== 4. 联邦查询 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('FederatedQueryCreate', '创建联邦查询', 2, '/federatedQuery/create', @federatedQueryMenuId, 10, 0),
('FederatedQueryList', '查询任务列表', 2, '/federatedQuery/list', @federatedQueryMenuId, 11, 0),
('FederatedQueryRun', '执行查询', 3, '/federatedQuery/run', @federatedQueryMenuId, 12, 0),
('FederatedQueryResult', '查看结果', 2, '/federatedQuery/result', @federatedQueryMenuId, 13, 0),
('FederatedQueryLog', '查询日志', 2, '/federatedQuery/logs', @federatedQueryMenuId, 14, 0),
('FederatedQueryTools', '查询工具', 2, '/federatedQuery/tools/save', @federatedQueryMenuId, 15, 0);

-- ========== 5. 联邦统计 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('FederatedStatsCreate', '创建统计任务', 2, '/federatedStatistics/task/create', @federatedStatsMenuId, 10, 0),
('FederatedStatsList', '统计任务列表', 2, '/federatedStatistics/task/list', @federatedStatsMenuId, 11, 0),
('FederatedStatsRun', '执行统计', 3, '/federatedStatistics/task/run', @federatedStatsMenuId, 12, 0),
('FederatedStatsResult', '统计结果', 2, '/federatedStatistics/result/list', @federatedStatsMenuId, 13, 0),
('FederatedStatsStorage', '存储配置', 2, '/federatedStatistics/storage/list', @federatedStatsMenuId, 14, 0),
('FederatedStatsLog', '统计日志', 2, '/federatedStatistics/log/list', @federatedStatsMenuId, 15, 0);

-- ========== 6. 联邦分析 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('FederatedAnalysisCreate', '创建分析任务', 2, '/federatedAnalysis/task/create', @federatedAnalysisMenuId, 10, 0),
('FederatedAnalysisList', '分析任务列表', 2, '/federatedAnalysis/task/list', @federatedAnalysisMenuId, 11, 0),
('FederatedAnalysisSql', 'SQL安全校验', 2, '/federatedAnalysis/sql/validate', @federatedAnalysisMenuId, 12, 0),
('FederatedAnalysisDatasource', '数据源管理', 2, '/federatedAnalysis/datasource/list', @federatedAnalysisMenuId, 13, 0),
('FederatedAnalysisLog', '分析日志', 2, '/federatedAnalysis/log/list', @federatedAnalysisMenuId, 14, 0);

-- ========== 7. 场景定制化-警务数据融合 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('PoliceFusionTask', '警务融合任务', 2, '/policeFusion/task/list', @systemSettingId, 130, 0),
('PoliceFusionApi', '警务API配置', 2, '/policeFusion/api/list', @systemSettingId, 131, 0),
('PoliceFusionKey', '警务密钥管理', 2, '/policeFusion/key/list', @systemSettingId, 132, 0),
('PoliceFusionEncrypt', '警务加密服务', 3, '/policeFusion/key/encrypt', @systemSettingId, 133, 0);

-- ========== 8. 场景定制化-电子证件 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('ElectronicCertTask', '电子证件任务', 2, '/electronicCert/task/list', @systemSettingId, 140, 0),
('ElectronicCertFeature', '特征转换', 2, '/electronicCert/feature/convert', @systemSettingId, 141, 0),
('ElectronicCertCompare', '隐私比对', 3, '/electronicCert/compare', @systemSettingId, 142, 0),
('ElectronicCertApi', '电子证件API', 2, '/electronicCert/api/list', @systemSettingId, 143, 0),
('ElectronicCertKey', '电子证件密钥', 2, '/electronicCert/key/list', @systemSettingId, 144, 0);

-- ========== 9. 系统配置 ==========
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('SystemConfigNetwork', '网络配置', 2, '/systemConfig/getNetworkConfig', @systemSettingId, 10, 0),
('SystemConfigTime', '时间配置', 2, '/systemConfig/getTimeConfig', @systemSettingId, 11, 0),
('SystemConfigLogin', '登录限制', 2, '/systemConfig/getLoginRestriction', @systemSettingId, 12, 0),
('SystemConfigPersonal', '个性化设置', 2, '/systemConfig/getPersonalizationConfig', @systemSettingId, 13, 0),
('SystemConfigFtp', 'FTP设置', 2, '/systemConfig/getFtpConfig', @systemSettingId, 14, 0);

-- ========== 分配权限到超级管理员 ==========
SET @auth_codes = 'EvidenceQuery,EvidenceCreate,EvidenceVerify,EvidenceTimestamp,EvidenceConfig,EvidenceExport,EvidenceApiKey,
    MonitorView,MonitorAlertConfig,MonitorAlertHistory,
    ApiManageList,ApiManageAdd,ApiManageEdit,ApiManageDelete,ApiManageAuth,ApiManageLog,
    FederatedQueryCreate,FederatedQueryList,FederatedQueryRun,FederatedQueryResult,FederatedQueryLog,FederatedQueryTools,
    FederatedStatsCreate,FederatedStatsList,FederatedStatsRun,FederatedStatsResult,FederatedStatsStorage,FederatedStatsLog,
    FederatedAnalysisCreate,FederatedAnalysisList,FederatedAnalysisSql,FederatedAnalysisDatasource,FederatedAnalysisLog,
    PoliceFusionTask,PoliceFusionApi,PoliceFusionKey,PoliceFusionEncrypt,
    ElectronicCertTask,ElectronicCertFeature,ElectronicCertCompare,ElectronicCertApi,ElectronicCertKey,
    SystemConfigNetwork,SystemConfigTime,SystemConfigLogin,SystemConfigPersonal,SystemConfigFtp';

INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE FIND_IN_SET(auth_code, @auth_codes) > 0 AND is_del = 0;

-- ========== 验证 ==========
SELECT '--- 新增权限验证 ---' AS '';
SELECT a.auth_code, a.auth_name, a.auth_type
FROM sys_auth a
WHERE FIND_IN_SET(a.auth_code, @auth_codes) > 0 AND a.is_del = 0
ORDER BY a.auth_code;

SELECT '--- 权限分配验证 ---' AS '';
SELECT a.auth_code, a.auth_name, COUNT(ra.id) as assigned_count
FROM sys_auth a
LEFT JOIN sys_ra ra ON a.auth_id = ra.auth_id AND ra.role_id = 1 AND ra.is_del = 0
WHERE FIND_IN_SET(a.auth_code, @auth_codes) > 0 AND a.is_del = 0
GROUP BY a.auth_code, a.auth_name
ORDER BY a.auth_code;
