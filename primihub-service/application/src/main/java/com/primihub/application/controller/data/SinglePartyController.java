package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.SinglePartyReq;
import com.primihub.biz.service.data.SinglePartyService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

@Api(value = "单方算法接口", tags = "单方算法接口")
@RequestMapping("singleParty")
@RestController
@Slf4j
public class SinglePartyController {

    @Autowired
    private SinglePartyService singlePartyService;

    @ApiOperation(value = "创建并运行单方算法任务")
    @PostMapping("createTask")
    public BaseResultEntity createTask(@RequestHeader("userId") Long userId,
                                       @RequestBody SinglePartyReq req) {
        if (userId <= 0) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "userId");
        }
        if (req.getAlgorithmType() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "algorithmType");
        }
        if (StringUtils.isBlank(req.getTaskName())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskName");
        }
        if (StringUtils.isBlank(req.getResourceId())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resourceId");
        }

        return singlePartyService.createTask(req, userId);
    }

    @ApiOperation(value = "查询单方算法任务列表")
    @GetMapping("getTaskList")
    public BaseResultEntity getTaskList(
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) Integer algorithmType,
            @RequestParam(required = false) Integer taskState,
            @RequestParam(required = false) Long projectId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "1") Integer pageNo,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return singlePartyService.getTaskList(taskName, algorithmType, taskState,
                projectId, startDate, endDate, pageNo, pageSize);
    }

    @ApiOperation(value = "查询单方算法任务详情")
    @GetMapping("getTaskDetails")
    public BaseResultEntity getTaskDetails(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return singlePartyService.getTaskDetails(taskId);
    }

    @ApiOperation(value = "下载结果")
    @GetMapping("downloadResult")
    public void downloadResult(HttpServletResponse response, @RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return;
        }
        singlePartyService.downloadResult(response, taskId);
    }

    @ApiOperation(value = "删除任务")
    @GetMapping("deleteTask")
    public BaseResultEntity deleteTask(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return singlePartyService.deleteTask(taskId);
    }

    @ApiOperation(value = "取消任务")
    @GetMapping("cancelTask")
    public BaseResultEntity cancelTask(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return singlePartyService.cancelTask(taskId);
    }
}
