package com.primihub.biz.service.sys.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.po.SysConfig;
import com.primihub.biz.entity.sys.vo.*;
import com.primihub.biz.repository.primarydb.sys.SysConfigPrimarydbRepository;
import com.primihub.biz.service.sys.SysConfigService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class SysConfigServiceImpl implements SysConfigService {

    @Autowired
    private SysConfigPrimarydbRepository sysConfigRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            log.error("JSON序列化失败", e);
            return "{}";
        }
    }

    private <T> T fromJson(String json, Class<T> clazz) {
        try {
            return objectMapper.readValue(json, clazz);
        } catch (JsonProcessingException e) {
            log.error("JSON反序列化失败", e);
            try {
                return clazz.getDeclaredConstructor().newInstance();
            } catch (Exception ex) {
                return null;
            }
        }
    }

    private Map<String, String> getConfigMap(String group) {
        List<SysConfig> configs = sysConfigRepository.selectByGroup(group);
        Map<String, String> map = new HashMap<>();
        for (SysConfig c : configs) {
            map.put(c.getConfigKey(), c.getConfigValue());
        }
        return map;
    }

    private void saveConfigMap(String group, Map<String, String> map) {
        for (Map.Entry<String, String> entry : map.entrySet()) {
            SysConfig existing = sysConfigRepository.selectByGroupAndKey(group, entry.getKey());
            SysConfig config = new SysConfig();
            config.setConfigGroup(group);
            config.setConfigKey(entry.getKey());
            config.setConfigValue(entry.getValue());
            config.setConfigDesc("");
            config.setIsEncrypted(0);
            if (existing != null) {
                sysConfigRepository.updateByGroupAndKey(config);
            } else {
                sysConfigRepository.insert(config);
            }
        }
    }

    private String getConfigValue(String group, String key, String defaultValue) {
        SysConfig config = sysConfigRepository.selectByGroupAndKey(group, key);
        return config != null ? config.getConfigValue() : defaultValue;
    }

    // ==================== 网络地址 ====================

    @Override
    public BaseResultEntity getNetworkConfig() {
        try {
            Map<String, String> map = getConfigMap("network");
            NetworkConfigVO vo = new NetworkConfigVO();
            vo.setDomain(map.getOrDefault("domain", ""));
            vo.setApiGateway(map.getOrDefault("api_gateway", ""));
            vo.setWebsocketUrl(map.getOrDefault("websocket_url", ""));
            vo.setFileServerUrl(map.getOrDefault("file_server_url", ""));
            vo.setHttpProxyHost(map.getOrDefault("http_proxy_host", ""));
            vo.setHttpProxyPort(parseInt(map.get("http_proxy_port"), 7890));
            vo.setCorsEnabled(parseBool(map.get("cors_enabled"), true));
            vo.setRequestTimeout(parseInt(map.get("request_timeout"), 30000));
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("获取网络地址配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取配置失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveNetworkConfig(NetworkConfigVO vo) {
        try {
            Map<String, String> map = new HashMap<>();
            map.put("domain", str(vo.getDomain()));
            map.put("api_gateway", str(vo.getApiGateway()));
            map.put("websocket_url", str(vo.getWebsocketUrl()));
            map.put("file_server_url", str(vo.getFileServerUrl()));
            map.put("http_proxy_host", str(vo.getHttpProxyHost()));
            map.put("http_proxy_port", String.valueOf(vo.getHttpProxyPort() != null ? vo.getHttpProxyPort() : 7890));
            map.put("cors_enabled", String.valueOf(vo.getCorsEnabled() != null ? vo.getCorsEnabled() : true));
            map.put("request_timeout", String.valueOf(vo.getRequestTimeout() != null ? vo.getRequestTimeout() : 30000));
            saveConfigMap("network", map);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存网络地址配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    // ==================== 时间配置 ====================

    @Override
    public BaseResultEntity getTimeConfig() {
        try {
            Map<String, String> map = getConfigMap("time");
            TimeConfigVO vo = new TimeConfigVO();
            vo.setTimezone(map.getOrDefault("timezone", "Asia/Shanghai"));
            vo.setDateFormat(map.getOrDefault("date_format", "YYYY-MM-DD"));
            vo.setDatetimeFormat(map.getOrDefault("datetime_format", "YYYY-MM-DD HH:mm:ss"));
            vo.setNtpEnabled(parseBool(map.get("ntp_enabled"), false));
            vo.setNtpServer(map.getOrDefault("ntp_server", "ntp.aliyun.com"));
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("获取时间配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取配置失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveTimeConfig(TimeConfigVO vo) {
        try {
            Map<String, String> map = new HashMap<>();
            map.put("timezone", str(vo.getTimezone()));
            map.put("date_format", str(vo.getDateFormat()));
            map.put("datetime_format", str(vo.getDatetimeFormat()));
            map.put("ntp_enabled", String.valueOf(vo.getNtpEnabled() != null ? vo.getNtpEnabled() : false));
            map.put("ntp_server", str(vo.getNtpServer()));
            saveConfigMap("time", map);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存时间配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    // ==================== 登录限制 ====================

    @Override
    public BaseResultEntity getLoginRestriction() {
        try {
            Map<String, String> map = getConfigMap("login_restriction");
            LoginRestrictionVO vo = new LoginRestrictionVO();
            vo.setForceChangePassword(parseBool(map.get("force_change_password"), true));
            vo.setPasswordMinLength(parseInt(map.get("password_min_length"), 8));
            vo.setPasswordRequireUpper(parseBool(map.get("password_require_upper"), true));
            vo.setPasswordRequireLower(parseBool(map.get("password_require_lower"), true));
            vo.setPasswordRequireDigit(parseBool(map.get("password_require_digit"), true));
            vo.setPasswordRequireSpecial(parseBool(map.get("password_require_special"), false));
            vo.setMaxLoginAttempts(parseInt(map.get("max_login_attempts"), 5));
            vo.setLockDurationMinutes(parseInt(map.get("lock_duration_minutes"), 30));
            vo.setLockResetMinutes(parseInt(map.get("lock_reset_minutes"), 60));
            vo.setCaptchaEnabled(parseBool(map.get("captcha_enabled"), true));
            vo.setSessionTimeoutMinutes(parseInt(map.get("session_timeout_minutes"), 30));
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("获取登录限制配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取配置失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveLoginRestriction(LoginRestrictionVO vo) {
        try {
            Map<String, String> map = new HashMap<>();
            map.put("force_change_password", String.valueOf(vo.getForceChangePassword() != null ? vo.getForceChangePassword() : true));
            map.put("password_min_length", String.valueOf(vo.getPasswordMinLength() != null ? vo.getPasswordMinLength() : 8));
            map.put("password_require_upper", String.valueOf(vo.getPasswordRequireUpper() != null ? vo.getPasswordRequireUpper() : true));
            map.put("password_require_lower", String.valueOf(vo.getPasswordRequireLower() != null ? vo.getPasswordRequireLower() : true));
            map.put("password_require_digit", String.valueOf(vo.getPasswordRequireDigit() != null ? vo.getPasswordRequireDigit() : true));
            map.put("password_require_special", String.valueOf(vo.getPasswordRequireSpecial() != null ? vo.getPasswordRequireSpecial() : false));
            map.put("max_login_attempts", String.valueOf(vo.getMaxLoginAttempts() != null ? vo.getMaxLoginAttempts() : 5));
            map.put("lock_duration_minutes", String.valueOf(vo.getLockDurationMinutes() != null ? vo.getLockDurationMinutes() : 30));
            map.put("lock_reset_minutes", String.valueOf(vo.getLockResetMinutes() != null ? vo.getLockResetMinutes() : 60));
            map.put("captcha_enabled", String.valueOf(vo.getCaptchaEnabled() != null ? vo.getCaptchaEnabled() : true));
            map.put("session_timeout_minutes", String.valueOf(vo.getSessionTimeoutMinutes() != null ? vo.getSessionTimeoutMinutes() : 30));
            saveConfigMap("login_restriction", map);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存登录限制配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    // ==================== 平台个性化 ====================

    @Override
    public BaseResultEntity getPersonalizationConfig() {
        try {
            Map<String, String> map = getConfigMap("personalization");
            PersonalizationConfigVO vo = new PersonalizationConfigVO();
            vo.setPlatformName(map.getOrDefault("platform_name", "PrimiHub"));
            vo.setPlatformShortName(map.getOrDefault("platform_short_name", "PrimiHub"));
            vo.setCopyright(map.getOrDefault("copyright", ""));
            vo.setIcpNumber(map.getOrDefault("icp_number", ""));
            vo.setThemeColor(map.getOrDefault("theme_color", "#409EFF"));
            vo.setDefaultLanguage(map.getOrDefault("default_language", "zh-CN"));
            vo.setPageSize(parseInt(map.get("page_size"), 10));
            vo.setFixedHeader(parseBool(map.get("fixed_header"), true));
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("获取个性化配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取配置失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity savePersonalizationConfig(PersonalizationConfigVO vo) {
        try {
            Map<String, String> map = new HashMap<>();
            map.put("platform_name", str(vo.getPlatformName()));
            map.put("platform_short_name", str(vo.getPlatformShortName()));
            map.put("copyright", str(vo.getCopyright()));
            map.put("icp_number", str(vo.getIcpNumber()));
            map.put("theme_color", str(vo.getThemeColor()));
            map.put("default_language", str(vo.getDefaultLanguage()));
            map.put("page_size", String.valueOf(vo.getPageSize() != null ? vo.getPageSize() : 10));
            map.put("fixed_header", String.valueOf(vo.getFixedHeader() != null ? vo.getFixedHeader() : true));
            saveConfigMap("personalization", map);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存个性化配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    // ==================== FTP配置 ====================

    @Override
    public BaseResultEntity getFtpConfig() {
        try {
            Map<String, String> map = getConfigMap("ftp");
            FtpConfigVO vo = new FtpConfigVO();
            vo.setEnabled(parseBool(map.get("enabled"), false));
            vo.setHost(map.getOrDefault("host", ""));
            vo.setPort(parseInt(map.get("port"), 21));
            vo.setUsername(map.getOrDefault("username", ""));
            vo.setPassword(map.getOrDefault("password", ""));
            vo.setMode(map.getOrDefault("mode", "passive"));
            vo.setTimeout(parseInt(map.get("timeout"), 30000));
            vo.setMaxConnections(parseInt(map.get("max_connections"), 5));
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("获取FTP配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "获取配置失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveFtpConfig(FtpConfigVO vo) {
        try {
            Map<String, String> map = new HashMap<>();
            map.put("enabled", String.valueOf(vo.getEnabled() != null ? vo.getEnabled() : false));
            map.put("host", str(vo.getHost()));
            map.put("port", String.valueOf(vo.getPort() != null ? vo.getPort() : 21));
            map.put("username", str(vo.getUsername()));
            map.put("password", str(vo.getPassword()));
            map.put("mode", str(vo.getMode()));
            map.put("timeout", String.valueOf(vo.getTimeout() != null ? vo.getTimeout() : 30000));
            map.put("max_connections", String.valueOf(vo.getMaxConnections() != null ? vo.getMaxConnections() : 5));
            saveConfigMap("ftp", map);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存FTP配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Override
    public BaseResultEntity testFtpConnection(FtpConfigVO vo) {
        try {
            if (vo.getHost() == null || vo.getHost().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "FTP主机地址不能为空");
            }
            // 使用 Apache Commons Net 测试连接
            boolean connected = testFtpConnect(vo);
            Map<String, Object> result = new HashMap<>();
            result.put("connected", connected);
            result.put("message", connected ? "连接成功" : "连接失败，请检查配置");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("测试FTP连接失败", e);
            Map<String, Object> result = new HashMap<>();
            result.put("connected", false);
            result.put("message", "连接异常: " + e.getMessage());
            return BaseResultEntity.success(result);
        }
    }

    private boolean testFtpConnect(FtpConfigVO vo) {
        // 使用Apache Commons Net FTPClient
        try {
            org.apache.commons.net.ftp.FTPClient ftpClient = new org.apache.commons.net.ftp.FTPClient();
            ftpClient.setConnectTimeout(vo.getTimeout() != null ? vo.getTimeout() : 10000);
            ftpClient.connect(vo.getHost(), vo.getPort() != null ? vo.getPort() : 21);
            boolean login = ftpClient.login(vo.getUsername(), vo.getPassword());
            if (login) {
                ftpClient.logout();
            }
            ftpClient.disconnect();
            return login;
        } catch (Exception e) {
            log.warn("FTP连接测试失败: {}", e.getMessage());
            return false;
        }
    }

    // ==================== 工具方法 ====================

    private int parseInt(String val, int defaultVal) {
        if (val == null || val.isEmpty()) return defaultVal;
        try { return Integer.parseInt(val); } catch (NumberFormatException e) { return defaultVal; }
    }

    private boolean parseBool(String val, boolean defaultVal) {
        if (val == null || val.isEmpty()) return defaultVal;
        return "true".equalsIgnoreCase(val) || "1".equals(val);
    }

    private String str(String val) {
        return val != null ? val : "";
    }
}
