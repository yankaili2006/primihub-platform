package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.FederatedStatsConfig;
import com.primihub.biz.entity.data.po.FederatedStatsResult;
import com.primihub.biz.entity.data.po.FederatedStatsTask;
import com.primihub.biz.entity.data.req.LogQueryReq;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface FederatedStatsRepository {

    void insertTask(FederatedStatsTask task);
    void updateTaskState(@Param("id") Long id, @Param("taskState") Integer taskState,
                         @Param("resultSummary") String resultSummary,
                         @Param("errorMessage") String errorMessage);
    void updateTask(FederatedStatsTask task);
    FederatedStatsTask selectTaskById(@Param("id") Long id);
    List<FederatedStatsTask> selectTaskList(Map<String, Object> params);
    int selectTaskCount(Map<String, Object> params);

    void insertResult(FederatedStatsResult result);
    List<FederatedStatsResult> selectResultsByTaskId(@Param("taskId") Long taskId);
    void deleteResultByTaskId(@Param("taskId") Long taskId);

    List<FederatedStatsResult> selectResultsByUserId(@Param("userId") Long userId);
    FederatedStatsResult selectResultById(@Param("id") Long id);
    void deleteResult(@Param("id") Long id);

    List<Map<String, Object>> selectLogList(LogQueryReq req);
    int selectLogCount(LogQueryReq req);
    Map<String, Object> selectLogById(@Param("id") Long id);

    void insertConfig(FederatedStatsConfig config);
    void updateConfig(FederatedStatsConfig config);
    void deleteConfig(@Param("id") Long id);
    FederatedStatsConfig selectConfigById(@Param("id") Long id);
    List<FederatedStatsConfig> selectConfigList(@Param("createdBy") Long createdBy);
    FederatedStatsConfig selectDefaultConfig();
}
