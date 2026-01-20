-- 警务数据融合菜单权限配置修复脚本
-- 需要在数据库中执行：privacy
-- 包含以下页面权限：
-- 1. 警务数据交集数据融合
-- 2. 保险机构接口对接
-- 3. 保险机构同态密钥创建
-- 4. 保险机构模型同态加密
-- 5. 加密模型联合运算
-- 6. 保险机构数据解密
-- 7. 警务数据对接
-- 8. 模型密文数据安全交换（批量）
-- 9. 流程执行日志记录
-- 10. 流程执行日志导出

-- ==================== 1. 检查并插入警务数据融合主菜单 ====================

-- 获取当前最大的auth_id
SET @max_auth_id = (SELECT IFNULL(MAX(auth_id), 1000) FROM sys_auth);
SET @max_auth_index = (SELECT IFNULL(MAX(auth_index), 0) FROM sys_auth WHERE auth_type = 1);

-- 检查警务数据融合主菜单是否存在
SET @pd_exists = (SELECT COUNT(*) FROM sys_auth WHERE auth_code = 'PoliceDataFusion' AND is_del = 0);

-- 如果不存在，插入主菜单
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT @max_auth_id + 1, '警务数据融合', 'PoliceDataFusion', 1, 0, @max_auth_id + 1, CONCAT(@max_auth_id + 1), '', '', @max_auth_index + 1, 0, 1, 1, 0
FROM DUAL WHERE @pd_exists = 0;

-- 获取警务数据融合主菜单的auth_id
SET @pd_id = (SELECT auth_id FROM sys_auth WHERE auth_code = 'PoliceDataFusion' AND is_del = 0 LIMIT 1);

-- ==================== 2. 插入子菜单（如果不存在） ====================

-- 警务数据交集数据融合
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '警务数据交集数据融合', 'PoliceDataIntersection', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/intersection', '', 1, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'PoliceDataIntersection' AND is_del = 0);

-- 保险机构接口对接
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '保险机构接口对接', 'InsuranceApiConnect', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/insuranceApi', '', 2, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'InsuranceApiConnect' AND is_del = 0);

-- 保险机构同态密钥创建
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '保险机构同态密钥创建', 'InsuranceHomomorphicKey', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/homomorphicKey', '', 3, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'InsuranceHomomorphicKey' AND is_del = 0);

-- 保险机构模型同态加密
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '保险机构模型同态加密', 'InsuranceModelEncrypt', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/modelEncrypt', '', 4, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'InsuranceModelEncrypt' AND is_del = 0);

-- 加密模型联合运算
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '加密模型联合运算', 'EncryptedModelCompute', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/encryptedCompute', '', 5, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'EncryptedModelCompute' AND is_del = 0);

-- 保险机构数据解密
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '保险机构数据解密', 'InsuranceDataDecrypt', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/dataDecrypt', '', 6, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'InsuranceDataDecrypt' AND is_del = 0);

-- 警务数据对接
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '警务数据对接', 'PoliceDataConnect', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/policeConnect', '', 7, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'PoliceDataConnect' AND is_del = 0);

-- 模型密文数据安全交换（批量）
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '模型密文数据安全交换（批量）', 'ModelCipherBatchExchange', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/batchExchange', '', 8, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'ModelCipherBatchExchange' AND is_del = 0);

-- 流程执行日志记录
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '流程执行日志记录', 'PoliceDataLogRecord', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/logRecord', '', 9, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'PoliceDataLogRecord' AND is_del = 0);

-- 流程执行日志导出
INSERT INTO sys_auth (auth_id, auth_name, auth_code, auth_type, p_auth_id, r_auth_id, full_path, auth_url, data_auth_code, auth_index, auth_depth, is_show, is_editable, is_del)
SELECT (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth), '流程执行日志导出', 'PoliceDataLogExport', 2, @pd_id, @pd_id, CONCAT(@pd_id, ',', (SELECT IFNULL(MAX(auth_id), 1000) + 1 FROM sys_auth)), '/policeDataFusion/logExport', '', 10, 1, 1, 1, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_auth WHERE auth_code = 'PoliceDataLogExport' AND is_del = 0);

-- ==================== 3. 为超级管理员(role_id=1)分配权限 ====================

-- 删除可能存在的重复权限记录
DELETE FROM sys_ra WHERE role_id = 1 AND auth_id IN (
    SELECT auth_id FROM sys_auth
    WHERE auth_code IN (
        'PoliceDataFusion', 'PoliceDataIntersection', 'InsuranceApiConnect',
        'InsuranceHomomorphicKey', 'InsuranceModelEncrypt', 'EncryptedModelCompute',
        'InsuranceDataDecrypt', 'PoliceDataConnect', 'ModelCipherBatchExchange',
        'PoliceDataLogRecord', 'PoliceDataLogExport'
    )
    AND is_del = 0
);

-- 为超级管理员分配所有警务数据融合权限
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN (
    'PoliceDataFusion', 'PoliceDataIntersection', 'InsuranceApiConnect',
    'InsuranceHomomorphicKey', 'InsuranceModelEncrypt', 'EncryptedModelCompute',
    'InsuranceDataDecrypt', 'PoliceDataConnect', 'ModelCipherBatchExchange',
    'PoliceDataLogRecord', 'PoliceDataLogExport'
)
AND is_del = 0;

-- ==================== 4. 为所有现有角色分配警务数据融合权限 ====================

-- 为所有角色分配警务数据融合主菜单权限
INSERT IGNORE INTO sys_ra (role_id, auth_id, is_del)
SELECT r.role_id, sa.auth_id, 0
FROM sys_role r
CROSS JOIN sys_auth sa
WHERE r.is_del = 0
AND sa.auth_code = 'PoliceDataFusion'
AND sa.is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra WHERE role_id = r.role_id AND auth_id = sa.auth_id AND is_del = 0
);

-- 为所有角色分配警务数据融合子菜单权限
INSERT IGNORE INTO sys_ra (role_id, auth_id, is_del)
SELECT r.role_id, sa.auth_id, 0
FROM sys_role r
CROSS JOIN sys_auth sa
WHERE r.is_del = 0
AND sa.auth_code IN (
    'PoliceDataIntersection', 'InsuranceApiConnect', 'InsuranceHomomorphicKey',
    'InsuranceModelEncrypt', 'EncryptedModelCompute', 'InsuranceDataDecrypt',
    'PoliceDataConnect', 'ModelCipherBatchExchange', 'PoliceDataLogRecord', 'PoliceDataLogExport'
)
AND sa.is_del = 0
AND NOT EXISTS (
    SELECT 1 FROM sys_ra WHERE role_id = r.role_id AND auth_id = sa.auth_id AND is_del = 0
);

-- ==================== 5. 验证结果 ====================

-- 查看警务数据融合菜单配置
SELECT auth_id, auth_name, auth_code, auth_type, p_auth_id, auth_url, auth_index, auth_depth
FROM sys_auth
WHERE auth_code IN (
    'PoliceDataFusion', 'PoliceDataIntersection', 'InsuranceApiConnect',
    'InsuranceHomomorphicKey', 'InsuranceModelEncrypt', 'EncryptedModelCompute',
    'InsuranceDataDecrypt', 'PoliceDataConnect', 'ModelCipherBatchExchange',
    'PoliceDataLogRecord', 'PoliceDataLogExport'
)
AND is_del = 0
ORDER BY auth_index;

-- 查看权限分配情况
SELECT sr.role_id, r.role_name, sa.auth_name, sa.auth_code
FROM sys_ra sr
JOIN sys_auth sa ON sr.auth_id = sa.auth_id
JOIN sys_role r ON sr.role_id = r.role_id
WHERE sa.auth_code IN (
    'PoliceDataFusion', 'PoliceDataIntersection', 'InsuranceApiConnect',
    'InsuranceHomomorphicKey', 'InsuranceModelEncrypt', 'EncryptedModelCompute',
    'InsuranceDataDecrypt', 'PoliceDataConnect', 'ModelCipherBatchExchange',
    'PoliceDataLogRecord', 'PoliceDataLogExport'
)
AND sr.is_del = 0 AND sa.is_del = 0
ORDER BY sr.role_id, sa.auth_index;
