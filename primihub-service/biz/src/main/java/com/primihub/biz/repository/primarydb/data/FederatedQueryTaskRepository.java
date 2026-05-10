package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.FederatedQueryLog;
import com.primihub.biz.entity.data.po.FederatedQueryTask;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface FederatedQueryTaskRepository {

    void insertQueryTask(FederatedQueryTask task);

    void updateQueryTask(FederatedQueryTask task);

    FederatedQueryTask selectQueryTaskById(@Param("id") Long id);

    List<FederatedQueryTask> selectQueryTaskList(Map<String, Object> params);

    int selectQueryTaskCount(Map<String, Object> params);

    void insertQueryLog(FederatedQueryLog log);

    List<FederatedQueryLog> selectQueryLogList(Map<String, Object> params);

    int selectQueryLogCount(Map<String, Object> params);

    void batchInsertQueryLog(List<FederatedQueryLog> logs);
}
