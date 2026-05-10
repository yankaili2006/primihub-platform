package com.primihub.biz.entity.data.vo;

import com.primihub.biz.entity.data.po.FederatedStatsResult;
import lombok.Data;
import java.util.Date;
import java.util.List;

@Data
public class StatsTaskDetailVO {
    private Long id;
    private String taskName;
    private String statsType;
    private String statsTypeName;
    private String algorithmType;
    private Integer taskState;
    private String taskStateName;
    private String taskParam;
    private String resultSummary;
    private String errorMessage;
    private Date createdAt;
    private List<FederatedStatsResult> results;
}
