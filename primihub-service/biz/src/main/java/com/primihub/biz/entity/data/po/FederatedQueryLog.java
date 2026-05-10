package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedQueryLog {
    private Long id;
    private Long taskId;
    private String logLevel;
    private String logMessage;
    private String logData;
    private Date createdAt;
}
