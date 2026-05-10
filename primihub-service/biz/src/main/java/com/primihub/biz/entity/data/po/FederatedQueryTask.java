package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedQueryTask {
    private Long id;
    private String taskName;
    private String algorithm;
    private String queryMode;
    private String queryType;
    private Integer taskState;
    private String sourceConfig;
    private String resultSummary;
    private Integer resultRowCount;
    private String errorMessage;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
