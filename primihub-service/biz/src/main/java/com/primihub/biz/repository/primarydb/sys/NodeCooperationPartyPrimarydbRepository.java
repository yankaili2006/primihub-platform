package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.NodeCooperationParty;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 合作方管理Repository接口
 */
public interface NodeCooperationPartyPrimarydbRepository {

    /**
     * 插入合作方记录
     */
    int insertNodeCooperationParty(NodeCooperationParty nodeCooperationParty);

    /**
     * 更新合作方记录
     */
    int updateNodeCooperationParty(NodeCooperationParty nodeCooperationParty);

    /**
     * 删除合作方记录(软删除)
     */
    int deleteNodeCooperationParty(@Param("id") Long id);

    /**
     * 根据ID查询合作方
     */
    NodeCooperationParty selectNodeCooperationPartyById(@Param("id") Long id);

    /**
     * 根据节点ID查询合作方
     */
    NodeCooperationParty selectNodeCooperationPartyByOrganId(@Param("organId") String organId);

    /**
     * 查询合作方列表
     */
    List<NodeCooperationParty> selectNodeCooperationPartyList(Map<String, Object> params);

    /**
     * 查询合作方总数
     */
    int selectNodeCooperationPartyCount(Map<String, Object> params);

    /**
     * 批量删除合作方
     */
    int batchDeleteNodeCooperationParty(@Param("ids") List<Long> ids);

    /**
     * 更新合作状态
     */
    int updateCooperationStatus(@Param("id") Long id, @Param("cooperationStatus") Integer cooperationStatus);

    /**
     * 更新健康评分
     */
    int updateHealthScore(@Param("id") Long id, @Param("healthScore") Integer healthScore);

    /**
     * 更新数据交换统计
     */
    int updateDataExchangeCount(@Param("id") Long id, @Param("dataSentCount") Long dataSentCount,
                                 @Param("dataReceivedCount") Long dataReceivedCount);

    /**
     * 更新最后活动时间
     */
    int updateLastActivityTime(@Param("id") Long id);

    /**
     * 查询进行中的合作方
     */
    List<NodeCooperationParty> selectActiveCooperationParties();

    /**
     * 查询即将过期的合作方
     */
    List<NodeCooperationParty> selectExpiringCooperationParties(@Param("days") Integer days);

    /**
     * 查询健康评分低于阈值的合作方
     */
    List<NodeCooperationParty> selectUnhealthyCooperationParties(@Param("threshold") Integer threshold);

    /**
     * 终止合作
     */
    int terminateCooperation(@Param("id") Long id, @Param("reason") String reason);

    /**
     * 续约合作
     */
    int renewCooperation(@Param("id") Long id, @Param("newEndDate") java.util.Date newEndDate);
}
