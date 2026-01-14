package com.primihub.biz.entity.data.po;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 联邦学习实体类
 */
@Getter
@Setter
public class FederatedLearning {

    /**
     * 联邦学习主键
     */
    private Long id;

    /**
     * 任务类型 1:建模 2:预测
     */
    private Integer taskType;

    /**
     * 算法类型 1:线性回归 2:逻辑回归 3:XGBoost
     */
    private Integer algorithmType;

    /**
     * 联邦类型 1:横向 2:纵向
     */
    private Integer federatedType;

    /**
     * 任务名称
     */
    private String taskName;

    /**
     * 项目ID
     */
    private Long projectId;

    /**
     * 本机构id
     */
    private String ownOrganId;

    /**
     * 本机构资源id
     */
    private String ownResourceId;

    /**
     * 本机构特征字段（逗号分隔）
     */
    private String ownFeatures;

    /**
     * 标签字段（仅标签方有值）
     */
    private String labelFeature;

    /**
     * 是否为标签方 0否 1是
     */
    private Integer isLabelOwner;

    /**
     * 参与机构ids（逗号分隔）
     */
    private String participantOrganIds;

    /**
     * 参与机构资源ids（JSON格式）
     */
    private String participantResourceIds;

    /**
     * 训练参数（JSON格式）
     */
    private String trainingParams;

    /**
     * 模型ID（预测时使用）
     */
    private String modelId;

    /**
     * 模型存储路径
     */
    private String modelPath;

    /**
     * 结果存储路径
     */
    private String resultPath;

    /**
     * 备注
     */
    private String remarks;

    private Long userId;

    /**
     * 是否删除
     */
    @JsonIgnore
    private Integer isDel;

    /**
     * 创建时间
     */
    @JsonIgnore
    private Date createDate;

    /**
     * 修改时间
     */
    @JsonIgnore
    private Date updateDate;
}
