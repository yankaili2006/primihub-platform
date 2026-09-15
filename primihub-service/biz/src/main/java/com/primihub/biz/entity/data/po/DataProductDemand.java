package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

/**
 * 数据产品需求实体
 */
@Data
public class DataProductDemand {
    /**
     * 主键
     */
    private Long id;
    
    /**
     * 需求名称
     */
    private String demandName;
    
    /**
     * 需求描述
     */
    private String demandDesc;
    
    /**
     * 需求类型
     */
    private String demandType;
    
    /**
     * 需求方机构ID
     */
    private Long organId;
    
    /**
     * 联系人
     */
    private String contactPerson;
    
    /**
     * 联系方式
     */
    private String contactInfo;
    
    /**
     * 预算
     */
    private String budget;
    
    /**
     * 期望交付时间
     */
    private Date expectedDelivery;
    
    /**
     * 技术要求
     */
    private String techRequirements;
    
    /**
     * 状态（待处理/进行中/已完成/已关闭）
     */
    private String status;
    
    /**
     * 优先级（低/中/高/紧急）
     */
    private String priority;
    
    /**
     * 来源
     */
    private String source;
    
    /**
     * 创建人ID
     */
    private Long createdBy;
    
    /**
     * 创建时间
     */
    private Date createdAt;
    
    /**
     * 更新时间
     */
    private Date updatedAt;
    
    /**
     * 备注
     */
    private String remark;
}
