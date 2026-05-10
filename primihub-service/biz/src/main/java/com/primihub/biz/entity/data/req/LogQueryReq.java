package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class LogQueryReq {
    private Long taskId;
    private String logLevel;
    private String startDate;
    private String endDate;
    private Integer pageNo = 1;
    private Integer pageSize = 10;
}
