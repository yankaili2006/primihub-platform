package com.primihub.biz.service.data.impl;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.FederatedBillingRecord;
import com.primihub.biz.entity.data.po.FederatedBillingRule;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.repository.primarydb.data.FederatedBillingRepository;
import com.primihub.biz.service.data.FederatedBillingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

@Slf4j
@Service
public class FederatedBillingServiceImpl implements FederatedBillingService {

    @Autowired
    private FederatedBillingRepository billingRepository;

    private static final Map<String, String> BILLING_TYPE_NAMES = new HashMap<>();
    static {
        BILLING_TYPE_NAMES.put("by_count", "按次数计费");
        BILLING_TYPE_NAMES.put("by_hit", "按命中计费");
        BILLING_TYPE_NAMES.put("fixed_dedup", "固定窗口去重计费");
        BILLING_TYPE_NAMES.put("rolling_dedup", "滚动窗口去重计费");
    }

    private static final Map<Integer, String> CHARGE_STATUS_NAMES = new HashMap<>();
    static {
        CHARGE_STATUS_NAMES.put(0, "待结算");
        CHARGE_STATUS_NAMES.put(1, "已结算");
        CHARGE_STATUS_NAMES.put(2, "已退款");
    }

    // ==================== 规则管理 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createRule(BillingRuleReq req, Long userId) {
        try {
            if (req.getRuleName() == null || req.getRuleName().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "规则名称不能为空");
            }
            if (req.getBillingType() == null || !BILLING_TYPE_NAMES.containsKey(req.getBillingType())) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "无效的计费类型");
            }

            FederatedBillingRule rule = toRule(req);
            rule.setCreatedBy(userId);
            rule.setIsActive(req.getIsActive() != null ? req.getIsActive() : 0);
            billingRepository.insertRule(rule);

            Map<String, Object> result = new HashMap<>();
            result.put("ruleId", rule.getId());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建计费规则失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateRule(BillingRuleReq req) {
        try {
            if (req.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "规则ID不能为空");
            }
            FederatedBillingRule existing = billingRepository.selectRuleById(req.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "规则不存在");
            }

            FederatedBillingRule rule = toRule(req);
            rule.setId(req.getId());
            billingRepository.updateRule(rule);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("更新计费规则失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteRule(Long ruleId) {
        try {
            billingRepository.deleteRule(ruleId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除计费规则失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity toggleRule(BillingToggleReq req) {
        try {
            billingRepository.toggleRule(req.getRuleId(), req.getIsActive() ? 1 : 0);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("启停计费规则失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "操作失败");
        }
    }

    @Override
    public BaseResultEntity getRuleList(BillingRuleQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("billingType", req.getBillingType());
            params.put("isActive", req.getIsActive());

            int total = billingRepository.selectRuleCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedBillingRule> list = billingRepository.selectRuleList(params);
            List<Map<String, Object>> voList = new ArrayList<>();
            for (FederatedBillingRule rule : list) {
                Map<String, Object> vo = new HashMap<>();
                vo.put("id", rule.getId());
                vo.put("ruleName", rule.getRuleName());
                vo.put("billingType", rule.getBillingType());
                vo.put("billingTypeName", BILLING_TYPE_NAMES.getOrDefault(rule.getBillingType(), rule.getBillingType()));
                vo.put("isActive", rule.getIsActive());
                vo.put("pricePerQuery", rule.getPricePerQuery());
                vo.put("pricePerHit", rule.getPricePerHit());
                vo.put("minCharge", rule.getMinCharge());
                vo.put("effectiveFrom", rule.getEffectiveFrom());
                vo.put("createdAt", rule.getCreatedAt());
                voList.add(vo);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("list", voList);
            result.put("total", total);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询计费规则列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getRuleDetail(Long ruleId) {
        try {
            FederatedBillingRule rule = billingRepository.selectRuleById(ruleId);
            if (rule == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "规则不存在");
            }
            return BaseResultEntity.success(rule);
        } catch (Exception e) {
            log.error("查询计费规则详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ==================== 计费记录 ====================

    @Override
    public BaseResultEntity getRecordList(BillingRecordQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("requesterOrganId", req.getRequesterOrganId());
            params.put("billingType", req.getBillingType());
            params.put("chargeStatus", req.getChargeStatus());

            int total = billingRepository.selectRecordCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedBillingRecord> list = billingRepository.selectRecordList(params);

            // 汇总
            Map<String, Object> summary = billingRepository.selectRecordSummary(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("total", total);
            result.put("summary", summary);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询计费记录失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getRecordStatistics(BillingStatsQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("requesterOrganId", req.getRequesterOrganId());
            params.put("startDate", req.getStartDate());
            params.put("endDate", req.getEndDate());

            Map<String, Object> summary = billingRepository.selectRecordSummary(params);
            List<Map<String, Object>> daily = billingRepository.selectDailyCharge(params);

            Map<String, Object> result = new HashMap<>();
            result.putAll(summary);
            result.put("dailyCharges", daily);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询计费统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public void exportRecord(BillingExportReq req, HttpServletResponse response) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("startDate", req.getStartDate());
            params.put("endDate", req.getEndDate());
            List<FederatedBillingRecord> records = billingRepository.selectRecordList(params);

            StringBuilder sb = new StringBuilder();
            sb.append("时间,类型,任务ID,请求方,命中数,金额,状态\n");
            for (FederatedBillingRecord r : records) {
                sb.append(r.getBillingTime()).append(",")
                  .append(r.getBillingType()).append(",")
                  .append(r.getTaskId()).append(",")
                  .append(r.getRequesterOrganId()).append(",")
                  .append(r.getHitCount()).append(",")
                  .append(r.getTotalCharge()).append(",")
                  .append(CHARGE_STATUS_NAMES.getOrDefault(r.getChargeStatus(), "未知")).append("\n");
            }

            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("billing_records.csv", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(sb.toString().getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("导出计费记录失败", e);
        }
    }

    // ==================== 工具方法 ====================

    private FederatedBillingRule toRule(BillingRuleReq req) {
        FederatedBillingRule rule = new FederatedBillingRule();
        rule.setRuleName(req.getRuleName());
        rule.setBillingType(req.getBillingType());
        rule.setBaseFee(req.getBaseFee());
        rule.setMinCharge(req.getMinCharge());
        // 各计费类型特有字段
        rule.setPricePerQuery(req.getPricePerQuery());
        rule.setEnableDiscount(req.getEnableDiscount() != null && req.getEnableDiscount() ? 1 : 0);
        rule.setDiscountThreshold(req.getDiscountThreshold());
        rule.setDiscountRate(req.getDiscountRate());
        rule.setPricePerHit(req.getPricePerHit());
        rule.setEnableTiered(req.getEnableTiered() != null && req.getEnableTiered() ? 1 : 0);
        rule.setDedupTimeWindow(req.getDedupTimeWindow());
        rule.setPricePerUnique(req.getPricePerUnique());
        rule.setRepeatDiscount(req.getRepeatDiscount());
        rule.setRollingWindowHours(req.getRollingWindowHours());
        rule.setSlideIntervalHours(req.getSlideIntervalHours());
        rule.setRollingPricePerUnique(req.getRollingPricePerUnique());
        rule.setRollingRepeatDiscount(req.getRollingRepeatDiscount());
        return rule;
    }
}
