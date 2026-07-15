package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;

import javax.servlet.http.HttpServletResponse;
import java.util.Map;

public interface SceneService {

    BaseResultEntity createTask(String sceneType, Map<String, Object> req, Long userId);
    // 场景日志（任务即日志记录）
    BaseResultEntity getLogList(String sceneType, String taskType, String keyword, Integer pageNo, Integer pageSize);
    void exportLog(HttpServletResponse response, String sceneType, String taskType, String keyword);
    BaseResultEntity getTaskList(String sceneType, String taskType, Integer pageNo, Integer pageSize);
    BaseResultEntity getTaskDetail(Long taskId);
    BaseResultEntity executeTask(Long taskId);
    /** 导出流程执行日志(真实 SceneTask 记录)为 CSV。 */
    BaseResultEntity exportTaskLog(String sceneType, String taskType);

    /** 机构数据接入: 解析上传数据行, 真实落库到 scene_imported_data, 返回导入行数/批次号/taskId。 */
    BaseResultEntity importData(String sceneType, Map<String, Object> req, Long userId);

    /** 机构数据导出: 查 scene_imported_data 真实数据行, 汇总为 CSV 返回。 */
    BaseResultEntity exportImportedData(String sceneType, Long taskId, String batchNo);

    /** 密文数据安全交换: 用指定密钥对每行数据做真实 AES-256-GCM 加密并落库, mode=batch|realtime。 */
    BaseResultEntity exchangeData(String sceneType, Map<String, Object> req, Long userId, String mode);

    /** 特征转换: 对特征字段归一化后做确定性 SHA-256 令牌化(可用于 PSI 隐私比对), 落库并返回令牌。 */
    BaseResultEntity convertFeature(String sceneType, Map<String, Object> req, Long userId);

    BaseResultEntity saveApiConfig(String sceneType, Map<String, Object> req, Long userId);
    BaseResultEntity getApiConfigList(String sceneType);
    BaseResultEntity deleteApiConfig(Long id);
    BaseResultEntity testApiConnection(Long id);
    BaseResultEntity callApi(Long id, Map<String, Object> params);

    BaseResultEntity generateKey(String sceneType, Map<String, Object> req, Long userId);
    BaseResultEntity getKeyList(String sceneType);
    BaseResultEntity deleteKey(Long id);
    BaseResultEntity encryptData(Long keyId, String data);
    BaseResultEntity decryptData(Long keyId, String encryptedData);

    // 数据源对接
    BaseResultEntity getDataSourceList();
    BaseResultEntity saveDataSource(Map<String, Object> req, Long userId);
    BaseResultEntity deleteDataSource(Long id);
    BaseResultEntity syncDataSource(Long sourceId);
    BaseResultEntity testDataSource(Long sourceId);
}
