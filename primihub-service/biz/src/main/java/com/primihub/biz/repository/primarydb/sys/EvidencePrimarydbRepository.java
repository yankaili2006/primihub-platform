package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.*;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface EvidencePrimarydbRepository {

    // ========== 存证记录 ==========

    void insertEvidenceRecord(EvidenceRecord record);

    void updateEvidenceRecord(EvidenceRecord record);

    void deleteEvidenceRecord(@Param("id") Long id);

    EvidenceRecord selectEvidenceRecordById(@Param("id") Long id);

    EvidenceRecord selectEvidenceRecordByHash(@Param("evidenceHash") String evidenceHash);

    List<EvidenceRecord> selectEvidenceRecordList(Map<String, Object> params);

    int selectEvidenceRecordCount(Map<String, Object> params);

    // ========== 时间戳 ==========

    void insertEvidenceTimestamp(EvidenceTimestamp timestamp);

    void updateEvidenceTimestamp(EvidenceTimestamp timestamp);

    EvidenceTimestamp selectEvidenceTimestampById(@Param("id") Long id);

    EvidenceTimestamp selectEvidenceTimestampByEvidenceId(@Param("evidenceId") Long evidenceId);

    List<EvidenceTimestamp> selectEvidenceTimestampList(Map<String, Object> params);

    int selectEvidenceTimestampCount(Map<String, Object> params);

    // ========== 存证配置 ==========

    EvidenceConfig selectEvidenceConfigByKey(@Param("configKey") String configKey);

    List<EvidenceConfig> selectEvidenceConfigList();

    void insertEvidenceConfig(EvidenceConfig config);

    void updateEvidenceConfig(EvidenceConfig config);

    // ========== API密钥 ==========

    void insertEvidenceApiKey(EvidenceApiKey apiKey);

    void updateEvidenceApiKey(EvidenceApiKey apiKey);

    void deleteEvidenceApiKey(@Param("id") Long id);

    EvidenceApiKey selectEvidenceApiKeyById(@Param("id") Long id);

    EvidenceApiKey selectEvidenceApiKeyByKey(@Param("apiKey") String apiKey);

    List<EvidenceApiKey> selectEvidenceApiKeyList(Map<String, Object> params);

    int selectEvidenceApiKeyCount(Map<String, Object> params);

    // ========== 导出记录 ==========

    void insertEvidenceExportRecord(EvidenceExportRecord record);

    List<EvidenceExportRecord> selectEvidenceExportRecordList(Map<String, Object> params);

    int selectEvidenceExportRecordCount(Map<String, Object> params);

    // ========== API调用日志 ==========

    void insertEvidenceApiCallLog(EvidenceApiCallLog log);

    List<EvidenceApiCallLog> selectEvidenceApiCallLogList(Map<String, Object> params);

    int selectEvidenceApiCallLogCount(Map<String, Object> params);
}
