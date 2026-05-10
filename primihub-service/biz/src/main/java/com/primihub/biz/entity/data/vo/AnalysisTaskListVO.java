package com.primihub.biz.entity.data.vo;

import lombok.Data;
import java.util.Date;

@Data
public class AnalysisTaskListVO {
    private Long id;
    private String taskName;
    private String sourceSql;
    private Integer taskState;
    private String taskStateName;
    private Integer resultRowCount;
    private Date createdAt;
}
