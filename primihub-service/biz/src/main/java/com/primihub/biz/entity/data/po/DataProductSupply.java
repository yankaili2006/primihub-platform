package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

/**
 * 数据产品供给实体
 */
@Data
public class DataProductSupply {
    /**
     * 主键
     */
    private Long id;
    
    /**
     * 产品名称
     */
    private String productName;
    
    /**
     * 产品描述
     */
    private String productDesc;
    
    /**
     * 产品类型
     */
    private String productType;
    
    /**
     * 提供方机构ID
     */
    private Long organId;
    
    /**
     * 关联节点ID
     */
    private Long nodeId;
    
    /**
     * 服务分类
     */
    private String serviceCategory;
    
    /**
     * 定价模式
     */
    private String pricingModel;
    
    /**
     * 价格区间
     */
    private String priceRange;
    
    /**
     * 能力说明
     */
    private String capabilities;
    
    /**
     * 技术栈
     */
    private String techStack;
    
    /**
     * API端点
     */
    private String apiEndpoint;
    
    /**
     * 文档链接
     */
    private String documentationUrl;
    
    /**
     * 演示链接
     */
    private String demoUrl;
    
    /**
     * 状态（上架/下架/维护中）
     */
    private String status;
    
    /**
     * 质量等级（基础/标准/高级）
     */
    private String qualityLevel;
    
    /**
     * 服务等级协议
     */
    private String sla;
    
    /**
     * 联系人
     */
    private String contactPerson;
    
    /**
     * 联系方式
     */
    private String contactInfo;
    
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
