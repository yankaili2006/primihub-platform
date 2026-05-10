package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.req.FederatedStatsQueryReq;
import com.primihub.biz.entity.data.req.LogExportReq;
import com.primihub.biz.entity.data.req.LogQueryReq;
import com.primihub.biz.entity.data.req.TaskActionReq;

import javax.servlet.http.HttpServletResponse;
import java.util.Map;

public interface FederatedQueryService {

    BaseResultEntity createQuery(Map<String, Object> req, Long userId);
    BaseResultEntity getQueryList(FederatedStatsQueryReq req);
    BaseResultEntity getQueryDetail(Long taskId);
    BaseResultEntity runQuery(Long taskId, Long userId);
    BaseResultEntity getQueryResult(Long taskId);
    BaseResultEntity getSupportedAlgorithms();

    BaseResultEntity getLogs(LogQueryReq req);
    void exportLogs(LogExportReq req, HttpServletResponse response);

    BaseResultEntity saveToolConfig(Map<String, Object> req, Long userId);
    BaseResultEntity getToolConfig(String toolName);
    BaseResultEntity testTool(Map<String, Object> req);
}
