package com.primihub.biz.entity.sys.vo;

import lombok.Data;

@Data
public class TimeConfigVO {
    private String timezone;
    private String dateFormat;
    private String datetimeFormat;
    private Boolean ntpEnabled;
    private String ntpServer;
}
