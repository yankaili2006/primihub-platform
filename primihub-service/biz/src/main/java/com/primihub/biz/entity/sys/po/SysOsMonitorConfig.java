package com.primihub.biz.entity.sys.po;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;
import java.util.Date;
@Data
public class SysOsMonitorConfig {
    private Long id; private String configKey; private String configName;
    private java.math.BigDecimal warningThreshold; private java.math.BigDecimal criticalThreshold;
    private Integer intervalSec; private Integer enabled; private String notifyType;
    private String notifyContact; private String remark; private Integer isDel;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date cTime;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date uTime;
}