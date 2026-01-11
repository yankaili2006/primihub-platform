package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 租户表
 */
@Data
public class Tenant {
    private Long id;
    private String tenantCode;
    private String tenantName;
    private String contactPerson;
    private String contactPhone;
    private String contactEmail;
    private String description;
    private Integer status; // 0-冻结 1-正常
    private Boolean dataIsolation;
    private Boolean computeIsolation;
    private Integer resourceCount;
    private Date createTime;
    private Date updateTime;
    private Integer isDel;
}
