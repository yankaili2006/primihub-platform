package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.FederatedBillingRecord;
import com.primihub.biz.entity.data.po.FederatedBillingRule;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface FederatedBillingRepository {

    void insertRule(FederatedBillingRule rule);
    void updateRule(FederatedBillingRule rule);
    void deleteRule(@Param("id") Long id);
    void toggleRule(@Param("id") Long id, @Param("isActive") Integer isActive);
    FederatedBillingRule selectRuleById(@Param("id") Long id);
    List<FederatedBillingRule> selectRuleList(Map<String, Object> params);
    int selectRuleCount(Map<String, Object> params);
    List<FederatedBillingRule> selectActiveRulesByTaskType(@Param("taskType") String taskType);

    void insertRecord(FederatedBillingRecord record);
    List<FederatedBillingRecord> selectRecordList(Map<String, Object> params);
    int selectRecordCount(Map<String, Object> params);
    Map<String, Object> selectRecordSummary(Map<String, Object> params);
    List<Map<String, Object>> selectDailyCharge(Map<String, Object> params);
    boolean existsByDedupKeyAndAfter(@Param("dedupKey") String dedupKey, @Param("after") java.util.Date after);
}
