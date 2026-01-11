package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 操作日志记录表
 */
@Data
public class OperationLog {
    private Long id;
    private String logCode;
    private Long userId;
    private String userName;
    private Long organId;
    private String organName;
    private String operationType;
    private String operationModule;
    private String operationDesc;
    private String requestMethod;
    private String requestUrl;
    private String requestParams;
    private String responseResult;
    private String ipAddress;
    private Integer status;
    private String errorMsg;
    private Long executionTime;
    private Integer isDel;
    private Date createDate;
}
