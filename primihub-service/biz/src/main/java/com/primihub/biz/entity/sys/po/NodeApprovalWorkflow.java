package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 审批工作流实体类
 */
@Data
public class NodeApprovalWorkflow implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 工作流类型: cooperation(合作申请), property_change(属性变更), data_exchange(数据交换), access_permission(访问权限)
     */
    private String workflowType;

    /**
     * 工作流标题
     */
    private String workflowTitle;

    /**
     * 关联节点ID
     */
    private String organId;

    /**
     * 关联节点名称
     */
    private String organName;

    /**
     * 请求数据(JSON格式)
     */
    private String requestData;

    /**
     * 当前审批步骤
     */
    private Integer currentStep;

    /**
     * 总审批步骤数
     */
    private Integer totalSteps;

    /**
     * 工作流状态: 0=待审批, 1=已批准, 2=已拒绝, 3=已取消
     */
    private Integer status;

    /**
     * 申请人ID
     */
    private Long requesterId;

    /**
     * 申请人姓名
     */
    private String requesterName;

    /**
     * 申请说明
     */
    private String requesterComment;

    /**
     * 最终审批人ID
     */
    private Long finalApproverId;

    /**
     * 最终审批人姓名
     */
    private String finalApproverName;

    /**
     * 最终审批意见
     */
    private String finalComment;

    /**
     * 最终审批时间
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
