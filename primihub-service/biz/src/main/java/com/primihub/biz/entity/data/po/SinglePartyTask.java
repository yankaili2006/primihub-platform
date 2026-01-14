package com.primihub.biz.entity.data.po;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 单方算法任务实体类
 */
@Getter
@Setter
public class SinglePartyTask {

    private Long id;
    private Long spId;
    private String taskId;

    /**
     * 运行状态 0未运行 1完成 2运行中 3失败 4取消
     */
    private Integer taskState;

    private Integer resultRows;
    private String resultFilePath;
    private String executionLog;

    @JsonIgnore
    private Integer isDel;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private Date createDate;

    @JsonIgnore
    private Date updateDate;
}
