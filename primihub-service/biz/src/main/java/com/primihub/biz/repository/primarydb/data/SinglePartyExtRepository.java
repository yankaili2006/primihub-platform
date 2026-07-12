package com.primihub.biz.repository.primarydb.data;

import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 单方作业「预处理/脚本/日志」Repository（补齐原缺失的 preprocess/script/log 子模块；
 * 用独立表 sp_ext_task / sp_ext_log，不碰已有的 single_party_task）。
 */
public interface SinglePartyExtRepository {

    List<Map<String, Object>> selectTaskPage(Map<String, Object> params);

    int selectTaskCount(Map<String, Object> params);

    Map<String, Object> selectTaskByTaskId(@Param("taskId") String taskId);

    int insertTask(Map<String, Object> task);

    int updateTaskState(Map<String, Object> params);

    int deleteTask(@Param("taskId") String taskId);

    int insertLog(Map<String, Object> logRow);

    List<Map<String, Object>> selectLogPage(Map<String, Object> params);

    int selectLogCount(Map<String, Object> params);
}
