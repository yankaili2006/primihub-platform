package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 共享数据集实体类
 */
@Data
public class SharedDataset implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 数据集编码
     */
    private String datasetCode;

    /**
     * 数据集名称
     */
    private String datasetName;

    /**
     * 数据集描述
     */
    private String datasetDesc;

    /**
     * 数据类型(结构化数据/非结构化数据/半结构化数据)
     */
    private String dataType;

    /**
     * 数据格式(CSV/JSON/Excel/Parquet/其他)
     */
    private String dataFormat;

    /**
     * 数据字段(逗号分隔)
     */
    private String dataFields;

    /**
     * 数据量
     */
    private Long dataVolume;

    /**
     * 共享状态(0-待审核 1-已共享 2-已拒绝 3-已下架)
     */
    private Integer shareStatus;

    /**
     * 共享范围(0-仅本机构 1-指定机构 2-全部机构)
     */
    private Integer shareScope;

    /**
     * 目标机构ID列表(JSON格式，当shareScope=1时使用)
     */
    private String targetOrganIds;

    /**
     * 关联资源ID
     */
    private Long resourceId;

    /**
     * 关联资源名称
     */
    private String resourceName;

    /**
     * 使用条款
     */
    private String usageTerms;

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
     * 有效期开始日期
     */
    private Date startDate;

    /**
     * 有效期结束日期
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
