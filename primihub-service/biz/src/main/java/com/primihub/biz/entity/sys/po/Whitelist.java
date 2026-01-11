package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 白名单表
 */
@Data
public class Whitelist {
    /**
     * 白名单ID
     */
    private Long id;

    /**
     * 类型：IP、DOMAIN、USER_ID
     */
    private String type;

    /**
     * 值
     */
    private String value;

    /**
     * 描述
     */
    private String description;

    /**
     * 状态：0-禁用，1-启用
     */
    private Integer status;

    /**
     * 创建时间
     */
    private Date createTime;

    /**
     * 更新时间
     */
    private Date updateTime;

    /**
     * 创建用户ID
     */
    private Long createUserId;

    /**
     * 是否删除：0-否，1-是
     */
    private Integer isDel;
}
