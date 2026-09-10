package com.primihub.biz.entity.sys.vo;

import lombok.Data;

import java.util.Date;
import java.util.List;

/**
 * 服务器列表/详情 VO
 */
@Data
public class ServerVO {
    private Long serverId;
    private String serverName;
    private String serverDesc;
    private String serverIp;
    private Integer serverPort;
    private String serverType;
    private Integer serverStatus;
    private Long organId;
    private Long userId;
    private Double cpuCores;
    private Long memoryGb;
    private Long storageGb;
    private String config;
    private Date lastHeartbeat;
    private String serverUrl;
    private Date createDate;
    private Date updateDate;

    /** 关联的数据资源列表（详情页使用） */
    private List<ServerResourceVO> resources;
    /** 关联的模型列表（详情页使用） */
    private List<ServerModelVO> models;
    /** 关联的模型产物列表（详情页使用） */
    private List<ServerArtifactVO> artifacts;
    /** 关联的节点列表（详情页使用） */
    private List<ServerNodeVO> nodes;
    /** 关联的智能体列表（详情页使用） */
    private List<ServerAgentVO> agents;
}
