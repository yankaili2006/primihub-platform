package com.primihub.biz.entity.data.param;

import lombok.Data;

/**
 * 时间戳申请参数
 */
@Data
public class ApplyTimestampParam {
    private Long id;
    private String title;
    private String fileName;
    private String fileHash;
    private Long fileSize;
    private String remark;
}

