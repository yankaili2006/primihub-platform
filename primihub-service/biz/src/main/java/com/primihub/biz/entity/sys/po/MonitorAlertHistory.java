package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class MonitorAlertHistory {
    private Long id;
    private Long configId;
    private String monitorType;
    private Integer alertLevel;
    private java.math.BigDecimal alertValue;
    private java.math.BigDecimal threshold;
    private String message;
    private Integer status;
    private Long handledBy;
    private Date handledAt;
    private String handleRemark;
    private Date createdAt;
}
