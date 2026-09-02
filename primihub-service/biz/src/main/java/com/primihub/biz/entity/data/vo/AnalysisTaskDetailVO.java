package com.primihub.biz.entity.data.vo;

import lombok.Data;
import java.util.Date;
import java.util.List;

@Data
public class AnalysisTaskDetailVO {
    private Long id;
    private String taskName;
    private String sourceSql;
    private String rewrittenSql;
    private Integer taskState;
    private String taskStateName;
    private Integer resultRowCount;
    private String errorMessage;
    private Date createdAt;
    private List<FederatedAnalysisResultVO> results;

    /**
     * 结果行。原先是本文件里的**包私有顶层类**，跨包（service.data.impl）引用不到，
     * 于是 results 字段从来没被赋过值 —— 前端只能看到 resultRowCount，拿不到任何结果数据。
     * 改为 public static 内部类以便填充。
     */
    @Data
    public static class FederatedAnalysisResultVO {
        private Long id;
        private String resultType;
        private Object resultData;
        private Integer rowCount;
        private Date createdAt;
    }
}
