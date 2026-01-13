package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 数据需求配置实体类
 */
@Data
public class DataRequirementConfig implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
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
     * 配置描述
     */
    private String configDesc;

    /**
     * 配置类型(系统配置/匹配规则/评分权重/其他)
     */
    private String configType;

    /**
     * 启用标记(0-禁用 1-启用)
     */
    private Integer isEnabled;

    /**
     * 删除标记(0-未删除 1-已删除)
     */
    private Integer isDel;

    /**
     * 创建时间
     */
    private Date createDate;

    /**
     * 更新时间
     */
    private Date updateDate;
}
