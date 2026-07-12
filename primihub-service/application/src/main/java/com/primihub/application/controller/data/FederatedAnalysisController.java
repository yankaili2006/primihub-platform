package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedAnalysisService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

@Api(value = "联邦分析接口", tags = "联邦分析接口")
@RestController
public class FederatedAnalysisController {

    @Autowired
    private FederatedAnalysisService federatedAnalysisService;

    // ==================== SQL操作 ====================

    @ApiOperation("SQL校验")
    @PostMapping("/federatedAnalysis/sql/validate")
    public BaseResultEntity validateSql(@RequestBody SqlValidateReq req) {
        return federatedAnalysisService.validateSql(req);
    }

    @ApiOperation("SQL格式化")
    @PostMapping("/federatedAnalysis/sql/format")
    public BaseResultEntity formatSql(@RequestBody SqlFormatReq req) {
        return federatedAnalysisService.formatSql(req);
    }

    @ApiOperation("获取SQL函数列表")
    @GetMapping("/federatedAnalysis/sql/functions")
    public BaseResultEntity getFunctions(@RequestParam(required = false) String category) {
        return federatedAnalysisService.getFunctions(category);
    }

    // ==================== 任务管理 ====================

    @ApiOperation("创建分析任务")
    @PostMapping("/federatedAnalysis/task/create")
    public BaseResultEntity createTask(@RequestBody AnalysisTaskReq req) {
        if (req == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedAnalysisService.createTask(req, getCurrentUserId());
    }

    @ApiOperation("获取分析任务列表")
    @GetMapping("/federatedAnalysis/task/list")
    public BaseResultEntity getTaskList(AnalysisTaskQueryReq req) {
        return federatedAnalysisService.getTaskList(req);
    }

    @ApiOperation("获取分析任务详情")
    @GetMapping("/federatedAnalysis/task/detail")
    public BaseResultEntity getTaskDetail(@RequestParam Long taskId) {
        return federatedAnalysisService.getTaskDetail(taskId);
    }

    @ApiOperation("执行分析任务")
    @PostMapping("/federatedAnalysis/task/run")
    public BaseResultEntity runTask(@RequestBody TaskActionReq req) {
        if (req == null || req.getTaskId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedAnalysisService.runTask(req.getTaskId(), getCurrentUserId());
    }

    @ApiOperation("停止分析任务")
    @PostMapping("/federatedAnalysis/task/stop")
    public BaseResultEntity stopTask(@RequestBody TaskActionReq req) {
        if (req == null || req.getTaskId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedAnalysisService.stopTask(req.getTaskId());
    }

    // ==================== 数据源管理 ====================

    @ApiOperation("获取数据源列表")
    @GetMapping("/federatedAnalysis/datasource/list")
    public BaseResultEntity getDataSourceList(@RequestParam(required = false) String sourceType) {
        return federatedAnalysisService.getDataSourceList(sourceType);
    }

    @ApiOperation("创建数据源")
    @PostMapping("/federatedAnalysis/datasource/create")
    public BaseResultEntity createDataSource(@RequestBody AnalysisDataSourceReq req) {
        if (req == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedAnalysisService.createDataSource(req, getCurrentUserId());
    }

    @ApiOperation("更新数据源")
    @PostMapping("/federatedAnalysis/datasource/update")
    public BaseResultEntity updateDataSource(@RequestBody AnalysisDataSourceReq req) {
        return federatedAnalysisService.updateDataSource(req);
    }

    @ApiOperation("删除数据源")
    @PostMapping("/federatedAnalysis/datasource/delete")
    public BaseResultEntity deleteDataSource(@RequestBody IdReq req) {
        if (req == null || req.getId() == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return federatedAnalysisService.deleteDataSource(req.getId());
    }

    @ApiOperation("测试数据源连接")
    @PostMapping("/federatedAnalysis/datasource/test")
    public BaseResultEntity testDataSourceConnection(@RequestBody AnalysisDataSourceReq req) {
        return federatedAnalysisService.testDataSourceConnection(req);
    }

    @ApiOperation("获取数据源表列表")
    @GetMapping("/federatedAnalysis/datasource/tables")
    public BaseResultEntity getDataSourceTables(@RequestParam Long datasourceId) {
        return federatedAnalysisService.getDataSourceTables(datasourceId);
    }

    @ApiOperation("获取表字段列表")
    @GetMapping("/federatedAnalysis/datasource/columns")
    public BaseResultEntity getTableColumns(@RequestParam Long datasourceId, @RequestParam String tableName) {
        return federatedAnalysisService.getTableColumns(datasourceId, tableName);
    }

    // ==================== 类型支持 ====================

    @ApiOperation("获取支持的RDBMS类型")
    @GetMapping("/federatedAnalysis/rdbms/types")
    public BaseResultEntity getSupportedRdbms() {
        return federatedAnalysisService.getSupportedRdbms();
    }

    @ApiOperation("创建RDBMS连接")
    @PostMapping("/federatedAnalysis/rdbms/create")
    public BaseResultEntity createRdbmsConnection(@RequestBody AnalysisDataSourceReq req) {
        return createDataSource(req);
    }

    @ApiOperation("测试RDBMS连接")
    @PostMapping("/federatedAnalysis/rdbms/test")
    public BaseResultEntity testRdbmsConnection(@RequestBody AnalysisDataSourceReq req) {
        return federatedAnalysisService.testDataSourceConnection(req);
    }

    @ApiOperation("获取支持的大数据平台")
    @GetMapping("/federatedAnalysis/bigdata/types")
    public BaseResultEntity getSupportedBigDataPlatforms() {
        return federatedAnalysisService.getSupportedBigDataPlatforms();
    }

    @ApiOperation("创建大数据连接")
    @PostMapping("/federatedAnalysis/bigdata/create")
    public BaseResultEntity createBigDataConnection(@RequestBody AnalysisDataSourceReq req) {
        return createDataSource(req);
    }

    @ApiOperation("测试大数据连接")
    @PostMapping("/federatedAnalysis/bigdata/test")
    public BaseResultEntity testBigDataConnection(@RequestBody AnalysisDataSourceReq req) {
        return federatedAnalysisService.testDataSourceConnection(req);
    }

    @ApiOperation("获取支持的云平台")
    @GetMapping("/federatedAnalysis/cloud/types")
    public BaseResultEntity getSupportedCloudPlatforms() {
        return federatedAnalysisService.getSupportedCloudPlatforms();
    }

    @ApiOperation("创建云平台连接")
    @PostMapping("/federatedAnalysis/cloud/create")
    public BaseResultEntity createCloudConnection(@RequestBody AnalysisDataSourceReq req) {
        return createDataSource(req);
    }

    @ApiOperation("测试云平台连接")
    @PostMapping("/federatedAnalysis/cloud/test")
    public BaseResultEntity testCloudConnection(@RequestBody AnalysisDataSourceReq req) {
        return federatedAnalysisService.testDataSourceConnection(req);
    }

    // ==================== 日志 ====================

    @ApiOperation("获取分析日志")
    @GetMapping("/federatedAnalysis/logs")
    public BaseResultEntity getLogs(LogQueryReq req) {
        return federatedAnalysisService.getLogs(req);
    }

    @ApiOperation("导出分析日志")
    @PostMapping("/federatedAnalysis/logs/export")
    public void exportLogs(@RequestBody LogExportReq req, HttpServletResponse response) {
        federatedAnalysisService.exportLogs(req, response);
    }

    @ApiOperation("批量导出分析日志")
    @PostMapping("/federatedAnalysis/logs/batchExport")
    public void batchExportLogs(@RequestBody BatchExportReq req, HttpServletResponse response) {
        federatedAnalysisService.batchExportLogs(req, response);
    }

    // ==================== 兼容路径 (data 前缀) ====================

    @ApiOperation("SQL校验(兼容)")
    @PostMapping("/data/federatedAnalysis/validate")
    public BaseResultEntity validateSqlCompat(@RequestBody SqlValidateReq req) {
        return validateSql(req);
    }

    @ApiOperation("创建分析任务(兼容)")
    @PostMapping("/data/federatedAnalysis/create")
    public BaseResultEntity createTaskCompat(@RequestBody AnalysisTaskReq req) {
        return createTask(req);
    }

    @ApiOperation("获取分析任务列表(兼容)")
    @GetMapping("/data/federatedAnalysis/list")
    public BaseResultEntity getTaskListCompat(AnalysisTaskQueryReq req) {
        return getTaskList(req);
    }

    @ApiOperation("获取分析任务详情(兼容)")
    @GetMapping("/data/federatedAnalysis/detail")
    public BaseResultEntity getTaskDetailCompat(@RequestParam Long taskId) {
        return getTaskDetail(taskId);
    }

    @ApiOperation("执行分析任务(兼容)")
    @PostMapping("/data/federatedAnalysis/start")
    public BaseResultEntity runTaskCompat(@RequestBody TaskActionReq req) {
        return runTask(req);
    }

    // 前端 exportFederatedAnalysisResult 调 /data/federatedAnalysis/result/export（blob），
    // 网关 StripPrefix 掉 /data → 应用侧须映射 /federatedAnalysis/result/export（与其它已生效路由同规则）。
    // 原 /data/federatedAnalysis/exportResult 空桩既路径不符、又带被剥的 /data 前缀，双重不可达。
    @ApiOperation("导出分析结果")
    @GetMapping("/federatedAnalysis/result/export")
    public void exportResult(@RequestParam Long taskId, HttpServletResponse response) {
        federatedAnalysisService.exportResult(taskId, response);
    }

    @ApiOperation("获取数据源列表(兼容)")
    @GetMapping("/data/federatedAnalysis/datasource/list")
    public BaseResultEntity getDataSourceListCompat(@RequestParam(required = false) String sourceType) {
        return getDataSourceList(sourceType);
    }

    @ApiOperation("获取分析日志(兼容)")
    @GetMapping("/data/federatedAnalysis/logs")
    public BaseResultEntity getLogsCompat(LogQueryReq req) {
        return getLogs(req);
    }

    @ApiOperation("导出分析日志(兼容)")
    @GetMapping("/data/federatedAnalysis/exportLogs")
    public void exportLogsCompat(LogExportReq req, HttpServletResponse response) {
        exportLogs(req, response);
    }

    private Long getCurrentUserId() {
        return 1L;
    }
}
