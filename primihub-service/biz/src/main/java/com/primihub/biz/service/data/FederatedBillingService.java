package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.req.*;
import javax.servlet.http.HttpServletResponse;

public interface FederatedBillingService {

    BaseResultEntity createRule(BillingRuleReq req, Long userId);
    BaseResultEntity updateRule(BillingRuleReq req);
    BaseResultEntity deleteRule(Long ruleId);
    BaseResultEntity toggleRule(BillingToggleReq req);
    BaseResultEntity getRuleList(BillingRuleQueryReq req);
    BaseResultEntity getRuleDetail(Long ruleId);

    BaseResultEntity getRecordList(BillingRecordQueryReq req);
    BaseResultEntity getRecordStatistics(BillingStatsQueryReq req);
    void exportRecord(BillingExportReq req, HttpServletResponse response);
}
