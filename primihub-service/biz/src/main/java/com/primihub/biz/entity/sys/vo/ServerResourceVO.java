package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-数据资源关联 VO（含资源基础信息）
 */
@Data
public class ServerResourceVO {
    private Long id;
    private Long serverId;
    private Long resourceId;
    /** 分配状态: 0待分配 1已分配 2已卸载 */
    private Integer allocationStatus;
    private Date createDate;

    /** 定位URI */
    private String uri;

    /** 资源名称（JOIN data_resource） */
    private String resourceName;
    /** 资源描述 */
    private String resourceDesc;
}
