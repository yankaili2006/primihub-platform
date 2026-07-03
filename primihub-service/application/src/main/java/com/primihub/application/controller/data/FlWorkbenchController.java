package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.FlWorkbenchService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 联邦学习建模工作台 Controller（工作流真持久化 + 运行 + 日志 + 选项）。
 * 前端 modelingWorkbench.vue 已重写为调这些接口。映射 federatedLearning（nginx 仅剥 /prod-api）。
 */
@Api(tags = "联邦学习建模工作台")
@RestController
@RequestMapping("federatedLearning")
public class FlWorkbenchController {

    @Autowired
    private FlWorkbenchService service;

    @ApiOperation("工作台概览")
    @GetMapping("workbench/overview")
    public BaseResultEntity overview() { return service.overview(); }

    @ApiOperation("工作台选项(参与方/数据集)")
    @GetMapping("workbench/options")
    public BaseResultEntity options(@RequestParam(required = false) String organId) { return service.options(organId); }

    @ApiOperation("工作流列表")
    @GetMapping("workflow/list")
    public BaseResultEntity list(@RequestParam Map<String, Object> query) { return service.listWorkflows(query); }

    @ApiOperation("工作流详情")
    @GetMapping("workflow/get")
    public BaseResultEntity get(@RequestParam String workflowId) { return service.getWorkflow(workflowId); }

    @ApiOperation("保存工作流")
    @PostMapping("workflow/save")
    public BaseResultEntity save(@RequestBody Map<String, Object> data,
                                 @RequestHeader(value = "userId", required = false) Long userId) {
        return service.saveWorkflow(data, userId, null);
    }

    @ApiOperation("运行工作流")
    @PostMapping("workflow/run")
    public BaseResultEntity run(@RequestBody Map<String, Object> data,
                               @RequestHeader(value = "userId", required = false) Long userId) {
        return service.runWorkflow(data, userId, null);
    }

    @ApiOperation("工作流运行日志")
    @GetMapping("workflow/logs")
    public BaseResultEntity logs(@RequestParam String workflowId) { return service.getLogs(workflowId); }

    @ApiOperation("删除工作流")
    @PostMapping("workflow/delete")
    public BaseResultEntity delete(@RequestParam String workflowId) { return service.deleteWorkflow(workflowId); }
}
