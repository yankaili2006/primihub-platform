package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.SysUserWhitelist;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

/**
 * 用户白名单主库Repository（写操作）
 */
@Repository
public interface SysUserWhitelistPrimarydbRepository {

    /**
     * 插入白名单记录
     *
     * @param whitelist 白名单实体
     * @return 影响行数
     */
    int insertWhitelist(SysUserWhitelist whitelist);

    /**
     * 更新白名单记录
     *
     * @param whitelist 白名单实体
     * @return 影响行数
     */
    int updateWhitelist(SysUserWhitelist whitelist);

    /**
     * 删除白名单记录（软删除）
     *
     * @param whitelistId 白名单ID
     * @return 影响行数
     */
    int deleteWhitelist(@Param("whitelistId") Long whitelistId);
}
