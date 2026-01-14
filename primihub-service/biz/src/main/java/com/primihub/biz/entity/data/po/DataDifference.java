package com.primihub.biz.entity.data.po;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

/**
 * 联邦求差实体类
 */
@Getter
@Setter
public class DataDifference {

    /**
     * 求差主键
     */
    private Long id;

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
     * 文件路径输出类型 0默认 自动生成
     */
    private Integer outputFilePathType;

    /**
     * 输出内容是否不去重 默认0 不去重 1去重
     */
    private Integer outputNoRepeat;

    /**
     * 0、ECDH
     * 1、KKRT
     * 2、TEE
     */
    private Integer tag;

    /**
     * 结果名称
     */
    private String resultName;

    /**
     * 输出格式
     */
    private String outputFormat;

    /**
     * 结果获取方 多机构","号间隔
     */
    private String resultOrganIds;

    /**
     * 求差方向 0:本机构-其他机构 1:其他机构-本机构
     */
    private Integer differenceDirection;

    /**
     * 备注
     */
    private String remarks;

    private Long userId;

    private String teeOrganId;

    /**
     * 是否删除
     */
    @JsonIgnore
    private Integer isDel;

    /**
     * 创建时间
     */
    @JsonIgnore
    private Date createDate;

    /**
     * 修改时间
     */
    @JsonIgnore
    private Date updateDate;
}
