package com.primihub.biz.entity.data.vo;

import lombok.Data;
import java.util.Date;

@Data
public class StatsTaskListVO {
    private Long id;
    private String taskName;
    private String statsType;
    private String statsTypeName;
    private Integer taskState;
    private String taskStateName;
    private String resultSummary;
    private Date createdAt;
}
