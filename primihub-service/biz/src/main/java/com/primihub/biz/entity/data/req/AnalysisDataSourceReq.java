package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class AnalysisDataSourceReq {
    private Long id;
    private String sourceName;
    private String sourceType;
    private String sourceConfig;
}
