package com.primihub.biz.entity.sys.po;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data; import java.util.Date;
@Data
public class SysAccessParty {
    private Long id; private String partyName; private String partyCode;
    private String apiKey; private String contactPerson; private String contactPhone;
    private Integer status; private String remark; private Integer isDel;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date cTime;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8") private Date uTime;
}