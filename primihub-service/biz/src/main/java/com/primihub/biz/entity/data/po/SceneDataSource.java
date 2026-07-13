package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class SceneDataSource {
    private Long id;
    private String sourceName;
    private String sourceType;
    private String department;
    private String host;
    private Integer port;
    private String dbName;
    private String username;
    private String password;
    private String connectionInfo;
    private Long dataCount;
    private Integer status; // 1=connected, 0=disconnected
    private Date lastSyncTime;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
