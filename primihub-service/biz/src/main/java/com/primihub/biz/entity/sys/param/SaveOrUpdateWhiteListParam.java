package com.primihub.biz.entity.sys.param;

import lombok.Data;

/**
 * 白名单保存/更新参数
 */
@Data
public class SaveOrUpdateWhiteListParam {
    private Long id;
    /** 白名单类型 1=手机号 2=IP地址 3=邮箱 */
    private Integer wlType;
    /** 白名单值 */
    private String wlValue;
    /** 添加原因/备注 */
    private String wlReason;
    /** 状态 1=启用 0=禁用 */
    private Integer status;
    /** 创建人用户ID */
    private Long creatorId;
    /** 创建人名称 */
    private String creatorName;
}