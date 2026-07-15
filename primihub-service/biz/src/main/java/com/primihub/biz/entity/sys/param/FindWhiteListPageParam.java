package com.primihub.biz.entity.sys.param;

import lombok.Data;

/**
 * 白名单查询参数
 */
@Data
public class FindWhiteListPageParam {
    private Integer wlType;
    private String wlValue;
    private Integer status;
    private Integer pageNum = 1;
    private Integer pageSize = 10;
}