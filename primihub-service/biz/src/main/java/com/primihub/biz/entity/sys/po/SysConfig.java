package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class SysConfig {
    private Long id;
    private String configGroup;
    private String configKey;
    private String configValue;
    private String configDesc;
    private Integer isEncrypted;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
