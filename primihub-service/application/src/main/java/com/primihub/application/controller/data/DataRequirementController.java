package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.po.DataRequirement;
import com.primihub.biz.entity.data.po.DataRequirementConfig;
import com.primihub.biz.service.data.DataRequirementService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 数据需求管理Controller
 */
@Slf4j
@Api(tags = "数据需求管理")
@RestController
@RequestMapping("/dataRequirement")
public class DataRequirementController {

    @Autowired
    private DataRequirementService dataRequirementService;

    // ========== 数据需求 CRUD ==========

    /**
     * 查询数据需求分页列表
     */
    @ApiOperation(value = "查询数据需求分页列表")
    @GetMapping("findDataRequirementPage")
    public BaseResultEntity findDataRequirementPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("需求类型") @RequestParam(required = false) String requirementType,
            @ApiParam("优先级") @RequestParam(required = false) Integer priority,
            @ApiParam("状态") @RequestParam(required = false) Integer status,
            @ApiParam("用户ID") @RequestParam(required = false) Long userId,
            @ApiParam("机构ID") @RequestParam(required = false) Long organId,
            @ApiParam("开始日期") @RequestParam(required = false) String startDate,
            @ApiParam("结束日期") @RequestParam(required = false) String endDate,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return dataRequirementService.findDataRequirementPage(keyword, requirementType, priority, status,
                userId, organId, startDate, endDate, pageNum, pageSize);
    }

    /**
     * 根据ID查询数据需求
     */
    @ApiOperation(value = "根据ID查询数据需求")
    @GetMapping("getDataRequirementById")
    public BaseResultEntity getDataRequirementById(
            @ApiParam("需求ID") @RequestParam Long id) {
        return dataRequirementService.getDataRequirementById(id);
    }

    /**
     * 添加数据需求
     */
    @ApiOperation(value = "添加数据需求")
    @PostMapping("addDataRequirement")
    public BaseResultEntity addDataRequirement(@RequestBody DataRequirement dataRequirement,
            @RequestHeader(value = "userId", required = false) Long userId) {
        // user_id 是 NOT NULL 但前端不传、service 也不设 → 插入必失败(#26)。从鉴权头补上。
        if (userId != null && dataRequirement.getUserId() == null) {
            dataRequirement.setUserId(userId);
        }
        return dataRequirementService.addDataRequirement(dataRequirement);
    }

    /**
     * 更新数据需求
     */
    @ApiOperation(value = "更新数据需求")
    @PostMapping("updateDataRequirement")
    public BaseResultEntity updateDataRequirement(@RequestBody DataRequirement dataRequirement) {
        return dataRequirementService.updateDataRequirement(dataRequirement);
    }

    /**
     * 删除数据需求
     */
    @ApiOperation(value = "删除数据需求")
    @PostMapping("deleteDataRequirement")
    public BaseResultEntity deleteDataRequirement(@RequestParam Long id) {
        return dataRequirementService.deleteDataRequirement(id);
    }

    /**
     * 批量删除数据需求
     */
    @ApiOperation(value = "批量删除数据需求")
    @PostMapping("batchDeleteDataRequirement")
    public BaseResultEntity batchDeleteDataRequirement(@RequestBody List<Long> ids) {
        return dataRequirementService.batchDeleteDataRequirement(ids);
    }

    // ========== 数据需求配置 CRUD ==========

    /**
     * 查询配置分页列表
     */
    @ApiOperation(value = "查询配置分页列表")
    @GetMapping("findConfigPage")
    public BaseResultEntity findConfigPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("配置类型") @RequestParam(required = false) String configType,
            @ApiParam("启用状态") @RequestParam(required = false) Integer isEnabled,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return dataRequirementService.findConfigPage(keyword, configType, isEnabled, pageNum, pageSize);
    }

    /**
     * 添加配置
     */
    @ApiOperation(value = "添加配置")
    @PostMapping("addConfig")
    public BaseResultEntity addConfig(@RequestBody DataRequirementConfig config) {
        return dataRequirementService.addConfig(config);
    }

    /**
     * 更新配置
     */
    @ApiOperation(value = "更新配置")
    @PostMapping("updateConfig")
    public BaseResultEntity updateConfig(@RequestBody DataRequirementConfig config) {
        return dataRequirementService.updateConfig(config);
    }

    /**
     * 删除配置
     */
    @ApiOperation(value = "删除配置")
    @PostMapping("deleteConfig")
    public BaseResultEntity deleteConfig(@RequestParam Long id) {
        return dataRequirementService.deleteConfig(id);
    }

    /**
     * 更新配置启用状态
     */
    @ApiOperation(value = "更新配置启用状态")
    @PostMapping("updateConfigStatus")
    public BaseResultEntity updateConfigStatus(
            @ApiParam("配置ID") @RequestParam Long id,
            @ApiParam("启用状态") @RequestParam Integer isEnabled) {
        return dataRequirementService.updateConfigStatus(id, isEnabled);
    }

    // ========== 数据需求匹配功能 ==========

    /**
     * 执行数据需求匹配
     */
    @ApiOperation(value = "执行数据需求匹配")
    @PostMapping("matchDataRequirements")
    public BaseResultEntity matchDataRequirements(@RequestParam Long requirementId) {
        return dataRequirementService.matchDataRequirements(requirementId);
    }

    /**
     * 查询匹配的资源列表
     */
    @ApiOperation(value = "查询匹配的资源列表")
    @GetMapping("findMatchedResources")
    public BaseResultEntity findMatchedResources(
            @ApiParam("需求ID") @RequestParam Long requirementId,
            @ApiParam("匹配状态") @RequestParam(required = false) Integer matchStatus,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return dataRequirementService.findMatchedResources(requirementId, matchStatus, pageNum, pageSize);
    }

    /**
     * 确认匹配
     */
    @ApiOperation(value = "确认匹配")
    @PostMapping("confirmMatch")
    public BaseResultEntity confirmMatch(
            @ApiParam("匹配ID") @RequestParam Long matchId,
            @ApiParam("确认人用户ID") @RequestParam Long confirmUserId,
            @ApiParam("确认人用户名") @RequestParam String confirmUserName) {
        return dataRequirementService.confirmMatch(matchId, confirmUserId, confirmUserName);
    }

    /**
     * 拒绝匹配
     */
    @ApiOperation(value = "拒绝匹配")
    @PostMapping("rejectMatch")
    public BaseResultEntity rejectMatch(
            @ApiParam("匹配ID") @RequestParam Long matchId,
            @ApiParam("确认人用户ID") @RequestParam Long confirmUserId,
            @ApiParam("确认人用户名") @RequestParam String confirmUserName) {
        return dataRequirementService.rejectMatch(matchId, confirmUserId, confirmUserName);
    }
}
