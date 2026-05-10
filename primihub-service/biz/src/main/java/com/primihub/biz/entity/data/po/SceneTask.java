package com.primihub.biz.entity.data.po;

import lombok.Data;
import java.util.Date;

@Data
public class SceneTask {
    private Long id;
    private String sceneType;
    private String taskName;
    private String taskType;
    private String params;
    private Integer taskState;
    private String resultData;
    private String errorMessage;
    private Long createdBy;
    private Date createdAt;
    private Date updatedAt;
}
