package com.primihub.biz.entity.sys.po;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.util.Date;

/**
 * 角色信息表
 */
@Data
public class SysRole {
    /**
     * 角色id
     */
    private Long roleId;
    /**
     * 角色名称
     */
    private String roleName;
    /**
     * 是否可编辑
     */
    private Integer isEditable;
    /**
     * 是否删除
     */
    private Integer isDel;
    /**
     * 创建时间
     */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private Date cTime;
    /**
     * 修改时间
     */
    private Date uTime;
}
