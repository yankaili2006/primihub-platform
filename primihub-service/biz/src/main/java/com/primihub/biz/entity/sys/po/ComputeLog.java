package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 计算日志记录表
 */
@Data
public class ComputeLog {
    private Long id;
    private String logCode;
    private String taskId;
    private String taskName;
    private String computeType;
    private Long projectId;
    private String projectName;
    private Long userId;
    private String userName;
    private Long organId;
    private String organName;
    private Date startTime;
    private Date endTime;
    private Long executionTime;
    private Integer status;
    private String resultData;
    private String errorMsg;
    private String resourceUsage;
    private Integer isDel;
    private Date createDate;
}
