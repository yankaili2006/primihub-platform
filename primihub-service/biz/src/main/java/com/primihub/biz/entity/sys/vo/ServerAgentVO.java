package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-智能体关联 VO
 */
@Data
public class ServerAgentVO {
    private Long id;
    private Long serverId;
    private Long agentId;
    /** 运行状态: 0停止 1运行中 */
    private Integer runStatus;
    private Date createDate;

    /** 定位URI */
    private String uri;

    /** 智能体名称 */
    private String agentName;
    /** 智能体类型 */
    private String agentType;
}
