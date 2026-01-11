package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 审批步骤实体类
 */
@Data
public class NodeApprovalStep implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 工作流ID
     */
    private Long workflowId;

    /**
     * 步骤序号
     */
    private Integer stepNumber;

    /**
     * 步骤名称
     */
    private String stepName;

    /**
     * 审批人ID
     */
    private Long approverId;

    /**
     * 审批人姓名
     */
    private String approverName;

    /**
     * 审批人角色
     */
    private String approverRole;

    /**
     * 步骤状态: 0=待审批, 1=已批准, 2=已拒绝
     */
    private Integer status;

    /**
     * 审批意见
     */
    private String comment;

    /**
     * 附件(JSON格式)
     */
    private String attachments;

    /**
     * 审批时间
     */
    private Date approvedAt;

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
