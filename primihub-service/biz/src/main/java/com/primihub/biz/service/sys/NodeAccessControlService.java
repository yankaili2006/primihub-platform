package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.NodeAccessParty;
import com.primihub.biz.repository.primarydb.sys.NodeAccessPartyPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 接入方管理Service
 * 管理申请接入我方的节点(inbound)
 */
@Slf4j
@Service
public class NodeAccessControlService {

    @Autowired
    private NodeAccessPartyPrimarydbRepository nodeAccessPartyRepository;

    @Autowired
    private NodeApprovalWorkflowService approvalWorkflowService;

    // ========== 接入方 CRUD ==========

    /**
     * 查询接入方分页列表
     */
    public BaseResultEntity findAccessPartyPage(String keyword, Integer applyStatus,
                                                Integer accessLevel, Integer isActive,
                                                Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("applyStatus", applyStatus);
            params.put("accessLevel", accessLevel);
            params.put("isActive", isActive);

            int total = nodeAccessPartyRepository.selectNodeAccessPartyCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<NodeAccessParty> list = nodeAccessPartyRepository.selectNodeAccessPartyList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询接入方列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据ID查询接入方
     */
    public BaseResultEntity getAccessPartyById(Long id) {
        try {
            NodeAccessParty accessParty = nodeAccessPartyRepository.selectNodeAccessPartyById(id);
            if (accessParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }
            return BaseResultEntity.success(accessParty);
        } catch (Exception e) {
            log.error("查询接入方失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加接入方申请
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addAccessParty(NodeAccessParty accessParty) {
        try {
            // 参数校验
            if (accessParty.getOrganId() == null || accessParty.getOrganId().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "节点ID不能为空");
            }
            if (accessParty.getOrganName() == null || accessParty.getOrganName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "节点名称不能为空");
            }

            // 检查节点是否已申请
            NodeAccessParty existing = nodeAccessPartyRepository.selectNodeAccessPartyByOrganId(accessParty.getOrganId());
            if (existing != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "该节点已提交申请");
            }

            // 设置默认值
            if (accessParty.getAccessLevel() == null) {
                accessParty.setAccessLevel(1); // 默认只读权限
            }
            if (accessParty.getApplyStatus() == null) {
                accessParty.setApplyStatus(0); // 默认待审批
            }

            nodeAccessPartyRepository.insertNodeAccessParty(accessParty);
            return BaseResultEntity.success(accessParty);
        } catch (Exception e) {
            log.error("添加接入方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新接入方信息
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateAccessParty(NodeAccessParty accessParty) {
        try {
            if (accessParty.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            NodeAccessParty existing = nodeAccessPartyRepository.selectNodeAccessPartyById(accessParty.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }

            nodeAccessPartyRepository.updateNodeAccessParty(accessParty);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新接入方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除接入方
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteAccessParty(Long id) {
        try {
            NodeAccessParty existing = nodeAccessPartyRepository.selectNodeAccessPartyById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }

            nodeAccessPartyRepository.deleteNodeAccessParty(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除接入方失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 批量删除接入方
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteAccessParty(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }

            nodeAccessPartyRepository.batchDeleteNodeAccessParty(ids);
            return BaseResultEntity.success("批量删除成功");
        } catch (Exception e) {
            log.error("批量删除接入方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量删除失败");
        }
    }

    // ========== 审批相关 ==========

    /**
     * 批准接入申请
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity approveAccessParty(Long id, Long approveUserId, String approveUserName,
                                               String approveComment) {
        try {
            NodeAccessParty accessParty = nodeAccessPartyRepository.selectNodeAccessPartyById(id);
            if (accessParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }

            if (accessParty.getApplyStatus() != 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "申请状态不正确，无法审批");
            }

            // 更新审批状态
            nodeAccessPartyRepository.updateApplyStatus(id, 1, approveUserId, approveUserName, approveComment);

            log.info("批准接入申请成功，id={}, organId={}, approveUser={}", id, accessParty.getOrganId(), approveUserName);
            return BaseResultEntity.success("批准成功");
        } catch (Exception e) {
            log.error("批准接入申请失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批准失败");
        }
    }

    /**
     * 拒绝接入申请
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity rejectAccessParty(Long id, Long approveUserId, String approveUserName,
                                              String approveComment) {
        try {
            NodeAccessParty accessParty = nodeAccessPartyRepository.selectNodeAccessPartyById(id);
            if (accessParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }

            if (accessParty.getApplyStatus() != 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "申请状态不正确，无法审批");
            }

            // 更新审批状态
            nodeAccessPartyRepository.updateApplyStatus(id, 2, approveUserId, approveUserName, approveComment);

            log.info("拒绝接入申请，id={}, organId={}, approveUser={}", id, accessParty.getOrganId(), approveUserName);
            return BaseResultEntity.success("已拒绝");
        } catch (Exception e) {
            log.error("拒绝接入申请失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "拒绝失败");
        }
    }

    /**
     * 批量批准
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchApproveAccessParty(List<Long> ids, Long approveUserId,
                                                    String approveUserName, String approveComment) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }

            nodeAccessPartyRepository.batchApprove(ids, approveUserId, approveUserName, approveComment);

            log.info("批量批准接入申请，count={}, approveUser={}", ids.size(), approveUserName);
            return BaseResultEntity.success("批量批准成功");
        } catch (Exception e) {
            log.error("批量批准失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量批准失败");
        }
    }

    /**
     * 更新接入权限级别
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateAccessLevel(Long id, Integer accessLevel) {
        try {
            NodeAccessParty accessParty = nodeAccessPartyRepository.selectNodeAccessPartyById(id);
            if (accessParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }

            if (accessLevel == null || accessLevel < 1 || accessLevel > 3) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "权限级别无效(1-3)");
            }

            nodeAccessPartyRepository.updateAccessLevel(id, accessLevel);

            log.info("更新接入权限级别，id={}, organId={}, accessLevel={}", id, accessParty.getOrganId(), accessLevel);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新接入权限级别失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 启用/禁用接入方
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateActiveStatus(Long id, Integer isActive) {
        try {
            NodeAccessParty accessParty = nodeAccessPartyRepository.selectNodeAccessPartyById(id);
            if (accessParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接入方不存在");
            }

            nodeAccessPartyRepository.updateActiveStatus(id, isActive);

            String action = isActive == 1 ? "启用" : "禁用";
            log.info("{}接入方，id={}, organId={}", action, id, accessParty.getOrganId());
            return BaseResultEntity.success(action + "成功");
        } catch (Exception e) {
            log.error("更新接入方状态失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 查询待审批的接入申请
     */
    public BaseResultEntity getPendingAccessParties() {
        try {
            List<NodeAccessParty> list = nodeAccessPartyRepository.selectPendingAccessParties();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询待审批接入申请失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询已批准的接入方
     */
    public BaseResultEntity getApprovedAccessParties() {
        try {
            List<NodeAccessParty> list = nodeAccessPartyRepository.selectApprovedAccessParties();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询已批准接入方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }
}
