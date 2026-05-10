package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class SceneApiConfig {
    private Long id;
    private String sceneType;
    private String apiName;
    private String apiUrl;
    private String protocol;
    private String authType;
    private String apiKey;
    private Integer status;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
