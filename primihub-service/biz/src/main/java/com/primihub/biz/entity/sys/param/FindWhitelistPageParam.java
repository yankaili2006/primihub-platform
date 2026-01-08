package com.primihub.biz.entity.sys.param;

import lombok.Data;

/**
 * 查询白名单分页参数
 */
@Data
public class FindWhitelistPageParam {

    /**
     * 白名单类型筛选（可选）：1=邮箱，2=手机号
     */
    private Integer whitelistType;

    /**
     * 白名单值模糊搜索（可选）
     */
    private String whitelistValue;

    /**
     * 状态筛选（可选）：0=禁用，1=启用
     */
    private Integer status;
}
