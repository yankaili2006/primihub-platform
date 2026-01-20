package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.po.SharedDataset;
import com.primihub.biz.service.data.SharedDatasetService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 共享数据集管理Controller
 */
@Slf4j
@Api(tags = "共享数据集管理")
@RestController
@RequestMapping("/sharedDataset")
public class SharedDatasetController {

    @Autowired
    private SharedDatasetService sharedDatasetService;

    // ========== 共享数据集 CRUD ==========

    /**
     * 查询共享数据集分页列表
     */
    @ApiOperation(value = "查询共享数据集分页列表")
    @GetMapping("findSharedDatasetPage")
    public BaseResultEntity findSharedDatasetPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("数据类型") @RequestParam(required = false) String dataType,
            @ApiParam("共享状态") @RequestParam(required = false) Integer shareStatus,
            @ApiParam("用户ID") @RequestParam(required = false) Long userId,
            @ApiParam("机构ID") @RequestParam(required = false) Long organId,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return sharedDatasetService.findSharedDatasetPage(keyword, dataType, shareStatus,
                userId, organId, pageNum, pageSize);
    }

    /**
     * 根据ID查询共享数据集
     */
    @ApiOperation(value = "根据ID查询共享数据集")
    @GetMapping("getSharedDatasetById")
    public BaseResultEntity getSharedDatasetById(
            @ApiParam("数据集ID") @RequestParam Long id) {
        return sharedDatasetService.getSharedDatasetById(id);
    }

    /**
     * 添加共享数据集
     */
    @ApiOperation(value = "添加共享数据集")
    @PostMapping("addSharedDataset")
    public BaseResultEntity addSharedDataset(@RequestBody SharedDataset sharedDataset) {
        return sharedDatasetService.addSharedDataset(sharedDataset);
    }

    /**
     * 更新共享数据集
     */
    @ApiOperation(value = "更新共享数据集")
    @PostMapping("updateSharedDataset")
    public BaseResultEntity updateSharedDataset(@RequestBody SharedDataset sharedDataset) {
        return sharedDatasetService.updateSharedDataset(sharedDataset);
    }

    /**
     * 删除共享数据集
     */
    @ApiOperation(value = "删除共享数据集")
    @PostMapping("deleteSharedDataset")
    public BaseResultEntity deleteSharedDataset(@RequestParam Long id) {
        return sharedDatasetService.deleteSharedDataset(id);
    }

    /**
     * 批量删除共享数据集
     */
    @ApiOperation(value = "批量删除共享数据集")
    @PostMapping("batchDeleteSharedDataset")
    public BaseResultEntity batchDeleteSharedDataset(@RequestBody List<Long> ids) {
        return sharedDatasetService.batchDeleteSharedDataset(ids);
    }

    /**
     * 更新共享数据集状态
     */
    @ApiOperation(value = "更新共享数据集状态")
    @PostMapping("updateSharedDatasetStatus")
    public BaseResultEntity updateSharedDatasetStatus(
            @ApiParam("数据集ID") @RequestParam Long id,
            @ApiParam("状态") @RequestParam Integer status) {
        return sharedDatasetService.updateSharedDatasetStatus(id, status);
    }

    /**
     * 获取可共享的资源列表
     */
    @ApiOperation(value = "获取可共享的资源列表")
    @GetMapping("getShareableResources")
    public BaseResultEntity getShareableResources(
            @ApiParam("机构ID") @RequestParam(required = false) Long organId) {
        return sharedDatasetService.getShareableResources(organId);
    }
}
