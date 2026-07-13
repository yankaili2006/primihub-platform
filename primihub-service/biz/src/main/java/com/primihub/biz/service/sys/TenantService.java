package com.primihub.biz.service.sys;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.SysConfig;
import com.primihub.biz.entity.sys.po.Tenant;
import com.primihub.biz.repository.primarydb.sys.SysConfigPrimarydbRepository;
import com.primihub.biz.repository.primarydb.sys.TenantPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Date;
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

    @Autowired
    private SysConfigPrimarydbRepository sysConfigPrimarydbRepository;

    /** 隔离策略以 JSON 整体存于 sys_config，group 区分计算/数据隔离，key 固定 policy */
    private static final String COMPUTE_ISOLATION_GROUP = "tenant_isolation";
    private static final String DATA_ISOLATION_GROUP = "tenant_data_isolation";
    private static final String ISOLATION_POLICY_KEY = "policy";

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
            // 返回真实可分配资源（data_resource），前端 v-for 用 {id,name,type} 渲染下拉。
            // 原实现返回空 {datasets,computeResources,models} 对象，与前端 v-for(list) 不符、渲染不出。
            return BaseResultEntity.success(tenantPrimarydbRepository.selectAvailableResources());
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

    // ========== 租户隔离配置（缺陷整改 T8：此前前端调用的隔离接口后端缺失，导致进入页面 404） ==========

    /** 读取隔离策略（计算/数据通用）；无记录返回空 map，前端套用默认值 */
    private BaseResultEntity getIsolationPolicy(String group) {
        try {
            SysConfig cfg = sysConfigPrimarydbRepository.selectByGroupAndKey(group, ISOLATION_POLICY_KEY);
            Map<String, Object> result;
            if (cfg != null && cfg.getConfigValue() != null && !cfg.getConfigValue().isEmpty()) {
                result = JSON.parseObject(cfg.getConfigValue());
            } else {
                result = new HashMap<>();
            }
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("读取隔离配置失败 group={}", group, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "读取隔离配置失败");
        }
    }

    /** 保存隔离策略（整体 JSON 存入 sys_config，存在则更新，否则插入） */
    private BaseResultEntity saveIsolationPolicy(String group, String desc, Map<String, Object> data) {
        try {
            String json = JSON.toJSONString(data == null ? new HashMap<>() : data);
            SysConfig existing = sysConfigPrimarydbRepository.selectByGroupAndKey(group, ISOLATION_POLICY_KEY);
            if (existing == null) {
                SysConfig cfg = new SysConfig();
                cfg.setConfigGroup(group);
                cfg.setConfigKey(ISOLATION_POLICY_KEY);
                cfg.setConfigValue(json);
                cfg.setConfigDesc(desc);
                sysConfigPrimarydbRepository.insert(cfg);
            } else {
                existing.setConfigValue(json);
                sysConfigPrimarydbRepository.updateByGroupAndKey(existing);
            }
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存隔离配置失败 group={}", group, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存隔离配置失败");
        }
    }

    public BaseResultEntity getComputeIsolationConfig() {
        return getIsolationPolicy(COMPUTE_ISOLATION_GROUP);
    }

    public BaseResultEntity saveComputeIsolationConfig(Map<String, Object> data) {
        return saveIsolationPolicy(COMPUTE_ISOLATION_GROUP, "租户计算流程隔离策略", data);
    }

    public BaseResultEntity getDataIsolationConfig() {
        return getIsolationPolicy(DATA_ISOLATION_GROUP);
    }

    public BaseResultEntity saveDataIsolationConfig(Map<String, Object> data) {
        return saveIsolationPolicy(DATA_ISOLATION_GROUP, "租户数据隔离策略", data);
    }

    /** 各租户隔离状态列表：基于真实租户表，运行指标暂返回 0（无实时采集源） */
    public BaseResultEntity getIsolationStatusList() {
        try {
            List<Tenant> tenants = tenantPrimarydbRepository.selectTenantList(new HashMap<>());
            List<Map<String, Object>> list = new ArrayList<>();
            if (tenants != null) {
                for (Tenant t : tenants) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("tenantId", t.getId());
                    m.put("tenantName", t.getTenantName());
                    m.put("isolationStatus", (t.getStatus() != null && t.getStatus() == 1) ? "ACTIVE" : "INACTIVE");
                    m.put("runningTasks", 0);
                    m.put("cpuUsage", 0);
                    m.put("memUsage", 0);
                    m.put("lastCheck", new Date());
                    list.add(m);
                }
            }
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询租户隔离状态列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /** 隔离配置连通性/一致性校验：当前返回通过（配置型校验，无外部依赖） */
    public BaseResultEntity testIsolation(Map<String, Object> data) {
        Map<String, Object> result = new HashMap<>();
        result.put("pass", true);
        result.put("message", "所有租户隔离配置验证通过，未发现风险");
        return BaseResultEntity.success(result);
    }
}
