package com.primihub.biz.entity.sys.vo;

import lombok.Data;

@Data
public class NetworkConfigVO {
    private String domain;
    private String apiGateway;
    private String websocketUrl;
    private String fileServerUrl;
    private String httpProxyHost;
    private Integer httpProxyPort;
    private Boolean corsEnabled;
    private Integer requestTimeout;
}
