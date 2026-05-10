package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedBillingService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

@Api(value = "联邦查询计费接口", tags = "联邦查询计费接口")
@RequestMapping("/federatedBilling")
@RestController
public class FederatedBillingController {

    @Autowired
    private FederatedBillingService federatedBillingService;

    @ApiOperation("创建计费规则")
    @PostMapping("/rule/create")
    public BaseResultEntity createRule(@RequestBody BillingRuleReq req) {
        if (req == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedBillingService.createRule(req, getCurrentUserId());
    }

    @ApiOperation("更新计费规则")
    @PostMapping("/rule/update")
    public BaseResultEntity updateRule(@RequestBody BillingRuleReq req) {
        return federatedBillingService.updateRule(req);
    }

    @ApiOperation("删除计费规则")
    @PostMapping("/rule/delete")
    public BaseResultEntity deleteRule(@RequestBody IdReq req) {
        if (req == null || req.getId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedBillingService.deleteRule(req.getId());
    }

    @ApiOperation("启停计费规则")
    @PostMapping("/rule/toggle")
    public BaseResultEntity toggleRule(@RequestBody BillingToggleReq req) {
        return federatedBillingService.toggleRule(req);
    }

    @ApiOperation("获取计费规则列表")
    @GetMapping("/rule/list")
    public BaseResultEntity getRuleList(BillingRuleQueryReq req) {
        return federatedBillingService.getRuleList(req);
    }

    @ApiOperation("获取计费规则详情")
    @GetMapping("/rule/detail")
    public BaseResultEntity getRuleDetail(@RequestParam Long ruleId) {
        return federatedBillingService.getRuleDetail(ruleId);
    }

    @ApiOperation("获取计费记录列表")
    @GetMapping("/record/list")
    public BaseResultEntity getRecordList(BillingRecordQueryReq req) {
        return federatedBillingService.getRecordList(req);
    }

    @ApiOperation("获取计费统计")
    @GetMapping("/record/statistics")
    public BaseResultEntity getRecordStatistics(BillingStatsQueryReq req) {
        return federatedBillingService.getRecordStatistics(req);
    }

    @ApiOperation("导出计费记录")
    @PostMapping("/record/export")
    public void exportRecord(@RequestBody BillingExportReq req, HttpServletResponse response) {
        federatedBillingService.exportRecord(req, response);
    }

    private Long getCurrentUserId() {
        return 1L;
    }
}
