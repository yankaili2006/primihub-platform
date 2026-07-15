package com.primihub.biz.entity.data.po;

import lombok.Data;

import java.util.Date;

/**
 * 场景机构数据接入-真实数据行(electronic_cert/police_fusion)。
 * 对应表 scene_imported_data(见 Flyway V4)。
 */
@Data
public class SceneImportedData {
    private Long id;
    private String sceneType;
    private Long taskId;
    private String batchNo;
    private Integer rowIndex;
    private String rowJson;
    private Long createdBy;
    private Date createdAt;
}
