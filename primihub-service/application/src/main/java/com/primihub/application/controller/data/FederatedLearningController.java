package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.FederatedLearningReq;
import com.primihub.biz.service.data.FederatedLearningService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

/**
 * 联邦学习接口
 */
@Api(value = "联邦学习接口", tags = "联邦学习接口")
@RequestMapping("federatedLearning")
@RestController
@Slf4j
public class FederatedLearningController {

    @Autowired
    private FederatedLearningService federatedLearningService;

    /**
     * 创建并运行联邦学习任务
     */
    @ApiOperation(value = "创建并运行联邦学习任务")
    @PostMapping("createTask")
    public BaseResultEntity createTask(@RequestHeader("userId") Long userId,
                                       @RequestBody FederatedLearningReq req) {
        if (userId <= 0) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "userId");
        }
        if (req.getTaskType() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskType");
        }
        if (req.getAlgorithmType() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "algorithmType");
        }
        if (req.getFederatedType() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "federatedType");
        }
        if (StringUtils.isBlank(req.getTaskName())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskName");
        }
        if (StringUtils.isBlank(req.getOwnOrganId())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ownOrganId");
        }
        if (StringUtils.isBlank(req.getOwnResourceId())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ownResourceId");
        }
        if (StringUtils.isBlank(req.getParticipantOrganIds())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "participantOrganIds");
        }

        // 预测任务需要模型ID
        if (req.getTaskType() == 2 && StringUtils.isBlank(req.getModelId())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "modelId");
        }

        return federatedLearningService.createTask(req, userId);
    }

    /**
     * 查询联邦学习任务列表
     */
    @ApiOperation(value = "查询联邦学习任务列表")
    @GetMapping("getTaskList")
    public BaseResultEntity getTaskList(
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) Integer taskType,
            @RequestParam(required = false) Integer algorithmType,
            @RequestParam(required = false) Integer taskState,
            @RequestParam(required = false) Long projectId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "1") Integer pageNo,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return federatedLearningService.getTaskList(taskName, taskType, algorithmType,
                taskState, projectId, startDate, endDate, pageNo, pageSize);
    }

    /**
     * 查询联邦学习任务详情
     */
    @ApiOperation(value = "查询联邦学习任务详情")
    @GetMapping("getTaskDetails")
    public BaseResultEntity getTaskDetails(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return federatedLearningService.getTaskDetails(taskId);
    }

    /**
     * 查询模型列表
     */
    @ApiOperation(value = "查询模型列表")
    @GetMapping("getModelList")
    public BaseResultEntity getModelList(
            @RequestParam(required = false) Integer algorithmType,
            @RequestParam(required = false) Long projectId,
            @RequestParam(defaultValue = "1") Integer pageNo,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return federatedLearningService.getModelList(algorithmType, projectId, pageNo, pageSize);
    }

    /**
     * 下载模型文件
     */
    @ApiOperation(value = "下载模型文件")
    @GetMapping("downloadModel")
    public void downloadModel(HttpServletResponse response, @RequestParam String modelId) {
        if (StringUtils.isBlank(modelId)) {
            return;
        }
        federatedLearningService.downloadModel(response, modelId);
    }

    /**
     * 下载预测结果
     */
    @ApiOperation(value = "下载预测结果")
    @GetMapping("downloadResult")
    public void downloadResult(HttpServletResponse response, @RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return;
        }
        federatedLearningService.downloadResult(response, taskId);
    }

    /**
     * 删除任务
     */
    @ApiOperation(value = "删除任务")
    @GetMapping("deleteTask")
    public BaseResultEntity deleteTask(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return federatedLearningService.deleteTask(taskId);
    }

    /**
     * 取消任务
     */
    @ApiOperation(value = "取消任务")
    @GetMapping("cancelTask")
    public BaseResultEntity cancelTask(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return federatedLearningService.cancelTask(taskId);
    }

    /**
     * 获取训练进度
     */
    @ApiOperation(value = "获取训练进度")
    @GetMapping("getTrainingProgress")
    public BaseResultEntity getTrainingProgress(@RequestParam String taskId) {
        if (StringUtils.isBlank(taskId)) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return federatedLearningService.getTrainingProgress(taskId);
    }
}
