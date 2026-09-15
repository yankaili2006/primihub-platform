package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.po.DataProductSupply;
import com.primihub.biz.service.data.DataProductSupplyService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 数据产品供给Controller
 */
@Slf4j
@Api(tags = "数据产品供给管理")
@RestController
@RequestMapping("/api/v2/service/supply")
public class DataProductSupplyController {

    @Autowired
    private DataProductSupplyService supplyService;

    /**
     * 查询供给列表
     */
    @ApiOperation(value = "查询供给列表")
    @GetMapping("/list")
    public BaseResultEntity list(
            @ApiParam("产品名称") @RequestParam(required = false) String productName,
            @ApiParam("服务分类") @RequestParam(required = false) String serviceCategory,
            @ApiParam("状态") @RequestParam(required = false) String status,
            @ApiParam("机构ID") @RequestParam(required = false) Long organId,
            @ApiParam("节点ID") @RequestParam(required = false) Long nodeId,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return supplyService.findSupplyPage(productName, serviceCategory, status, organId, nodeId, pageNum, pageSize);
    }

    /**
     * 根据ID查询供给
     */
    @ApiOperation(value = "根据ID查询供给")
    @GetMapping("/{id}")
    public BaseResultEntity getById(@PathVariable Long id) {
        return supplyService.findSupplyById(id);
    }

    /**
     * 按机构查询
     */
    @ApiOperation(value = "按机构查询")
    @GetMapping("/byOrgan/{organId}")
    public BaseResultEntity getByOrgan(@PathVariable Long organId) {
        return supplyService.findSupplyByOrganId(organId);
    }

    /**
     * 按节点查询
     */
    @ApiOperation(value = "按节点查询")
    @GetMapping("/byNode/{nodeId}")
    public BaseResultEntity getByNode(@PathVariable Long nodeId) {
        return supplyService.findSupplyByNodeId(nodeId);
    }

    /**
     * 新增供给
     */
    @ApiOperation(value = "新增供给")
    @PostMapping
    public BaseResultEntity add(@RequestBody DataProductSupply supply,
                               @RequestHeader(value = "userId", required = false) Long userId) {
        if (userId != null && supply.getCreatedBy() == null) {
            supply.setCreatedBy(userId);
        }
        return supplyService.saveSupply(supply);
    }

    /**
     * 更新供给
     */
    @ApiOperation(value = "更新供给")
    @PutMapping("/{id}")
    public BaseResultEntity update(@PathVariable Long id,
                                   @RequestBody DataProductSupply supply) {
        supply.setId(id);
        return supplyService.updateSupply(supply);
    }

    /**
     * 删除供给
     */
    @ApiOperation(value = "删除供给")
    @DeleteMapping("/{id}")
    public BaseResultEntity delete(@PathVariable Long id) {
        return supplyService.deleteSupply(id);
    }

    /**
     * 统计数据
     */
    @ApiOperation(value = "统计数据")
    @GetMapping("/stats")
    public BaseResultEntity stats(@RequestParam(required = false) Long organId) {
        return supplyService.getStatistics(organId);
    }

    /**
     * 导出
     */
    @ApiOperation(value = "导出供给")
    @GetMapping("/export")
    public BaseResultEntity export(
            @ApiParam("产品名称") @RequestParam(required = false) String productName,
            @ApiParam("服务分类") @RequestParam(required = false) String serviceCategory,
            @ApiParam("状态") @RequestParam(required = false) String status,
            @ApiParam("机构ID") @RequestParam(required = false) Long organId) {
        // TODO: 实现导出功能
        return BaseResultEntity.success("导出功能待实现");
    }
}
