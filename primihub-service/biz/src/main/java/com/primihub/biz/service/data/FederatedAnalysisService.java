package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.req.*;
import javax.servlet.http.HttpServletResponse;

public interface FederatedAnalysisService {

    BaseResultEntity validateSql(SqlValidateReq req);
    BaseResultEntity formatSql(SqlFormatReq req);
    BaseResultEntity getFunctions(String category);

    BaseResultEntity createTask(AnalysisTaskReq req, Long userId);
    BaseResultEntity getTaskList(AnalysisTaskQueryReq req);
    BaseResultEntity getTaskDetail(Long taskId);
    BaseResultEntity runTask(Long taskId, Long userId);
    BaseResultEntity stopTask(Long taskId);

    BaseResultEntity getDataSourceList(String sourceType);
    BaseResultEntity createDataSource(AnalysisDataSourceReq req, Long userId);
    BaseResultEntity updateDataSource(AnalysisDataSourceReq req);
    BaseResultEntity deleteDataSource(Long id);
    BaseResultEntity testDataSourceConnection(AnalysisDataSourceReq req);
    BaseResultEntity getDataSourceTables(Long datasourceId);
    BaseResultEntity getTableColumns(Long datasourceId, String tableName);

    BaseResultEntity getSupportedRdbms();
    BaseResultEntity getSupportedBigDataPlatforms();
    BaseResultEntity getSupportedCloudPlatforms();

    BaseResultEntity getLogs(LogQueryReq req);
    void exportLogs(LogExportReq req, HttpServletResponse response);
    void batchExportLogs(BatchExportReq req, HttpServletResponse response);
}
