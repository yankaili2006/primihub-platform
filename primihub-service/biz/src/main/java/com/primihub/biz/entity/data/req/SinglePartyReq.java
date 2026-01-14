package com.primihub.biz.entity.data.req;

import lombok.Getter;
import lombok.Setter;

/**
 * 单方算法请求参数
 */
@Getter
@Setter
public class SinglePartyReq {

    private Integer algorithmType;
    private String taskName;
    private Long projectId;
    private String resourceId;
    private String selectedFeatures;
    private String algorithmParams;
    private String remarks;
}
