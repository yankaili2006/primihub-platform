package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.po.*;
import com.primihub.biz.service.sys.LogManagementService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

/**
 * 日志管理Controller
 */
@Api(value = "日志管理接口", tags = "日志管理接口")
@RequestMapping("log")
@RestController
public class LogManagementController {

    @Autowired
    private LogManagementService logManagementService;

    // ========== 操作日志定义 ==========

    @ApiOperation(value = "查询操作日志定义分页列表")
    @GetMapping("findOperationLogDefinitionPage")
    public BaseResultEntity findOperationLogDefinitionPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String logType,
            @RequestParam(required = false) String moduleName,
            @RequestParam(required = false) Integer isEnabled,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return logManagementService.findOperationLogDefinitionPage(keyword, logType, moduleName, isEnabled, pageNum, pageSize);
    }

    @ApiOperation(value = "添加操作日志定义")
    @PostMapping("addOperationLogDefinition")
    public BaseResultEntity addOperationLogDefinition(@RequestBody OperationLogDefinition definition) {
        if (definition == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.addOperationLogDefinition(definition);
    }

    @ApiOperation(value = "更新操作日志定义")
    @PostMapping("updateOperationLogDefinition")
    public BaseResultEntity updateOperationLogDefinition(@RequestBody OperationLogDefinition definition) {
        if (definition == null || definition.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.updateOperationLogDefinition(definition);
    }

    @ApiOperation(value = "删除操作日志定义")
    @PostMapping("deleteOperationLogDefinition")
    public BaseResultEntity deleteOperationLogDefinition(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.deleteOperationLogDefinition(id);
    }

    @ApiOperation(value = "更新操作日志定义状态")
    @PostMapping("updateOperationLogDefinitionStatus")
    public BaseResultEntity updateOperationLogDefinitionStatus(@RequestParam Long id, @RequestParam Integer isEnabled) {
        if (id == null || isEnabled == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.updateOperationLogDefinitionStatus(id, isEnabled);
    }

    // ========== 调度日志定义 ==========

    @ApiOperation(value = "查询调度日志定义分页列表")
    @GetMapping("findScheduleLogDefinitionPage")
    public BaseResultEntity findScheduleLogDefinitionPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String scheduleType,
            @RequestParam(required = false) String moduleName,
            @RequestParam(required = false) Integer isEnabled,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return logManagementService.findScheduleLogDefinitionPage(keyword, scheduleType, moduleName, isEnabled, pageNum, pageSize);
    }

    @ApiOperation(value = "添加调度日志定义")
    @PostMapping("addScheduleLogDefinition")
    public BaseResultEntity addScheduleLogDefinition(@RequestBody ScheduleLogDefinition definition) {
        if (definition == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.addScheduleLogDefinition(definition);
    }

    @ApiOperation(value = "更新调度日志定义")
    @PostMapping("updateScheduleLogDefinition")
    public BaseResultEntity updateScheduleLogDefinition(@RequestBody ScheduleLogDefinition definition) {
        if (definition == null || definition.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.updateScheduleLogDefinition(definition);
    }

    @ApiOperation(value = "删除调度日志定义")
    @PostMapping("deleteScheduleLogDefinition")
    public BaseResultEntity deleteScheduleLogDefinition(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.deleteScheduleLogDefinition(id);
    }

    // ========== 计算日志定义 ==========

    @ApiOperation(value = "查询计算日志定义分页列表")
    @GetMapping("findComputeLogDefinitionPage")
    public BaseResultEntity findComputeLogDefinitionPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String computeType,
            @RequestParam(required = false) String moduleName,
            @RequestParam(required = false) Integer isEnabled,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return logManagementService.findComputeLogDefinitionPage(keyword, computeType, moduleName, isEnabled, pageNum, pageSize);
    }

    @ApiOperation(value = "添加计算日志定义")
    @PostMapping("addComputeLogDefinition")
    public BaseResultEntity addComputeLogDefinition(@RequestBody ComputeLogDefinition definition) {
        if (definition == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.addComputeLogDefinition(definition);
    }

    @ApiOperation(value = "更新计算日志定义")
    @PostMapping("updateComputeLogDefinition")
    public BaseResultEntity updateComputeLogDefinition(@RequestBody ComputeLogDefinition definition) {
        if (definition == null || definition.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.updateComputeLogDefinition(definition);
    }

    @ApiOperation(value = "删除计算日志定义")
    @PostMapping("deleteComputeLogDefinition")
    public BaseResultEntity deleteComputeLogDefinition(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return logManagementService.deleteComputeLogDefinition(id);
    }

    // ========== 操作日志记录 ==========

    @ApiOperation(value = "查询操作日志记录分页列表")
    @GetMapping("findOperationLogPage")
    public BaseResultEntity findOperationLogPage(
            @RequestParam(required = false) String logCode,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) String operationType,
            @RequestParam(required = false) String operationModule,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return logManagementService.findOperationLogPage(logCode, userId, userName, operationType, operationModule,
                                                         status, startTime, endTime, pageNum, pageSize);
    }

    @ApiOperation(value = "导出操作日志")
    @GetMapping("exportOperationLog")
    public void exportOperationLog(
            HttpServletResponse response,
            @RequestParam(required = false) String logCode,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) String operationType,
            @RequestParam(required = false) String operationModule,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        logManagementService.exportOperationLog(response, logCode, userId, userName, operationType, operationModule,
                                                status, startTime, endTime);
    }

    // ========== 调度日志记录 ==========

    @ApiOperation(value = "查询调度日志记录分页列表")
    @GetMapping("findScheduleLogPage")
    public BaseResultEntity findScheduleLogPage(
            @RequestParam(required = false) String logCode,
            @RequestParam(required = false) String scheduleName,
            @RequestParam(required = false) String scheduleType,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return logManagementService.findScheduleLogPage(logCode, scheduleName, scheduleType,
                                                        status, startTime, endTime, pageNum, pageSize);
    }

    @ApiOperation(value = "导出调度日志")
    @GetMapping("exportScheduleLog")
    public void exportScheduleLog(
            HttpServletResponse response,
            @RequestParam(required = false) String logCode,
            @RequestParam(required = false) String scheduleName,
            @RequestParam(required = false) String scheduleType,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        logManagementService.exportScheduleLog(response, logCode, scheduleName, scheduleType,
                                               status, startTime, endTime);
    }

    // ========== 计算日志记录 ==========

    @ApiOperation(value = "查询计算日志记录分页列表")
    @GetMapping("findComputeLogPage")
    public BaseResultEntity findComputeLogPage(
            @RequestParam(required = false) String logCode,
            @RequestParam(required = false) String taskId,
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) String computeType,
            @RequestParam(required = false) Long projectId,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return logManagementService.findComputeLogPage(logCode, taskId, taskName, computeType, projectId, userId,
                                                       status, startTime, endTime, pageNum, pageSize);
    }

    @ApiOperation(value = "导出计算日志")
    @GetMapping("exportComputeLog")
    public void exportComputeLog(
            HttpServletResponse response,
            @RequestParam(required = false) String logCode,
            @RequestParam(required = false) String taskId,
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) String computeType,
            @RequestParam(required = false) Long projectId,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        logManagementService.exportComputeLog(response, logCode, taskId, taskName, computeType, projectId, userId,
                                              status, startTime, endTime);
    }
}
