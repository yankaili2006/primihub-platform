package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 计算日志定义表
 */
@Data
public class ComputeLogDefinition {
    private Long id;
    private String logCode;
    private String logName;
    private String computeType;
    private String moduleName;
    private String description;
    private Integer isEnabled;
    private Integer retentionDays;
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
