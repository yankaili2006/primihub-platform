package com.primihub.biz.entity.data.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.util.Date;

/**
 * 模型产物视图
 */
@Data
public class DataModelArtifactVo {
    private Long artifactId;
    private String modelName;
    private String modelKind;
    private String framework;
    private String format;
    private String version;
    private Long fileId;
    private String url;
    private String objectKey;
    private String checksum;
    private String metadata;
    private String organId;
    private Long userId;
    private String userName;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private Date createDate;
}
