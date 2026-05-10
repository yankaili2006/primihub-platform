package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedStatsService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

@Api(value = "联邦统计接口", tags = "联邦统计接口")
@RestController
public class FederatedStatsController {

    @Autowired
    private FederatedStatsService federatedStatsService;

    // ==================== 任务管理 (主路径) ====================

    @ApiOperation("创建统计任务")
    @PostMapping("/federatedStatistics/task/create")
    public BaseResultEntity createTask(@RequestBody FederatedStatsReq req) {
        if (req == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedStatsService.createTask(req, getCurrentUserId());
    }

    @ApiOperation("获取统计任务列表")
    @GetMapping("/federatedStatistics/task/list")
    public BaseResultEntity getTaskList(FederatedStatsQueryReq req) {
        return federatedStatsService.getTaskList(req);
    }

    @ApiOperation("获取统计任务详情")
    @GetMapping("/federatedStatistics/task/detail")
    public BaseResultEntity getTaskDetail(@RequestParam Long taskId) {
        return federatedStatsService.getTaskDetail(taskId);
    }

    @ApiOperation("执行统计任务")
    @PostMapping("/federatedStatistics/task/run")
    public BaseResultEntity runTask(@RequestBody TaskActionReq req) {
        if (req == null || req.getTaskId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedStatsService.runTask(req.getTaskId(), getCurrentUserId());
    }

    @ApiOperation("停止统计任务")
    @PostMapping("/federatedStatistics/task/stop")
    public BaseResultEntity stopTask(@RequestBody TaskActionReq req) {
        if (req == null || req.getTaskId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedStatsService.stopTask(req.getTaskId());
    }

    @ApiOperation("删除统计任务")
    @RequestMapping(value = "/federatedStatistics/task/delete", method = {RequestMethod.DELETE, RequestMethod.POST})
    public BaseResultEntity deleteTask(@RequestParam(required = false) Long taskId,
                                       @RequestBody(required = false) IdReq req) {
        Long id = taskId != null ? taskId : (req != null ? req.getId() : null);
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedStatsService.deleteTask(id);
    }

    // ==================== 结果管理 ====================

    @ApiOperation("获取统计结果")
    @GetMapping("/federatedStatistics/result")
    public BaseResultEntity getResult(@RequestParam Long taskId) {
        return federatedStatsService.getResult(taskId);
    }

    @ApiOperation("保存统计结果")
    @PostMapping("/federatedStatistics/result/save")
    public BaseResultEntity saveResult(@RequestBody SaveResultReq req) {
        if (req == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedStatsService.saveResult(req, getCurrentUserId());
    }

    @ApiOperation("导出统计结果")
    @GetMapping("/federatedStatistics/result/export")
    public void exportResult(@RequestParam Long taskId, @RequestParam(defaultValue = "TXT") String format,
                              HttpServletResponse response) {
        federatedStatsService.exportResult(taskId, format, response);
    }

    @ApiOperation("批量导出统计结果")
    @PostMapping("/federatedStatistics/result/batchExport")
    public void batchExportResult(@RequestBody BatchExportReq req, HttpServletResponse response) {
        federatedStatsService.batchExportResult(req, response);
    }

    // ==================== 存储配置 ====================

    @ApiOperation("获取存储配置")
    @GetMapping("/federatedStatistics/storage/config")
    public BaseResultEntity getStorageConfig() {
        return federatedStatsService.getStorageConfig(getCurrentUserId());
    }

    @ApiOperation("保存存储配置")
    @PostMapping("/federatedStatistics/storage/saveConfig")
    public BaseResultEntity saveStorageConfig(@RequestBody StorageConfigReq req) {
        return federatedStatsService.saveStorageConfig(req, getCurrentUserId());
    }

    @ApiOperation("测试存储连接")
    @PostMapping("/federatedStatistics/storage/testConnection")
    public BaseResultEntity testStorageConnection(@RequestBody StorageConfigReq req) {
        return federatedStatsService.testStorageConnection(req);
    }

    @ApiOperation("获取已存储的结果列表")
    @GetMapping("/federatedStatistics/storage/results")
    public BaseResultEntity getStoredResults(@RequestParam(defaultValue = "1") Integer pageNo,
                                              @RequestParam(defaultValue = "10") Integer pageSize) {
        return federatedStatsService.getStoredResults(pageNo, pageSize, getCurrentUserId());
    }

    @ApiOperation("预览存储结果")
    @GetMapping("/federatedStatistics/storage/preview")
    public BaseResultEntity previewStoredResult(@RequestParam Long resultId,
                                                 @RequestParam(defaultValue = "10") Integer rows) {
        return federatedStatsService.previewStoredResult(resultId, rows);
    }

    @ApiOperation("下载存储结果")
    @GetMapping("/federatedStatistics/storage/download")
    public void downloadStoredResult(@RequestParam Long resultId, HttpServletResponse response) {
        federatedStatsService.downloadStoredResult(resultId, response);
    }

    @ApiOperation("删除存储结果")
    @DeleteMapping("/federatedStatistics/storage/delete")
    public BaseResultEntity deleteStoredResult(@RequestParam Long resultId) {
        return federatedStatsService.deleteStoredResult(resultId);
    }

    // ==================== 日志 ====================

    @ApiOperation("获取统计日志")
    @GetMapping("/federatedStatistics/logs")
    public BaseResultEntity getLogs(LogQueryReq req) {
        return federatedStatsService.getLogs(req);
    }

    @ApiOperation("获取日志详情")
    @GetMapping("/federatedStatistics/logs/detail")
    public BaseResultEntity getLogDetail(@RequestParam Long logId) {
        return federatedStatsService.getLogDetail(logId);
    }

    @ApiOperation("导出统计日志")
    @PostMapping("/federatedStatistics/logs/export")
    public void exportLogs(@RequestBody LogExportReq req, HttpServletResponse response) {
        federatedStatsService.exportLogs(req, response);
    }

    // ==================== 统计类型 ====================

    @ApiOperation("获取支持的统计类型")
    @GetMapping("/federatedStatistics/types")
    public BaseResultEntity getStatisticsTypes() {
        return federatedStatsService.getStatisticsTypes();
    }

    // ==================== 兼容路径 (data 前缀) ====================

    @ApiOperation("创建统计任务(兼容)")
    @PostMapping("/data/federatedStatistics/create")
    public BaseResultEntity createTaskCompat(@RequestBody FederatedStatsReq req) {
        return createTask(req);
    }

    @ApiOperation("获取统计任务列表(兼容)")
    @GetMapping("/data/federatedStatistics/list")
    public BaseResultEntity getTaskListCompat(FederatedStatsQueryReq req) {
        return getTaskList(req);
    }

    @ApiOperation("获取统计任务详情(兼容)")
    @GetMapping("/data/federatedStatistics/detail")
    public BaseResultEntity getTaskDetailCompat(@RequestParam Long taskId) {
        return getTaskDetail(taskId);
    }

    @ApiOperation("执行统计任务(兼容)")
    @PostMapping("/data/federatedStatistics/start")
    public BaseResultEntity runTaskCompat(@RequestBody TaskActionReq req) {
        return runTask(req);
    }

    @ApiOperation("获取统计结果(兼容)")
    @GetMapping("/data/federatedStatistics/result")
    public BaseResultEntity getResultCompat(@RequestParam Long taskId) {
        return getResult(taskId);
    }

    @ApiOperation("保存统计结果(兼容)")
    @PostMapping("/data/federatedStatistics/saveResult")
    public BaseResultEntity saveResultCompat(@RequestBody SaveResultReq req) {
        return saveResult(req);
    }

    @ApiOperation("导出统计结果(兼容)")
    @GetMapping("/data/federatedStatistics/exportResult")
    public void exportResultCompat(@RequestParam Long taskId, @RequestParam(defaultValue = "TXT") String format,
                                    HttpServletResponse response) {
        exportResult(taskId, format, response);
    }

    @ApiOperation("批量导出统计结果(兼容)")
    @PostMapping("/data/federatedStatistics/batchExportResult")
    public void batchExportResultCompat(@RequestBody BatchExportReq req, HttpServletResponse response) {
        batchExportResult(req, response);
    }

    @ApiOperation("获取统计日志(兼容)")
    @GetMapping("/data/federatedStatistics/logs")
    public BaseResultEntity getLogsCompat(LogQueryReq req) {
        return getLogs(req);
    }

    @ApiOperation("导出统计日志(兼容)")
    @GetMapping("/data/federatedStatistics/exportLogs")
    public void exportLogsCompat(LogExportReq req, HttpServletResponse response) {
        exportLogs(req, response);
    }

    @ApiOperation("删除统计任务(兼容)")
    @PostMapping("/data/federatedStatistics/delete")
    public BaseResultEntity deleteTaskCompat(@RequestBody IdReq req) {
        return deleteTask(null, req);
    }

    private Long getCurrentUserId() {
        return 1L;
    }
}
