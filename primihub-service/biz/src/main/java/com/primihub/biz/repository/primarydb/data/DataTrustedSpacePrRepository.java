package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataTrustedSpace;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 可信空间 写仓库（primarydb）。
 */
@Repository
public interface DataTrustedSpacePrRepository {

    int insertTrustedSpace(DataTrustedSpace space);

    int updateTrustedSpace(DataTrustedSpace space);

    /** 软删；同时把 space_code 改为 code_del_<id>，释放编码供复用 */
    int deleteTrustedSpace(@Param("spaceId") Long spaceId);

    /** 把资源划入空间 */
    int updateResourceTrustedSpace(@Param("spaceId") Long spaceId, @Param("resourceIds") List<Long> resourceIds);

    /** 把空间内资源置回缺省(NULL)；resourceIds 为空则清整个空间 */
    int clearResourceTrustedSpace(@Param("spaceId") Long spaceId, @Param("resourceIds") List<Long> resourceIds);
}
