package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class EvidenceApiKey {
    private Long id;
    private String apiKey;
    private String secretKey;
    private Integer status;
    private Date expiryDate;
    private String description;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
