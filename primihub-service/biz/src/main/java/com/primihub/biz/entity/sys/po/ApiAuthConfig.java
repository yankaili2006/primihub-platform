package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class ApiAuthConfig {
    private Long id;
    private Long apiId;
    private String authName;
    private String appKey;
    private String appSecret;
    private String authType;
    private String allowedIps;
    private Date expireTime;
    private Integer status;
    private String description;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
