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
}
