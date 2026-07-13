package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.sys.MonitorService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Api(value = "监控管理接口", tags = "监控管理接口")
@RequestMapping("monitor")
@RestController
public class MonitorController {

    @Autowired
    private MonitorService monitorService;

    @ApiOperation(value = "获取系统监控数据")
    @GetMapping("getSystemMonitor")
    public BaseResultEntity getSystemMonitor() {
        return monitorService.getSystemMonitor();
    }

    @ApiOperation(value = "获取CPU监控数据")
    @GetMapping("getCpuMonitor")
    public BaseResultEntity getCpuMonitor() {
        return monitorService.getCpuMonitor();
    }

    @ApiOperation(value = "获取内存监控数据")
    @GetMapping("getMemoryMonitor")
    public BaseResultEntity getMemoryMonitor() {
        return monitorService.getMemoryMonitor();
    }

    @ApiOperation(value = "获取磁盘监控数据")
    @GetMapping("getDiskMonitor")
    public BaseResultEntity getDiskMonitor() {
        return monitorService.getDiskMonitor();
    }

    @ApiOperation(value = "获取数据库监控数据")
    @GetMapping("getDatabaseMonitor")
    public BaseResultEntity getDatabaseMonitor() {
        return monitorService.getDatabaseMonitor();
    }

    @ApiOperation(value = "获取JVM监控数据")
    @GetMapping("getJvmMonitor")
    public BaseResultEntity getJvmMonitor() {
        return monitorService.getJvmMonitor();
    }

    @ApiOperation(value = "获取Redis监控数据")
    @GetMapping("getRedisMonitor")
    public BaseResultEntity getRedisMonitor() {
        return monitorService.getRedisMonitor();
    }

    @ApiOperation(value = "获取监控历史数据")
    @GetMapping("getMonitorHistory")
    public BaseResultEntity getMonitorHistory(
            @RequestParam String type,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        return monitorService.getMonitorHistory(type, startTime, endTime);
    }

    @ApiOperation(value = "获取告警配置")
    @GetMapping("getAlertConfig")
    public BaseResultEntity getAlertConfig(@RequestParam(required = false) String type) {
        return monitorService.getAlertConfig(type);
    }

    @ApiOperation(value = "保存告警配置")
    @PostMapping("saveAlertConfig")
    public BaseResultEntity saveAlertConfig(@RequestBody Map<String, Object> data) {
        return monitorService.saveAlertConfig(data);
    }

    @ApiOperation(value = "获取告警历史")
    @GetMapping("getAlertHistory")
    public BaseResultEntity getAlertHistory(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return monitorService.getAlertHistory(pageNum, pageSize);
    }

    @ApiOperation(value = "处理告警")
    @PostMapping("handleAlert")
    public BaseResultEntity handleAlert(@RequestBody Map<String, Object> data) {
        return monitorService.handleAlert(data);
    }

    @ApiOperation(value = "获取监控统计数据")
    @GetMapping("getMonitorStatistics")
    public BaseResultEntity getMonitorStatistics() {
        return monitorService.getMonitorStatistics();
    }
}
