package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedQueryService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.Map;

@Api(value = "联邦查询接口", tags = "联邦查询接口")
@RequestMapping("/federatedQuery")
@RestController
public class FederatedQueryController {

    @Autowired
    private FederatedQueryService federatedQueryService;

    @ApiOperation("创建查询任务")
    @PostMapping("/create")
    public BaseResultEntity createQuery(@RequestBody Map<String, Object> req) {
        if (req == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedQueryService.createQuery(req, getCurrentUserId());
    }

    @ApiOperation("查询任务列表")
    @GetMapping("/list")
    public BaseResultEntity getQueryList(FederatedStatsQueryReq req) {
        return federatedQueryService.getQueryList(req);
    }

    @ApiOperation("查询任务详情")
    @GetMapping("/detail")
    public BaseResultEntity getQueryDetail(@RequestParam Long taskId) {
        return federatedQueryService.getQueryDetail(taskId);
    }

    @ApiOperation("执行查询任务")
    @PostMapping("/run")
    public BaseResultEntity runQuery(@RequestBody TaskActionReq req) {
        if (req == null || req.getTaskId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedQueryService.runQuery(req.getTaskId(), getCurrentUserId());
    }

    @ApiOperation("获取查询结果")
    @GetMapping("/result")
    public BaseResultEntity getQueryResult(@RequestParam Long taskId) {
        return federatedQueryService.getQueryResult(taskId);
    }

    @ApiOperation("获取支持的算法列表")
    @GetMapping("/algorithms")
    public BaseResultEntity getSupportedAlgorithms() {
        return federatedQueryService.getSupportedAlgorithms();
    }

    @ApiOperation("获取查询日志")
    @GetMapping("/logs")
    public BaseResultEntity getLogs(LogQueryReq req) {
        return federatedQueryService.getLogs(req);
    }

    @ApiOperation("导出查询日志")
    @PostMapping("/logs/export")
    public void exportLogs(@RequestBody LogExportReq req, HttpServletResponse response) {
        federatedQueryService.exportLogs(req, response);
    }

    // ==================== 工具配置 ====================

    @ApiOperation("保存工具配置")
    @PostMapping("/tools/save")
    public BaseResultEntity saveToolConfig(@RequestBody Map<String, Object> req) {
        return federatedQueryService.saveToolConfig(req, getCurrentUserId());
    }

    @ApiOperation("获取工具配置")
    @GetMapping("/tools/config")
    public BaseResultEntity getToolConfig(@RequestParam String toolName) {
        return federatedQueryService.getToolConfig(toolName);
    }

    @ApiOperation("测试工具")
    @PostMapping("/tools/test")
    public BaseResultEntity testTool(@RequestBody Map<String, Object> req) {
        return federatedQueryService.testTool(req);
    }

    private Long getCurrentUserId() {
        return 1L;
    }
}
