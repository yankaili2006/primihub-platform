package com.primihub.biz.config.base;

import com.primihub.biz.entity.data.vo.ModelComponent;
import com.primihub.biz.entity.sys.config.BaseAuthConfig;
import com.primihub.biz.entity.sys.config.LokiConfig;
import com.primihub.sdk.config.GrpcClientConfig;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.autoconfigure.mail.MailProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Set;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "base")
public class BaseConfiguration {
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
     * Development mode settings
     */
    private boolean devMode = false;
    private boolean skipCaptcha = false;
    private boolean skipVerificationCode = false;
    private boolean skipRsaValidation = false;
    /**
     * loki
     */
    private LokiConfig lokiConfig;
    /**
     * Open the nacos template for debugging
     */
    private Boolean openDynamicTuning = false;

    private Integer uploadSize = 10;
}
