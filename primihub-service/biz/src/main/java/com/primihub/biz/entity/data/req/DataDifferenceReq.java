package com.primihub.biz.entity.data.req;

import lombok.Data;

/**
 * 联邦求差请求参数
 */
@Data
public class DataDifferenceReq {
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
     * 求差方向 0:本机构-其他机构 1:其他机构-本机构
     */
    private Integer differenceDirection;

    /**
     * TEE机构ID
     */
    private String teeOrganId;

    /**
     * 备注
     */
    private String remarks;
}
