package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class LogExportReq {
    private Long taskId;
    private String format;
    private String startDate;
    private String endDate;
}
