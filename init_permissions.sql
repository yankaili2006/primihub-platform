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

-- 14. 联邦求差 (Difference)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('联邦求差', 'Difference', 1, 0, LAST_INSERT_ID(), '/Difference', '', '', 13, 0, 1, 1, 0);
SET @diff_id = LAST_INSERT_ID();
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('联邦求差列表', 'DifferenceList', 2, @diff_id, @diff_id, '/Difference/list', '', '', 1, 1, 1, 1, 0),
('联邦求差任务', 'DifferenceTask', 2, @diff_id, @diff_id, '/Difference/task', '', '', 2, 1, 1, 1, 0),
('联邦求差详情', 'DifferenceDetail', 2, @diff_id, @diff_id, '/Difference/detail/:id', '', '', 3, 1, 1, 1, 0);

-- 15. 联邦求并 (Union)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('联邦求并', 'Union', 1, 0, LAST_INSERT_ID(), '/Union', '', '', 14, 0, 1, 1, 0);
SET @union_id = LAST_INSERT_ID();
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('联邦求并列表', 'UnionList', 2, @union_id, @union_id, '/Union/list', '', '', 1, 1, 1, 1, 0),
('联邦求并任务', 'UnionTask', 2, @union_id, @union_id, '/Union/task', '', '', 2, 1, 1, 1, 0),
('联邦求并详情', 'UnionDetail', 2, @union_id, @union_id, '/Union/detail/:id', '', '', 3, 1, 1, 1, 0);

-- 16. 单方算法 (SingleParty)
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES ('单方算法', 'SingleParty', 1, 0, LAST_INSERT_ID(), '/SingleParty', '', '', 15, 0, 1, 1, 0);
SET @sp_id = LAST_INSERT_ID();
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('单方算法列表', 'SinglePartyList', 2, @sp_id, @sp_id, '/SingleParty/list', '', '', 1, 1, 1, 1, 0),
('单方算法任务', 'SinglePartyTask', 2, @sp_id, @sp_id, '/SingleParty/task', '', '', 2, 1, 1, 1, 0),
('单方算法详情', 'SinglePartyDetail', 2, @sp_id, @sp_id, '/SingleParty/detail/:id', '', '', 3, 1, 1, 1, 0),
('单方数据清洗', 'SinglePartyDataCleaning', 2, @sp_id, @sp_id, '/SingleParty/dataCleaning', '', '', 4, 1, 1, 1, 0),
('单方数据缩放', 'SinglePartyDataScaling', 2, @sp_id, @sp_id, '/SingleParty/dataScaling', '', '', 5, 1, 1, 1, 0),
('单方数据统计', 'SinglePartyDataStats', 2, @sp_id, @sp_id, '/SingleParty/dataStats', '', '', 6, 1, 1, 1, 0),
('单方特征分箱', 'SinglePartyFeatureBin', 2, @sp_id, @sp_id, '/SingleParty/featureBin', '', '', 7, 1, 1, 1, 0),
('单方特征衍生', 'SinglePartyFeatureDerive', 2, @sp_id, @sp_id, '/SingleParty/featureDerive', '', '', 8, 1, 1, 1, 0),
('单方特征编码', 'SinglePartyFeatureEncode', 2, @sp_id, @sp_id, '/SingleParty/featureEncode', '', '', 9, 1, 1, 1, 0),
('单方特征筛选', 'SinglePartyFeatureSelect', 2, @sp_id, @sp_id, '/SingleParty/featureSelect', '', '', 10, 1, 1, 1, 0),
('单方学习日志记录', 'SinglePartyLogRecord', 2, @sp_id, @sp_id, '/SingleParty/logRecord', '', '', 11, 1, 1, 1, 0),
('单方学习日志导出', 'SinglePartyLogExport', 2, @sp_id, @sp_id, '/SingleParty/logExport', '', '', 12, 1, 1, 1, 0),
('单方LR算法', 'SinglePartyLRAlgorithm', 2, @sp_id, @sp_id, '/SingleParty/lrAlgorithm', '', '', 13, 1, 1, 1, 0),
('单方XGB算法', 'SinglePartyXGBAlgorithm', 2, @sp_id, @sp_id, '/SingleParty/xgbAlgorithm', '', '', 14, 1, 1, 1, 0),
('单方Python脚本', 'SinglePartyPythonScript', 2, @sp_id, @sp_id, '/SingleParty/pythonScript', '', '', 15, 1, 1, 1, 0),
('单方SQL处理', 'SinglePartySqlProcess', 2, @sp_id, @sp_id, '/SingleParty/sqlProcess', '', '', 16, 1, 1, 1, 0);

-- 17. 联邦学习子页面 (Federated Learning sub-pages, parent auth already exists)
SET @fl_parent = (SELECT auth_id FROM sys_auth WHERE auth_code = 'FederatedLearning');
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('联邦学习-数据融合', 'FLDataFusion', 2, @fl_parent, @fl_parent, '/federatedLearning/dataFusion', '', '', 100, 1, 1, 1, 0),
('联邦学习-特征相似度分析', 'FLFeatureSimilarity', 2, @fl_parent, @fl_parent, '/federatedLearning/featureSimilarity', '', '', 101, 1, 1, 1, 0),
('联邦学习-特征编码', 'FLFeatureEncode', 2, @fl_parent, @fl_parent, '/federatedLearning/featureEncodeFL', '', '', 102, 1, 1, 1, 0),
('联邦学习-特征对齐', 'FLFeatureAlign', 2, @fl_parent, @fl_parent, '/federatedLearning/featureAlign', '', '', 103, 1, 1, 1, 0),
('联邦学习-特征分享', 'FLFeatureShare', 2, @fl_parent, @fl_parent, '/federatedLearning/featureShare', '', '', 104, 1, 1, 1, 0),
('联邦学习-特征填充', 'FLFeatureFill', 2, @fl_parent, @fl_parent, '/federatedLearning/featureFill', '', '', 105, 1, 1, 1, 0),
('联邦学习-样本列扩展', 'FLSampleExpand', 2, @fl_parent, @fl_parent, '/federatedLearning/sampleExpand', '', '', 106, 1, 1, 1, 0),
('联邦学习-样本加权', 'FLSampleWeight', 2, @fl_parent, @fl_parent, '/federatedLearning/sampleWeight', '', '', 107, 1, 1, 1, 0),
('联邦学习-指标建模分析', 'FLMetricModeling', 2, @fl_parent, @fl_parent, '/federatedLearning/metricModeling', '', '', 108, 1, 1, 1, 0),
('联邦学习-特征装仓', 'FLFeatureWarehouse', 2, @fl_parent, @fl_parent, '/federatedLearning/featureWarehouse', '', '', 109, 1, 1, 1, 0),
('联邦学习-数据分割', 'FLDataSplit', 2, @fl_parent, @fl_parent, '/federatedLearning/dataSplit', '', '', 110, 1, 1, 1, 0),
('联邦学习-数据转换', 'FLDataTransform', 2, @fl_parent, @fl_parent, '/federatedLearning/dataTransform', '', '', 111, 1, 1, 1, 0),
('纵向线性回归建模', 'FLVerticalLinearTrain', 2, @fl_parent, @fl_parent, '/federatedLearning/verticalLinearTrain', '', '', 112, 1, 1, 1, 0),
('纵向逻辑回归建模', 'FLVerticalLogisticTrain', 2, @fl_parent, @fl_parent, '/federatedLearning/verticalLogisticTrain', '', '', 113, 1, 1, 1, 0),
('纵向XGBoost建模', 'FLVerticalXGBoostTrain', 2, @fl_parent, @fl_parent, '/federatedLearning/verticalXGBoostTrain', '', '', 114, 1, 1, 1, 0),
('纵向线性回归预测', 'FLVerticalLinearPredict', 2, @fl_parent, @fl_parent, '/federatedLearning/verticalLinearPredict', '', '', 115, 1, 1, 1, 0),
('纵向逻辑回归预测', 'FLVerticalLogisticPredict', 2, @fl_parent, @fl_parent, '/federatedLearning/verticalLogisticPredict', '', '', 116, 1, 1, 1, 0),
('纵向XGBoost预测', 'FLVerticalXGBoostPredict', 2, @fl_parent, @fl_parent, '/federatedLearning/verticalXGBoostPredict', '', '', 117, 1, 1, 1, 0),
('联邦学习-参数调优', 'FederatedLearningParamTuning', 2, @fl_parent, @fl_parent, '/federatedLearning/paramTuning', '', '', 118, 1, 1, 1, 0),
('联邦学习-训练报告', 'FederatedLearningTrainingReport', 2, @fl_parent, @fl_parent, '/federatedLearning/trainingReport', '', '', 119, 1, 1, 1, 0),
('联邦学习-日志记录', 'FederatedLearningLogRecord', 2, @fl_parent, @fl_parent, '/federatedLearning/logRecord', '', '', 120, 1, 1, 1, 0),
('联邦学习-日志导出', 'FederatedLearningLogExport', 2, @fl_parent, @fl_parent, '/federatedLearning/logExport', '', '', 121, 1, 1, 1, 0);

-- 18. 联邦分析子页面 (Federated Analysis, parent is ProjectFederatedAnalysis)
SET @fa_parent = (SELECT auth_id FROM sys_auth WHERE auth_code = 'ProjectFederatedAnalysis');
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('联邦分析-SQL校验', 'FederatedAnalysisSqlValidator', 2, @fa_parent, @fa_parent, '/federatedAnalysis/sqlValidator', '', '', 200, 1, 1, 1, 0),
('联邦分析-关系型数据库', 'FederatedAnalysisRelationalDB', 2, @fa_parent, @fa_parent, '/federatedAnalysis/relationalDB', '', '', 201, 1, 1, 1, 0),
('联邦分析-大数据平台', 'FederatedAnalysisBigData', 2, @fa_parent, @fa_parent, '/federatedAnalysis/bigData', '', '', 202, 1, 1, 1, 0),
('联邦分析-公有云', 'FederatedAnalysisPublicCloud', 2, @fa_parent, @fa_parent, '/federatedAnalysis/publicCloud', '', '', 203, 1, 1, 1, 0),
('联邦分析-筛选算子', 'FAFilterOperator', 2, @fa_parent, @fa_parent, '/federatedAnalysis/filterOperator', '', '', 204, 1, 1, 1, 0),
('联邦分析-连接算子', 'FAJoinOperator', 2, @fa_parent, @fa_parent, '/federatedAnalysis/joinOperator', '', '', 205, 1, 1, 1, 0),
('联邦分析-聚合算子', 'FAAggregateOperator', 2, @fa_parent, @fa_parent, '/federatedAnalysis/aggregateOperator', '', '', 206, 1, 1, 1, 0),
('联邦分析-分组算子', 'FAGroupOperator', 2, @fa_parent, @fa_parent, '/federatedAnalysis/groupOperator', '', '', 207, 1, 1, 1, 0),
('联邦分析-排序算子', 'FASortOperator', 2, @fa_parent, @fa_parent, '/federatedAnalysis/sortOperator', '', '', 208, 1, 1, 1, 0),
('联邦分析-窗口函数', 'FAWindowFunction', 2, @fa_parent, @fa_parent, '/federatedAnalysis/windowFunction', '', '', 209, 1, 1, 1, 0),
('联邦分析-字符函数', 'FACharFunctions', 2, @fa_parent, @fa_parent, '/federatedAnalysis/charFunctions', '', '', 210, 1, 1, 1, 0),
('联邦分析-日期函数', 'FADateFunctions', 2, @fa_parent, @fa_parent, '/federatedAnalysis/dateFunctions', '', '', 211, 1, 1, 1, 0),
('联邦分析-SQL格式化', 'FASqlFormatter', 2, @fa_parent, @fa_parent, '/federatedAnalysis/sqlFormatter', '', '', 212, 1, 1, 1, 0),
('联邦分析-浮点函数', 'FAFloatFunctions', 2, @fa_parent, @fa_parent, '/federatedAnalysis/floatFunctions', '', '', 213, 1, 1, 1, 0);

-- 19. 联邦统计子页面 (Federated Statistics, parent is ProjectFederatedStatistics)
SET @fs_parent = (SELECT auth_id FROM sys_auth WHERE auth_code = 'ProjectFederatedStatistics');
INSERT INTO sys_auth (auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
VALUES
('联邦统计-卡方检验', 'FederatedStatisticsChiSquareTest', 2, @fs_parent, @fs_parent, '/federatedStatistics/chiSquareTest', '', '', 300, 1, 1, 1, 0),
('联邦统计-F检验', 'FederatedStatisticsFTest', 2, @fs_parent, @fs_parent, '/federatedStatistics/fTest', '', '', 301, 1, 1, 1, 0),
('联邦统计-分组统计', 'FederatedStatisticsGroupStats', 2, @fs_parent, @fs_parent, '/federatedStatistics/groupStats', '', '', 302, 1, 1, 1, 0),
('联邦统计-T检验', 'FederatedStatisticsTTest', 2, @fs_parent, @fs_parent, '/federatedStatistics/tTest', '', '', 303, 1, 1, 1, 0),
('联邦统计-占比统计', 'FederatedStatisticsRatioStats', 2, @fs_parent, @fs_parent, '/federatedStatistics/ratioStats', '', '', 304, 1, 1, 1, 0),
('联邦统计-日志记录', 'FederatedStatisticsLogRecord', 2, @fs_parent, @fs_parent, '/federatedStatistics/logRecord', '', '', 305, 1, 1, 1, 0),
('联邦统计-日志导出', 'FederatedStatisticsLogExport', 2, @fs_parent, @fs_parent, '/federatedStatistics/logExport', '', '', 306, 1, 1, 1, 0),
('联邦统计-结果存储', 'FederatedStatisticsResultStorage', 2, @fs_parent, @fs_parent, '/federatedStatistics/resultStorage', '', '', 307, 1, 1, 1, 0),
('联邦统计-结果导出', 'FederatedStatisticsResultExport', 2, @fs_parent, @fs_parent, '/federatedStatistics/resultExport', '', '', 308, 1, 1, 1, 0);
