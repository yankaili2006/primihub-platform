package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-节点关联表
 */
@Data
public class ServerNode {
    private Long id;
    /** 服务器ID */
    private Long serverId;
    /** 节点ID (node_cooperation_party.id) */
    private Long nodeId;
    /** 接入类型: project/compute/data_exchange */
    private String accessType;
    /** 是否主节点: 0否 1是 */
    private Integer isPrimary;
    /** 定位URI */
    private String uri;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
