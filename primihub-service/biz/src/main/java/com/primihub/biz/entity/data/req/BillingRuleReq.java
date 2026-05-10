package com.primihub.biz.entity.data.req;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Data
public class BillingRuleReq {
    private Long id;
    private String ruleName;
    private String billingType;
    private List<Long> applyResourceIds;
    private List<String> applyOrganIds;
    private BigDecimal baseFee;
    private BigDecimal minCharge;
    private Integer isActive;
    private String effectiveFrom;
    private String effectiveTo;
    private BigDecimal pricePerQuery;
    private Boolean enableDiscount;
    private Integer discountThreshold;
    private BigDecimal discountRate;
    private BigDecimal pricePerHit;
    private Boolean enableTiered;
    private List<Map<String, Object>> tieredPricing;
    private String dedupTimeWindow;
    private BigDecimal pricePerUnique;
    private BigDecimal repeatDiscount;
    private Integer rollingWindowHours;
    private Integer slideIntervalHours;
    private BigDecimal rollingPricePerUnique;
    private BigDecimal rollingRepeatDiscount;
}
