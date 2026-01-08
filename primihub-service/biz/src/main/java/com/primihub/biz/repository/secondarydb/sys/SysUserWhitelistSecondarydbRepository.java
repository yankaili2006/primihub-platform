package com.primihub.biz.repository.secondarydb.sys;

import com.primihub.biz.entity.sys.po.SysUserWhitelist;
import com.primihub.biz.entity.sys.vo.SysUserWhitelistVO;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * 用户白名单从库Repository（读操作）
 */
@Repository
public interface SysUserWhitelistSecondarydbRepository {

    /**
     * 根据ID查询白名单
     *
     * @param whitelistId 白名单ID
     * @return 白名单实体
     */
    SysUserWhitelist selectWhitelistById(@Param("whitelistId") Long whitelistId);

    /**
     * 根据类型和值查询白名单
     *
     * @param whitelistType  白名单类型
     * @param whitelistValue 白名单值
     * @return 白名单实体
     */
    SysUserWhitelist selectWhitelistByTypeAndValue(
            @Param("whitelistType") Integer whitelistType,
            @Param("whitelistValue") String whitelistValue
    );

    /**
     * 分页查询白名单列表
     *
     * @param paramMap 查询参数
     * @return 白名单VO列表
     */
    List<SysUserWhitelistVO> selectWhitelistPage(Map<String, Object> paramMap);

    /**
     * 查询白名单总数
     *
     * @param paramMap 查询参数
     * @return 总数
     */
    Long selectWhitelistCount(Map<String, Object> paramMap);

    /**
     * 检查用户是否在白名单中
     *
     * @param whitelistType  白名单类型
     * @param whitelistValue 白名单值
     * @return 匹配数量（大于0表示在白名单中）
     */
    Integer checkUserInWhitelist(
            @Param("whitelistType") Integer whitelistType,
            @Param("whitelistValue") String whitelistValue
    );
}
