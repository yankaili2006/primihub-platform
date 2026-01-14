package com.primihub.biz.entity.data.req;

import lombok.Data;

/**
 * 联邦学习请求参数
 */
@Data
public class FederatedLearningReq {
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
     * 参与机构资源配置（JSON格式）
     */
    private String participantResourceIds;

    /**
     * 训练参数
     */
    private TrainingParams trainingParams;

    /**
     * 模型ID（预测时使用）
     */
    private String modelId;

    /**
     * 备注
     */
    private String remarks;

    @Data
    public static class TrainingParams {
        /**
         * 学习率
         */
        private Double learningRate = 0.01;

        /**
         * 批次大小
         */
        private Integer batchSize = 32;

        /**
         * 训练轮次
         */
        private Integer epochs = 10;

        /**
         * XGBoost树的数量
         */
        private Integer numTrees = 100;

        /**
         * XGBoost最大深度
         */
        private Integer maxDepth = 6;

        /**
         * 正则化参数
         */
        private Double regularization = 0.01;

        /**
         * 是否使用差分隐私
         */
        private Boolean useDifferentialPrivacy = false;

        /**
         * 隐私预算epsilon
         */
        private Double epsilon = 1.0;
    }
}
