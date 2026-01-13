package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.Tenant;
import com.primihub.biz.repository.primarydb.sys.TenantPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 租户管理Service
 */
@Slf4j
@Service
public class TenantService {

    @Autowired
    private TenantPrimarydbRepository tenantPrimarydbRepository;

    // ========== 租户管理 ==========

    /**
     * 查询租户分页列表
     */
    public BaseResultEntity findTenantPage(String keyword, Integer status, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("status", status);

            int total = tenantPrimarydbRepository.selectTenantCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<Tenant> list = tenantPrimarydbRepository.selectTenantList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询租户列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加租户
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addTenant(Tenant tenant) {
        try {
            // 1. 验证租户编码唯一性
            if (tenant.getTenantCode() == null || tenant.getTenantCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户编码不能为空");
            }
            if (tenant.getTenantName() == null || tenant.getTenantName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户名称不能为空");
            }

            Tenant existingTenant = tenantPrimarydbRepository.selectTenantByCode(tenant.getTenantCode());
            if (existingTenant != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "租户编码已存在");
            }

            // 2. 设置默认值
            if (tenant.getStatus() == null) {
                tenant.setStatus(1); // 默认正常状态
            }
            if (tenant.getDataIsolation() == null) {
                tenant.setDataIsolation(true); // 默认启用数据隔离
            }
            if (tenant.getComputeIsolation() == null) {
                tenant.setComputeIsolation(true); // 默认启用计算流程隔离
            }

            // 3. 创建租户记录
            tenantPrimarydbRepository.insertTenant(tenant);

            // 4. 初始化租户隔离配置
            Map<String, Object> isolationConfig = new HashMap<>();
            isolationConfig.put("tenantId", tenant.getId());
            isolationConfig.put("cpuQuota", 0);
            isolationConfig.put("memoryQuota", 0);
            isolationConfig.put("storageQuota", 0);
            isolationConfig.put("datasetLimit", 0);
            isolationConfig.put("modelLimit", 0);
            isolationConfig.put("concurrentTasks", 10);
            isolationConfig.put("networkIsolation", 0);
            isolationConfig.put("namespace", "tenant_" + tenant.getTenantCode());
            tenantPrimarydbRepository.insertTenantIsolationConfig(isolationConfig);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("添加租户失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败: " + e.getMessage());
        }
    }

    /**
     * 更新租户
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateTenant(Tenant tenant) {
        try {
            if (tenant.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            Tenant existingTenant = tenantPrimarydbRepository.selectTenantById(tenant.getId());
            if (existingTenant == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户不存在");
            }

            tenantPrimarydbRepository.updateTenant(tenant);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("更新租户失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除租户
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteTenant(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            // 1. 检查租户是否存在
            Tenant tenant = tenantPrimarydbRepository.selectTenantById(id);
            if (tenant == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户不存在");
            }

            // 2. 检查租户是否有资源分配（可选，根据业务需求）
            if (tenant.getResourceCount() != null && tenant.getResourceCount() > 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户有资源分配，无法删除");
            }

            // 3. 删除租户（软删除）
            tenantPrimarydbRepository.deleteTenant(id);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除租户失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 冻结租户
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity freezeTenant(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            Tenant tenant = tenantPrimarydbRepository.selectTenantById(id);
            if (tenant == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户不存在");
            }

            if (tenant.getStatus() == 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户已被冻结");
            }

            // 更新租户状态为冻结
            tenantPrimarydbRepository.updateTenantStatus(id, 0);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("冻结租户失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "冻结失败");
        }
    }

    /**
     * 解冻租户
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity unfreezeTenant(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            Tenant tenant = tenantPrimarydbRepository.selectTenantById(id);
            if (tenant == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户不存在");
            }

            if (tenant.getStatus() == 1) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户未被冻结");
            }

            // 更新租户状态为正常
            tenantPrimarydbRepository.updateTenantStatus(id, 1);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("解冻租户失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "解冻失败");
        }
    }

    /**
     * 查询租户详情
     */
    public BaseResultEntity getTenantDetail(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            Tenant tenant = tenantPrimarydbRepository.selectTenantById(id);
            if (tenant == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户不存在");
            }

            // 查询租户隔离配置
            Map<String, Object> isolationConfig = tenantPrimarydbRepository.selectTenantIsolationConfig(id);

            Map<String, Object> result = new HashMap<>();
            result.put("tenant", tenant);
            result.put("isolationConfig", isolationConfig);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询租户详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== 租户资源分配 ==========

    /**
     * 查询租户资源分配列表
     */
    public BaseResultEntity findTenantResourceList(Long tenantId, String resourceName, String resourceType,
                                                   Integer status, Integer pageNum, Integer pageSize) {
        try {
            if (tenantId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            Map<String, Object> params = new HashMap<>();
            params.put("tenantId", tenantId);
            params.put("resourceName", resourceName);
            params.put("resourceType", resourceType);
            params.put("status", status);

            int total = tenantPrimarydbRepository.selectTenantResourceCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<Map<String, Object>> list = tenantPrimarydbRepository.selectTenantResourceList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询租户资源列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加租户资源分配
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addTenantResource(Map<String, Object> params) {
        try {
            Long tenantId = params.get("tenantId") != null ? Long.valueOf(params.get("tenantId").toString()) : null;
            if (tenantId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "租户ID不能为空");
            }

            // 验证租户是否存在
            Tenant tenant = tenantPrimarydbRepository.selectTenantById(tenantId);
            if (tenant == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "租户不存在");
            }

            // 设置默认值
            if (params.get("status") == null) {
                params.put("status", 1);
            }
            if (params.get("permissionLevel") == null) {
                params.put("permissionLevel", "READ");
            }

            // 创建资源分配记录
            tenantPrimarydbRepository.insertTenantResourceAllocation(params);

            // 更新租户资源数量
            tenantPrimarydbRepository.updateTenantResourceCount(tenantId, 1);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("添加租户资源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 删除租户资源分配
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteTenantResource(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "资源分配ID不能为空");
            }

            // 查询资源分配信息
            Map<String, Object> resource = tenantPrimarydbRepository.selectTenantResourceById(id);
            if (resource == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "资源分配不存在");
            }

            Long tenantId = (Long) resource.get("tenantId");

            // 删除资源分配
            tenantPrimarydbRepository.deleteTenantResourceAllocation(id);

            // 更新租户资源数量
            tenantPrimarydbRepository.updateTenantResourceCount(tenantId, -1);

            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除租户资源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 获取可分配资源列表
     */
    public BaseResultEntity getAvailableResources(Long tenantId) {
        try {
            // TODO: 实现可用资源查询逻辑，需要根据实际业务系统的资源管理模块集成
            // 这里返回示例数据
            Map<String, Object> resources = new HashMap<>();
            resources.put("datasets", new HashMap<>());
            resources.put("computeResources", new HashMap<>());
            resources.put("models", new HashMap<>());

            return BaseResultEntity.success(resources);
        } catch (Exception e) {
            log.error("查询可分配资源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询租户统计信息
     */
    public BaseResultEntity getTenantStatistics() {
        try {
            Map<String, Object> statistics = tenantPrimarydbRepository.selectTenantStatistics();
            return BaseResultEntity.success(statistics);
        } catch (Exception e) {
            log.error("查询租户统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }
}
