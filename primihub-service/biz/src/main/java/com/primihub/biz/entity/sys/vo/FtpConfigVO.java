package com.primihub.biz.entity.sys.vo;

import lombok.Data;

@Data
public class FtpConfigVO {
    private Boolean enabled;
    private String host;
    private Integer port;
    private String username;
    private String password;
    private String mode;
    private Integer timeout;
    private Integer maxConnections;
}
