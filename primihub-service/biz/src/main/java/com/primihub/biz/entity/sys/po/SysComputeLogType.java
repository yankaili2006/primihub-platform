package com.primihub.biz.entity.sys.po;
import lombok.Data;
import java.util.Date;
@Data
public class SysComputeLogType {
    private Long id; private String typeName; private String typeCode;
    private String typeDesc; private Integer status; private Integer sortOrder;
    private Integer isDel; private Date cTime; private Date uTime;
}