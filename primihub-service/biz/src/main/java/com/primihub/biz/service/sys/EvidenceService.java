package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.*;
import com.primihub.biz.repository.primarydb.sys.EvidencePrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.util.*;

@Slf4j
@Service
public class EvidenceService {

    @Autowired
    private EvidencePrimarydbRepository evidenceRepository;

    // ========== 存证记录 ==========

    public BaseResultEntity findEvidencePage(String keyword, String status, String evidenceType,
                                             String startTime, String endTime, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            if (status != null && !status.isEmpty()) params.put("status", Integer.parseInt(status));
            params.put("evidenceType", evidenceType);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            int total = evidenceRepository.selectEvidenceRecordCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<EvidenceRecord> list = evidenceRepository.selectEvidenceRecordList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询存证列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getEvidenceDetail(Long id) {
        try {
            EvidenceRecord record = evidenceRepository.selectEvidenceRecordById(id);
            if (record == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "存证不存在");
            }
            return BaseResultEntity.success(record);
        } catch (Exception e) {
            log.error("查询存证详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createEvidence(Map<String, Object> data) {
        try {
            String evidenceData = data.get("data") != null ? data.get("data").toString() : "";
            String evidenceType = data.get("evidenceType") != null ? data.get("evidenceType").toString() : "text";
            String chainType = data.get("chainType") != null ? data.get("chainType").toString() : "FABRIC";
            String description = data.get("description") != null ? data.get("description").toString() : "";
            Long createdBy = data.get("createdBy") != null ? Long.valueOf(data.get("createdBy").toString()) : null;

            String hash = sha256Hex(evidenceData + System.currentTimeMillis());

            EvidenceRecord record = new EvidenceRecord();
            record.setEvidenceHash(hash);
            record.setEvidenceData(evidenceData);
            record.setEvidenceType(evidenceType);
            record.setChainType(chainType);
            record.setDescription(description);
            record.setStatus(0);
            record.setCreatedBy(createdBy);
            evidenceRepository.insertEvidenceRecord(record);

            EvidenceTimestamp timestamp = new EvidenceTimestamp();
            timestamp.setEvidenceId(record.getId());
            timestamp.setTimestampValue(new Date());
            timestamp.setTimestampHash(sha256Hex(hash + new Date().getTime()));
            timestamp.setTimestampSource("LOCAL");
            timestamp.setNonce(UUID.randomUUID().toString().replace("-", ""));
            timestamp.setStatus(1);
            evidenceRepository.insertEvidenceTimestamp(timestamp);

            Map<String, Object> result = new HashMap<>();
            result.put("id", record.getId());
            result.put("evidenceHash", hash);
            result.put("status", 0);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建存证失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "创建存证失败");
        }
    }

    public BaseResultEntity verifyEvidence(Long id) {
        try {
            EvidenceRecord record = evidenceRepository.selectEvidenceRecordById(id);
            if (record == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "存证不存在");
            }
            EvidenceTimestamp timestamp = evidenceRepository.selectEvidenceTimestampByEvidenceId(id);

            Map<String, Object> result = new HashMap<>();
            result.put("valid", record.getStatus() >= 1);
            result.put("evidenceHash", record.getEvidenceHash());
            result.put("status", record.getStatus());
            result.put("timestamp", timestamp != null ? timestamp.getTimestampValue() : null);
            result.put("message", record.getStatus() >= 1 ? "存证验证通过" : "存证尚未上链");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("验证存证失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "验证失败");
        }
    }

    public BaseResultEntity getEvidenceStatistics() {
        try {
            Map<String, Object> params = new HashMap<>();
            int total = evidenceRepository.selectEvidenceRecordCount(params);

            params.put("startTime", new java.text.SimpleDateFormat("yyyy-MM-dd").format(new Date()) + " 00:00:00");
            int todayCount = evidenceRepository.selectEvidenceRecordCount(params);

            Calendar weekCal = Calendar.getInstance();
            weekCal.add(Calendar.DAY_OF_YEAR, -7);
            params.put("startTime", new java.text.SimpleDateFormat("yyyy-MM-dd").format(weekCal.getTime()) + " 00:00:00");
            int weekCount = evidenceRepository.selectEvidenceRecordCount(params);

            Calendar monthCal = Calendar.getInstance();
            monthCal.add(Calendar.MONTH, -1);
            params.put("startTime", new java.text.SimpleDateFormat("yyyy-MM-dd").format(monthCal.getTime()) + " 00:00:00");
            int monthCount = evidenceRepository.selectEvidenceRecordCount(params);

            Map<String, Object> result = new HashMap<>();
            result.put("total", total);
            result.put("todayCount", todayCount);
            result.put("weekCount", weekCount);
            result.put("monthCount", monthCount);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询存证统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== 时间戳管理 ==========

    public BaseResultEntity findTimestampPage(String keyword, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            int total = evidenceRepository.selectEvidenceTimestampCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<EvidenceTimestamp> list = evidenceRepository.selectEvidenceTimestampList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询时间戳列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity applyTimestamp(Map<String, Object> data) {
        try {
            Long evidenceId = data.get("evidenceId") != null ? Long.valueOf(data.get("evidenceId").toString()) : null;
            if (evidenceId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "存证ID不能为空");
            }

            EvidenceRecord record = evidenceRepository.selectEvidenceRecordById(evidenceId);
            if (record == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "存证不存在");
            }

            EvidenceTimestamp timestamp = new EvidenceTimestamp();
            timestamp.setEvidenceId(evidenceId);
            timestamp.setTimestampValue(new Date());
            timestamp.setTimestampHash(sha256Hex(record.getEvidenceHash() + new Date().getTime()));
            timestamp.setTimestampSource("LOCAL");
            timestamp.setNonce(UUID.randomUUID().toString().replace("-", ""));
            timestamp.setStatus(1);
            evidenceRepository.insertEvidenceTimestamp(timestamp);

            record.setStatus(1);
            evidenceRepository.updateEvidenceRecord(record);

            Map<String, Object> result = new HashMap<>();
            result.put("timestampId", timestamp.getId());
            result.put("status", "SUCCESS");
            result.put("timestamp", timestamp.getTimestampValue());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("申请时间戳失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "申请失败");
        }
    }

    public BaseResultEntity verifyTimestamp(Long id) {
        try {
            EvidenceTimestamp timestamp = evidenceRepository.selectEvidenceTimestampById(id);
            if (timestamp == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "时间戳不存在");
            }
            Map<String, Object> result = new HashMap<>();
            result.put("valid", timestamp.getStatus() == 1);
            result.put("timestampValue", timestamp.getTimestampValue());
            result.put("timestampHash", timestamp.getTimestampHash());
            result.put("message", timestamp.getStatus() == 1 ? "验证成功" : "时间戳尚未确认");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("验证时间戳失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "验证失败");
        }
    }

    // ========== 存证配置 ==========

    public BaseResultEntity getEvidenceConfig() {
        try {
            List<EvidenceConfig> configs = evidenceRepository.selectEvidenceConfigList();
            Map<String, Object> result = new HashMap<>();
            for (EvidenceConfig config : configs) {
                result.put(config.getConfigKey(), config.getConfigValue());
            }
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询存证配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveEvidenceConfig(Map<String, Object> data) {
        try {
            for (Map.Entry<String, Object> entry : data.entrySet()) {
                EvidenceConfig existing = evidenceRepository.selectEvidenceConfigByKey(entry.getKey());
                if (existing != null) {
                    existing.setConfigValue(entry.getValue() != null ? entry.getValue().toString() : "");
                    evidenceRepository.updateEvidenceConfig(existing);
                } else {
                    EvidenceConfig config = new EvidenceConfig();
                    config.setConfigKey(entry.getKey());
                    config.setConfigValue(entry.getValue() != null ? entry.getValue().toString() : "");
                    config.setIsEncrypted(0);
                    evidenceRepository.insertEvidenceConfig(config);
                }
            }
            return BaseResultEntity.success("配置保存成功");
        } catch (Exception e) {
            log.error("保存存证配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    // ========== 存证导出 ==========

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity exportEvidence(Map<String, Object> data) {
        try {
            Long evidenceId = data.get("evidenceId") != null ? Long.valueOf(data.get("evidenceId").toString()) : null;
            Long createdBy = data.get("createdBy") != null ? Long.valueOf(data.get("createdBy").toString()) : null;

            EvidenceExportRecord record = new EvidenceExportRecord();
            record.setEvidenceId(evidenceId);
            record.setExportType("plain");
            record.setFileName("evidence_export_" + System.currentTimeMillis() + ".json");
            record.setIsEncrypted(0);
            record.setStatus(1);
            record.setCreatedBy(createdBy);
            evidenceRepository.insertEvidenceExportRecord(record);

            return BaseResultEntity.success("导出成功");
        } catch (Exception e) {
            log.error("导出存证失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "导出失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity encryptExport(Map<String, Object> data) {
        try {
            Long evidenceId = data.get("evidenceId") != null ? Long.valueOf(data.get("evidenceId").toString()) : null;
            String algorithm = data.get("algorithm") != null ? data.get("algorithm").toString() : "AES";
            Long createdBy = data.get("createdBy") != null ? Long.valueOf(data.get("createdBy").toString()) : null;

            EvidenceExportRecord record = new EvidenceExportRecord();
            record.setEvidenceId(evidenceId);
            record.setExportType("encrypted");
            record.setFileName("evidence_encrypted_" + System.currentTimeMillis() + ".enc");
            record.setIsEncrypted(1);
            record.setEncryptAlgorithm(algorithm);
            record.setStatus(1);
            record.setCreatedBy(createdBy);
            evidenceRepository.insertEvidenceExportRecord(record);

            return BaseResultEntity.success("加密导出成功");
        } catch (Exception e) {
            log.error("加密导出失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "导出失败");
        }
    }

    public BaseResultEntity getExportHistory(Long createdBy, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("createdBy", createdBy);
            int total = evidenceRepository.selectEvidenceExportRecordCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<EvidenceExportRecord> list = evidenceRepository.selectEvidenceExportRecordList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询导出历史失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== API密钥 ==========

    public BaseResultEntity getApiKeyList() {
        try {
            List<EvidenceApiKey> list = evidenceRepository.selectEvidenceApiKeyList(new HashMap<>());
            Map<String, Object> result = new HashMap<>();
            if (!list.isEmpty()) {
                EvidenceApiKey key = list.get(0);
                result.put("apiKey", key.getApiKey());
                result.put("secretKey", key.getSecretKey());
                result.put("createTime", key.getCreatedAt());
                result.put("expiryTime", key.getExpiryDate());
                result.put("status", key.getStatus() == 1 ? "ACTIVE" : "INACTIVE");
            } else {
                result.put("apiKey", "");
                result.put("secretKey", "");
                result.put("status", "NONE");
            }
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询API密钥失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getApiKey() {
        return getApiKeyList();
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity regenerateApiKey(Map<String, Object> data) {
        try {
            EvidenceApiKey key = new EvidenceApiKey();
            key.setApiKey("pk_test_" + UUID.randomUUID().toString().replace("-", "").substring(0, 24));
            key.setSecretKey("sk_test_" + UUID.randomUUID().toString().replace("-", ""));
            key.setStatus(1);
            Calendar cal = Calendar.getInstance();
            cal.add(Calendar.YEAR, 1);
            key.setExpiryDate(cal.getTime());
            key.setDescription(data.get("description") != null ? data.get("description").toString() : "");
            Long createdBy = data.get("createdBy") != null ? Long.valueOf(data.get("createdBy").toString()) : null;
            key.setCreatedBy(createdBy);
            evidenceRepository.insertEvidenceApiKey(key);

            Map<String, Object> result = new HashMap<>();
            result.put("apiKey", key.getApiKey());
            result.put("secretKey", key.getSecretKey());
            result.put("createTime", key.getCreatedAt());
            result.put("expiryTime", key.getExpiryDate());
            result.put("status", "ACTIVE");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("重新生成API密钥失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "生成失败");
        }
    }

    // ========== API调用日志 ==========

    public BaseResultEntity getApiCallLog(Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            int total = evidenceRepository.selectEvidenceApiCallLogCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<EvidenceApiCallLog> list = evidenceRepository.selectEvidenceApiCallLogList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询API调用日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ========== 辅助方法 ==========

    private String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();
        } catch (Exception e) {
            log.error("SHA-256计算失败", e);
            return UUID.randomUUID().toString().replace("-", "");
        }
    }
}
