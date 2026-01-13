package com.primihub.biz.service.sys;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.NodeApprovalWorkflow;
import com.primihub.biz.entity.sys.po.NodeApprovalStep;
import com.primihub.biz.entity.sys.po.NodeApprovalConfig;
import com.primihub.biz.repository.primarydb.sys.NodeApprovalWorkflowPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 审批工作流Service
 */
@Slf4j
@Service
public class NodeApprovalWorkflowService {

    @Autowired
    private NodeApprovalWorkflowPrimarydbRepository approvalWorkflowRepository;

    // ========== 工作流 CRUD ==========

    /**
     * 查询工作流分页列表
     */
    public BaseResultEntity findWorkflowPage(String keyword, String workflowType,
                                             Integer status, Long requesterId,
                                             Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("workflowType", workflowType);
            params.put("status", status);
            params.put("requesterId", requesterId);

            int total = approvalWorkflowRepository.selectNodeApprovalWorkflowCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<NodeApprovalWorkflow> list = approvalWorkflowRepository.selectNodeApprovalWorkflowList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询工作流列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据ID查询工作流(包含所有步骤)
     */
    public BaseResultEntity getWorkflowById(Long id) {
        try {
            NodeApprovalWorkflow workflow = approvalWorkflowRepository.selectNodeApprovalWorkflowById(id);
            if (workflow == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "工作流不存在");
            }

            // 查询所有步骤
            List<NodeApprovalStep> steps = approvalWorkflowRepository.selectStepsByWorkflowId(id);

            Map<String, Object> result = new HashMap<>();
            result.put("workflow", workflow);
            result.put("steps", steps);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询工作流失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 创建审批工作流
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createWorkflow(NodeApprovalWorkflow workflow, List<NodeApprovalStep> steps) {
        try {
            // 参数校验
            if (workflow.getWorkflowType() == null || workflow.getWorkflowType().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "工作流类型不能为空");
            }
            if (workflow.getWorkflowTitle() == null || workflow.getWorkflowTitle().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "工作流标题不能为空");
            }

            // 查询该类型的工作流配置
            NodeApprovalConfig config = approvalWorkflowRepository.selectNodeApprovalConfigByType(workflow.getWorkflowType());
            if (config != null && config.getIsEnabled() != null && config.getIsEnabled() == 0) {
                // 如果审批未启用，直接返回成功（不需要审批）
                log.info("工作流类型{}未启用审批，跳过", workflow.getWorkflowType());
                return BaseResultEntity.success("无需审批");
            }

            // 设置默认值
            if (workflow.getTotalSteps() == null) {
                workflow.setTotalSteps(steps != null ? steps.size() : 1);
            }
            if (workflow.getCurrentStep() == null) {
                workflow.setCurrentStep(1);
            }
            if (workflow.getStatus() == null) {
                workflow.setStatus(0); // 默认待审批
            }

            // 插入工作流
            approvalWorkflowRepository.insertNodeApprovalWorkflow(workflow);

            // 插入审批步骤
            if (steps != null && !steps.isEmpty()) {
                for (NodeApprovalStep step : steps) {
                    step.setWorkflowId(workflow.getId());
                }
                approvalWorkflowRepository.batchInsertNodeApprovalSteps(steps);
            }

            log.info("创建审批工作流，type={}, title={}, requester={}",
                     workflow.getWorkflowType(), workflow.getWorkflowTitle(), workflow.getRequesterName());
            return BaseResultEntity.success(workflow);
        } catch (Exception e) {
            log.error("创建审批工作流失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    /**
     * 审批通过
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity approveWorkflow(Long workflowId, Long approverId, String approverName, String comment) {
        try {
            NodeApprovalWorkflow workflow = approvalWorkflowRepository.selectNodeApprovalWorkflowById(workflowId);
            if (workflow == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "工作流不存在");
            }

            if (workflow.getStatus() != 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "工作流已完成，无法审批");
            }

            // 查询当前步骤
            NodeApprovalStep currentStep = approvalWorkflowRepository.selectStepByWorkflowIdAndStepNumber(
                workflowId, workflow.getCurrentStep());

            if (currentStep == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "当前审批步骤不存在");
            }

            // 更新当前步骤状态
            approvalWorkflowRepository.updateStepStatus(currentStep.getId(), 1, comment);

            // 判断是否还有下一步
            if (workflow.getCurrentStep() < workflow.getTotalSteps()) {
                // 进入下一步
                approvalWorkflowRepository.updateCurrentStep(workflowId, workflow.getCurrentStep() + 1);
                log.info("审批通过，进入下一步，workflowId={}, nextStep={}", workflowId, workflow.getCurrentStep() + 1);
                return BaseResultEntity.success("审批通过，已进入下一步");
            } else {
                // 所有步骤完成，工作流审批通过
                approvalWorkflowRepository.updateWorkflowStatus(workflowId, 1, approverId, approverName, comment);
                log.info("审批工作流全部通过，workflowId={}, type={}", workflowId, workflow.getWorkflowType());
                return BaseResultEntity.success("审批全部通过");
            }
        } catch (Exception e) {
            log.error("审批失败，workflowId={}", workflowId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "审批失败");
        }
    }

    /**
     * 审批拒绝
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity rejectWorkflow(Long workflowId, Long approverId, String approverName, String comment) {
        try {
            NodeApprovalWorkflow workflow = approvalWorkflowRepository.selectNodeApprovalWorkflowById(workflowId);
            if (workflow == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "工作流不存在");
            }

            if (workflow.getStatus() != 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "工作流已完成，无法审批");
            }

            // 查询当前步骤
            NodeApprovalStep currentStep = approvalWorkflowRepository.selectStepByWorkflowIdAndStepNumber(
                workflowId, workflow.getCurrentStep());

            if (currentStep != null) {
                // 更新当前步骤状态为拒绝
                approvalWorkflowRepository.updateStepStatus(currentStep.getId(), 2, comment);
            }

            // 更新工作流状态为拒绝
            approvalWorkflowRepository.updateWorkflowStatus(workflowId, 2, approverId, approverName, comment);

            log.info("审批拒绝，workflowId={}, type={}, approver={}", workflowId, workflow.getWorkflowType(), approverName);
            return BaseResultEntity.success("已拒绝");
        } catch (Exception e) {
            log.error("审批拒绝失败，workflowId={}", workflowId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "拒绝失败");
        }
    }

    /**
     * 取消工作流
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity cancelWorkflow(Long workflowId, String reason) {
        try {
            NodeApprovalWorkflow workflow = approvalWorkflowRepository.selectNodeApprovalWorkflowById(workflowId);
            if (workflow == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "工作流不存在");
            }

            if (workflow.getStatus() != 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "工作流已完成，无法取消");
            }

            approvalWorkflowRepository.cancelWorkflow(workflowId, reason);

            log.info("取消工作流，workflowId={}, type={}, reason={}", workflowId, workflow.getWorkflowType(), reason);
            return BaseResultEntity.success("已取消");
        } catch (Exception e) {
            log.error("取消工作流失败，workflowId={}", workflowId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    /**
     * 查询待审批的工作流
     */
    public BaseResultEntity getPendingWorkflows() {
        try {
            List<NodeApprovalWorkflow> list = approvalWorkflowRepository.selectPendingWorkflows();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询待审批工作流失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询我的待审批工作流
     */
    public BaseResultEntity getMyPendingWorkflows(Long userId) {
        try {
            if (userId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "用户ID不能为空");
            }

            List<NodeApprovalWorkflow> list = approvalWorkflowRepository.selectMyPendingWorkflows(userId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询我的待审批工作流失败，userId={}", userId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询用户创建的工作流
     */
    public BaseResultEntity getWorkflowsByRequester(Long requesterId) {
        try {
            if (requesterId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "申请人ID不能为空");
            }

            List<NodeApprovalWorkflow> list = approvalWorkflowRepository.selectWorkflowsByRequester(requesterId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询用户创建的工作流失败，requesterId={}", requesterId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== 审批配置 CRUD ==========

    /**
     * 查询所有审批配置
     */
    public BaseResultEntity getAllConfigs() {
        try {
            List<NodeApprovalConfig> list = approvalWorkflowRepository.selectAllNodeApprovalConfigs();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询审批配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据类型查询审批配置
     */
    public BaseResultEntity getConfigByType(String workflowType) {
        try {
            NodeApprovalConfig config = approvalWorkflowRepository.selectNodeApprovalConfigByType(workflowType);
            return BaseResultEntity.success(config);
        } catch (Exception e) {
            log.error("查询审批配置失败，type={}", workflowType, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 更新审批配置
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateConfig(NodeApprovalConfig config) {
        try {
            if (config.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            NodeApprovalConfig existing = approvalWorkflowRepository.selectNodeApprovalConfigById(config.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
            }

            approvalWorkflowRepository.updateNodeApprovalConfig(config);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新审批配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 启用/禁用审批配置
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateConfigEnabled(Long id, Integer isEnabled) {
        try {
            NodeApprovalConfig config = approvalWorkflowRepository.selectNodeApprovalConfigById(id);
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
            }

            approvalWorkflowRepository.updateConfigEnabled(id, isEnabled);

            String action = isEnabled == 1 ? "启用" : "禁用";
            log.info("{}审批配置，id={}, type={}", action, id, config.getWorkflowType());
            return BaseResultEntity.success(action + "成功");
        } catch (Exception e) {
            log.error("更新审批配置启用状态失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }
}
