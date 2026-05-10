package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

@Data
public class EvidenceTimestamp {
    private Long id;
    private Long evidenceId;
    private Date timestampValue;
    private String timestampHash;
    private String timestampSource;
    private String nonce;
    private Integer status;
    private Date createdAt;
}
