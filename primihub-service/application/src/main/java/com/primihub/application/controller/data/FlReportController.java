package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.FlReportService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.Map;

/**
 * 联邦学习 训练曲线 / 模型报告 / 日志 / 参数调优 Controller（补齐原全 404 的可视化接口）。
 * 映射 federatedLearning（nginx 仅剥 /prod-api）。
 */
@Api(tags = "联邦学习-训练曲线/报告/日志")
@RestController
@RequestMapping("federatedLearning")
public class FlReportController {

    @Autowired
    private FlReportService service;

    // 训练曲线
    @ApiOperation("训练迭代明细") @GetMapping("training/iterations")
    public BaseResultEntity iterations(@RequestParam(required = false) String taskId) { return service.trainingIterations(taskId); }
    @ApiOperation("训练指标") @GetMapping("training/metrics")
    public BaseResultEntity metrics(@RequestParam(required = false) String taskId) { return service.trainingMetrics(taskId); }
    @ApiOperation("损失曲线") @GetMapping("training/lossCurve")
    public BaseResultEntity lossCurve(@RequestParam(required = false) String taskId) { return service.lossCurve(taskId); }
    @ApiOperation("精度曲线") @GetMapping("training/accuracyCurve")
    public BaseResultEntity accuracyCurve(@RequestParam(required = false) String taskId) { return service.accuracyCurve(taskId); }
    @ApiOperation("训练日志") @GetMapping("training/logs")
    public BaseResultEntity trainingLogs(@RequestParam(required = false) String taskId) { return service.trainingLogs(taskId); }

    // 模型报告
    @ApiOperation("训练报告详情") @GetMapping("report/detail")
    public BaseResultEntity reportDetail(@RequestParam(required = false) String taskId) { return service.reportDetail(taskId); }
    @ApiOperation("模型评估") @GetMapping("report/evaluation")
    public BaseResultEntity evaluation(@RequestParam(required = false) String taskId) { return service.reportEvaluation(taskId); }
    @ApiOperation("特征重要性") @GetMapping("report/featureImportance")
    public BaseResultEntity featureImportance(@RequestParam(required = false) String taskId) { return service.featureImportance(taskId); }
    @ApiOperation("生成报告") @PostMapping("report/generate")
    public BaseResultEntity generate(@RequestBody(required = false) Map<String, Object> data) {
        return service.generateReport(data == null ? null : String.valueOf(data.get("taskId")));
    }
    @ApiOperation("导出报告") @GetMapping("report/export")
    public void export(@RequestParam(required = false) String taskId, HttpServletResponse response) { service.exportReport(taskId, response); }

    // 日志
    @ApiOperation("联邦学习日志") @GetMapping("logs")
    public BaseResultEntity logs(@RequestParam Map<String, Object> query) { return service.logs(query); }
    @ApiOperation("任务日志") @GetMapping("taskLogs")
    public BaseResultEntity taskLogs(@RequestParam(required = false) String taskId) { return service.taskLogs(taskId); }

    // 参数调优
    @ApiOperation("参数调优列表") @GetMapping("paramTuning/list")
    public BaseResultEntity ptList(@RequestParam Map<String, Object> query) { return service.paramTuningList(query); }
    @ApiOperation("参数调优结果") @GetMapping("paramTuning/result")
    public BaseResultEntity ptResult(@RequestParam(required = false) String taskId) { return service.paramTuningResult(taskId); }
    @ApiOperation("创建参数调优") @PostMapping("paramTuning/create")
    public BaseResultEntity ptCreate(@RequestBody(required = false) Map<String, Object> data) { return service.paramTuningCreate(data); }
    @ApiOperation("应用最优参数") @PostMapping("paramTuning/apply")
    public BaseResultEntity ptApply(@RequestBody(required = false) Map<String, Object> data) { return service.applyBestParams(data); }
}
