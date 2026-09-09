package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-模型关联 VO（含模型基础信息）
 */
@Data
public class ServerModelVO {
    private Long id;
    private Long serverId;
    private Long modelId;
    private String modelVersion;
    /** 部署状态: 0待部署 1已部署 2运行中 3已停止 */
    private Integer deploymentStatus;
    private Date createDate;

    /** 模型名称（JOIN data_model） */
    private String modelName;
}
