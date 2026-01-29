package com.primihub.biz.config.base;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.nacos.api.NacosFactory;
import com.alibaba.nacos.api.config.ConfigService;
import com.alibaba.nacos.api.config.annotation.NacosConfigurationProperties;
import com.alibaba.nacos.api.config.listener.Listener;
import com.primihub.biz.entity.data.vo.ModelComponent;
import com.primihub.biz.entity.sys.config.BaseAuthConfig;
import com.primihub.biz.entity.sys.config.LokiConfig;
import com.primihub.sdk.config.GrpcClientConfig;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.boot.autoconfigure.mail.MailProperties;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.Executor;

@Slf4j
@Getter
@Setter
@Component
@NacosConfigurationProperties(dataId = "base.json",autoRefreshed = true)
public class BaseConfiguration {
    @Resource
    private Environment environment;
    private Set<String> tokenValidateUriBlackList;
    private Set<String> needSignUriList;
    private Set<Long> adminUserIds;
    private String primihubOfficalService;
    private String defaultPassword;
    private String defaultPasswordVector;
    private GrpcClientConfig grpcClient;
    private Integer grpcServerPort;
    private String uploadUrlDirPrefix;
    private String resultUrlDirPrefix;
    private String runModelFileUrlDirPrefix;
    private String usefulToken;
    private String taskEmailSubject;
    /**
     * resource
     */
    private boolean displayDatabaseSourceType = false;
    /**
     * auth
     */
    private Map<String, BaseAuthConfig> authConfigs;
    /**
     * mail
     */
    private MailProperties mailProperties;
    /**
     * Use in mail text content
     */
    private String systemDomainName;
    /**
     * loki
     */
    private LokiConfig lokiConfig;
    /**
     * Open the nacos template for debugging
     */
    private Boolean openDynamicTuning = false;

    private Integer uploadSize = 10;

    @PostConstruct
    public void init() {
        loadBaseConfigFromNacos();
    }

    private void loadBaseConfigFromNacos() {
        try {
            String group = environment.getProperty("nacos.config.group", "DEFAULT_GROUP");
            String serverAddr = environment.getProperty("nacos.config.server-addr");
            String namespace = environment.getProperty("nacos.config.namespace");

            if (StringUtils.isBlank(serverAddr)) {
                log.warn("Nacos server address not configured, skipping base.json loading");
                return;
            }

            Properties properties = new Properties();
            properties.put("serverAddr", serverAddr);
            if (StringUtils.isNotBlank(namespace)) {
                properties.put("namespace", namespace);
            }

            ConfigService configService = NacosFactory.createConfigService(properties);
            String baseConfigContent = configService.getConfig("base.json", group, 3000);
            log.info("Nacos base.json loaded, content length: {}", baseConfigContent != null ? baseConfigContent.length() : 0);

            if (StringUtils.isNotBlank(baseConfigContent)) {
                parseAndSetConfig(baseConfigContent);
            }

            configService.addListener("base.json", group, new Listener() {
                @Override
                public Executor getExecutor() {
                    return null;
                }

                @Override
                public void receiveConfigInfo(String config) {
                    log.info("Nacos base.json updated, content length: {}", config != null ? config.length() : 0);
                    if (StringUtils.isNotBlank(config)) {
                        parseAndSetConfig(config);
                    }
                }
            });
        } catch (Exception e) {
            log.error("Failed to load base.json from Nacos: {}", e.getMessage(), e);
        }
    }

    private void parseAndSetConfig(String jsonContent) {
        try {
            JSONObject json = JSON.parseObject(jsonContent);

            if (json.containsKey("tokenValidateUriBlackList")) {
                this.tokenValidateUriBlackList = new java.util.HashSet<>(
                    json.getJSONArray("tokenValidateUriBlackList").toJavaList(String.class));
                log.info("Loaded tokenValidateUriBlackList with {} entries",
                    this.tokenValidateUriBlackList != null ? this.tokenValidateUriBlackList.size() : 0);
            }
            if (json.containsKey("needSignUriList")) {
                this.needSignUriList = new java.util.HashSet<>(
                    json.getJSONArray("needSignUriList").toJavaList(String.class));
            }
            if (json.containsKey("adminUserIds")) {
                this.adminUserIds = new java.util.HashSet<>(
                    json.getJSONArray("adminUserIds").toJavaList(Long.class));
            }
            if (json.containsKey("primihubOfficalService")) {
                this.primihubOfficalService = json.getString("primihubOfficalService");
            }
            if (json.containsKey("defaultPassword")) {
                this.defaultPassword = json.getString("defaultPassword");
            }
            if (json.containsKey("defaultPasswordVector")) {
                this.defaultPasswordVector = json.getString("defaultPasswordVector");
            }
            if (json.containsKey("grpcClient")) {
                this.grpcClient = json.getObject("grpcClient", GrpcClientConfig.class);
            }
            if (json.containsKey("grpcServerPort")) {
                this.grpcServerPort = json.getInteger("grpcServerPort");
            }
            if (json.containsKey("uploadUrlDirPrefix")) {
                this.uploadUrlDirPrefix = json.getString("uploadUrlDirPrefix");
            }
            if (json.containsKey("resultUrlDirPrefix")) {
                this.resultUrlDirPrefix = json.getString("resultUrlDirPrefix");
            }
            if (json.containsKey("runModelFileUrlDirPrefix")) {
                this.runModelFileUrlDirPrefix = json.getString("runModelFileUrlDirPrefix");
            }
            if (json.containsKey("usefulToken")) {
                this.usefulToken = json.getString("usefulToken");
            }
            if (json.containsKey("taskEmailSubject")) {
                this.taskEmailSubject = json.getString("taskEmailSubject");
            }
            if (json.containsKey("displayDatabaseSourceType")) {
                this.displayDatabaseSourceType = json.getBoolean("displayDatabaseSourceType");
            }
            if (json.containsKey("authConfigs")) {
                JSONObject authConfigsJson = json.getJSONObject("authConfigs");
                if (authConfigsJson != null) {
                    this.authConfigs = new java.util.HashMap<>();
                    for (String key : authConfigsJson.keySet()) {
                        BaseAuthConfig config = authConfigsJson.getObject(key, BaseAuthConfig.class);
                        this.authConfigs.put(key, config);
                    }
                }
            }
            if (json.containsKey("mailProperties")) {
                this.mailProperties = json.getObject("mailProperties", MailProperties.class);
            }
            if (json.containsKey("systemDomainName")) {
                this.systemDomainName = json.getString("systemDomainName");
            }
            if (json.containsKey("lokiConfig")) {
                this.lokiConfig = json.getObject("lokiConfig", LokiConfig.class);
            }
            if (json.containsKey("openDynamicTuning")) {
                this.openDynamicTuning = json.getBoolean("openDynamicTuning");
            }
            if (json.containsKey("uploadSize")) {
                this.uploadSize = json.getInteger("uploadSize");
            }
        } catch (Exception e) {
            log.error("Failed to parse base.json content: {}", e.getMessage(), e);
        }
    }
}
