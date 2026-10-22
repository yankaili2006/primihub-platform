package com.primihub.biz.entity.data.vo;

import com.primihub.biz.entity.data.po.DataTrustedSpace;
import lombok.Data;

import java.util.Date;

/**
 * 可信空间 列表/详情 出参：PO 字段 + 资源数。
 */
@Data
public class DataTrustedSpaceVo {
    private Long spaceId;
    private String spaceCode;
    private String spaceName;
    private String spaceDesc;
    private String organId;
    private String organName;
    private Integer isDefault;
    private Integer status;
    private Integer sortIndex;
    private Long userId;
    private Date createDate;
    private Date updateDate;
    /** 归属该空间的有效资源数（缺省空间含 trusted_space 为 NULL 的资源） */
    private Integer resourceCount = 0;

    public static DataTrustedSpaceVo of(DataTrustedSpace po) {
        DataTrustedSpaceVo vo = new DataTrustedSpaceVo();
        vo.setSpaceId(po.getSpaceId());
        vo.setSpaceCode(po.getSpaceCode());
        vo.setSpaceName(po.getSpaceName());
        vo.setSpaceDesc(po.getSpaceDesc());
        vo.setOrganId(po.getOrganId());
        vo.setOrganName(po.getOrganName());
        vo.setIsDefault(po.getIsDefault() == null ? 0 : po.getIsDefault());
        vo.setStatus(po.getStatus() == null ? 1 : po.getStatus());
        vo.setSortIndex(po.getSortIndex());
        vo.setUserId(po.getUserId());
        vo.setCreateDate(po.getCreateDate());
        vo.setUpdateDate(po.getUpdateDate());
        return vo;
    }
}
