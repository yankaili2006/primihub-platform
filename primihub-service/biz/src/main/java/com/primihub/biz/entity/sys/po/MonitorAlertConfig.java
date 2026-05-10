package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class MonitorAlertConfig {
    private Long id;
    private String monitorType;
    private java.math.BigDecimal threshold;
    private Integer duration;
    private Integer alertLevel;
    private String notifyMethod;
    private String notifyTarget;
    private Integer isEnabled;
    private Date createdAt;
    private Date updatedAt;
}
