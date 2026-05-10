package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class RdbmsReq {
    private String type;
    private String host;
    private Integer port;
    private String dbName;
    private String username;
    private String password;
    private Boolean ssl;
}
