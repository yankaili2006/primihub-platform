package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 数据需求实体类
 */
@Data
public class DataRequirement implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 需求编码
     */
    private String requirementCode;

    /**
     * 需求名称
     */
    private String requirementName;

    /**
     * 需求描述
     */
    private String requirementDesc;

    /**
     * 需求类型(模型训练/数据分析/隐私求交/其他)
     */
    private String requirementType;

    /**
     * 所需数据字段(JSON格式)
     */
    private String dataFields;

    /**
     * 所需数据量
     */
    private Long dataVolume;

    /**
     * 所需数据格式(CSV/JSON/Excel/其他)
     */
    private String dataFormat;

    /**
     * 优先级(0-低 1-中 2-高)
     */
    private Integer priority;

    /**
     * 状态(0-待匹配 1-已匹配 2-已完成 3-已关闭)
     */
    private Integer status;

    /**
     * 创建人用户ID
     */
    private Long userId;

    /**
     * 创建人用户名
     */
    private String userName;

    /**
     * 机构ID
     */
    private Long organId;

    /**
     * 机构名称
     */
    private String organName;

    /**
     * 需求开始日期
     */
    private Date startDate;

    /**
     * 需求结束日期
     */
    private Date endDate;

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
}
