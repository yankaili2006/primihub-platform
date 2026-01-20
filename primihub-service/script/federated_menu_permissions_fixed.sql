-- 联邦学习、联邦分析、联邦统计菜单权限配置（修正版）
-- 这三个菜单是项目管理(auth_id=1001)下的二级菜单
-- 需要在数据库中执行：privacy

-- 项目管理的 auth_id = 1001

-- ==================== 联邦学习菜单（项目管理的二级菜单） ====================

-- 联邦学习作为项目管理的二级菜单
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1140, '联邦学习', 'ProjectFederatedLearning', 2, 1001, 1001, '1001,1140', '/project/federatedLearning', '', 6, 1, 1, 1, 0);

-- 联邦学习的子菜单（三级菜单）
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1141, '联邦建模工作台', 'FederatedLearningIndex', 3, 1140, 1001, '1001,1140,1141', '/federatedLearning/index', '', 1, 2, 1, 1, 0),
(1142, '联邦建模参数调优', 'FederatedLearningParamTuning', 3, 1140, 1001, '1001,1140,1142', '/federatedLearning/paramTuning', '', 2, 2, 1, 1, 0),
(1143, '联邦建模训练迭代', 'FederatedLearningTrainingIteration', 3, 1140, 1001, '1001,1140,1143', '/federatedLearning/trainingIteration', '', 3, 2, 1, 1, 0),
(1144, '联邦建模训练报告', 'FederatedLearningTrainingReport', 3, 1140, 1001, '1001,1140,1144', '/federatedLearning/trainingReport', '', 4, 2, 1, 1, 0),
(1145, '联邦学习日志记录', 'FederatedLearningLogRecord', 3, 1140, 1001, '1001,1140,1145', '/federatedLearning/logRecord', '', 5, 2, 1, 1, 0),
(1146, '联邦学习日志导出', 'FederatedLearningLogExport', 3, 1140, 1001, '1001,1140,1146', '/federatedLearning/logExport', '', 6, 2, 1, 1, 0),
(1147, '单方数据合并模块', 'FederatedLearningSinglePartyDataMerge', 3, 1140, 1001, '1001,1140,1147', '/federatedLearning/dataMerge', '', 7, 2, 1, 1, 0);

-- ==================== 联邦分析菜单（项目管理的二级菜单） ====================

-- 联邦分析作为项目管理的二级菜单
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1150, '联邦分析', 'ProjectFederatedAnalysis', 2, 1001, 1001, '1001,1150', '/project/federatedAnalysis', '', 7, 1, 1, 1, 0);

-- 联邦分析的子菜单（三级菜单）
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1151, '联邦分析首页', 'FederatedAnalysisIndex', 3, 1150, 1001, '1001,1150,1151', '/federatedAnalysis/index', '', 1, 2, 1, 1, 0),
(1152, '联邦分析对接主流关系型数据库', 'FederatedAnalysisRelationalDB', 3, 1150, 1001, '1001,1150,1152', '/federatedAnalysis/relationalDB', '', 2, 2, 1, 1, 0),
(1153, '联邦分析对接主流大数据平台', 'FederatedAnalysisBigData', 3, 1150, 1001, '1001,1150,1153', '/federatedAnalysis/bigData', '', 3, 2, 1, 1, 0),
(1154, '联邦分析对接主流公有云平台', 'FederatedAnalysisPublicCloud', 3, 1150, 1001, '1001,1150,1154', '/federatedAnalysis/publicCloud', '', 4, 2, 1, 1, 0),
(1155, '联邦分析日志记录', 'FederatedAnalysisLogRecord', 3, 1150, 1001, '1001,1150,1155', '/federatedAnalysis/logRecord', '', 5, 2, 1, 1, 0),
(1156, '联邦分析日志导出', 'FederatedAnalysisLogExport', 3, 1150, 1001, '1001,1150,1156', '/federatedAnalysis/logExport', '', 6, 2, 1, 1, 0);

-- ==================== 联邦统计菜单（项目管理的二级菜单） ====================

-- 联邦统计作为项目管理的二级菜单
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1160, '联邦统计', 'ProjectFederatedStatistics', 2, 1001, 1001, '1001,1160', '/project/federatedStatistics', '', 8, 1, 1, 1, 0);

-- 联邦统计的子菜单（三级菜单）
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(1161, '联邦统计首页', 'FederatedStatisticsIndex', 3, 1160, 1001, '1001,1160,1161', '/federatedStatistics/index', '', 1, 2, 1, 1, 0),
(1162, '联邦统计结果存储', 'FederatedStatisticsResultStorage', 3, 1160, 1001, '1001,1160,1162', '/federatedStatistics/resultStorage', '', 2, 2, 1, 1, 0),
(1163, '联邦统计结果导出', 'FederatedStatisticsResultExport', 3, 1160, 1001, '1001,1160,1163', '/federatedStatistics/resultExport', '', 3, 2, 1, 1, 0),
(1164, '联邦统计日志记录', 'FederatedStatisticsLogRecord', 3, 1160, 1001, '1001,1160,1164', '/federatedStatistics/logRecord', '', 4, 2, 1, 1, 0),
(1165, '联邦统计日志导出', 'FederatedStatisticsLogExport', 3, 1160, 1001, '1001,1160,1165', '/federatedStatistics/logExport', '', 5, 2, 1, 1, 0);

-- ==================== 为超级管理员分配权限 ====================

INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN (
    'ProjectFederatedLearning', 'FederatedLearningIndex', 'FederatedLearningParamTuning',
    'FederatedLearningTrainingIteration', 'FederatedLearningTrainingReport',
    'FederatedLearningLogRecord', 'FederatedLearningLogExport', 'FederatedLearningSinglePartyDataMerge',
    'ProjectFederatedAnalysis', 'FederatedAnalysisIndex', 'FederatedAnalysisRelationalDB',
    'FederatedAnalysisBigData', 'FederatedAnalysisPublicCloud',
    'FederatedAnalysisLogRecord', 'FederatedAnalysisLogExport',
    'ProjectFederatedStatistics', 'FederatedStatisticsIndex', 'FederatedStatisticsResultStorage',
    'FederatedStatisticsResultExport', 'FederatedStatisticsLogRecord', 'FederatedStatisticsLogExport'
)
AND is_del = 0;

-- 验证插入结果
SELECT auth_id, auth_name, auth_code, auth_type, p_auth_id, auth_depth
FROM sys_auth
WHERE auth_code LIKE '%Federated%' AND is_del = 0
ORDER BY auth_id;
