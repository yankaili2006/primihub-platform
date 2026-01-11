package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.NodeDataExchangeLog;
import com.primihub.biz.repository.primarydb.sys.NodeDataExchangeLogPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 节点数据交换Service
 */
@Slf4j
@Service
public class NodeDataExchangeService {

    @Autowired
    private NodeDataExchangeLogPrimarydbRepository dataExchangeLogRepository;

    @Autowired
    private NodeCooperationService cooperationService;

    // ========== 数据交换日志 CRUD ==========

    /**
     * 查询数据交换日志分页列表
     */
    public BaseResultEntity findDataExchangeLogPage(String keyword, String sourceOrganId, String targetOrganId,
                                                    String exchangeType, String dataType, Integer status,
                                                    String startDate, String endDate,
                                                    Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("sourceOrganId", sourceOrganId);
            params.put("targetOrganId", targetOrganId);
            params.put("exchangeType", exchangeType);
            params.put("dataType", dataType);
            params.put("status", status);
            params.put("startDate", startDate);
            params.put("endDate", endDate);

            int total = dataExchangeLogRepository.selectNodeDataExchangeLogCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectNodeDataExchangeLogList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询数据交换日志列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据ID查询数据交换日志
     */
    public BaseResultEntity getDataExchangeLogById(Long id) {
        try {
            NodeDataExchangeLog exchangeLog = dataExchangeLogRepository.selectNodeDataExchangeLogById(id);
            if (exchangeLog == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据交换日志不存在");
            }
            return BaseResultEntity.success(exchangeLog);
        } catch (Exception e) {
            log.error("查询数据交换日志失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据交换ID查询日志
     */
    public BaseResultEntity getDataExchangeLogByExchangeId(String exchangeId) {
        try {
            NodeDataExchangeLog exchangeLog = dataExchangeLogRepository.selectNodeDataExchangeLogByExchangeId(exchangeId);
            if (exchangeLog == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据交换日志不存在");
            }
            return BaseResultEntity.success(exchangeLog);
        } catch (Exception e) {
            log.error("查询数据交换日志失败，exchangeId={}", exchangeId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加数据交换日志
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addDataExchangeLog(NodeDataExchangeLog exchangeLog) {
        try {
            // 参数校验
            if (exchangeLog.getExchangeId() == null || exchangeLog.getExchangeId().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "交换ID不能为空");
            }
            if (exchangeLog.getSourceOrganId() == null || exchangeLog.getSourceOrganId().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "源节点ID不能为空");
            }
            if (exchangeLog.getTargetOrganId() == null || exchangeLog.getTargetOrganId().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "目标节点ID不能为空");
            }

            // 设置默认值
            if (exchangeLog.getStatus() == null) {
                exchangeLog.setStatus(0); // 默认待处理
            }
            if (exchangeLog.getRetryCount() == null) {
                exchangeLog.setRetryCount(0);
            }
            if (exchangeLog.getStartedAt() == null) {
                exchangeLog.setStartedAt(new Date());
            }

            dataExchangeLogRepository.insertNodeDataExchangeLog(exchangeLog);

            log.info("添加数据交换日志，exchangeId={}, source={}, target={}",
                     exchangeLog.getExchangeId(), exchangeLog.getSourceOrganId(), exchangeLog.getTargetOrganId());
            return BaseResultEntity.success(exchangeLog);
        } catch (Exception e) {
            log.error("添加数据交换日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新数据交换日志
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateDataExchangeLog(NodeDataExchangeLog exchangeLog) {
        try {
            if (exchangeLog.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            NodeDataExchangeLog existing = dataExchangeLogRepository.selectNodeDataExchangeLogById(exchangeLog.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据交换日志不存在");
            }

            dataExchangeLogRepository.updateNodeDataExchangeLog(exchangeLog);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新数据交换日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除数据交换日志
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteDataExchangeLog(Long id) {
        try {
            NodeDataExchangeLog existing = dataExchangeLogRepository.selectNodeDataExchangeLogById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据交换日志不存在");
            }

            dataExchangeLogRepository.deleteNodeDataExchangeLog(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除数据交换日志失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 批量删除数据交换日志
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteDataExchangeLog(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }

            dataExchangeLogRepository.batchDeleteNodeDataExchangeLog(ids);
            return BaseResultEntity.success("批量删除成功");
        } catch (Exception e) {
            log.error("批量删除数据交换日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量删除失败");
        }
    }

    // ========== 交换状态管理 ==========

    /**
     * 更新交换状态
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateExchangeStatus(Long id, Integer status, String errorMsg) {
        try {
            NodeDataExchangeLog exchangeLog = dataExchangeLogRepository.selectNodeDataExchangeLogById(id);
            if (exchangeLog == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据交换日志不存在");
            }

            dataExchangeLogRepository.updateExchangeStatus(id, status, errorMsg);

            log.info("更新交换状态，id={}, exchangeId={}, status={}", id, exchangeLog.getExchangeId(), status);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新交换状态失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 更新重试次数
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateRetryCount(Long id, Integer retryCount) {
        try {
            dataExchangeLogRepository.updateRetryCount(id, retryCount);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新重试次数失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 完成交换
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity completeExchange(Long id, Integer status, Date completedAt, Long durationMs) {
        try {
            NodeDataExchangeLog exchangeLog = dataExchangeLogRepository.selectNodeDataExchangeLogById(id);
            if (exchangeLog == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据交换日志不存在");
            }

            dataExchangeLogRepository.completeExchange(id, status, completedAt, durationMs);

            log.info("完成数据交换，id={}, exchangeId={}, status={}, duration={}ms",
                     id, exchangeLog.getExchangeId(), status, durationMs);
            return BaseResultEntity.success("完成成功");
        } catch (Exception e) {
            log.error("完成数据交换失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "完成失败");
        }
    }

    // ========== 查询相关 ==========

    /**
     * 查询源节点的交换日志
     */
    public BaseResultEntity getExchangeLogsBySourceOrgan(String sourceOrganId) {
        try {
            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectExchangeLogsBySourceOrgan(sourceOrganId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询源节点交换日志失败，sourceOrganId={}", sourceOrganId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询目标节点的交换日志
     */
    public BaseResultEntity getExchangeLogsByTargetOrgan(String targetOrganId) {
        try {
            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectExchangeLogsByTargetOrgan(targetOrganId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询目标节点交换日志失败，targetOrganId={}", targetOrganId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询失败的交换日志
     */
    public BaseResultEntity getFailedExchangeLogs() {
        try {
            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectFailedExchangeLogs();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询失败交换日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询待处理的交换日志
     */
    public BaseResultEntity getPendingExchangeLogs() {
        try {
            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectPendingExchangeLogs();
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询待处理交换日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询交换统计信息
     */
    public BaseResultEntity getExchangeStatistics(String organId) {
        try {
            Map<String, Object> statistics = dataExchangeLogRepository.selectExchangeStatistics(organId);
            return BaseResultEntity.success(statistics);
        } catch (Exception e) {
            log.error("查询交换统计失败，organId={}", organId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询节点间的交换记录
     */
    public BaseResultEntity getExchangeLogsBetweenOrgans(String sourceOrganId, String targetOrganId) {
        try {
            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectExchangeLogsBetweenOrgans(
                sourceOrganId, targetOrganId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询节点间交换记录失败，source={}, target={}", sourceOrganId, targetOrganId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询最近N天的交换日志
     */
    public BaseResultEntity getRecentExchangeLogs(Integer days) {
        try {
            if (days == null || days <= 0) {
                days = 7; // 默认7天
            }

            List<NodeDataExchangeLog> list = dataExchangeLogRepository.selectRecentExchangeLogs(days);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询最近交换日志失败，days={}", days, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 触发数据同步
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity triggerDataSync(String sourceOrganId, String targetOrganId,
                                            String exchangeType, String dataType, String dataId, String dataName) {
        try {
            // 生成交换ID
            String exchangeId = UUID.randomUUID().toString();

            // 创建交换日志
            NodeDataExchangeLog exchangeLog = new NodeDataExchangeLog();
            exchangeLog.setExchangeId(exchangeId);
            exchangeLog.setSourceOrganId(sourceOrganId);
            exchangeLog.setTargetOrganId(targetOrganId);
            exchangeLog.setExchangeType(exchangeType);
            exchangeLog.setDataType(dataType);
            exchangeLog.setDataId(dataId);
            exchangeLog.setDataName(dataName);
            exchangeLog.setStatus(0); // 待处理
            exchangeLog.setRetryCount(0);
            exchangeLog.setStartedAt(new Date());

            dataExchangeLogRepository.insertNodeDataExchangeLog(exchangeLog);

            log.info("触发数据同步，exchangeId={}, source={}, target={}, type={}",
                     exchangeId, sourceOrganId, targetOrganId, exchangeType);

            Map<String, Object> result = new HashMap<>();
            result.put("exchangeId", exchangeId);
            result.put("exchangeLog", exchangeLog);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("触发数据同步失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "触发同步失败");
        }
    }
}
