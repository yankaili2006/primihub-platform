package com.primihub.biz.entity.data.req;

import lombok.Data;
import java.util.List;

@Data
public class BatchExportReq {
    private List<Long> taskIds;
    private String format;
}
