package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.ProjectLedgerService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.List;
import java.util.Map;

/**
 * 项目台账管理 Controller。
 * 前端 projectLedger.js 调 /prod-api/project/ledger/*，nginx 仅剥 /prod-api → 应用侧映射 project/ledger。
 * （原后端完全无此模块，整页 8 接口 404；本类补齐真实实现。）
 */
@Api(tags = "项目台账管理")
@RestController
@RequestMapping("project/ledger")
public class ProjectLedgerController {

    @Autowired
    private ProjectLedgerService projectLedgerService;

    @ApiOperation("查询项目台账分页列表")
    @GetMapping("findPage")
    public BaseResultEntity findPage(
            @RequestParam(required = false) String projectName,
            @RequestParam(required = false) Integer projectStatus,
            @RequestParam(required = false) List<String> dateRange,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        // 前端传 dateRange=[start,end]；兼容也接受独立 startDate/endDate
        if (dateRange != null && dateRange.size() >= 2) {
            startDate = dateRange.get(0);
            endDate = dateRange.get(1);
        }
        return projectLedgerService.findProjectLedgerPage(projectName, projectStatus, startDate, endDate, pageNum, pageSize);
    }

    @ApiOperation("获取项目台账详情")
    @GetMapping("getDetail")
    public BaseResultEntity getDetail(@RequestParam String projectId) {
        return projectLedgerService.getProjectLedgerDetail(projectId);
    }

    @ApiOperation("导出单个项目台账")
    @PostMapping("export")
    @SuppressWarnings("unchecked")
    public BaseResultEntity export(@RequestBody(required = false) Map<String, Object> body,
                                   @RequestHeader(value = "userId", required = false) Long userId) {
        String type = body == null ? "SINGLE" : str(body.getOrDefault("exportType", "SINGLE"));
        String format = body == null ? "CSV" : str(body.get("exportFormat"));
        List<String> ids = body == null ? null : (List<String>) body.get("projectIds");
        return projectLedgerService.createExport(type, format, ids, userId, null);
    }

    @ApiOperation("批量导出项目台账")
    @PostMapping("batchExport")
    @SuppressWarnings("unchecked")
    public BaseResultEntity batchExport(@RequestBody(required = false) Map<String, Object> body,
                                        @RequestHeader(value = "userId", required = false) Long userId) {
        String format = body == null ? "CSV" : str(body.get("exportFormat"));
        List<String> ids = body == null ? null : (List<String>) body.get("projectIds");
        return projectLedgerService.createExport("BATCH", format, ids, userId, null);
    }

    @ApiOperation("导出全部项目台账")
    @PostMapping("exportAll")
    public BaseResultEntity exportAll(@RequestBody(required = false) Map<String, Object> body,
                                      @RequestHeader(value = "userId", required = false) Long userId) {
        String format = body == null ? "CSV" : str(body.get("exportFormat"));
        return projectLedgerService.createExport("ALL", format, null, userId, null);
    }

    @ApiOperation("获取导出历史记录")
    @GetMapping("getExportHistory")
    public BaseResultEntity getExportHistory(
            @RequestHeader(value = "userId", required = false) Long userId) {
        // 历史对所有人可见（不按 user 过滤），传 null
        return projectLedgerService.getExportHistory(null);
    }

    @ApiOperation("下载导出文件")
    @GetMapping("downloadExportFile")
    public void downloadExportFile(@RequestParam Long exportId, HttpServletResponse response) {
        projectLedgerService.downloadExportFile(exportId, response);
    }

    @ApiOperation("重试导出")
    @PostMapping("retryExport")
    public BaseResultEntity retryExport(@RequestParam Long exportId,
                                        @RequestHeader(value = "userId", required = false) Long userId) {
        return projectLedgerService.retryExport(exportId, userId, null);
    }

    private String str(Object o) {
        return o == null ? null : String.valueOf(o);
    }
}
