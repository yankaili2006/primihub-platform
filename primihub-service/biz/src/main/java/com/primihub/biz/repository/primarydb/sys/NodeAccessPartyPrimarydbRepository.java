package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.NodeAccessParty;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 接入方管理Repository接口
 */
public interface NodeAccessPartyPrimarydbRepository {

    /**
     * 插入接入方记录
     */
    int insertNodeAccessParty(NodeAccessParty nodeAccessParty);

    /**
     * 更新接入方记录
     */
    int updateNodeAccessParty(NodeAccessParty nodeAccessParty);

    /**
     * 删除接入方记录(软删除)
     */
    int deleteNodeAccessParty(@Param("id") Long id);

    /**
     * 根据ID查询接入方
     */
    NodeAccessParty selectNodeAccessPartyById(@Param("id") Long id);

    /**
     * 根据节点ID查询接入方
     */
    NodeAccessParty selectNodeAccessPartyByOrganId(@Param("organId") String organId);

    /**
     * 查询接入方列表
     */
    List<NodeAccessParty> selectNodeAccessPartyList(Map<String, Object> params);

    /**
     * 查询接入方总数
     */
    int selectNodeAccessPartyCount(Map<String, Object> params);

    /**
     * 批量删除接入方
     */
    int batchDeleteNodeAccessParty(@Param("ids") List<Long> ids);

    /**
     * 更新申请状态
     */
    int updateApplyStatus(@Param("id") Long id, @Param("applyStatus") Integer applyStatus,
                          @Param("approveUserId") Long approveUserId, @Param("approveUserName") String approveUserName,
                          @Param("approveComment") String approveComment);

    /**
     * 更新激活状态
     */
    int updateActiveStatus(@Param("id") Long id, @Param("isActive") Integer isActive);

    /**
     * 更新接入级别
     */
    int updateAccessLevel(@Param("id") Long id, @Param("accessLevel") Integer accessLevel);

    /**
     * 查询待审批的接入申请
     */
    List<NodeAccessParty> selectPendingAccessParties();

    /**
     * 查询已批准的接入方
     */
    List<NodeAccessParty> selectApprovedAccessParties();

    /**
     * 批量审批
     */
    int batchApprove(@Param("ids") List<Long> ids, @Param("approveUserId") Long approveUserId,
                     @Param("approveUserName") String approveUserName, @Param("approveComment") String approveComment);
}
