package com.primihub.biz.repository.secondarydb.data;

import com.primihub.biz.entity.data.po.DataTrustedSpace;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * 可信空间 读仓库（secondarydb）。
 */
@Repository
public interface DataTrustedSpaceRepository {

    List<DataTrustedSpace> selectTrustedSpacePage(Map<String, Object> paramMap);

    Integer selectTrustedSpaceCount(Map<String, Object> paramMap);

    /** 启用且未删除，按 sort_index, space_id 排序（供下拉） */
    List<DataTrustedSpace> selectAllEnabled();

    DataTrustedSpace selectTrustedSpaceById(@Param("spaceId") Long spaceId);

    /** 未删除行内按编码查（排除 excludeId 自身，用于编辑查重） */
    DataTrustedSpace selectTrustedSpaceByCode(@Param("spaceCode") String spaceCode, @Param("excludeId") Long excludeId);

    /** 未删除行内按名称查（排除 excludeId 自身，用于编辑查重） */
    DataTrustedSpace selectTrustedSpaceByName(@Param("spaceName") String spaceName, @Param("excludeId") Long excludeId);

    DataTrustedSpace selectDefaultTrustedSpace();

    /** 空间内有效资源数；isDefault=1 时把 trusted_space 为 NULL 的资源也算进来 */
    Integer countResourcesBySpace(@Param("spaceId") Long spaceId, @Param("isDefault") Integer isDefault);

    /** 每个 trusted_space 取值（含 NULL）的有效资源数，键 spaceId / cnt */
    List<Map<String, Object>> selectResourceCountGroupBySpace();
}
