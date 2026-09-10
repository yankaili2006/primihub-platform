package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-节点关联 VO
 */
@Data
public class ServerNodeVO {
    private Long id;
    private Long serverId;
    private Long nodeId;
    /** 接入类型: project/compute/data_exchange */
    private String accessType;
    /** 是否主节点: 0否 1是 */
    private Integer isPrimary;
    private Date createDate;

    /** 定位URI */
    private String uri;

    /** 节点名称 */
    private String nodeName;
    /** 节点类型 */
    private String cooperationType;
}
