package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class AnalysisTaskQueryReq {
    private String taskName;
    private Integer taskState;
    private Long projectId;
    private String startDate;
    private String endDate;
    private Integer pageNo = 1;
    private Integer pageSize = 10;
}
