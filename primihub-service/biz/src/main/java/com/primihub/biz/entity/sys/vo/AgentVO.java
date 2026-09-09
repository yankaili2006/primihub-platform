package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;

/**
 * 智能体列表/详情 VO
 */
@Data
public class AgentVO {
    private Long agentId;
    private String agentName;
    private String agentType;
    private String agentDesc;
    private String endpoint;
    private Integer status;
    private Long organId;
    private Long userId;
    private Date createDate;
    private Date updateDate;
}
