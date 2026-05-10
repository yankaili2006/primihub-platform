package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class MonitorRecord {
    private Long id;
    private String monitorType;
    private String metricName;
    private java.math.BigDecimal metricValue;
    private String unit;
    private String extraData;
    private Date recordedAt;
    private Date createdAt;
}
