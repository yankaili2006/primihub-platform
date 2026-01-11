package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.NodeDataExchangeLog;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 节点数据交换日志Repository接口
 */
public interface NodeDataExchangeLogPrimarydbRepository {

    /**
     * 插入数据交换日志
     */
    int insertNodeDataExchangeLog(NodeDataExchangeLog log);

    /**
     * 更新数据交换日志
     */
    int updateNodeDataExchangeLog(NodeDataExchangeLog log);

    /**
     * 删除数据交换日志(软删除)
     */
    int deleteNodeDataExchangeLog(@Param("id") Long id);

    /**
     * 根据ID查询数据交换日志
     */
    NodeDataExchangeLog selectNodeDataExchangeLogById(@Param("id") Long id);

    /**
     * 根据交换ID查询日志
     */
    NodeDataExchangeLog selectNodeDataExchangeLogByExchangeId(@Param("exchangeId") String exchangeId);

    /**
     * 查询数据交换日志列表
     */
    List<NodeDataExchangeLog> selectNodeDataExchangeLogList(Map<String, Object> params);

    /**
     * 查询数据交换日志总数
     */
    int selectNodeDataExchangeLogCount(Map<String, Object> params);

    /**
     * 批量删除数据交换日志
     */
    int batchDeleteNodeDataExchangeLog(@Param("ids") List<Long> ids);

    /**
     * 更新交换状态
     */
    int updateExchangeStatus(@Param("id") Long id, @Param("status") Integer status,
                             @Param("errorMsg") String errorMsg);

    /**
     * 更新重试次数
     */
    int updateRetryCount(@Param("id") Long id, @Param("retryCount") Integer retryCount);

    /**
     * 完成交换(更新完成时间和持续时间)
     */
    int completeExchange(@Param("id") Long id, @Param("status") Integer status,
                         @Param("completedAt") java.util.Date completedAt,
                         @Param("durationMs") Long durationMs);

    /**
     * 查询源节点的交换日志
     */
    List<NodeDataExchangeLog> selectExchangeLogsBySourceOrgan(@Param("sourceOrganId") String sourceOrganId);

    /**
     * 查询目标节点的交换日志
     */
    List<NodeDataExchangeLog> selectExchangeLogsByTargetOrgan(@Param("targetOrganId") String targetOrganId);

    /**
     * 查询失败的交换日志
     */
    List<NodeDataExchangeLog> selectFailedExchangeLogs();

    /**
     * 查询待处理的交换日志
     */
    List<NodeDataExchangeLog> selectPendingExchangeLogs();

    /**
     * 查询交换统计信息
     */
    Map<String, Object> selectExchangeStatistics(@Param("organId") String organId);

    /**
     * 查询节点间的交换记录
     */
    List<NodeDataExchangeLog> selectExchangeLogsBetweenOrgans(@Param("sourceOrganId") String sourceOrganId,
                                                               @Param("targetOrganId") String targetOrganId);

    /**
     * 查询最近N天的交换日志
     */
    List<NodeDataExchangeLog> selectRecentExchangeLogs(@Param("days") Integer days);
}
