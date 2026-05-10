package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class ApiDefinition {
    private Long id;
    private String apiName;
    private String apiPath;
    private String apiMethod;
    private String protocol;
    private String contentType;
    private String description;
    private String requestExample;
    private String responseExample;
    private Integer status;
    private Integer isRequireAuth;
    private Integer rateLimit;
    private Integer timeout;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
