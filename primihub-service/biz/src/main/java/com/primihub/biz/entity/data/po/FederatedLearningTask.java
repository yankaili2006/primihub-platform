package com.primihub.biz.entity.data.po;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 联邦学习任务实体类
 */
@Getter
@Setter
public class FederatedLearningTask {

    /**
     * 联邦学习任务id
     */
    private Long id;

    /**
     * 联邦学习id
     */
    private Long flId;

    /**
     * 对外展示的任务uuid
     */
    private String taskId;

    /**
     * 运行状态 0未运行 1完成 2运行中 3失败 4取消
     */
    private Integer taskState;

    /**
     * 当前轮次
     */
    private Integer currentRound;

    /**
     * 总轮次
     */
    private Integer totalRounds;

    /**
     * 训练准确率
     */
    private Double accuracy;

    /**
     * 训练损失
     */
    private Double loss;

    /**
     * 模型评估指标（JSON格式）
     */
    private String metrics;

    /**
     * 预测结果行数
     */
    private Integer resultRows;

    /**
     * 结果文件路径
     */
    @JsonIgnore
    private String resultFilePath;

    /**
     * 执行日志
     */
    @JsonIgnore
    private String executionLog;

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
