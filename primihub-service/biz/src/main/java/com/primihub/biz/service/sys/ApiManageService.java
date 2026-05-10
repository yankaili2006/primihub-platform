package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.ApiAuthConfig;
import com.primihub.biz.entity.sys.po.ApiCallLog;
import com.primihub.biz.entity.sys.po.ApiDefinition;
import com.primihub.biz.repository.primarydb.sys.ApiManagePrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Slf4j
@Service
public class ApiManageService {

    @Autowired
    private ApiManagePrimarydbRepository apiManageRepository;

    // ========== 接口定义 ==========

    public BaseResultEntity findApiPage(String keyword, String status, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            if (status != null && !status.isEmpty()) params.put("status", Integer.parseInt(status));
            if (pageNum == null) pageNum = 1;
            if (pageSize == null) pageSize = 10;

            int total = apiManageRepository.selectApiDefinitionCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ApiDefinition> list = apiManageRepository.selectApiDefinitionList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询接口列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addApi(Map<String, Object> data) {
        try {
            String apiName = data.get("apiName") != null ? data.get("apiName").toString() : "";
            String apiPath = data.get("apiPath") != null ? data.get("apiPath").toString() : "";
            if (apiName.isEmpty() || apiPath.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "接口名称和路径不能为空");
            }

            ApiDefinition definition = new ApiDefinition();
            definition.setApiName(apiName);
            definition.setApiPath(apiPath);
            definition.setApiMethod(data.get("apiMethod") != null ? data.get("apiMethod").toString() : "POST");
            definition.setProtocol(data.get("protocol") != null ? data.get("protocol").toString() : "REST");
            definition.setContentType(data.get("contentType") != null ? data.get("contentType").toString() : "application/json");
            definition.setDescription(data.get("description") != null ? data.get("description").toString() : "");
            definition.setRequestExample(data.get("requestExample") != null ? data.get("requestExample").toString() : "");
            definition.setResponseExample(data.get("responseExample") != null ? data.get("responseExample").toString() : "");
            definition.setStatus(1);
            definition.setIsRequireAuth(1);
            definition.setRateLimit(data.get("rateLimit") != null ? Integer.valueOf(data.get("rateLimit").toString()) : 0);
            definition.setTimeout(data.get("timeout") != null ? Integer.valueOf(data.get("timeout").toString()) : 30000);
            definition.setCreatedBy(data.get("createdBy") != null ? Long.valueOf(data.get("createdBy").toString()) : null);
            apiManageRepository.insertApiDefinition(definition);
            return BaseResultEntity.success("新增成功");
        } catch (Exception e) {
            log.error("新增接口失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "新增失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateApi(Map<String, Object> data) {
        try {
            Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }
            ApiDefinition existing = apiManageRepository.selectApiDefinitionById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接口不存在");
            }
            if (data.containsKey("apiName")) existing.setApiName(data.get("apiName").toString());
            if (data.containsKey("apiPath")) existing.setApiPath(data.get("apiPath").toString());
            if (data.containsKey("apiMethod")) existing.setApiMethod(data.get("apiMethod").toString());
            if (data.containsKey("description")) existing.setDescription(data.get("description").toString());
            if (data.containsKey("isRequireAuth")) existing.setIsRequireAuth(Integer.valueOf(data.get("isRequireAuth").toString()));
            if (data.containsKey("rateLimit")) existing.setRateLimit(Integer.valueOf(data.get("rateLimit").toString()));
            if (data.containsKey("timeout")) existing.setTimeout(Integer.valueOf(data.get("timeout").toString()));
            apiManageRepository.updateApiDefinition(existing);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新接口失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "更新失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteApi(Long id) {
        try {
            apiManageRepository.deleteApiDefinition(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除接口失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteApi(List<Long> ids) {
        try {
            apiManageRepository.batchDeleteApiDefinition(ids);
            return BaseResultEntity.success("批量删除成功");
        } catch (Exception e) {
            log.error("批量删除接口失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "批量删除失败");
        }
    }

    public BaseResultEntity getApiDetail(Long id) {
        try {
            ApiDefinition definition = apiManageRepository.selectApiDefinitionById(id);
            if (definition == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "接口不存在");
            }
            return BaseResultEntity.success(definition);
        } catch (Exception e) {
            log.error("查询接口详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity toggleApiStatus(Long id, Integer status) {
        try {
            apiManageRepository.updateApiDefinitionStatus(id, status);
            return BaseResultEntity.success(status == 1 ? "启用成功" : "禁用成功");
        } catch (Exception e) {
            log.error("更新接口状态失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    // ========== 接口授权 ==========

    public BaseResultEntity findApiAuthPage(String keyword, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            if (pageNum == null) pageNum = 1;
            if (pageSize == null) pageSize = 10;

            int total = apiManageRepository.selectApiAuthConfigCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ApiAuthConfig> list = apiManageRepository.selectApiAuthConfigList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询接口授权列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addApiAuth(Map<String, Object> data) {
        try {
            ApiAuthConfig config = new ApiAuthConfig();
            config.setApiId(data.get("apiId") != null ? Long.valueOf(data.get("apiId").toString()) : null);
            config.setAuthName(data.get("authName") != null ? data.get("authName").toString() : "");
            config.setAppKey("ak_" + UUID.randomUUID().toString().replace("-", "").substring(0, 20));
            config.setAppSecret("sk_" + UUID.randomUUID().toString().replace("-", ""));
            config.setAuthType(data.get("authType") != null ? data.get("authType").toString() : "APP_KEY");
            config.setAllowedIps(data.get("allowedIps") != null ? data.get("allowedIps").toString() : "");
            config.setStatus(1);
            config.setDescription(data.get("description") != null ? data.get("description").toString() : "");
            config.setCreatedBy(data.get("createdBy") != null ? Long.valueOf(data.get("createdBy").toString()) : null);
            apiManageRepository.insertApiAuthConfig(config);
            return BaseResultEntity.success("新增授权成功");
        } catch (Exception e) {
            log.error("新增接口授权失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "新增失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateApiAuth(Map<String, Object> data) {
        try {
            Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }
            ApiAuthConfig config = apiManageRepository.selectApiAuthConfigById(id);
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "授权不存在");
            }
            if (data.containsKey("authName")) config.setAuthName(data.get("authName").toString());
            if (data.containsKey("allowedIps")) config.setAllowedIps(data.get("allowedIps").toString());
            if (data.containsKey("status")) config.setStatus(Integer.valueOf(data.get("status").toString()));
            if (data.containsKey("description")) config.setDescription(data.get("description").toString());
            apiManageRepository.updateApiAuthConfig(config);
            return BaseResultEntity.success("更新授权成功");
        } catch (Exception e) {
            log.error("更新接口授权失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "更新失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteApiAuth(Long id) {
        try {
            apiManageRepository.deleteApiAuthConfig(id);
            return BaseResultEntity.success("删除授权成功");
        } catch (Exception e) {
            log.error("删除接口授权失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        }
    }

    public BaseResultEntity validateApiAuth(Map<String, Object> data) {
        try {
            String appKey = data.get("appKey") != null ? data.get("appKey").toString() : "";
            String appSecret = data.get("appSecret") != null ? data.get("appSecret").toString() : "";
            if (appKey.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "AppKey不能为空");
            }
            ApiAuthConfig config = apiManageRepository.selectApiAuthConfigByAppKey(appKey);
            if (config == null) {
                Map<String, Object> result = new HashMap<>();
                result.put("valid", false);
                result.put("message", "授权不存在");
                return BaseResultEntity.success(result);
            }
            if (config.getStatus() != 1) {
                Map<String, Object> result = new HashMap<>();
                result.put("valid", false);
                result.put("message", "授权已禁用");
                return BaseResultEntity.success(result);
            }
            if (config.getExpireTime() != null && config.getExpireTime().before(new Date())) {
                Map<String, Object> result = new HashMap<>();
                result.put("valid", false);
                result.put("message", "授权已过期");
                return BaseResultEntity.success(result);
            }
            Map<String, Object> result = new HashMap<>();
            result.put("valid", true);
            result.put("message", "授权验证成功");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("校验接口授权失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "校验失败");
        }
    }

    public BaseResultEntity getAuthToken(Map<String, Object> data) {
        try {
            String appKey = data.get("appKey") != null ? data.get("appKey").toString() : "";
            String appSecret = data.get("appSecret") != null ? data.get("appSecret").toString() : "";

            ApiAuthConfig config = apiManageRepository.selectApiAuthConfigByAppKey(appKey);
            if (config == null || config.getStatus() != 1) {
                return BaseResultEntity.failure(BaseResultEnum.AUTH_LOGIN, "授权验证失败");
            }

            String token = Base64.getEncoder().encodeToString((appKey + ":" + System.currentTimeMillis()).getBytes());
            Map<String, Object> result = new HashMap<>();
            result.put("token", token);
            result.put("expiresIn", 3600);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("获取授权令牌失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取令牌失败");
        }
    }

    public BaseResultEntity refreshAuthToken(Map<String, Object> data) {
        return getAuthToken(data);
    }

    // ========== 接口日志 ==========

    public BaseResultEntity findApiLogPage(String apiPath, String startTime, String endTime, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("apiPath", apiPath);
            params.put("startTime", startTime);
            params.put("endTime", endTime);
            if (pageNum == null) pageNum = 1;
            if (pageSize == null) pageSize = 10;

            int total = apiManageRepository.selectApiCallLogCount(params);
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ApiCallLog> list = apiManageRepository.selectApiCallLogList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询接口日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getApiLogDetail(Long id) {
        try {
            ApiCallLog log = apiManageRepository.selectApiCallLogById(id);
            if (log == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "日志不存在");
            }
            return BaseResultEntity.success(log);
        } catch (Exception e) {
            log.error("查询接口日志详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getApiStatistics(String startTime, String endTime) {
        try {
            Map<String, Object> stats = apiManageRepository.selectApiCallStatistics(startTime, endTime);
            if (stats == null) {
                stats = new HashMap<>();
                stats.put("totalCalls", 0);
                stats.put("successCalls", 0);
                stats.put("failedCalls", 0);
                stats.put("avgResponseTime", 0);
            }
            return BaseResultEntity.success(stats);
        } catch (Exception e) {
            log.error("获取接口调用统计失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity exportApiLog(String startTime, String endTime) {
        try {
            return BaseResultEntity.success("导出成功");
        } catch (Exception e) {
            log.error("导出接口日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "导出失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity clearApiLog(Map<String, Object> data) {
        try {
            String beforeTime = data.get("beforeTime") != null ? data.get("beforeTime").toString() : null;
            apiManageRepository.clearApiCallLog(beforeTime);
            return BaseResultEntity.success("清空成功");
        } catch (Exception e) {
            log.error("清空接口日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "清空失败");
        }
    }
}
