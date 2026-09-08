package com.primihub.biz.entity.data.req;

import lombok.Data;

/**
 * 模型产物登记/查询请求
 */
@Data
public class DataModelArtifactReq extends PageReq {
    /**
     * 模型产物id（编辑时必传）
     */
    private Long artifactId;
    /**
     * 模型名称
     */
    private String modelName;
    /**
     * 产物类别 vision_weights/llm_config/rule_pack/sklearn等
     */
    private String modelKind;
    /**
     * 框架 pytorch/onnx/qwen-vl等
     */
    private String framework;
    /**
     * 格式 pt/onnx/json等
     */
    private String format;
    /**
     * 版本
     */
    private String version;
    /**
     * 文件id（sys_file，可选：产物文件走 /sys/file/upload 后回填）
     */
    private Long fileId;
    /**
     * 产物校验值
     */
    private String checksum;
    /**
     * 元数据JSON
     */
    private String metadata;
    /**
     * 机构id（查询过滤）
     */
    private String organId;
}
