package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 白名单配置表
 */
@Data
public class WhitelistConfig {
    /**
     * 配置ID
     */
    private Long id;

    /**
     * 配置键
     */
    private String configKey;

    /**
     * 配置值
     */
    private String configValue;

    /**
     * 配置类型
     */
    private String configType;

    /**
     * 描述
     */
    private String description;

    /**
     * 创建时间
     */
    private Date createTime;

    /**
     * 更新时间
     */
    private Date updateTime;

    /**
     * 更新用户ID
     */
    private Long updateUserId;

    /**
     * 更新用户名
     */
    private String updateUser;
}
