package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.math.BigDecimal;
import java.util.Date;

@Data
public class FederatedBillingRecord {
    private Long id;
    private Long ruleId;
    private String taskType;
    private Long taskId;
    private String requesterOrganId;
    private String providerOrganId;
    private String resourceIds;
    private String billingType;
    private Integer queryCount;
    private Integer hitCount;
    private String dedupKey;
    private Date dedupWindowStart;
    private Date dedupWindowEnd;
    private BigDecimal unitPrice;
    private BigDecimal discountRateApplied;
    private BigDecimal totalCharge;
    private Integer chargeStatus;
    private Date billingTime;
    private Date settledAt;
    private String remark;
    private Date createdAt;
}
