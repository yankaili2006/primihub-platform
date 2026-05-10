package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class FederatedStatsResult {
    private Long id;
    private Long taskId;
    private String resultType;
    private String resultData;
    private String resultFile;
    private Integer rowCount;
    private Date createdAt;
}
