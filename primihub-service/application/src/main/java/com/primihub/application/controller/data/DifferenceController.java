package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataDifferenceReq;
import com.primihub.biz.service.data.DataDifferenceService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

/**
 * 联邦求差接口
 */
@Api(value = "联邦求差接口", tags = "联邦求差接口")
@RequestMapping("difference")
@RestController
@Slf4j
public class DifferenceController {

    @Autowired
    private DataDifferenceService dataDifferenceService;

    /**
     * 创建并运行联邦求差任务
     */
    @ApiOperation(value = "创建并运行联邦求差任务")
    @PostMapping("saveDataDifference")
    public BaseResultEntity saveDataDifference(@RequestHeader("userId") Long userId,
                                                @RequestBody DataDifferenceReq req) {
        if (userId <= 0) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "userId");
        }
        if (req.getOwnOrganId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ownOrganId");
        }
        if (StringUtils.isBlank(req.getOwnResourceId())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ownResourceId");
        }
        if (StringUtils.isBlank(req.getOwnKeyword())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ownKeyword");
        }
        if (req.getOtherOrganId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "otherOrganId");
        }
        if (req.getOtherResourceId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "otherResourceId");
        }
        if (StringUtils.isBlank(req.getOtherKeyword())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "otherKeyword");
        }
        if (StringUtils.isBlank(req.getResultName())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resultName");
        }
        if (StringUtils.isBlank(req.getResultOrganIds())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resultOrganIds");
        }
        if (req.getTag() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "tag");
        }
        if (req.getDifferenceDirection() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "differenceDirection");
        }
        return dataDifferenceService.saveDataDifference(req, userId);
    }

    /**
     * 查询联邦求差任务列表
     */
    @ApiOperation(value = "查询联邦求差任务列表")
    @GetMapping("getDifferenceTaskList")
    public BaseResultEntity getDifferenceTaskList(
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) Integer taskState,
            @RequestParam(required = false) String organId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "1") Integer pageNo,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return dataDifferenceService.getDifferenceTaskList(taskName, taskState, organId, startDate, endDate, pageNo, pageSize);
    }

    /**
     * 查询联邦求差任务详情
     */
    @ApiOperation(value = "查询联邦求差任务详情")
    @GetMapping("getDifferenceTaskDetails")
    public BaseResultEntity getDifferenceTaskDetails(@RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return dataDifferenceService.getDifferenceTaskDetails(taskId);
    }

    /**
     * 下载联邦求差结果文件
     */
    @ApiOperation(value = "下载联邦求差结果文件")
    @GetMapping("downloadDifferenceTask")
    public void downloadDifferenceTask(HttpServletResponse response, @RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return;
        }
        dataDifferenceService.downloadDifferenceTask(response, taskId);
    }

    /**
     * 删除联邦求差任务
     */
    @ApiOperation(value = "删除联邦求差任务")
    @GetMapping("delDifferenceTask")
    public BaseResultEntity delDifferenceTask(@RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return dataDifferenceService.delDifferenceTask(taskId);
    }

    /**
     * 取消联邦求差任务
     */
    @ApiOperation(value = "取消联邦求差任务")
    @GetMapping("cancelDifferenceTask")
    public BaseResultEntity cancelDifferenceTask(@RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return dataDifferenceService.cancelDifferenceTask(taskId);
    }
}
