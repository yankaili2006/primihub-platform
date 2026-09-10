package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.util.Date;

/**
 * 服务器主表
 */
@Data
public class Server {
    /** 服务器主键ID */
    private Long serverId;
    /** 服务器名称 */
    private String serverName;
    /** 服务器描述 */
    private String serverDesc;
    /** 服务器IP地址 */
    private String serverIp;
    /** 服务器端口 */
    private Integer serverPort;
    /** 服务器类型: compute/storage/gateway/tee */
    private String serverType;
    /** 服务器状态: 0离线 1在线 2维护 */
    private Integer serverStatus;
    /** 机构ID */
    private Long organId;
    /** 创建人用户ID */
    private Long userId;
    /** CPU核数 */
    private Double cpuCores;
    /** 内存(GB) */
    private Long memoryGb;
    /** 存储(GB) */
    private Long storageGb;
    /** 扩展配置JSON */
    private String config;
    /** 最后心跳时间 */
    private Date lastHeartbeat;
    /** 定位URL */
    private String serverUrl;
    /** 是否删除: 0否 1是 */
    private Integer isDel;
    /** 创建时间 */
    private Date createDate;
    /** 修改时间 */
    private Date updateDate;
}
