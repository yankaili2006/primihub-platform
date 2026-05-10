package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class StorageConfigReq {
    private Long id;
    private String configName;
    private String storageType;
    private String storagePath;
    private String connectionJson;
    private Integer isDefault;
}
