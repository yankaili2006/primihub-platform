package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedStatsTask {
    private Long id;
    private String taskName;
    private Long projectId;
    private String statsType;
    private String algorithmType;
    private Integer taskState;
    private String taskParam;
    private String resultSummary;
    private String errorMessage;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
