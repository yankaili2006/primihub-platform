package com.primihub.biz.entity.sys.po;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data; import java.util.Date;
@Data
public class SysApprovalWorkflow {
    private Long id; private String workflowName; private String workflowDesc;
    private String approvalType; private Integer approvalLevels; private String approvers;
    private Integer status; private Integer isDel;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date cTime;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date uTime;
}