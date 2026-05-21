package com.primihub.biz.entity.data.req;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LogQueryReq {
    private Long taskId;
    private String logLevel;
    private String startDate;
    private String endDate;
    private Integer pageNo = 1;
    private Integer pageSize = 10;

    public LogQueryReq(Long taskId, String startDate, String endDate) {
        this.taskId = taskId;
        this.startDate = startDate;
        this.endDate = endDate;
    }
}
