package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class BillingRuleQueryReq {
    private String billingType;
    private Integer isActive;
    private Integer pageNo = 1;
    private Integer pageSize = 10;
}
