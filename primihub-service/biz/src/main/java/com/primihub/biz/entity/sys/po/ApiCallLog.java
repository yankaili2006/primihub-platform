package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class ApiCallLog {
    private Long id;
    private Long apiId;
    private Long authId;
    private String requestPath;
    private String requestMethod;
    private String requestParams;
    private String requestHeaders;
    private Integer responseCode;
    private String responseBody;
    private String clientIp;
    private Integer executionTime;
    private Integer isSuccess;
    private String errorMessage;
    private Date createdAt;
}
