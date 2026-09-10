package com.primihub.biz.entity.data.po;

import lombok.Data;

import java.math.BigDecimal;
import java.util.Date;

/**
 * 资源表
 */
@Data
public class DataResource {
    /**
     * 资源id
     */
    private Long resourceId;
    /**
     * 资源名称
     */
    private String resourceName;
    /**
     * 资源描述
     */
    private String resourceDesc;
    /**
     * 授权类型 1.公开 2.私有
     */
    private Integer resourceAuthType;
    /**
     * 资源来源 文件上传 数据库链接
     */
    private Integer resourceSource;
    /**
     * 资源数
     */
    private Integer resourceNum;
    /**
     * 文件id
     */
    private Long fileId;
    /**
     * 文件大小
     */
    private Integer fileSize;
    /**
     * 文件后缀
     */
    private String fileSuffix;
    /**
     * 文件行数
     */
    private Integer fileRows;
    /**
     * 文件列数
     */
    private Integer fileColumns;
    /**
     * 文件处理状态 0 未处理 1处理中 2处理完成 3失败
     */
    private Integer fileHandleStatus;
    /**
     * 表头
     */
    private String fileHandleField;
    /**
     * 文件字段是否包含y字段 0否 1是
     */
    private Integer fileContainsY;
    /**
     * 文件字段y值内容不为空的行数
     */
    private Integer fileYRows;
    /**
     * 文件字段y值内容不为空的行数在总行的占比
     */
    private BigDecimal fileYRatio;

    /**
     * 可见机构列表
     */
    private String publicOrganId;
    /**
     * 中心节点资源id
     */
    private String resourceFusionId;
    /**
     * 数据库id
     */
    private Long dbId;
    /**
     * 用户id
     */
    private Long userId;
    /**
     * 机构id
     */
    private Long organId;
    /**
     * 资源标识路径
     */
    private String url;
    /**
     * 资源hash文件编码
     */
    private String resourceHashCode;

    /**
     * 资源状态 目前有 0上线 1下线
     */
    private Integer resourceState;
    /**
     * 资源形态 0表格 1图像/blob目录 2模型产物引用
     */
    private Integer resourceKind;
    /**
     * 对象存储key预留（本轮存本地相对路径）
     */
    private String objectKey;
    /**
     * 可信空间 = 主标签 tag_id（data_resource_tag）：水利/新能源车/农业/…，未知=PrimiHub。由 pcloud skill 维护
     */
    private Long trustedSpace;
    /**
     * 可信空间名（查询时由 tag_id 解析，非持久列）
     */
    private String trustedSpaceName;
    /**
     * 是否删除
     */
    private Integer isDel;

    /**
     * 创建时间
     */
    private Date createDate;
    /**
     * 修改时间
     */
    private Date updateDate;
}
