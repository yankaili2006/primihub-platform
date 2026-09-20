package com.primihub.biz.entity.data.po;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 联邦学习参数调优试验实体类。
 * 每行 = 一个真实 FL 训练试验（child_task_id 指向 createTask 派发的真实任务）；
 * 同一 tuning_id 归属一次调优运行。
 */
@Getter
@Setter
public class FederatedLearningTuning {

    /**
     * 主键
     */
    private Long id;

    /**
     * 调优运行id（同一次调优的试验共享）
     */
    private String tuningId;

    /**
     * 基础任务id（federated_learning_task.task_id）
     */
    private String baseTaskId;

    /**
     * 派生的真实 FL 试验任务id
     */
    private String childTaskId;

    /**
     * 项目ID
     */
    private Long projectId;

    /**
     * 搜索方法 GRID/RANDOM/BAYESIAN
     */
    private String searchMethod;

    /**
     * 学习率
     */
    private Double learningRate;

    /**
     * 迭代次数（epochs）
     */
    private Integer iterations;

    /**
     * 批次大小
     */
    private Integer batchSize;

    /**
     * 真实训练准确率（进度回读，未完成为 null）
     */
    private Double accuracy;

    /**
     * 真实训练损失
     */
    private Double loss;

    /**
     * AUC —— 仅真实可得时有值，绝不编造
     */
    private Double auc;

    /**
     * 试验任务状态 0未运行 1完成 2运行中 3失败 4取消
     */
    private Integer taskState;

    /**
     * 按真实 accuracy 的排名（无指标为 null）
     */
    private Integer rankNo;

    /**
     * 是否已被记录为应用参数 0否 1是（只做标记，不改动基础任务）
     */
    private Integer applied;

    private Long userId;

    /**
     * 是否删除
     */
    @JsonIgnore
    private Integer isDel;

    /**
     * 创建时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private Date createDate;

    /**
     * 修改时间
     */
    @JsonIgnore
    private Date updateDate;
}
