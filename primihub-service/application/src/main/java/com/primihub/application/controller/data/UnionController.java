package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataUnionReq;
import com.primihub.biz.service.data.DataUnionService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;

/**
 * 联邦求并接口
 */
@Api(value = "联邦求并接口", tags = "联邦求并接口")
@RequestMapping("union")
@RestController
@Slf4j
public class UnionController {

    @Autowired
    private DataUnionService dataUnionService;

    /**
     * 创建并运行联邦求并任务
     */
    @ApiOperation(value = "创建并运行联邦求并任务")
    @PostMapping("saveDataUnion")
    public BaseResultEntity saveDataUnion(@RequestHeader("userId") Long userId,
                                          @RequestBody DataUnionReq req) {
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
        return dataUnionService.saveDataUnion(req, userId);
    }

    /**
     * 查询联邦求并任务列表
     */
    @ApiOperation(value = "查询联邦求并任务列表")
    @GetMapping("getUnionTaskList")
    public BaseResultEntity getUnionTaskList(
            @RequestParam(required = false) String taskName,
            @RequestParam(required = false) Integer taskState,
            @RequestParam(required = false) String organId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "1") Integer pageNo,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return dataUnionService.getUnionTaskList(taskName, taskState, organId, startDate, endDate, pageNo, pageSize);
    }

    /**
     * 查询联邦求并任务详情
     */
    @ApiOperation(value = "查询联邦求并任务详情")
    @GetMapping("getUnionTaskDetails")
    public BaseResultEntity getUnionTaskDetails(@RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return dataUnionService.getUnionTaskDetails(taskId);
    }

    /**
     * 下载联邦求并结果文件
     */
    @ApiOperation(value = "下载联邦求并结果文件")
    @GetMapping("downloadUnionTask")
    public void downloadUnionTask(HttpServletResponse response, @RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return;
        }
        dataUnionService.downloadUnionTask(response, taskId);
    }

    /**
     * 删除联邦求并任务
     */
    @ApiOperation(value = "删除联邦求并任务")
    @GetMapping("delUnionTask")
    public BaseResultEntity delUnionTask(@RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return dataUnionService.delUnionTask(taskId);
    }

    /**
     * 取消联邦求并任务
     */
    @ApiOperation(value = "取消联邦求并任务")
    @GetMapping("cancelUnionTask")
    public BaseResultEntity cancelUnionTask(@RequestParam Long taskId) {
        if (taskId == null || taskId == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
        }
        return dataUnionService.cancelUnionTask(taskId);
    }

    @ApiOperation(value = "导出联邦求并日志")
    @GetMapping("exportUnionLog")
    public void exportUnionLog(HttpServletResponse response, @RequestParam(required = false) Long taskId) {
        try {
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                java.net.URLEncoder.encode("union_log.txt", "UTF-8"));
            response.getOutputStream().write(("联邦求并日志 - 任务ID: " + taskId).getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("导出联邦求并日志失败", e);
        }
    }
}
