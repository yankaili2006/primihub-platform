package com.primihub.biz.entity.sys.param;
import lombok.Data; import java.math.BigDecimal;
@Data
public class SaveDatabaseMonitorParam {
    private Long id; private String dbType; private String dbName;
    private String host; private Integer port; private String dbUser; private String dbPassword;
    private Integer connectTimeout; private BigDecimal warningThreshold; private BigDecimal criticalThreshold;
    private Integer checkInterval; private Integer enabled; private String notifyType; private String remark;
}