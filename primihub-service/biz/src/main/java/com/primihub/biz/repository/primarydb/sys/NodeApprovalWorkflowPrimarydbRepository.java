package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.NodeApprovalWorkflow;
import com.primihub.biz.entity.sys.po.NodeApprovalStep;
import com.primihub.biz.entity.sys.po.NodeApprovalConfig;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 审批工作流Repository接口
 */
public interface NodeApprovalWorkflowPrimarydbRepository {

    // ========== 工作流 CRUD ==========

    /**
     * 插入工作流
     */
    int insertNodeApprovalWorkflow(NodeApprovalWorkflow workflow);

    /**
     * 更新工作流
     */
    int updateNodeApprovalWorkflow(NodeApprovalWorkflow workflow);

    /**
     * 删除工作流(软删除)
     */
    int deleteNodeApprovalWorkflow(@Param("id") Long id);

    /**
     * 根据ID查询工作流
     */
    NodeApprovalWorkflow selectNodeApprovalWorkflowById(@Param("id") Long id);

    /**
     * 查询工作流列表
     */
    List<NodeApprovalWorkflow> selectNodeApprovalWorkflowList(Map<String, Object> params);

    /**
     * 查询工作流总数
     */
    int selectNodeApprovalWorkflowCount(Map<String, Object> params);

    /**
     * 更新工作流状态
     */
    int updateWorkflowStatus(@Param("id") Long id, @Param("status") Integer status,
                             @Param("finalApproverId") Long finalApproverId,
                             @Param("finalApproverName") String finalApproverName,
                             @Param("finalComment") String finalComment);

    /**
     * 更新当前步骤
     */
    int updateCurrentStep(@Param("id") Long id, @Param("currentStep") Integer currentStep);

    /**
     * 查询待审批的工作流
     */
    List<NodeApprovalWorkflow> selectPendingWorkflows();

    /**
     * 查询我的待审批工作流
     */
    List<NodeApprovalWorkflow> selectMyPendingWorkflows(@Param("userId") Long userId);

    /**
     * 查询用户创建的工作流
     */
    List<NodeApprovalWorkflow> selectWorkflowsByRequester(@Param("requesterId") Long requesterId);

    /**
     * 取消工作流
     */
    int cancelWorkflow(@Param("id") Long id, @Param("reason") String reason);

    // ========== 审批步骤 CRUD ==========

    /**
     * 插入审批步骤
     */
    int insertNodeApprovalStep(NodeApprovalStep step);

    /**
     * 批量插入审批步骤
     */
    int batchInsertNodeApprovalSteps(@Param("stepList") List<NodeApprovalStep> stepList);

    /**
     * 更新审批步骤
     */
    int updateNodeApprovalStep(NodeApprovalStep step);

    /**
     * 删除审批步骤(软删除)
     */
    int deleteNodeApprovalStep(@Param("id") Long id);

    /**
     * 根据ID查询审批步骤
     */
    NodeApprovalStep selectNodeApprovalStepById(@Param("id") Long id);

    /**
     * 根据工作流ID查询所有步骤
     */
    List<NodeApprovalStep> selectStepsByWorkflowId(@Param("workflowId") Long workflowId);

    /**
     * 根据工作流ID和步骤号查询步骤
     */
    NodeApprovalStep selectStepByWorkflowIdAndStepNumber(@Param("workflowId") Long workflowId,
                                                          @Param("stepNumber") Integer stepNumber);

    /**
     * 更新步骤状态
     */
    int updateStepStatus(@Param("id") Long id, @Param("status") Integer status,
                         @Param("comment") String comment);

    /**
     * 删除工作流的所有步骤
     */
    int deleteStepsByWorkflowId(@Param("workflowId") Long workflowId);

    // ========== 审批配置 CRUD ==========

    /**
     * 插入审批配置
     */
    int insertNodeApprovalConfig(NodeApprovalConfig config);

    /**
     * 更新审批配置
     */
    int updateNodeApprovalConfig(NodeApprovalConfig config);

    /**
     * 删除审批配置(软删除)
     */
    int deleteNodeApprovalConfig(@Param("id") Long id);

    /**
     * 根据ID查询审批配置
     */
    NodeApprovalConfig selectNodeApprovalConfigById(@Param("id") Long id);

    /**
     * 根据工作流类型查询配置
     */
    NodeApprovalConfig selectNodeApprovalConfigByType(@Param("workflowType") String workflowType);

    /**
     * 查询所有审批配置
     */
    List<NodeApprovalConfig> selectAllNodeApprovalConfigs();

    /**
     * 更新配置启用状态
     */
    int updateConfigEnabled(@Param("id") Long id, @Param("isEnabled") Integer isEnabled);

    /**
     * 查询所有启用的配置
     */
    List<NodeApprovalConfig> selectEnabledConfigs();
}
