package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.OperationLogDefinition;
import com.primihub.biz.entity.sys.po.ScheduleLogDefinition;
import com.primihub.biz.entity.sys.po.ComputeLogDefinition;
import com.primihub.biz.entity.sys.po.OperationLog;
import com.primihub.biz.entity.sys.po.ScheduleLog;
import com.primihub.biz.entity.sys.po.ComputeLog;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface LogManagementPrimarydbRepository {

    // ========== 操作日志定义 ==========

    /**
     * 新增操作日志定义
     */
    void insertOperationLogDefinition(OperationLogDefinition definition);

    /**
     * 更新操作日志定义
     */
    void updateOperationLogDefinition(OperationLogDefinition definition);

    /**
     * 删除操作日志定义
     */
    void deleteOperationLogDefinition(@Param("id") Long id);

    /**
     * 根据ID查询操作日志定义
     */
    OperationLogDefinition selectOperationLogDefinitionById(@Param("id") Long id);

    /**
     * 根据日志代码查询操作日志定义
     */
    OperationLogDefinition selectOperationLogDefinitionByCode(@Param("logCode") String logCode);

    /**
     * 查询操作日志定义列表
     */
    List<OperationLogDefinition> selectOperationLogDefinitionList(Map<String, Object> params);

    /**
     * 查询操作日志定义总数
     */
    int selectOperationLogDefinitionCount(Map<String, Object> params);

    /**
     * 更新操作日志定义状态
     */
    void updateOperationLogDefinitionStatus(@Param("id") Long id, @Param("isEnabled") Integer isEnabled);

    // ========== 调度日志定义 ==========

    /**
     * 新增调度日志定义
     */
    void insertScheduleLogDefinition(ScheduleLogDefinition definition);

    /**
     * 更新调度日志定义
     */
    void updateScheduleLogDefinition(ScheduleLogDefinition definition);

    /**
     * 删除调度日志定义
     */
    void deleteScheduleLogDefinition(@Param("id") Long id);

    /**
     * 根据ID查询调度日志定义
     */
    ScheduleLogDefinition selectScheduleLogDefinitionById(@Param("id") Long id);

    /**
     * 根据日志代码查询调度日志定义
     */
    ScheduleLogDefinition selectScheduleLogDefinitionByCode(@Param("logCode") String logCode);

    /**
     * 查询调度日志定义列表
     */
    List<ScheduleLogDefinition> selectScheduleLogDefinitionList(Map<String, Object> params);

    /**
     * 查询调度日志定义总数
     */
    int selectScheduleLogDefinitionCount(Map<String, Object> params);

    /**
     * 更新调度日志定义状态
     */
    void updateScheduleLogDefinitionStatus(@Param("id") Long id, @Param("isEnabled") Integer isEnabled);

    // ========== 计算日志定义 ==========

    /**
     * 新增计算日志定义
     */
    void insertComputeLogDefinition(ComputeLogDefinition definition);

    /**
     * 更新计算日志定义
     */
    void updateComputeLogDefinition(ComputeLogDefinition definition);

    /**
     * 删除计算日志定义
     */
    void deleteComputeLogDefinition(@Param("id") Long id);

    /**
     * 根据ID查询计算日志定义
     */
    ComputeLogDefinition selectComputeLogDefinitionById(@Param("id") Long id);

    /**
     * 根据日志代码查询计算日志定义
     */
    ComputeLogDefinition selectComputeLogDefinitionByCode(@Param("logCode") String logCode);

    /**
     * 查询计算日志定义列表
     */
    List<ComputeLogDefinition> selectComputeLogDefinitionList(Map<String, Object> params);

    /**
     * 查询计算日志定义总数
     */
    int selectComputeLogDefinitionCount(Map<String, Object> params);

    /**
     * 更新计算日志定义状态
     */
    void updateComputeLogDefinitionStatus(@Param("id") Long id, @Param("isEnabled") Integer isEnabled);

    // ========== 操作日志记录 ==========

    /**
     * 新增操作日志记录
     */
    void insertOperationLog(OperationLog log);

    /**
     * 根据ID查询操作日志记录
     */
    OperationLog selectOperationLogById(@Param("id") Long id);

    /**
     * 查询操作日志记录列表
     */
    List<OperationLog> selectOperationLogList(Map<String, Object> params);

    /**
     * 查询操作日志记录总数
     */
    int selectOperationLogCount(Map<String, Object> params);

    /**
     * 批量删除过期操作日志
     */
    int deleteExpiredOperationLogs(@Param("beforeDate") String beforeDate);

    // ========== 调度日志记录 ==========

    /**
     * 新增调度日志记录
     */
    void insertScheduleLog(ScheduleLog log);

    /**
     * 更新调度日志记录
     */
    void updateScheduleLog(ScheduleLog log);

    /**
     * 根据ID查询调度日志记录
     */
    ScheduleLog selectScheduleLogById(@Param("id") Long id);

    /**
     * 查询调度日志记录列表
     */
    List<ScheduleLog> selectScheduleLogList(Map<String, Object> params);

    /**
     * 查询调度日志记录总数
     */
    int selectScheduleLogCount(Map<String, Object> params);

    /**
     * 批量删除过期调度日志
     */
    int deleteExpiredScheduleLogs(@Param("beforeDate") String beforeDate);

    // ========== 计算日志记录 ==========

    /**
     * 新增计算日志记录
     */
    void insertComputeLog(ComputeLog log);

    /**
     * 更新计算日志记录
     */
    void updateComputeLog(ComputeLog log);

    /**
     * 根据ID查询计算日志记录
     */
    ComputeLog selectComputeLogById(@Param("id") Long id);

    /**
     * 根据任务ID查询计算日志记录
     */
    ComputeLog selectComputeLogByTaskId(@Param("taskId") String taskId);

    /**
     * 查询计算日志记录列表
     */
    List<ComputeLog> selectComputeLogList(Map<String, Object> params);

    /**
     * 查询计算日志记录总数
     */
    int selectComputeLogCount(Map<String, Object> params);

    /**
     * 批量删除过期计算日志
     */
    int deleteExpiredComputeLogs(@Param("beforeDate") String beforeDate);
}
