package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-模型关联表
 */
@Data
public class ServerModel {
    private Long id;
    /** 服务器ID */
    private Long serverId;
    /** 模型ID */
    private Long modelId;
    /** 部署模型版本 */
    private String modelVersion;
    /** 部署状态: 0待部署 1已部署 2运行中 3已停止 */
    private Integer deploymentStatus;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
