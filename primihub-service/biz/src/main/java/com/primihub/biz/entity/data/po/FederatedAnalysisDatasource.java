package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedAnalysisDatasource {
    private Long id;
    private String sourceName;
    private String sourceType;
    private String sourceConfig;
    private Integer isConnected;
    private Date lastTestTime;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
