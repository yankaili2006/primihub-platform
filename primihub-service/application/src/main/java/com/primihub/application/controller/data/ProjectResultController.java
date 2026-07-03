package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.ProjectResultService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.List;
import java.util.Map;

/**
 * 项目结果保存 Controller。
 * 前端 projectResult.js 调 /prod-api/project/result/*，nginx 仅剥 /prod-api → 映射 project/result。
 * （原后端完全无此模块，整页 8 接口 404；本类补齐真实实现。）
 */
@Api(tags = "项目结果保存")
@RestController
@RequestMapping("project/result")
public class ProjectResultController {

    @Autowired
    private ProjectResultService projectResultService;

    @ApiOperation("查询项目结果分页列表")
    @GetMapping("findPage")
    public BaseResultEntity findPage(
            @RequestParam(required = false) String projectName,
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) String resultType,
            @RequestParam(required = false) Integer saveStatus,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return projectResultService.findProjectResultPage(projectName, taskName, resultType, saveStatus, pageNum, pageSize);
    }

    @ApiOperation("保存项目结果")
    @PostMapping("save")
    public BaseResultEntity save(@RequestBody Map<String, Object> data,
                                 @RequestHeader(value = "userId", required = false) Long userId) {
        return projectResultService.saveProjectResult(data, userId);
    }

    @ApiOperation("批量保存项目结果")
    @PostMapping("batchSave")
    public BaseResultEntity batchSave(@RequestBody List<Long> ids) {
        return projectResultService.batchSaveProjectResult(ids);
    }

    @ApiOperation("删除项目结果")
    @PostMapping("delete")
    public BaseResultEntity delete(@RequestParam Long id) {
        return projectResultService.deleteProjectResult(id);
    }

    @ApiOperation("批量删除项目结果")
    @PostMapping("batchDelete")
    public BaseResultEntity batchDelete(@RequestBody List<Long> ids) {
        return projectResultService.batchDeleteProjectResult(ids);
    }

    @ApiOperation("下载项目结果")
    @GetMapping("download")
    public void download(@RequestParam Long id, HttpServletResponse response) {
        projectResultService.downloadProjectResult(id, response);
    }

    @ApiOperation("获取结果保存配置")
    @GetMapping("getConfig")
    public BaseResultEntity getConfig() {
        return projectResultService.getResultConfig();
    }

    @ApiOperation("更新结果保存配置")
    @PostMapping("updateConfig")
    public BaseResultEntity updateConfig(@RequestBody Map<String, Object> data) {
        return projectResultService.updateResultConfig(data);
    }
}
