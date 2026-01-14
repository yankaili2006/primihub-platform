package com.primihub.biz.entity.data.req;

import lombok.Data;

/**
 * 联邦求并请求参数
 */
@Data
public class DataUnionReq {
    /**
     * 本机构id
     */
    private String ownOrganId;

    /**
     * 本机构资源id
     */
    private String ownResourceId;

    /**
     * 本机构资源关键字
     */
    private String ownKeyword;

    /**
     * 其他机构id
     */
    private String otherOrganId;

    /**
     * 其他机构资源id
     */
    private String otherResourceId;

    /**
     * 其他机构资源关键字
     */
    private String otherKeyword;

    /**
     * 结果名称
     */
    private String resultName;

    /**
     * 结果获取方 多机构","号间隔
     */
    private String resultOrganIds;

    /**
     * 0、ECDH 1、KKRT 2、TEE
     */
    private Integer tag;

    /**
     * TEE机构ID
     */
    private String teeOrganId;

    /**
     * 备注
     */
    private String remarks;
}
