package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class EvidenceApiCallLog {
    private Long id;
    private Long apiKeyId;
    private String apiPath;
    private String requestMethod;
    private String requestParams;
    private Integer responseCode;
    private String responseBody;
    private String clientIp;
    private Integer executionTime;
    private Integer status;
    private Date createdAt;
}
