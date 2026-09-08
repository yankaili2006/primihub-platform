package com.primihub.biz.entity.data.po;

import lombok.Data;

import java.util.Date;

/**
 * 外部模型产物登记表
 * 与 data_model（联邦训练DAG模板）语义不同：本表登记外部已训模型的权重/配置产物
 */
@Data
public class DataModelArtifact {
    /**
     * 模型产物id
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
     * 文件id（sys_file）
     */
    private Long fileId;
    /**
     * 物理路径
     */
    private String url;
    /**
     * 对象存储key预留
     */
    private String objectKey;
    /**
     * 产物校验值
     */
    private String checksum;
    /**
     * 元数据JSON：指标/输入输出契约/训练快照引用
     */
    private String metadata;
    /**
     * 机构id
     */
    private String organId;
    /**
     * 用户id
     */
    private Long userId;
    /**
     * 是否删除
     */
    private Integer isDel;
    /**
     * 创建时间
     */
    private Date createDate;
    /**
     * 修改时间
     */
    private Date updateDate;
}
