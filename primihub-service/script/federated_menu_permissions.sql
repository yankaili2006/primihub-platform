-- 联邦学习、联邦分析、联邦统计、警务数据融合、电子证件比对菜单权限配置
-- 需要在数据库中执行：privacy

-- 获取当前最大的auth_id和auth_index
SELECT MAX(auth_id) INTO @max_auth_id FROM sys_auth;
SELECT MAX(auth_index) INTO @max_auth_index FROM sys_auth WHERE auth_type = 1;

-- ==================== 联邦学习菜单 ====================

SET @fl_id = @max_auth_id + 1;
SET @fl_index = @max_auth_index + 1;

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@fl_id, '联邦学习', 'ProjectFederatedLearning', 1, 0, @fl_id, CONCAT(@fl_id), '', '', @fl_index, 0, 1, 1, 0);

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@fl_id + 1, '联邦建模工作台', 'FLWorkbench', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 1), '/federatedLearning/index', '', 1, 1, 1, 1, 0),
(@fl_id + 2, '联邦建模参数调优', 'FLParamTuning', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 2), '/federatedLearning/paramTuning', '', 2, 1, 1, 1, 0),
(@fl_id + 3, '联邦建模训练迭代', 'FLTrainingIteration', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 3), '/federatedLearning/trainingIteration', '', 3, 1, 1, 1, 0),
(@fl_id + 4, '联邦建模训练报告', 'FLTrainingReport', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 4), '/federatedLearning/trainingReport', '', 4, 1, 1, 1, 0),
(@fl_id + 5, '联邦学习日志记录', 'FLLogRecord', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 5), '/federatedLearning/logRecord', '', 5, 1, 1, 1, 0),
(@fl_id + 6, '联邦学习日志导出', 'FLLogExport', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 6), '/federatedLearning/logExport', '', 6, 1, 1, 1, 0),
(@fl_id + 7, '单方数据合并模块', 'FLDataMerge', 2, @fl_id, @fl_id, CONCAT(@fl_id, ',', @fl_id + 7), '/federatedLearning/dataMerge', '', 7, 1, 1, 1, 0);

-- ==================== 联邦分析菜单 ====================

SET @fa_id = @fl_id + 8;
SET @fa_index = @fl_index + 1;

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@fa_id, '联邦分析', 'ProjectFederatedAnalysis', 1, 0, @fa_id, CONCAT(@fa_id), '', '', @fa_index, 0, 1, 1, 0);

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@fa_id + 1, '联邦分析', 'FAIndex', 2, @fa_id, @fa_id, CONCAT(@fa_id, ',', @fa_id + 1), '/federatedAnalysis/index', '', 1, 1, 1, 1, 0),
(@fa_id + 2, '联邦分析对接主流关系型数据库', 'FARelationalDB', 2, @fa_id, @fa_id, CONCAT(@fa_id, ',', @fa_id + 2), '/federatedAnalysis/relationalDB', '', 2, 1, 1, 1, 0),
(@fa_id + 3, '联邦分析对接主流大数据平台', 'FABigData', 2, @fa_id, @fa_id, CONCAT(@fa_id, ',', @fa_id + 3), '/federatedAnalysis/bigData', '', 3, 1, 1, 1, 0),
(@fa_id + 4, '联邦分析对接主流公有云平台', 'FAPublicCloud', 2, @fa_id, @fa_id, CONCAT(@fa_id, ',', @fa_id + 4), '/federatedAnalysis/publicCloud', '', 4, 1, 1, 1, 0),
(@fa_id + 5, '联邦分析日志记录', 'FALogRecord', 2, @fa_id, @fa_id, CONCAT(@fa_id, ',', @fa_id + 5), '/federatedAnalysis/logRecord', '', 5, 1, 1, 1, 0),
(@fa_id + 6, '联邦分析日志导出', 'FALogExport', 2, @fa_id, @fa_id, CONCAT(@fa_id, ',', @fa_id + 6), '/federatedAnalysis/logExport', '', 6, 1, 1, 1, 0);

-- ==================== 联邦统计菜单 ====================

SET @fs_id = @fa_id + 7;
SET @fs_index = @fa_index + 1;

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@fs_id, '联邦统计', 'ProjectFederatedStatistics', 1, 0, @fs_id, CONCAT(@fs_id), '', '', @fs_index, 0, 1, 1, 0);

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@fs_id + 1, '联邦统计', 'FederatedStatisticsIndex', 2, @fs_id, @fs_id, CONCAT(@fs_id, ',', @fs_id + 1), '/federatedStatistics/index', '', 1, 1, 1, 1, 0),
(@fs_id + 2, '联邦统计结果存储', 'FederatedStatisticsResultStorage', 2, @fs_id, @fs_id, CONCAT(@fs_id, ',', @fs_id + 2), '/federatedStatistics/resultStorage', '', 2, 1, 1, 1, 0),
(@fs_id + 3, '联邦统计结果导出', 'FederatedStatisticsResultExport', 2, @fs_id, @fs_id, CONCAT(@fs_id, ',', @fs_id + 3), '/federatedStatistics/resultExport', '', 3, 1, 1, 1, 0),
(@fs_id + 4, '联邦统计日志记录', 'FederatedStatisticsLogRecord', 2, @fs_id, @fs_id, CONCAT(@fs_id, ',', @fs_id + 4), '/federatedStatistics/logRecord', '', 4, 1, 1, 1, 0),
(@fs_id + 5, '联邦统计日志导出', 'FederatedStatisticsLogExport', 2, @fs_id, @fs_id, CONCAT(@fs_id, ',', @fs_id + 5), '/federatedStatistics/logExport', '', 5, 1, 1, 1, 0);

-- ==================== 警务数据融合菜单 ====================

SET @pd_id = @fs_id + 6;
SET @pd_index = @fs_index + 1;

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@pd_id, '警务数据融合', 'PoliceDataFusion', 1, 0, @pd_id, CONCAT(@pd_id), '', '', @pd_index, 0, 1, 1, 0);

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@pd_id + 1, '警务数据交集数据融合', 'PoliceDataIntersection', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 1), '/policeDataFusion/intersection', '', 1, 1, 1, 1, 0),
(@pd_id + 2, '保险机构接口对接', 'InsuranceApiConnect', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 2), '/policeDataFusion/insuranceApi', '', 2, 1, 1, 1, 0),
(@pd_id + 3, '保险机构同态密钥创建', 'InsuranceHomomorphicKey', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 3), '/policeDataFusion/homomorphicKey', '', 3, 1, 1, 1, 0),
(@pd_id + 4, '保险机构模型同态加密', 'InsuranceModelEncrypt', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 4), '/policeDataFusion/modelEncrypt', '', 4, 1, 1, 1, 0),
(@pd_id + 5, '加密模型联合运算', 'EncryptedModelCompute', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 5), '/policeDataFusion/encryptedCompute', '', 5, 1, 1, 1, 0),
(@pd_id + 6, '保险机构数据解密', 'InsuranceDataDecrypt', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 6), '/policeDataFusion/dataDecrypt', '', 6, 1, 1, 1, 0),
(@pd_id + 7, '警务数据对接', 'PoliceDataConnect', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 7), '/policeDataFusion/policeConnect', '', 7, 1, 1, 1, 0),
(@pd_id + 8, '模型密文数据安全交换（批量）', 'ModelCipherBatchExchange', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 8), '/policeDataFusion/batchExchange', '', 8, 1, 1, 1, 0),
(@pd_id + 9, '流程执行日志记录', 'PoliceDataLogRecord', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 9), '/policeDataFusion/logRecord', '', 9, 1, 1, 1, 0),
(@pd_id + 10, '流程执行日志导出', 'PoliceDataLogExport', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', @pd_id + 10), '/policeDataFusion/logExport', '', 10, 1, 1, 1, 0);

-- ==================== 电子证件比对菜单 ====================

SET @ec_id = @pd_id + 11;
SET @ec_index = @pd_index + 1;

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@ec_id, '电子证件比对', 'ElectronicCertCompare', 1, 0, @ec_id, CONCAT(@ec_id), '', '', @ec_index, 0, 1, 1, 0);

INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del) VALUES
(@ec_id + 1, '电子证件特征转换', 'ElectronicCertFeatureConvert', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 1), '/electronicCert/featureConvert', '', 1, 1, 1, 1, 0),
(@ec_id + 2, '现场证件特征转换', 'OnSiteCertFeatureConvert', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 2), '/electronicCert/onSiteConvert', '', 2, 1, 1, 1, 0),
(@ec_id + 3, '特征数据隐私比对', 'FeaturePrivacyCompare', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 3), '/electronicCert/privacyCompare', '', 3, 1, 1, 1, 0),
(@ec_id + 4, '警务数据对接', 'ElectronicCertPoliceConnect', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 4), '/electronicCert/policeConnect', '', 4, 1, 1, 1, 0),
(@ec_id + 5, '使用机构数据接入', 'OrgDataImport', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 5), '/electronicCert/orgDataImport', '', 5, 1, 1, 1, 0),
(@ec_id + 6, '使用机构数据导出', 'OrgDataExport', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 6), '/electronicCert/orgDataExport', '', 6, 1, 1, 1, 0),
(@ec_id + 7, '特征密文数据安全交换（批量）', 'FeatureCipherBatchExchange', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 7), '/electronicCert/batchExchange', '', 7, 1, 1, 1, 0),
(@ec_id + 8, '特征密文数据安全交换（实时）', 'FeatureCipherRealTimeExchange', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 8), '/electronicCert/realTimeExchange', '', 8, 1, 1, 1, 0),
(@ec_id + 9, '流程执行日志记录', 'ElectronicCertLogRecord', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 9), '/electronicCert/logRecord', '', 9, 1, 1, 1, 0),
(@ec_id + 10, '流程执行日志导出', 'ElectronicCertLogExport', 2, @ec_id, @ec_id, CONCAT(@ec_id, ',', @ec_id + 10), '/electronicCert/logExport', '', 10, 1, 1, 1, 0);

-- ==================== 为超级管理员分配权限 ====================

INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN (
    'ProjectFederatedLearning', 'FLWorkbench', 'FLParamTuning',
    'FLTrainingIteration', 'FLTrainingReport',
    'FLLogRecord', 'FLLogExport', 'FLDataMerge',
    'ProjectFederatedAnalysis', 'FAIndex', 'FARelationalDB',
    'FABigData', 'FAPublicCloud',
    'FALogRecord', 'FALogExport',
    'ProjectFederatedStatistics', 'FederatedStatisticsIndex', 'FederatedStatisticsResultStorage',
    'FederatedStatisticsResultExport', 'FederatedStatisticsLogRecord', 'FederatedStatisticsLogExport',
    'PoliceDataFusion', 'PoliceDataIntersection', 'InsuranceApiConnect', 'InsuranceHomomorphicKey',
    'InsuranceModelEncrypt', 'EncryptedModelCompute', 'InsuranceDataDecrypt', 'PoliceDataConnect',
    'ModelCipherBatchExchange', 'PoliceDataLogRecord', 'PoliceDataLogExport',
    'ElectronicCertCompare', 'ElectronicCertFeatureConvert', 'OnSiteCertFeatureConvert',
    'FeaturePrivacyCompare', 'ElectronicCertPoliceConnect', 'OrgDataImport', 'OrgDataExport',
    'FeatureCipherBatchExchange', 'FeatureCipherRealTimeExchange',
    'ElectronicCertLogRecord', 'ElectronicCertLogExport'
)
AND is_del = 0;

-- 验证插入结果
SELECT auth_id, auth_name, auth_code, auth_type, p_auth_id FROM sys_auth WHERE auth_type = 1 AND is_del = 0 ORDER BY auth_index;
