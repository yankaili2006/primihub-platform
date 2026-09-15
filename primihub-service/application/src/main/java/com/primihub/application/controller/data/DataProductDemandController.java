package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.po.DataProductDemand;
import com.primihub.biz.service.data.DataProductDemandService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 数据产品需求Controller
 */
@Slf4j
@Api(tags = "数据产品需求管理")
@RestController
@RequestMapping("/api/v2/service/demand")
public class DataProductDemandController {

    @Autowired
    private DataProductDemandService demandService;

    /**
     * 查询需求列表
     */
    @ApiOperation(value = "查询需求列表")
    @GetMapping("/list")
    public BaseResultEntity list(
            @ApiParam("需求名称") @RequestParam(required = false) String demandName,
            @ApiParam("需求类型") @RequestParam(required = false) String demandType,
            @ApiParam("状态") @RequestParam(required = false) String status,
            @ApiParam("机构ID") @RequestParam(required = false) Long organId,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return demandService.findDemandPage(demandName, demandType, status, organId, pageNum, pageSize);
    }

    /**
     * 根据ID查询需求
     */
    @ApiOperation(value = "根据ID查询需求")
    @GetMapping("/{id}")
    public BaseResultEntity getById(@PathVariable Long id) {
        return demandService.findDemandById(id);
    }

    /**
     * 新增需求
     */
    @ApiOperation(value = "新增需求")
    @PostMapping
    public BaseResultEntity add(@RequestBody DataProductDemand demand,
                               @RequestHeader(value = "userId", required = false) Long userId) {
        if (userId != null && demand.getCreatedBy() == null) {
            demand.setCreatedBy(userId);
        }
        return demandService.saveDemand(demand);
    }

    /**
     * 更新需求
     */
    @ApiOperation(value = "更新需求")
    @PutMapping("/{id}")
    public BaseResultEntity update(@PathVariable Long id,
                                   @RequestBody DataProductDemand demand) {
        demand.setId(id);
        return demandService.updateDemand(demand);
    }

    /**
     * 删除需求
     */
    @ApiOperation(value = "删除需求")
    @DeleteMapping("/{id}")
    public BaseResultEntity delete(@PathVariable Long id) {
        return demandService.deleteDemand(id);
    }

    /**
     * 统计数据
     */
    @ApiOperation(value = "统计数据")
    @GetMapping("/stats")
    public BaseResultEntity stats(@RequestParam(required = false) Long organId) {
        return demandService.getStatistics(organId);
    }

    /**
     * 导出
     */
    @ApiOperation(value = "导出需求")
    @GetMapping("/export")
    public BaseResultEntity export(
            @ApiParam("需求名称") @RequestParam(required = false) String demandName,
            @ApiParam("需求类型") @RequestParam(required = false) String demandType,
            @ApiParam("状态") @RequestParam(required = false) String status,
            @ApiParam("机构ID") @RequestParam(required = false) Long organId) {
        // TODO: 实现导出功能
        return BaseResultEntity.success("导出功能待实现");
    }
}
