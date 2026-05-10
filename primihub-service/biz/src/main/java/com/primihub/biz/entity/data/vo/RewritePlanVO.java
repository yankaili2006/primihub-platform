package com.primihub.biz.entity.data.vo;

import lombok.Data;
import java.util.List;

@Data
public class RewritePlanVO {
    private Long taskId;
    private String originalSql;
    private String rewrittenSql;
    private List<String> subQueries;
    private List<String> executionSteps;
}
