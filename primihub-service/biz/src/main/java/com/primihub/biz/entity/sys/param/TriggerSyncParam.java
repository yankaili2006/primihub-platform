package com.primihub.biz.entity.sys.param;
import lombok.Data;
@Data
public class TriggerSyncParam {
    private Long id; private String exchangeType; private String exchangeName;
    private String sourceOrgan; private String targetOrgan; private Long dataSize;
}