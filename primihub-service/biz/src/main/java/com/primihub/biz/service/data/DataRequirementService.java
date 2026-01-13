package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.*;
import com.primihub.biz.repository.primarydb.data.DataRequirementPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.data.DataResourceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * 数据需求管理Service
 */
@Slf4j
@Service
public class DataRequirementService {

    @Autowired
    private DataRequirementPrimarydbRepository dataRequirementRepository;

    @Autowired
    private DataResourceRepository dataResourceRepository;

    // ========== 数据需求 CRUD ==========

    /**
     * 查询数据需求分页列表
     */
    public BaseResultEntity findDataRequirementPage(String keyword, String requirementType,
                                                     Integer priority, Integer status,
                                                     Long userId, Long organId,
                                                     String startDate, String endDate,
                                                     Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("requirementType", requirementType);
            params.put("priority", priority);
            params.put("status", status);
            params.put("userId", userId);
            params.put("organId", organId);
            params.put("startDate", startDate);
            params.put("endDate", endDate);

            int total = dataRequirementRepository.selectDataRequirementCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<DataRequirement> list = dataRequirementRepository.selectDataRequirementList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询数据需求列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据ID查询数据需求
     */
    public BaseResultEntity getDataRequirementById(Long id) {
        try {
            DataRequirement dataRequirement = dataRequirementRepository.selectDataRequirementById(id);
            if (dataRequirement == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据需求不存在");
            }
            return BaseResultEntity.success(dataRequirement);
        } catch (Exception e) {
            log.error("查询数据需求失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加数据需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addDataRequirement(DataRequirement dataRequirement) {
        try {
            // 参数校验
            if (dataRequirement.getRequirementCode() == null || dataRequirement.getRequirementCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "需求编码不能为空");
            }
            if (dataRequirement.getRequirementName() == null || dataRequirement.getRequirementName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "需求名称不能为空");
            }

            // 检查需求编码是否已存在
            DataRequirement existing = dataRequirementRepository.selectDataRequirementByCode(dataRequirement.getRequirementCode());
            if (existing != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "需求编码已存在");
            }

            // 设置默认值
            if (dataRequirement.getPriority() == null) {
                dataRequirement.setPriority(0); // 默认低优先级
            }
            if (dataRequirement.getStatus() == null) {
                dataRequirement.setStatus(0); // 默认待匹配
            }

            dataRequirementRepository.insertDataRequirement(dataRequirement);
            return BaseResultEntity.success(dataRequirement);
        } catch (Exception e) {
            log.error("添加数据需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新数据需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateDataRequirement(DataRequirement dataRequirement) {
        try {
            if (dataRequirement.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            DataRequirement existing = dataRequirementRepository.selectDataRequirementById(dataRequirement.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据需求不存在");
            }

            dataRequirementRepository.updateDataRequirement(dataRequirement);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新数据需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除数据需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteDataRequirement(Long id) {
        try {
            DataRequirement existing = dataRequirementRepository.selectDataRequirementById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据需求不存在");
            }

            // 删除数据需求
            dataRequirementRepository.deleteDataRequirement(id);

            // 同时删除该需求的所有匹配记录
            dataRequirementRepository.deleteMatchesByRequirementId(id);

            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除数据需求失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 批量删除数据需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteDataRequirement(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }

            dataRequirementRepository.batchDeleteDataRequirement(ids);

            // 删除这些需求的所有匹配记录
            for (Long id : ids) {
                dataRequirementRepository.deleteMatchesByRequirementId(id);
            }

            return BaseResultEntity.success("批量删除成功");
        } catch (Exception e) {
            log.error("批量删除数据需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量删除失败");
        }
    }

    // ========== 数据需求配置 CRUD ==========

    /**
     * 查询配置分页列表
     */
    public BaseResultEntity findConfigPage(String keyword, String configType,
                                           Integer isEnabled, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("configType", configType);
            params.put("isEnabled", isEnabled);

            int total = dataRequirementRepository.selectDataRequirementConfigCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<DataRequirementConfig> list = dataRequirementRepository.selectDataRequirementConfigList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询配置列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加配置
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addConfig(DataRequirementConfig config) {
        try {
            if (config.getConfigKey() == null || config.getConfigKey().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "配置键不能为空");
            }
            if (config.getConfigValue() == null || config.getConfigValue().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "配置值不能为空");
            }

            // 检查配置键是否已存在
            DataRequirementConfig existing = dataRequirementRepository.selectDataRequirementConfigByKey(config.getConfigKey());
            if (existing != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "配置键已存在");
            }

            if (config.getIsEnabled() == null) {
                config.setIsEnabled(1);
            }

            dataRequirementRepository.insertDataRequirementConfig(config);
            return BaseResultEntity.success("添加成功");
        } catch (Exception e) {
            log.error("添加配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新配置
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateConfig(DataRequirementConfig config) {
        try {
            if (config.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            DataRequirementConfig existing = dataRequirementRepository.selectDataRequirementConfigById(config.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
            }

            dataRequirementRepository.updateDataRequirementConfig(config);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除配置
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteConfig(Long id) {
        try {
            DataRequirementConfig existing = dataRequirementRepository.selectDataRequirementConfigById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
            }

            dataRequirementRepository.deleteDataRequirementConfig(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除配置失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 更新配置启用状态
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateConfigStatus(Long id, Integer isEnabled) {
        try {
            dataRequirementRepository.updateDataRequirementConfigStatus(id, isEnabled);
            return BaseResultEntity.success("更新状态成功");
        } catch (Exception e) {
            log.error("更新配置状态失败，id={}, isEnabled={}", id, isEnabled, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新状态失败");
        }
    }

    // ========== 数据需求匹配功能 ==========

    /**
     * 执行数据需求匹配
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity matchDataRequirements(Long requirementId) {
        try {
            // 1. 查询需求详情
            DataRequirement requirement = dataRequirementRepository.selectDataRequirementById(requirementId);
            if (requirement == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据需求不存在");
            }

            // 2. 查询配置参数
            Map<String, String> configMap = loadConfigs();
            BigDecimal matchThreshold = new BigDecimal(configMap.getOrDefault("match_threshold", "60.00"));
            int maxResults = Integer.parseInt(configMap.getOrDefault("max_match_results", "50"));

            // 3. 查询所有可用资源
            Map<String, Object> resourceParams = new HashMap<>();
            resourceParams.put("isDel", 0);
            List<DataResource> resources = dataResourceRepository.queryDataResource(resourceParams);

            // 4. 删除旧的匹配记录
            dataRequirementRepository.deleteMatchesByRequirementId(requirementId);

            // 5. 计算匹配得分并保存
            List<DataRequirementMatch> matchList = new ArrayList<>();
            for (DataResource resource : resources) {
                try {
                    BigDecimal score = calculateMatchScore(requirement, resource, configMap);

                    // 只保存得分高于阈值的匹配
                    if (score.compareTo(matchThreshold) >= 0) {
                        DataRequirementMatch match = new DataRequirementMatch();
                        match.setRequirementId(requirementId);
                        match.setResourceId(resource.getResourceId());
                        match.setMatchScore(score);
                        match.setMatchStatus(0); // 待确认
                        match.setMatchType("自动匹配");

                        // 保存匹配详情
                        JSONObject details = calculateMatchDetails(requirement, resource, configMap);
                        match.setMatchDetails(details.toJSONString());

                        matchList.add(match);
                    }
                } catch (Exception e) {
                    log.error("计算匹配得分失败，requirementId={}, resourceId={}", requirementId, resource.getResourceId(), e);
                }
            }

            // 按得分排序，只保留前N条
            matchList.sort((m1, m2) -> m2.getMatchScore().compareTo(m1.getMatchScore()));
            if (matchList.size() > maxResults) {
                matchList = matchList.subList(0, maxResults);
            }

            // 批量保存匹配结果
            if (!matchList.isEmpty()) {
                dataRequirementRepository.batchInsertDataRequirementMatch(matchList);
            }

            // 更新需求状态为已匹配
            if (!matchList.isEmpty()) {
                dataRequirementRepository.updateDataRequirementStatus(requirementId, 1);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("matchCount", matchList.size());
            result.put("threshold", matchThreshold);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("执行数据需求匹配失败，requirementId={}", requirementId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "匹配失败");
        }
    }

    /**
     * 计算匹配得分
     */
    private BigDecimal calculateMatchScore(DataRequirement requirement, DataResource resource,
                                            Map<String, String> configMap) {
        BigDecimal fieldScore = calculateFieldMatchScore(requirement, resource);
        BigDecimal volumeScore = calculateVolumeMatchScore(requirement, resource);
        BigDecimal formatScore = calculateFormatMatchScore(requirement, resource);
        BigDecimal typeScore = calculateTypeMatchScore(requirement, resource);

        // 获取权重
        int fieldWeight = Integer.parseInt(configMap.getOrDefault("field_match_weight", "40"));
        int volumeWeight = Integer.parseInt(configMap.getOrDefault("volume_match_weight", "20"));
        int formatWeight = Integer.parseInt(configMap.getOrDefault("format_match_weight", "20"));
        int typeWeight = Integer.parseInt(configMap.getOrDefault("type_match_weight", "20"));

        // 计算加权总分
        BigDecimal totalScore = fieldScore.multiply(new BigDecimal(fieldWeight))
                .add(volumeScore.multiply(new BigDecimal(volumeWeight)))
                .add(formatScore.multiply(new BigDecimal(formatWeight)))
                .add(typeScore.multiply(new BigDecimal(typeWeight)))
                .divide(new BigDecimal(100), 2, RoundingMode.HALF_UP);

        return totalScore;
    }

    /**
     * 计算匹配详情
     */
    private JSONObject calculateMatchDetails(DataRequirement requirement, DataResource resource,
                                              Map<String, String> configMap) {
        JSONObject details = new JSONObject();

        BigDecimal fieldScore = calculateFieldMatchScore(requirement, resource);
        BigDecimal volumeScore = calculateVolumeMatchScore(requirement, resource);
        BigDecimal formatScore = calculateFormatMatchScore(requirement, resource);
        BigDecimal typeScore = calculateTypeMatchScore(requirement, resource);

        int fieldWeight = Integer.parseInt(configMap.getOrDefault("field_match_weight", "40"));
        int volumeWeight = Integer.parseInt(configMap.getOrDefault("volume_match_weight", "20"));
        int formatWeight = Integer.parseInt(configMap.getOrDefault("format_match_weight", "20"));
        int typeWeight = Integer.parseInt(configMap.getOrDefault("type_match_weight", "20"));

        details.put("fieldScore", fieldScore);
        details.put("volumeScore", volumeScore);
        details.put("formatScore", formatScore);
        details.put("typeScore", typeScore);
        details.put("fieldWeight", fieldWeight);
        details.put("volumeWeight", volumeWeight);
        details.put("formatWeight", formatWeight);
        details.put("typeWeight", typeWeight);

        return details;
    }

    /**
     * 计算字段匹配得分(0-100)
     */
    private BigDecimal calculateFieldMatchScore(DataRequirement requirement, DataResource resource) {
        try {
            String requirementFieldsJson = requirement.getDataFields();
            String resourceFieldsJson = resource.getFileHandleField();

            if (requirementFieldsJson == null || requirementFieldsJson.trim().isEmpty()) {
                return new BigDecimal(50); // 未指定字段要求，给中等分
            }

            if (resourceFieldsJson == null || resourceFieldsJson.trim().isEmpty()) {
                return BigDecimal.ZERO;
            }

            // 解析JSON字段列表
            JSONArray requiredFields = JSON.parseArray(requirementFieldsJson);
            JSONArray resourceFields = JSON.parseArray(resourceFieldsJson);

            if (requiredFields.isEmpty()) {
                return new BigDecimal(50);
            }

            // 计算匹配字段数量
            int matchCount = 0;
            for (int i = 0; i < requiredFields.size(); i++) {
                String requiredField = requiredFields.getString(i);
                for (int j = 0; j < resourceFields.size(); j++) {
                    String resourceField = resourceFields.getString(j);
                    if (requiredField.equalsIgnoreCase(resourceField)) {
                        matchCount++;
                        break;
                    }
                }
            }

            // 计算匹配率
            BigDecimal matchRate = new BigDecimal(matchCount)
                    .divide(new BigDecimal(requiredFields.size()), 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal(100));

            return matchRate;
        } catch (Exception e) {
            log.error("计算字段匹配得分失败", e);
            return BigDecimal.ZERO;
        }
    }

    /**
     * 计算数据量匹配得分(0-100)
     */
    private BigDecimal calculateVolumeMatchScore(DataRequirement requirement, DataResource resource) {
        try {
            Long requiredVolume = requirement.getDataVolume();
            Long resourceVolume = resource.getFileRows() != null ? resource.getFileRows().longValue() : 0L;

            if (requiredVolume == null || requiredVolume == 0) {
                return new BigDecimal(50); // 未指定数据量要求，给中等分
            }

            if (resourceVolume == null || resourceVolume == 0) {
                return BigDecimal.ZERO;
            }

            // 如果资源数据量大于等于需求数据量，满分
            if (resourceVolume >= requiredVolume) {
                return new BigDecimal(100);
            }

            // 否则按比例计算得分
            BigDecimal ratio = new BigDecimal(resourceVolume)
                    .divide(new BigDecimal(requiredVolume), 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal(100));

            return ratio;
        } catch (Exception e) {
            log.error("计算数据量匹配得分失败", e);
            return BigDecimal.ZERO;
        }
    }

    /**
     * 计算数据格式匹配得分(0-100)
     */
    private BigDecimal calculateFormatMatchScore(DataRequirement requirement, DataResource resource) {
        try {
            String requiredFormat = requirement.getDataFormat();
            String resourceFormat = resource.getFileSuffix();

            if (requiredFormat == null || requiredFormat.trim().isEmpty()) {
                return new BigDecimal(50); // 未指定格式要求，给中等分
            }

            if (resourceFormat == null || resourceFormat.trim().isEmpty()) {
                return BigDecimal.ZERO;
            }

            // 完全匹配
            if (requiredFormat.equalsIgnoreCase(resourceFormat)) {
                return new BigDecimal(100);
            }

            // 兼容格式(CSV和Excel可以互转)
            if ((requiredFormat.equalsIgnoreCase("CSV") && resourceFormat.toLowerCase().contains("excel")) ||
                (requiredFormat.toLowerCase().contains("excel") && resourceFormat.equalsIgnoreCase("CSV"))) {
                return new BigDecimal(80);
            }

            return BigDecimal.ZERO;
        } catch (Exception e) {
            log.error("计算数据格式匹配得分失败", e);
            return BigDecimal.ZERO;
        }
    }

    /**
     * 计算数据类型匹配得分(0-100)
     */
    private BigDecimal calculateTypeMatchScore(DataRequirement requirement, DataResource resource) {
        try {
            String requirementType = requirement.getRequirementType();
            String resourceType = null; // DataResource没有tag字段，使用null

            if (requirementType == null || requirementType.trim().isEmpty()) {
                return new BigDecimal(50); // 未指定类型要求，给中等分
            }

            if (resourceType == null || resourceType.trim().isEmpty()) {
                return new BigDecimal(30); // 资源未标记类型，给较低分
            }

            // 完全匹配
            if (requirementType.equalsIgnoreCase(resourceType)) {
                return new BigDecimal(100);
            }

            // 模糊匹配
            if (resourceType.contains(requirementType) || requirementType.contains(resourceType)) {
                return new BigDecimal(60);
            }

            return new BigDecimal(30); // 不匹配但给基础分
        } catch (Exception e) {
            log.error("计算数据类型匹配得分失败", e);
            return BigDecimal.ZERO;
        }
    }

    /**
     * 加载所有启用的配置
     */
    private Map<String, String> loadConfigs() {
        Map<String, String> configMap = new HashMap<>();
        try {
            List<DataRequirementConfig> configs = dataRequirementRepository.selectEnabledConfigs();
            for (DataRequirementConfig config : configs) {
                configMap.put(config.getConfigKey(), config.getConfigValue());
            }
        } catch (Exception e) {
            log.error("加载配置失败", e);
        }
        return configMap;
    }

    /**
     * 查询匹配的资源列表
     */
    public BaseResultEntity findMatchedResources(Long requirementId, Integer matchStatus,
                                                  Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("requirementId", requirementId);
            params.put("matchStatus", matchStatus);

            int total = dataRequirementRepository.selectDataRequirementMatchCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<DataRequirementMatch> list = dataRequirementRepository.selectDataRequirementMatchList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询匹配资源列表失败，requirementId={}", requirementId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 确认匹配
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity confirmMatch(Long matchId, Long confirmUserId, String confirmUserName) {
        try {
            DataRequirementMatch match = dataRequirementRepository.selectDataRequirementMatchById(matchId);
            if (match == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "匹配记录不存在");
            }

            dataRequirementRepository.updateMatchStatus(matchId, 1, confirmUserId, confirmUserName);

            // 更新需求状态为已完成
            dataRequirementRepository.updateDataRequirementStatus(match.getRequirementId(), 2);

            return BaseResultEntity.success("确认成功");
        } catch (Exception e) {
            log.error("确认匹配失败，matchId={}", matchId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "确认失败");
        }
    }

    /**
     * 拒绝匹配
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity rejectMatch(Long matchId, Long confirmUserId, String confirmUserName) {
        try {
            DataRequirementMatch match = dataRequirementRepository.selectDataRequirementMatchById(matchId);
            if (match == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "匹配记录不存在");
            }

            dataRequirementRepository.updateMatchStatus(matchId, 2, confirmUserId, confirmUserName);

            return BaseResultEntity.success("拒绝成功");
        } catch (Exception e) {
            log.error("拒绝匹配失败，matchId={}", matchId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "拒绝失败");
        }
    }
}
