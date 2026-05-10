package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class BillingStatsQueryReq {
    private String startDate;
    private String endDate;
    private String requesterOrganId;
}
