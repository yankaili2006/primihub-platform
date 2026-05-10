package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class EvidenceExportRecord {
    private Long id;
    private Long evidenceId;
    private String exportType;
    private String fileName;
    private Long fileSize;
    private Integer isEncrypted;
    private String encryptAlgorithm;
    private Integer status;
    private Long createdBy;
    private Date createdAt;
}
