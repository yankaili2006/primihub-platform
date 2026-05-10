package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.ApiDefinition;
import com.primihub.biz.entity.sys.po.ApiAuthConfig;
import com.primihub.biz.entity.sys.po.ApiCallLog;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface ApiManagePrimarydbRepository {

    // ========== 接口定义 ==========

    void insertApiDefinition(ApiDefinition definition);

    void updateApiDefinition(ApiDefinition definition);

    void deleteApiDefinition(@Param("id") Long id);

    void batchDeleteApiDefinition(@Param("ids") List<Long> ids);

    ApiDefinition selectApiDefinitionById(@Param("id") Long id);

    List<ApiDefinition> selectApiDefinitionList(Map<String, Object> params);

    int selectApiDefinitionCount(Map<String, Object> params);

    void updateApiDefinitionStatus(@Param("id") Long id, @Param("status") Integer status);

    // ========== 接口授权 ==========

    void insertApiAuthConfig(ApiAuthConfig config);

    void updateApiAuthConfig(ApiAuthConfig config);

    void deleteApiAuthConfig(@Param("id") Long id);

    ApiAuthConfig selectApiAuthConfigById(@Param("id") Long id);

    ApiAuthConfig selectApiAuthConfigByAppKey(@Param("appKey") String appKey);

    List<ApiAuthConfig> selectApiAuthConfigList(Map<String, Object> params);

    int selectApiAuthConfigCount(Map<String, Object> params);

    // ========== 接口调用日志 ==========

    void insertApiCallLog(ApiCallLog log);

    ApiCallLog selectApiCallLogById(@Param("id") Long id);

    List<ApiCallLog> selectApiCallLogList(Map<String, Object> params);

    int selectApiCallLogCount(Map<String, Object> params);

    void clearApiCallLog(@Param("beforeTime") String beforeTime);

    Map<String, Object> selectApiCallStatistics(@Param("startTime") String startTime,
                                                 @Param("endTime") String endTime);
}
