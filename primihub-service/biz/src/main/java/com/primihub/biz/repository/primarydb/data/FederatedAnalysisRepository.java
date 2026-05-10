package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.FederatedAnalysisDatasource;
import com.primihub.biz.entity.data.po.FederatedAnalysisResult;
import com.primihub.biz.entity.data.po.FederatedAnalysisTask;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface FederatedAnalysisRepository {

    void insertTask(FederatedAnalysisTask task);
    void updateTaskState(@Param("id") Long id, @Param("taskState") Integer taskState,
                         @Param("resultSummary") String resultSummary,
                         @Param("errorMessage") String errorMessage);
    void updateTaskRewrittenSql(@Param("id") Long id, @Param("rewrittenSql") String rewrittenSql);
    FederatedAnalysisTask selectTaskById(@Param("id") Long id);
    List<FederatedAnalysisTask> selectTaskList(Map<String, Object> params);
    int selectTaskCount(Map<String, Object> params);

    void insertResult(FederatedAnalysisResult result);
    List<FederatedAnalysisResult> selectResultsByTaskId(@Param("taskId") Long taskId);

    void insertDatasource(FederatedAnalysisDatasource ds);
    void updateDatasource(FederatedAnalysisDatasource ds);
    void updateDatasourceConnection(@Param("id") Long id, @Param("isConnected") Integer isConnected,
                                    @Param("lastTestTime") java.util.Date lastTestTime);
    void deleteDatasource(@Param("id") Long id);
    FederatedAnalysisDatasource selectDatasourceById(@Param("id") Long id);
    List<FederatedAnalysisDatasource> selectDatasourceList(Map<String, Object> params);
}
