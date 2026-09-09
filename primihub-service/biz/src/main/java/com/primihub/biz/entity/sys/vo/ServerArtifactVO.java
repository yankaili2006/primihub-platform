package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;

/**
 * 服务器-模型产物关联 VO
 */
@Data
public class ServerArtifactVO {
    private Long id;
    private Long serverId;
    private Long artifactId;
    /** 产物状态: 0未部署 1已部署 2运行中 */
    private Integer artifactStatus;
    private Date createDate;

    /** 产物名称 */
    private String artifactName;
}
