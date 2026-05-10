package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.req.*;
import javax.servlet.http.HttpServletResponse;

public interface FederatedStatsService {

    BaseResultEntity createTask(FederatedStatsReq req, Long userId);
    BaseResultEntity getTaskList(FederatedStatsQueryReq req);
    BaseResultEntity getTaskDetail(Long taskId);
    BaseResultEntity runTask(Long taskId, Long userId);
    BaseResultEntity stopTask(Long taskId);
    BaseResultEntity deleteTask(Long taskId);

    BaseResultEntity getResult(Long taskId);
    BaseResultEntity saveResult(SaveResultReq req, Long userId);
    void exportResult(Long taskId, String format, HttpServletResponse response);
    void batchExportResult(BatchExportReq req, HttpServletResponse response);

    BaseResultEntity getStorageConfig(Long userId);
    BaseResultEntity saveStorageConfig(StorageConfigReq req, Long userId);
    BaseResultEntity testStorageConnection(StorageConfigReq req);
    BaseResultEntity getStoredResults(Integer pageNo, Integer pageSize, Long userId);
    BaseResultEntity previewStoredResult(Long resultId, Integer rows);
    void downloadStoredResult(Long resultId, HttpServletResponse response);
    BaseResultEntity deleteStoredResult(Long resultId);

    BaseResultEntity getLogs(LogQueryReq req);
    BaseResultEntity getLogDetail(Long logId);
    void exportLogs(LogExportReq req, HttpServletResponse response);

    BaseResultEntity getStatisticsTypes();
}
