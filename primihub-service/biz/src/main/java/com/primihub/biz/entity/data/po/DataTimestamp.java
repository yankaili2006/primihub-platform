package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

/**
 * 时间戳 PO
 */
@Data
public class DataTimestamp {
    private Long id;
    private String applyId;
    private String title;
    private String fileName;
    private String fileHash;
    private Long fileSize;
    private String timestampValue;
    private String certNumber;
    private Integer applyStatus;
    private Long applyUserId;
    private String applyUserName;
    private Date applyTime;
    private Date issueTime;
    private String remark;
    private Integer isDel;
    private Date cTime;
    private Date uTime;
}