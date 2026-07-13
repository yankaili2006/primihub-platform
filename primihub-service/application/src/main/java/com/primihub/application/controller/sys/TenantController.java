package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.po.Tenant;
import com.primihub.biz.service.sys.TenantService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 租户管理Controller - 简化版本
 * TODO: 需要补充完整的接口实现
 */
@Api(value = "租户管理接口", tags = "租户管理接口")
@RequestMapping("tenant")
@RestController
public class TenantController {

    @Autowired
    private TenantService tenantService;

    @ApiOperation(value = "查询租户分页列表")
    @GetMapping("findTenantPage")
    public BaseResultEntity findTenantPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return tenantService.findTenantPage(keyword, status, pageNum, pageSize);
    }

    @ApiOperation(value = "添加租户")
    @PostMapping("addTenant")
    public BaseResultEntity addTenant(@RequestBody Tenant tenant) {
        if (tenant == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.addTenant(tenant);
    }

    @ApiOperation(value = "更新租户")
    @PostMapping("updateTenant")
    public BaseResultEntity updateTenant(@RequestBody Tenant tenant) {
        if (tenant == null || tenant.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.updateTenant(tenant);
    }

    @ApiOperation(value = "删除租户")
    @PostMapping("deleteTenant")
    public BaseResultEntity deleteTenant(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.deleteTenant(id);
    }

    @ApiOperation(value = "冻结租户")
    @PostMapping("freezeTenant")
    public BaseResultEntity freezeTenant(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.freezeTenant(id);
    }

    @ApiOperation(value = "解冻租户")
    @PostMapping("unfreezeTenant")
    public BaseResultEntity unfreezeTenant(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.unfreezeTenant(id);
    }

    @ApiOperation(value = "查询租户详情")
    @GetMapping("getTenantDetail")
    public BaseResultEntity getTenantDetail(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.getTenantDetail(id);
    }

    @ApiOperation(value = "查询租户资源列表")
    @GetMapping("findTenantResourceList")
    public BaseResultEntity findTenantResourceList(
            @RequestParam Long tenantId,
            @RequestParam(required = false) String resourceName,
            @RequestParam(required = false) String resourceType,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return tenantService.findTenantResourceList(tenantId, resourceName, resourceType, status, pageNum, pageSize);
    }

    @ApiOperation(value = "添加租户资源")
    @PostMapping("addTenantResource")
    public BaseResultEntity addTenantResource(@RequestBody Map<String, Object> params) {
        return tenantService.addTenantResource(params);
    }

    @ApiOperation(value = "删除租户资源")
    @PostMapping("deleteTenantResource")
    public BaseResultEntity deleteTenantResource(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return tenantService.deleteTenantResource(id);
    }

    @ApiOperation(value = "获取可分配资源")
    @GetMapping("getAvailableResources")
    public BaseResultEntity getAvailableResources(@RequestParam Long tenantId) {
        return tenantService.getAvailableResources(tenantId);
    }

    @ApiOperation(value = "查询租户统计")
    @GetMapping("getTenantStatistics")
    public BaseResultEntity getTenantStatistics() {
        return tenantService.getTenantStatistics();
    }

    // ===== 租户隔离配置（缺陷整改 T8：补齐前端隔离页面所调用、此前后端缺失的接口，消除进入页面 404） =====

    @ApiOperation(value = "获取计算流程隔离配置")
    @GetMapping("isolation/config")
    public BaseResultEntity getComputeIsolationConfig() {
        return tenantService.getComputeIsolationConfig();
    }

    @ApiOperation(value = "保存计算流程隔离配置")
    @PostMapping("isolation/config")
    public BaseResultEntity saveComputeIsolationConfig(@RequestBody(required = false) Map<String, Object> data) {
        return tenantService.saveComputeIsolationConfig(data);
    }

    @ApiOperation(value = "查询各租户隔离状态列表")
    @GetMapping("isolation/status/list")
    public BaseResultEntity getIsolationStatusList() {
        return tenantService.getIsolationStatusList();
    }

    @ApiOperation(value = "隔离配置校验")
    @PostMapping("isolation/test")
    public BaseResultEntity testIsolation(@RequestBody(required = false) Map<String, Object> data) {
        return tenantService.testIsolation(data);
    }

    @ApiOperation(value = "获取数据隔离配置")
    @GetMapping("dataIsolation/config")
    public BaseResultEntity getDataIsolationConfig() {
        return tenantService.getDataIsolationConfig();
    }

    @ApiOperation(value = "保存数据隔离配置")
    @PostMapping("dataIsolation/config")
    public BaseResultEntity saveDataIsolationConfig(@RequestBody(required = false) Map<String, Object> data) {
        return tenantService.saveDataIsolationConfig(data);
    }
}
