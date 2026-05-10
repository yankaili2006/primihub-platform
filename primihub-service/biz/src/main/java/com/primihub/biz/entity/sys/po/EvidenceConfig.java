package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class EvidenceConfig {
    private Long id;
    private String configKey;
    private String configValue;
    private String configDesc;
    private Integer isEncrypted;
    private Date createdAt;
    private Date updatedAt;
}
