package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

/**
 * 数据需求匹配实体类
 */
@Data
public class DataRequirementMatch implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 需求ID
     */
    private Long requirementId;

    /**
     * 资源ID(来自data_resource表)
     */
    private Long resourceId;

    /**
     * 匹配得分(0.00-100.00)
     */
    private BigDecimal matchScore;

    /**
     * 匹配状态(0-待确认 1-已确认 2-已拒绝)
     */
    private Integer matchStatus;

    /**
     * 匹配类型(自动匹配/手动匹配)
     */
    private String matchType;

    /**
     * 匹配详情(JSON格式,包含各项得分明细)
     */
    private String matchDetails;

    /**
     * 确认人用户ID
     */
    private Long confirmUserId;

    /**
     * 确认人用户名
     */
    private String confirmUserName;

    /**
     * 确认时间
     */
    private Date confirmDate;

    /**
     * 备注
     */
    private String remark;

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

    // 扩展字段(用于查询时关联显示)
    /**
     * 需求名称
     */
    private String requirementName;

    /**
     * 资源名称
     */
    private String resourceName;
}
