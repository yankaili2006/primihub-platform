package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 接入方管理实体类
 * 管理申请接入我方的节点(inbound)
 */
@Data
public class NodeAccessParty implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 节点ID(申请方)
     */
    private String organId;

    /**
     * 节点名称
     */
    private String organName;

    /**
     * 节点网关地址
     */
    private String organGateway;

    /**
     * 申请理由
     */
    private String applyReason;

    /**
     * 接入级别: 1=只读, 2=读写, 3=管理员
     */
    private Integer accessLevel;

    /**
     * IP白名单(JSON格式)
     */
    private String ipWhitelist;

    /**
     * 有效期开始时间
     */
    private Date validFrom;

    /**
     * 有效期结束时间
     */
    private Date validUntil;

    /**
     * 申请状态: 0=待审批, 1=已批准, 2=已拒绝
     */
    private Integer applyStatus;

    /**
     * 审批人ID
     */
    private Long approveUserId;

    /**
     * 审批人姓名
     */
    private String approveUserName;

    /**
     * 审批意见
     */
    private String approveComment;

    /**
     * 审批时间
     */
    private Date approveDate;

    /**
     * 是否激活: 0=否, 1=是
     */
    private Integer isActive;

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
