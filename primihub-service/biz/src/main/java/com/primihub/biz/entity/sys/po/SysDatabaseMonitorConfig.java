package com.primihub.biz.entity.sys.po;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data; import java.util.Date; import java.math.BigDecimal;
@Data
public class SysDatabaseMonitorConfig {
    private Long id; private String dbType; private String dbName;
    private String host; private Integer port; private String dbUser; private String dbPassword;
    private Integer connectTimeout; private BigDecimal warningThreshold; private BigDecimal criticalThreshold;
    private Integer checkInterval; private Integer enabled; private String notifyType;
    private String remark; private Integer isDel;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date cTime;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date uTime;
}