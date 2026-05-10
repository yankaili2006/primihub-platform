package com.primihub.biz.entity.data.vo;

import lombok.Data;
import java.util.Date;
import java.util.List;

@Data
public class AnalysisTaskDetailVO {
    private Long id;
    private String taskName;
    private String sourceSql;
    private String rewrittenSql;
    private Integer taskState;
    private String taskStateName;
    private Integer resultRowCount;
    private String errorMessage;
    private Date createdAt;
    private List<FederatedAnalysisResultVO> results;
}

@Data
class FederatedAnalysisResultVO {
    private Long id;
    private String resultType;
    private Object resultData;
    private Integer rowCount;
    private Date createdAt;
}
