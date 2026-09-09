package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 智能体主表（平台当前无该实体，新建最小主表）
 */
@Data
public class Agent {
    /** 智能体主键ID */
    private Long agentId;
    /** 智能体名称 */
    private String agentName;
    /** 智能体类型 */
    private String agentType;
    /** 智能体描述 */
    private String agentDesc;
    /** 接入端点 */
    private String endpoint;
    /** 状态: 0停用 1启用 */
    private Integer status;
    /** 机构ID */
    private Long organId;
    /** 创建人用户ID */
    private Long userId;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    /** 创建时间 */
    private Date createDate;
    /** 修改时间 */
    private Date updateDate;
}
