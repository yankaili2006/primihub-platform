package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 调度日志记录表
 */
@Data
public class ScheduleLog {
    private Long id;
    private String logCode;
    private String scheduleName;
    private String scheduleType;
    private String scheduleCron;
    private String executeServer;
    private Date startTime;
    private Date endTime;
    private Long executionTime;
    private Integer status;
    private String resultMessage;
    private String errorMsg;
    private Integer retryCount;
    private Integer isDel;
    private Date createDate;
}
