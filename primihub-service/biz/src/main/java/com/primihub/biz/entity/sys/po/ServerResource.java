package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-数据资源关联表
 */
@Data
public class ServerResource {
    private Long id;
    /** 服务器ID */
    private Long serverId;
    /** 数据资源ID */
    private Long resourceId;
    /** 分配状态: 0待分配 1已分配 2已卸载 */
    private Integer allocationStatus;
    /** 定位URI */
    private String uri;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
