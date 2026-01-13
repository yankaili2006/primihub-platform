package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.Whitelist;
import com.primihub.biz.entity.sys.po.WhitelistAccessLog;
import com.primihub.biz.entity.sys.po.WhitelistConfig;
import com.primihub.biz.repository.primarydb.sys.WhitelistPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class WhitelistService {

    @Autowired
    private WhitelistPrimarydbRepository whitelistPrimarydbRepository;

    // ========== 白名单管理 ==========

    /**
     * 查询白名单分页列表
     */
    public BaseResultEntity findWhitelistPage(String keyword, String type, Integer status, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("type", type);
            params.put("status", status);

            int total = whitelistPrimarydbRepository.selectWhitelistCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageNum", pageParam.getPageNum());
            params.put("pageSize", pageParam.getPageSize());

            List<Whitelist> list = whitelistPrimarydbRepository.selectWhitelistList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询白名单列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加白名单
     */
    public BaseResultEntity addWhitelist(Whitelist whitelist) {
        try {
            if (whitelist.getType() == null || whitelist.getValue() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            whitelist.setStatus(whitelist.getStatus() == null ? 1 : whitelist.getStatus());
            whitelistPrimarydbRepository.insertWhitelist(whitelist);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("添加白名单失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新白名单
     */
    public BaseResultEntity updateWhitelist(Whitelist whitelist) {
        try {
            if (whitelist.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            whitelistPrimarydbRepository.updateWhitelist(whitelist);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("更新白名单失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除白名单
     */
    public BaseResultEntity deleteWhitelist(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            whitelistPrimarydbRepository.deleteWhitelist(id);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除白名单失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 查询白名单详情
     */
    public BaseResultEntity getWhitelistDetail(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            Whitelist whitelist = whitelistPrimarydbRepository.selectWhitelistById(id);

            return BaseResultEntity.success(whitelist);
        } catch (Exception e) {
            log.error("查询白名单详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== 白名单配置管理 ==========

    /**
     * 查询白名单配置列表
     */
    public BaseResultEntity findWhitelistConfigList() {
        try {
            List<WhitelistConfig> configList = whitelistPrimarydbRepository.selectWhitelistConfigList();
            List<WhitelistConfig> historyList = whitelistPrimarydbRepository.selectWhitelistConfigHistory();

            Map<String, Object> result = new HashMap<>();
            result.put("configList", configList);
            result.put("historyList", historyList);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询配置列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 保存白名单配置
     */
    public BaseResultEntity saveWhitelistConfig(List<WhitelistConfig> configList) {
        try {
            if (configList == null || configList.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            for (WhitelistConfig config : configList) {
                whitelistPrimarydbRepository.insertOrUpdateWhitelistConfig(config);
            }

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    /**
     * 查询白名单配置详情
     */
    public BaseResultEntity getWhitelistConfigDetail(String configKey) {
        try {
            if (configKey == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            WhitelistConfig config = whitelistPrimarydbRepository.selectWhitelistConfigByKey(configKey);

            return BaseResultEntity.success(config);
        } catch (Exception e) {
            log.error("查询配置详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== 白名单访问日志管理 ==========

    /**
     * 查询访问日志分页列表
     */
    public BaseResultEntity findWhitelistAccessLogPage(String accessIp, String accessUrl, String accessResult,
                                                        String startTime, String endTime, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("accessIp", accessIp);
            params.put("accessUrl", accessUrl);
            params.put("accessResult", accessResult);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            int total = whitelistPrimarydbRepository.selectWhitelistAccessLogCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageNum", pageParam.getPageNum());
            params.put("pageSize", pageParam.getPageSize());

            List<WhitelistAccessLog> list = whitelistPrimarydbRepository.selectWhitelistAccessLogList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询访问日志列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询访问日志详情
     */
    public BaseResultEntity getWhitelistAccessLogDetail(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            WhitelistAccessLog log = whitelistPrimarydbRepository.selectWhitelistAccessLogById(id);

            return BaseResultEntity.success(log);
        } catch (Exception e) {
            log.error("查询访问日志详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询访问统计
     */
    public BaseResultEntity getWhitelistAccessStatistics() {
        try {
            Map<String, Object> statistics = whitelistPrimarydbRepository.selectWhitelistAccessStatistics();

            return BaseResultEntity.success(statistics);
        } catch (Exception e) {
            log.error("查询访问统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 记录访问日志
     */
    public void recordAccessLog(WhitelistAccessLog accessLog) {
        try {
            whitelistPrimarydbRepository.insertWhitelistAccessLog(accessLog);
        } catch (Exception e) {
            log.error("记录访问日志失败", e);
        }
    }

    /**
     * 批量删除访问日志
     */
    public BaseResultEntity batchDeleteAccessLog(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }
            whitelistPrimarydbRepository.batchDeleteAccessLog(ids);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("批量删除访问日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 清理过期日志
     */
    public BaseResultEntity cleanExpiredLogs(Integer days) {
        try {
            if (days == null || days <= 0) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            // 计算过期日期
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            java.util.Calendar calendar = java.util.Calendar.getInstance();
            calendar.add(java.util.Calendar.DAY_OF_MONTH, -days);
            String beforeDate = sdf.format(calendar.getTime());

            int count = whitelistPrimarydbRepository.deleteExpiredLogs(beforeDate);

            Map<String, Object> result = new HashMap<>();
            result.put("deletedCount", count);
            result.put("beforeDate", beforeDate);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("清理过期日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "清理失败");
        }
    }

    /**
     * 导出访问日志
     */
    public BaseResultEntity exportAccessLog(String accessIp, String accessUrl, String accessResult,
                                            String startTime, String endTime) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("accessIp", accessIp);
            params.put("accessUrl", accessUrl);
            params.put("accessResult", accessResult);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            List<WhitelistAccessLog> list = whitelistPrimarydbRepository.exportAccessLogList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("total", list.size());

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("导出访问日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "导出失败");
        }
    }

    /**
     * 获取访问趋势
     */
    public BaseResultEntity getAccessTrend(Integer days) {
        try {
            if (days == null || days <= 0) {
                days = 7;
            }

            List<Map<String, Object>> trendList = whitelistPrimarydbRepository.selectAccessTrend(days);

            Map<String, Object> result = new HashMap<>();
            result.put("trendList", trendList);
            result.put("days", days);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询访问趋势失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 获取IP访问排行
     */
    public BaseResultEntity getTopAccessIps(Integer limit) {
        try {
            if (limit == null || limit <= 0) {
                limit = 10;
            }

            List<Map<String, Object>> topIps = whitelistPrimarydbRepository.selectTopAccessIps(limit);

            Map<String, Object> result = new HashMap<>();
            result.put("topIps", topIps);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询IP访问排行失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 获取URL访问排行
     */
    public BaseResultEntity getTopAccessUrls(Integer limit) {
        try {
            if (limit == null || limit <= 0) {
                limit = 10;
            }

            List<Map<String, Object>> topUrls = whitelistPrimarydbRepository.selectTopAccessUrls(limit);

            Map<String, Object> result = new HashMap<>();
            result.put("topUrls", topUrls);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询URL访问排行失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 获取访问详细统计
     */
    public BaseResultEntity getAccessDetailStatistics(String startTime, String endTime) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            Map<String, Object> statistics = whitelistPrimarydbRepository.selectAccessDetailStatistics(params);

            return BaseResultEntity.success(statistics);
        } catch (Exception e) {
            log.error("查询访问详细统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }
}
