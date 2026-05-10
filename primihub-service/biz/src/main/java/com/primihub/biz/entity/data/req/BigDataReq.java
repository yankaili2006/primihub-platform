package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class BigDataReq {
    private String type;
    private String master;
    private String appName;
    private String deployMode;
    private String executorMemory;
}
