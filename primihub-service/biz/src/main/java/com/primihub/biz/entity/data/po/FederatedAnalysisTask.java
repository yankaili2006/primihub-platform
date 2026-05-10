package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedAnalysisTask {
    private Long id;
    private String taskName;
    private Long projectId;
    private String sourceSql;
    private String rewrittenSql;
    private Integer taskState;
    private String taskParam;
    private String resultSummary;
    private Integer resultRowCount;
    private String errorMessage;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
