package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedBillingRule {
    private Long id;
    private String ruleName;
    private String billingType;
    private String applyResourceIds;
    private String applyOrganIds;
    private java.math.BigDecimal baseFee;
    private java.math.BigDecimal minCharge;
    private Integer isActive;
    private Date effectiveFrom;
    private Date effectiveTo;
    private java.math.BigDecimal pricePerQuery;
    private Integer enableDiscount;
    private Integer discountThreshold;
    private java.math.BigDecimal discountRate;
    private java.math.BigDecimal pricePerHit;
    private Integer enableTiered;
    private String tieredPricing;
    private String dedupTimeWindow;
    private java.math.BigDecimal pricePerUnique;
    private java.math.BigDecimal repeatDiscount;
    private Integer rollingWindowHours;
    private Integer slideIntervalHours;
    private java.math.BigDecimal rollingPricePerUnique;
    private java.math.BigDecimal rollingRepeatDiscount;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
