package com.primihub.biz.entity.data.vo;

import lombok.Data;

@Data
public class DataSourceVO {
    private Long id;
    private String sourceName;
    private String sourceType;
    private Boolean isConnected;
    private String lastTestTime;
}
