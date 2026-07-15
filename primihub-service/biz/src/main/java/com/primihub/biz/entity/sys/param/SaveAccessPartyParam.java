package com.primihub.biz.entity.sys.param;
import lombok.Data;
@Data
public class SaveAccessPartyParam {
    private Long id; private String partyName; private String partyCode;
    private String apiKey; private String contactPerson; private String contactPhone;
    private Integer status; private String remark;
}