package com.primihub.biz.entity.data.po;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 单方算法实体类
 */
@Getter
@Setter
public class SingleParty {

    private Long id;

    /**
     * 算法类型
     * 1:数据统计 2:数据清洗 3:数据缩放 4:特征编码 5:特征分箱
     * 6:特征筛选 7:特征衍生 8:LR算法 9:XGB算法 10:Python脚本
     */
    private Integer algorithmType;

    private String taskName;
    private Long projectId;
    private String resourceId;
    private String selectedFeatures;
    private String algorithmParams;
    private String resultPath;
    private String remarks;
    private Long userId;

    @JsonIgnore
    private Integer isDel;

    @JsonIgnore
    private Date createDate;

    @JsonIgnore
    private Date updateDate;
}
