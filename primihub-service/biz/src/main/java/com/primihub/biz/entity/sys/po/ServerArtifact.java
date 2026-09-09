package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-模型产物关联表
 */
@Data
public class ServerArtifact {
    private Long id;
    /** 服务器ID */
    private Long serverId;
    /** 模型产物ID */
    private Long artifactId;
    /** 产物状态: 0未部署 1已部署 2运行中 */
    private Integer artifactStatus;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
