package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.Tenant;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface TenantPrimarydbRepository {

    // ========== 租户管理 ==========

    /**
     * 新增租户
     */
    void insertTenant(Tenant tenant);

    /**
     * 更新租户
     */
    void updateTenant(Tenant tenant);

    /**
     * 删除租户（逻辑删除）
     */
    void deleteTenant(@Param("id") Long id);

    /**
     * 根据ID查询租户
     */
    Tenant selectTenantById(@Param("id") Long id);

    /**
     * 根据租户编码查询租户
     */
    Tenant selectTenantByCode(@Param("tenantCode") String tenantCode);

    /**
     * 查询租户列表
     */
    List<Tenant> selectTenantList(Map<String, Object> params);

    /**
     * 查询租户总数
     */
    int selectTenantCount(Map<String, Object> params);

    /**
     * 更新租户状态（冻结/解冻）
     */
    void updateTenantStatus(@Param("id") Long id, @Param("status") Integer status);

    /**
     * 更新租户资源数量
     */
    void updateTenantResourceCount(@Param("tenantId") Long tenantId, @Param("increment") Integer increment);

    // ========== 租户资源分配 ==========

    /**
     * 新增租户资源分配
     */
    void insertTenantResourceAllocation(Map<String, Object> params);

    /**
     * 删除租户资源分配
     */
    void deleteTenantResourceAllocation(@Param("id") Long id);

    /**
     * 查询租户资源分配列表
     */
    List<Map<String, Object>> selectTenantResourceList(Map<String, Object> params);

    /**
     * 查询租户资源分配总数
     */
    int selectTenantResourceCount(Map<String, Object> params);

    /**
     * 根据ID查询租户资源分配
     */
    Map<String, Object> selectTenantResourceById(@Param("id") Long id);

    // ========== 租户隔离配置 ==========

    /**
     * 新增租户隔离配置
     */
    void insertTenantIsolationConfig(Map<String, Object> params);

    /**
     * 更新租户隔离配置
     */
    void updateTenantIsolationConfig(Map<String, Object> params);

    /**
     * 查询租户隔离配置
     */
    Map<String, Object> selectTenantIsolationConfig(@Param("tenantId") Long tenantId);

    // ========== 租户统计 ==========

    /**
     * 查询租户统计信息
     */
    Map<String, Object> selectTenantStatistics();

    /**
     * 可分配资源列表（真实 data_resource），供租户资源分配下拉
     */
    java.util.List<Map<String, Object>> selectAvailableResources();
}
