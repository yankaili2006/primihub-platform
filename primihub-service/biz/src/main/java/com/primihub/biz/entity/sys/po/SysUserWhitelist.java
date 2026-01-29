package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 用户白名单实体类
 */
@Data
public class SysUserWhitelist {

    /**
     * 白名单ID
     */
    private Long whitelistId;

    /**
     * 白名单类型：1=邮箱，2=手机号
     */
    private Integer whitelistType;

    /**
     * 白名单值（邮箱地址或手机号）
     */
    private String whitelistValue;

    /**
     * 备注说明
     */
    private String whitelistDesc;

    /**
     * 状态：0=禁用，1=启用
     */
    private Integer status;

    /**
     * 是否删除：0=否，1=是
     */
    private Integer isDel;

    /**
     * 创建人ID
     */
    private Long creatorId;

    /**
     * 创建人姓名
     */
    private String creatorName;

    /**
     * 创建时间
     */
    private Date cTime;

    /**
     * 更新时间
     */
    private Date uTime;
}
