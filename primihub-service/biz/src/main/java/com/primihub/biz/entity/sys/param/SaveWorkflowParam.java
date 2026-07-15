package com.primihub.biz.entity.sys.param;
import lombok.Data;
@Data
public class SaveWorkflowParam {
    private Long id; private String workflowName; private String workflowDesc;
    private String approvalType; private Integer approvalLevels; private String approvers;
    private Integer status;
}