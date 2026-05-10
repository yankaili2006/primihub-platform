package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class ExportReq {
    private Long taskId;
    private String format;
}
