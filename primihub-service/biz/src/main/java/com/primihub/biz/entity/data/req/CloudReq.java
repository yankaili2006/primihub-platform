package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class CloudReq {
    private String type;
    private String endpoint;
    private String bucket;
    private String accessKey;
    private String secretKey;
    private String region;
}
