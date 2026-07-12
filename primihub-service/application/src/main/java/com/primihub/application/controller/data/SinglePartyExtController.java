package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.SinglePartyExtService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.HashMap;
import java.util.Map;

/**
 * 单方作业「预处理 / 脚本 / 学习日志」补齐 Controller（MAIN 任务另有 SinglePartyController）。
 * 同映射 singleParty，仅补原缺失的 preprocess/script/log 子路径（原整页部分 404）。
 */
@Api(tags = "单方作业-预处理/脚本/日志")
@RestController
@RequestMapping("singleParty")
public class SinglePartyExtController {

    @Autowired
    private SinglePartyExtService service;

    // ===== 预处理 =====
    @ApiOperation("预处理任务列表")
    @GetMapping("preprocess/list")
    public BaseResultEntity preprocessList(@RequestParam Map<String, Object> query) { return service.listPreprocess(query); }

    @ApiOperation("创建预处理任务")
    @PostMapping("preprocess/create")
    public BaseResultEntity preprocessCreate(@RequestBody Map<String, Object> data,
                                             @RequestHeader(value = "userId", required = false) Long userId) {
        return service.createPreprocess(data, userId, null);
    }

    @ApiOperation("运行预处理任务")
    @PostMapping("preprocess/run")
    public BaseResultEntity preprocessRun(@RequestBody Map<String, Object> data) { return service.runPreprocess(data); }

    @ApiOperation("删除预处理任务")
    @PostMapping("preprocess/delete")
    public BaseResultEntity preprocessDelete(@RequestBody Map<String, Object> data) { return service.deletePreprocess(data); }

    @ApiOperation("下载预处理结果")
    @GetMapping("preprocess/download")
    public void preprocessDownload(@RequestParam String taskId, HttpServletResponse response) { service.downloadPreprocess(taskId, response); }

    // ===== 脚本 =====
    @ApiOperation("脚本任务列表")
    @GetMapping("script/list")
    public BaseResultEntity scriptList(@RequestParam Map<String, Object> query) { return service.listScript(query); }

    @ApiOperation("创建脚本任务")
    @PostMapping("script/create")
    public BaseResultEntity scriptCreate(@RequestBody Map<String, Object> data,
                                         @RequestHeader(value = "userId", required = false) Long userId) {
        return service.createScript(data, userId, null);
    }

    @ApiOperation("运行脚本任务")
    @PostMapping("script/run")
    public BaseResultEntity scriptRun(@RequestBody Map<String, Object> data) { return service.runScript(data); }

    @ApiOperation("删除脚本任务")
    @PostMapping("script/delete")
    public BaseResultEntity scriptDelete(@RequestBody Map<String, Object> data) { return service.deleteScript(data); }

    @ApiOperation("下载脚本结果")
    @GetMapping("script/download")
    public void scriptDownload(@RequestParam String taskId, HttpServletResponse response) { service.downloadScript(taskId, response); }

    // ===== 学习日志 =====
    @ApiOperation("单方学习日志列表")
    @GetMapping("log/list")
    public BaseResultEntity logList(@RequestParam Map<String, Object> query) { return service.getLogs(query); }

    @ApiOperation("导出单方学习日志")
    @GetMapping("log/export")
    public void logExport(@RequestParam Map<String, Object> query, HttpServletResponse response) { service.exportLogs(query, response); }
}
