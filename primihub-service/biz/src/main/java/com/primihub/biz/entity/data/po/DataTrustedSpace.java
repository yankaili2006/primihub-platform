package com.primihub.biz.entity.data.po;

import lombok.Data;

import java.util.Date;

/**
 * 可信空间（机构本地实体，不进 fusion 同步）。
 * data_resource.trusted_space 指向 spaceId；NULL 表示缺省空间（isDefault=1 的那一行）。
 */
@Data
public class DataTrustedSpace {
    /** 主键 */
    private Long spaceId;
    /** 稳定编码，库内唯一（primihub/water/nev/agri/...），与 pcloud DOMAIN_RULES 对齐 */
    private String spaceCode;
    /** 显示名，未删除行内唯一（服务层校验） */
    private String spaceName;
    /** 描述 */
    private String spaceDesc;
    /** 所属机构全局 id */
    private String organId;
    /** 所属机构名 */
    private String organName;
    /** 1=缺省空间：不可删除、不可停用、不可改码 */
    private Integer isDefault;
    /** 1 启用 0 停用 */
    private Integer status;
    /** 排序，小者在前 */
    private Integer sortIndex;
    /** 创建人 */
    private Long userId;
    /** 是否删除 */
    private Integer isDel;
    private Date createDate;
    private Date updateDate;
}
