package com.primihub.biz.entity.sys.vo;

import lombok.Data;

@Data
public class PersonalizationConfigVO {
    private String platformName;
    private String platformShortName;
    private String copyright;
    private String icpNumber;
    private String themeColor;
    private String defaultLanguage;
    private Integer pageSize;
    private Boolean fixedHeader;
}
