package com.primihub.biz.entity.sys.vo;

import lombok.Data;
import java.util.Date;

/**
 * 用户白名单视图对象
 */
@Data
public class SysUserWhitelistVO {

    /**
     * 白名单ID
     */
    private Long whitelistId;

    /**
     * 白名单类型：1=邮箱，2=手机号
     */
    private Integer whitelistType;

    /**
     * 类型描述：邮箱/手机号
     */
    private String whitelistTypeDesc;

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
     * 状态描述：启用/禁用
     */
    private String statusDesc;

    /**
     * 创建人姓名
     */
    private String creatorName;

    /**
     * 创建时间
     */
    private Date cTime;
}
