package com.primihub.biz.entity.sys.param;
import lombok.Data;
@Data
public class SaveComputeLogTypeParam {
    private Long id; private String typeName; private String typeCode;
    private String typeDesc; private Integer status; private Integer sortOrder;
}