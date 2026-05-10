package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class BillingToggleReq {
    private Long ruleId;
    private Boolean isActive;
}
