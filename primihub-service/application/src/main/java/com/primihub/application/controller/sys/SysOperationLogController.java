package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.param.FindOperationLogPageParam;
import com.primihub.biz.service.sys.SysOperationLogService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

/**
 * 系统操作日志控制器
 */
@Api(value = "操作日志接口", tags = "操作日志管理")
@RequestMapping("sys/operationLog")
@RestController
public class SysOperationLogController {

    @Autowired
    private SysOperationLogService operationLogService;

    /**
     * 分页查询操作日志
     *
     * @param param 查询参数
     * @return 分页结果
     */
    @ApiOperation("分页查询操作日志")
    @PostMapping("getOperationLogPage")
    public BaseResultEntity getOperationLogPage(@RequestBody FindOperationLogPageParam param) {
        return operationLogService.findOperationLogPage(param);
    }

    /**
     * 获取操作日志详情
     *
     * @param logId 日志ID
     * @return 日志详情
     */
    @ApiOperation("获取操作日志详情")
    @GetMapping("getOperationLogDetail")
    public BaseResultEntity getOperationLogDetail(@RequestParam Long logId) {
        return operationLogService.getOperationLogDetail(logId);
    }

    /**
     * 导出操作日志
     *
     * @param param    查询参数
     * @param response HTTP响应
     */
    @ApiOperation("导出操作日志")
    @PostMapping("exportOperationLog")
    public void exportOperationLog(@RequestBody FindOperationLogPageParam param,
                                    HttpServletResponse response) {
        operationLogService.exportOperationLog(param, response);
    }

    /**
     * 删除操作日志
     *
     * @param logId  日志ID
     * @param userId 用户ID（从请求头获取）
     * @return 操作结果
     */
    @ApiOperation("删除操作日志")
    @DeleteMapping("deleteOperationLog")
    public BaseResultEntity deleteOperationLog(
            @RequestParam Long logId,
            @RequestHeader(value = "userId", required = false) Long userId) {
        return operationLogService.deleteOperationLog(logId, userId);
    }

    /**
     * 获取操作日志统计
     *
     * @param param 查询参数
     * @return 统计信息
     */
    @ApiOperation("获取操作日志统计")
    @PostMapping("getOperationLogStatistics")
    public BaseResultEntity getOperationLogStatistics(@RequestBody FindOperationLogPageParam param) {
        return operationLogService.getOperationLogStatistics(param);
    }
}
