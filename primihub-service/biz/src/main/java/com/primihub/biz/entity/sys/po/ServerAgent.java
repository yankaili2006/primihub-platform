package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-智能体关联表
 */
@Data
public class ServerAgent {
    private Long id;
    /** 服务器ID */
    private Long serverId;
    /** 智能体ID */
    private Long agentId;
    /** 运行状态: 0停止 1运行中 */
    private Integer runStatus;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
