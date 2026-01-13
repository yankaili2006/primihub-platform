package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 审批配置实体类
 */
@Data
public class NodeApprovalConfig implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 工作流类型
     */
    private String workflowType;

    /**
     * 是否启用审批: 0=否, 1=是
     */
    private Integer isEnabled;

    /**
     * 审批步骤数
     */
    private Integer stepsCount;

    /**
     * 自动审批规则(JSON格式)
     */
    private String autoApproveRules;

    /**
     * 是否启用通知: 0=否, 1=是
     */
    private Integer notificationEnabled;

    /**
     * 通知邮箱列表(逗号分隔)
     */
    private String notificationEmails;

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
