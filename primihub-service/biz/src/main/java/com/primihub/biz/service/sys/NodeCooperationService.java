package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.NodeCooperationParty;
import com.primihub.biz.repository.primarydb.sys.NodeCooperationPartyPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 合作方管理Service
 * 管理我方主动合作的节点(outbound)
 */
@Slf4j
@Service
public class NodeCooperationService {

    @Autowired
    private NodeCooperationPartyPrimarydbRepository nodeCooperationPartyRepository;

    @Autowired
    private NodeApprovalWorkflowService approvalWorkflowService;

    // ========== 合作方 CRUD ==========

    /**
     * 查询合作方分页列表
     */
    public BaseResultEntity findCooperationPartyPage(String keyword, String cooperationType,
                                                     Integer cooperationStatus, Integer initiatedByUs,
                                                     Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("cooperationType", cooperationType);
            params.put("cooperationStatus", cooperationStatus);
            params.put("initiatedByUs", initiatedByUs);

            int total = nodeCooperationPartyRepository.selectNodeCooperationPartyCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<NodeCooperationParty> list = nodeCooperationPartyRepository.selectNodeCooperationPartyList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询合作方列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据ID查询合作方
     */
    public BaseResultEntity getCooperationPartyById(Long id) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }
            return BaseResultEntity.success(cooperationParty);
        } catch (Exception e) {
            log.error("查询合作方失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 建立合作关系
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity establishCooperation(NodeCooperationParty cooperationParty) {
        try {
            // 参数校验
            if (cooperationParty.getOrganId() == null || cooperationParty.getOrganId().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "节点ID不能为空");
            }
            if (cooperationParty.getOrganName() == null || cooperationParty.getOrganName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "节点名称不能为空");
            }

            // 检查是否已建立合作
            NodeCooperationParty existing = nodeCooperationPartyRepository.selectNodeCooperationPartyByOrganId(cooperationParty.getOrganId());
            if (existing != null && existing.getCooperationStatus() == 1) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "已与该节点建立合作关系");
            }

            // 设置默认值
            if (cooperationParty.getCooperationStatus() == null) {
                cooperationParty.setCooperationStatus(0); // 默认待确认
            }
            if (cooperationParty.getInitiatedByUs() == null) {
                cooperationParty.setInitiatedByUs(1); // 我方发起
            }
            if (cooperationParty.getHealthScore() == null) {
                cooperationParty.setHealthScore(100); // 默认满分
            }

            nodeCooperationPartyRepository.insertNodeCooperationParty(cooperationParty);

            log.info("建立合作关系，organId={}, organName={}, createdBy={}",
                     cooperationParty.getOrganId(), cooperationParty.getOrganName(), cooperationParty.getCreatedByName());
            return BaseResultEntity.success(cooperationParty);
        } catch (Exception e) {
            log.error("建立合作关系失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "建立合作失败");
        }
    }

    /**
     * 更新合作方信息
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateCooperationParty(NodeCooperationParty cooperationParty) {
        try {
            if (cooperationParty.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            NodeCooperationParty existing = nodeCooperationPartyRepository.selectNodeCooperationPartyById(cooperationParty.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            nodeCooperationPartyRepository.updateNodeCooperationParty(cooperationParty);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新合作方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 取消合作关系
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity cancelCooperation(Long id, String reason) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            // 软删除
            nodeCooperationPartyRepository.deleteNodeCooperationParty(id);

            log.info("取消合作关系，id={}, organId={}, reason={}", id, cooperationParty.getOrganId(), reason);
            return BaseResultEntity.success("取消合作成功");
        } catch (Exception e) {
            log.error("取消合作关系失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消合作失败");
        }
    }

    /**
     * 终止合作
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity terminateCooperation(Long id, String reason) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            nodeCooperationPartyRepository.terminateCooperation(id, reason);

            log.info("终止合作，id={}, organId={}, reason={}", id, cooperationParty.getOrganId(), reason);
            return BaseResultEntity.success("终止成功");
        } catch (Exception e) {
            log.error("终止合作失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "终止失败");
        }
    }

    /**
     * 续约合作
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity renewCooperation(Long id, Date newEndDate) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            if (newEndDate == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "新的结束日期不能为空");
            }

            nodeCooperationPartyRepository.renewCooperation(id, newEndDate);

            log.info("续约合作，id={}, organId={}, newEndDate={}", id, cooperationParty.getOrganId(), newEndDate);
            return BaseResultEntity.success("续约成功");
        } catch (Exception e) {
            log.error("续约合作失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "续约失败");
        }
    }

    // ========== 合作状态管理 ==========

    /**
     * 更新合作状态
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateCooperationStatus(Long id, Integer cooperationStatus) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            nodeCooperationPartyRepository.updateCooperationStatus(id, cooperationStatus);

            log.info("更新合作状态，id={}, organId={}, status={}", id, cooperationParty.getOrganId(), cooperationStatus);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新合作状态失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 更新健康评分
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateHealthScore(Long id, Integer healthScore) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            if (healthScore < 0 || healthScore > 100) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "健康评分范围0-100");
            }

            nodeCooperationPartyRepository.updateHealthScore(id, healthScore);

            log.info("更新健康评分，id={}, organId={}, healthScore={}", id, cooperationParty.getOrganId(), healthScore);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新健康评分失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 更新数据交换统计
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateDataExchangeCount(Long id, Long dataSentCount, Long dataReceivedCount) {
        try {
            NodeCooperationParty cooperationParty = nodeCooperationPartyRepository.selectNodeCooperationPartyById(id);
            if (cooperationParty == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "合作方不存在");
            }

            nodeCooperationPartyRepository.updateDataExchangeCount(id, dataSentCount, dataReceivedCount);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新数据交换统计失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 更新最后活动时间
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateLastActivityTime(Long id) {
        try {
            nodeCooperationPartyRepository.updateLastActivityTime(id);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新最后活动时间失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    // ========== 查询相关 ==========

    /**
     * 查询进行中的合作方
     */
    public BaseResultEntity getActiveCooperationParties() {
        try {
            List<NodeCooperationParty> list = nodeCooperationPartyRepository.selectActiveCooperationParties();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询进行中的合作方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询即将过期的合作方
     */
    public BaseResultEntity getExpiringCooperationParties(Integer days) {
        try {
            if (days == null || days <= 0) {
                days = 30; // 默认30天
            }

            List<NodeCooperationParty> list = nodeCooperationPartyRepository.selectExpiringCooperationParties(days);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询即将过期的合作方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询健康评分低的合作方
     */
    public BaseResultEntity getUnhealthyCooperationParties(Integer threshold) {
        try {
            if (threshold == null || threshold < 0 || threshold > 100) {
                threshold = 60; // 默认阈值60分
            }

            List<NodeCooperationParty> list = nodeCooperationPartyRepository.selectUnhealthyCooperationParties(threshold);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询健康评分低的合作方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 批量删除合作方
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteCooperationParty(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }

            nodeCooperationPartyRepository.batchDeleteNodeCooperationParty(ids);
            return BaseResultEntity.success("批量删除成功");
        } catch (Exception e) {
            log.error("批量删除合作方失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量删除失败");
        }
    }
}
