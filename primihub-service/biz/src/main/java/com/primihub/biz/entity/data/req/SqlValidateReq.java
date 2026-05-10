package com.primihub.biz.entity.data.req;

import lombok.Data;

@Data
public class SqlValidateReq {
    private String sql;
    private String dataResources;
}
