package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class BillingRecordQueryReq {
    private String requesterOrganId;
    private String billingType;
    private Integer chargeStatus;
    private String startDate;
    private String endDate;
    private Integer pageNo = 1;
    private Integer pageSize = 10;
}
