package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.Whitelist;
import com.primihub.biz.entity.sys.po.WhitelistAccessLog;
import com.primihub.biz.entity.sys.po.WhitelistConfig;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface WhitelistPrimarydbRepository {

    // ========== 白名单管理 ==========

    /**
     * 插入白名单
     */
    void insertWhitelist(Whitelist whitelist);

    /**
     * 更新白名单
     */
    void updateWhitelist(Whitelist whitelist);

    /**
     * 删除白名单（逻辑删除）
     */
    void deleteWhitelist(@Param("id") Long id);

    /**
     * 根据ID查询白名单
     */
    Whitelist selectWhitelistById(@Param("id") Long id);

    /**
     * 查询白名单列表
     */
    List<Whitelist> selectWhitelistList(Map<String, Object> params);

    /**
     * 查询白名单总数
     */
    int selectWhitelistCount(Map<String, Object> params);

    // ========== 白名单配置管理 ==========

    /**
     * 查询所有配置
     */
    List<WhitelistConfig> selectWhitelistConfigList();

    /**
     * 根据配置键查询配置
     */
    WhitelistConfig selectWhitelistConfigByKey(@Param("configKey") String configKey);

    /**
     * 插入或更新配置
     */
    void insertOrUpdateWhitelistConfig(WhitelistConfig config);

    /**
     * 查询配置历史
     */
    List<WhitelistConfig> selectWhitelistConfigHistory();

    // ========== 白名单访问日志管理 ==========

    /**
     * 插入访问日志
     */
    void insertWhitelistAccessLog(WhitelistAccessLog log);

    /**
     * 查询访问日志列表
     */
    List<WhitelistAccessLog> selectWhitelistAccessLogList(Map<String, Object> params);

    /**
     * 查询访问日志总数
     */
    int selectWhitelistAccessLogCount(Map<String, Object> params);

    /**
     * 根据ID查询访问日志详情
     */
    WhitelistAccessLog selectWhitelistAccessLogById(@Param("id") Long id);

    /**
     * 查询访问统计
     */
    Map<String, Object> selectWhitelistAccessStatistics();

    /**
     * 批量删除访问日志
     */
    void batchDeleteAccessLog(@Param("ids") List<Long> ids);

    /**
     * 清理过期日志
     */
    int deleteExpiredLogs(@Param("beforeDate") String beforeDate);

    /**
     * 导出访问日志（不分页）
     */
    List<WhitelistAccessLog> exportAccessLogList(Map<String, Object> params);

    /**
     * 查询访问趋势（按天统计）
     */
    List<Map<String, Object>> selectAccessTrend(@Param("days") Integer days);

    /**
     * 查询IP访问排行
     */
    List<Map<String, Object>> selectTopAccessIps(@Param("limit") Integer limit);

    /**
     * 查询URL访问排行
     */
    List<Map<String, Object>> selectTopAccessUrls(@Param("limit") Integer limit);

    /**
     * 查询详细统计（按结果类型、按小时等）
     */
    Map<String, Object> selectAccessDetailStatistics(Map<String, Object> params);
}
