package com.primihub.biz.entity.sys.param;
import lombok.Data; import java.math.BigDecimal;
@Data
public class SaveMiddlewareMonitorParam {
    private Long id; private String mwType; private String mwName;
    private String host; private Integer port; private Integer connectTimeout;
    private BigDecimal warningThreshold; private BigDecimal criticalThreshold;
    private Integer checkInterval; private Integer enabled; private String notifyType; private String remark;
}