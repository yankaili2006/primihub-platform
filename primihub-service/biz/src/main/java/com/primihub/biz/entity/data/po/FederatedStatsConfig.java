package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedStatsConfig {
    private Long id;
    private String configName;
    private String storageType;
    private String storagePath;
    private String connectionJson;
    private Integer isDefault;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
