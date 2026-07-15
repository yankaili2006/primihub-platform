package com.primihub.biz.entity.sys.po;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data; import java.util.Date;
@Data
public class SysDataExchangeLog {
    private Long id; private String exchangeType; private String exchangeName;
    private String sourceOrgan; private String targetOrgan; private Long dataSize;
    private Integer syncStatus; private String syncMsg; private String triggerType;
    private Integer isDel;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date cTime;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date uTime;
}