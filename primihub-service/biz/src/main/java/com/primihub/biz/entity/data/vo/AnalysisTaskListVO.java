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
    /** 该任务绑定的数据源类型(由 task_param.datasourceId 解析)，未绑定则为 null */
    private String dataSourceType;
    private Date createdAt;
}
