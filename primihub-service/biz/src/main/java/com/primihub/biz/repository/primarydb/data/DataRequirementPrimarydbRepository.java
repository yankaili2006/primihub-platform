package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataRequirement;
import com.primihub.biz.entity.data.po.DataRequirementConfig;
import com.primihub.biz.entity.data.po.DataRequirementMatch;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 数据需求Repository接口
 */
public interface DataRequirementPrimarydbRepository {

    // ========== 数据需求 CRUD ==========

    /**
     * 插入数据需求
     */
    int insertDataRequirement(DataRequirement dataRequirement);

    /**
     * 更新数据需求
     */
    int updateDataRequirement(DataRequirement dataRequirement);

    /**
     * 删除数据需求(软删除)
     */
    int deleteDataRequirement(@Param("id") Long id);

    /**
     * 根据ID查询数据需求
     */
    DataRequirement selectDataRequirementById(@Param("id") Long id);

    /**
     * 根据需求编码查询数据需求
     */
    DataRequirement selectDataRequirementByCode(@Param("requirementCode") String requirementCode);

    /**
     * 查询数据需求列表
     */
    List<DataRequirement> selectDataRequirementList(Map<String, Object> params);

    /**
     * 查询数据需求总数
     */
    int selectDataRequirementCount(Map<String, Object> params);

    /**
     * 批量删除数据需求
     */
    int batchDeleteDataRequirement(@Param("ids") List<Long> ids);

    /**
     * 更新数据需求状态
     */
    int updateDataRequirementStatus(@Param("id") Long id, @Param("status") Integer status);

    // ========== 数据需求配置 CRUD ==========

    /**
     * 插入配置
     */
    int insertDataRequirementConfig(DataRequirementConfig config);

    /**
     * 更新配置
     */
    int updateDataRequirementConfig(DataRequirementConfig config);

    /**
     * 删除配置(软删除)
     */
    int deleteDataRequirementConfig(@Param("id") Long id);

    /**
     * 根据ID查询配置
     */
    DataRequirementConfig selectDataRequirementConfigById(@Param("id") Long id);

    /**
     * 根据配置键查询配置
     */
    DataRequirementConfig selectDataRequirementConfigByKey(@Param("configKey") String configKey);

    /**
     * 查询配置列表
     */
    List<DataRequirementConfig> selectDataRequirementConfigList(Map<String, Object> params);

    /**
     * 查询配置总数
     */
    int selectDataRequirementConfigCount(Map<String, Object> params);

    /**
     * 更新配置启用状态
     */
    int updateDataRequirementConfigStatus(@Param("id") Long id, @Param("isEnabled") Integer isEnabled);

    /**
     * 查询所有启用的配置
     */
    List<DataRequirementConfig> selectEnabledConfigs();

    // ========== 数据需求匹配 CRUD ==========

    /**
     * 插入匹配记录
     */
    int insertDataRequirementMatch(DataRequirementMatch match);

    /**
     * 批量插入匹配记录
     */
    int batchInsertDataRequirementMatch(@Param("matchList") List<DataRequirementMatch> matchList);

    /**
     * 更新匹配记录
     */
    int updateDataRequirementMatch(DataRequirementMatch match);

    /**
     * 删除匹配记录(软删除)
     */
    int deleteDataRequirementMatch(@Param("id") Long id);

    /**
     * 根据ID查询匹配记录
     */
    DataRequirementMatch selectDataRequirementMatchById(@Param("id") Long id);

    /**
     * 查询匹配记录列表
     */
    List<DataRequirementMatch> selectDataRequirementMatchList(Map<String, Object> params);

    /**
     * 查询匹配记录总数
     */
    int selectDataRequirementMatchCount(Map<String, Object> params);

    /**
     * 根据需求ID查询匹配的资源
     */
    List<DataRequirementMatch> selectMatchedResourcesByRequirementId(@Param("requirementId") Long requirementId);

    /**
     * 根据资源ID查询匹配的需求
     */
    List<DataRequirementMatch> selectMatchedRequirementsByResourceId(@Param("resourceId") Long resourceId);

    /**
     * 更新匹配状态
     */
    int updateMatchStatus(@Param("id") Long id, @Param("matchStatus") Integer matchStatus,
                          @Param("confirmUserId") Long confirmUserId, @Param("confirmUserName") String confirmUserName);

    /**
     * 删除需求的所有匹配记录
     */
    int deleteMatchesByRequirementId(@Param("requirementId") Long requirementId);

    /**
     * 查询需求是否已有匹配记录
     */
    int checkMatchExists(@Param("requirementId") Long requirementId, @Param("resourceId") Long resourceId);
}
