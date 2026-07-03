package com.primihub.biz.repository.primarydb.data;

import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 联邦学习建模工作台 Repository（工作流真持久化 + 运行日志）。
 */
public interface FlWorkbenchRepository {

    List<Map<String, Object>> selectWorkflowPage(Map<String, Object> params);

    int selectWorkflowCount(Map<String, Object> params);

    int countByStatus(@Param("status") Integer status);

    Map<String, Object> selectWorkflowById(@Param("workflowId") String workflowId);

    int insertWorkflow(Map<String, Object> wf);

    int updateWorkflow(Map<String, Object> wf);

    int deleteWorkflow(@Param("workflowId") String workflowId);

    int insertLog(Map<String, Object> logRow);

    List<Map<String, Object>> selectLogs(@Param("workflowId") String workflowId);

    int deleteLogs(@Param("workflowId") String workflowId);

    // 选项：真实数据资源 + 机构
    List<Map<String, Object>> selectDatasets(@Param("organId") String organId);

    List<Map<String, Object>> selectOrgans();
}
