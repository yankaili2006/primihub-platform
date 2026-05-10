package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class SceneKeyConfig {
    private Long id;
    private String sceneType;
    private String keyName;
    private String scheme;
    private String publicKey;
    private String privateKey;
    private Integer keySize;
    private Integer status;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
