package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class EvidenceRecord {
    private Long id;
    private String evidenceHash;
    private String evidenceData;
    private String evidenceType;
    private String fileName;
    private Long fileSize;
    private String fileType;
    private Integer status;
    private Long blockHeight;
    private String blockHash;
    private String txHash;
    private String chainType;
    private String description;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
