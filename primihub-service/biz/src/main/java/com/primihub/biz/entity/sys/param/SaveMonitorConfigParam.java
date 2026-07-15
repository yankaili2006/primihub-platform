package com.primihub.biz.entity.sys.param;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class SaveMonitorConfigParam {
    private Long id; private String configKey; private String configName;
    private BigDecimal warningThreshold; private BigDecimal criticalThreshold;
    private Integer intervalSec; private Integer enabled; private String notifyType;
    private String notifyContact; private String remark;
}