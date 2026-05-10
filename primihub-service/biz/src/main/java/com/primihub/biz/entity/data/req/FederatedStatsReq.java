package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class FederatedStatsReq {
    private String taskName;
    private Long projectId;
    private String statsType;
    private String algorithmType;
    private String taskParam;
}
