package com.primihub.biz.entity.data.req;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class AnalysisTaskReq {
    private String taskName;
    private Long projectId;
    private String sourceSql;
    private Map<String, Object> params;
}
