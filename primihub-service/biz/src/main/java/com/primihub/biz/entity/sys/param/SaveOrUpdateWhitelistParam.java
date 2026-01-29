package com.primihub.biz.entity.sys.param;

import lombok.Data;

/**
 * 保存或更新白名单参数
 */
@Data
public class SaveOrUpdateWhitelistParam {

    /**
     * 白名单ID（更新时传入，新增时为空）
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
}
