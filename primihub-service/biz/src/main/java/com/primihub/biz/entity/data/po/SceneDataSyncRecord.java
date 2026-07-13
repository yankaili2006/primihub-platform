package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class SceneDataSyncRecord {
    private Long id;
    private Long sourceId;
    private String sourceName;
    private String syncType;
    private Long recordCount;
    private String duration;
    private Integer status; // 1=success, 0=failed
    private Date syncTime;
}
