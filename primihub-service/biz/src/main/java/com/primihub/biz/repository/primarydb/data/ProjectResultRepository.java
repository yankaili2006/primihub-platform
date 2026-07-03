package com.primihub.biz.repository.primarydb.data;

import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 项目结果保存 Repository（真实 DB 存储 + 一份保存配置）。
 */
public interface ProjectResultRepository {

    List<Map<String, Object>> selectResultPage(Map<String, Object> params);

    int selectResultCount(Map<String, Object> params);

    Map<String, Object> selectResultById(@Param("id") Long id);

    int insertResult(Map<String, Object> result);

    int updateResult(Map<String, Object> result);

    int markSaved(Map<String, Object> params);

    int deleteResult(@Param("id") Long id);

    int batchDeleteResult(@Param("ids") List<Long> ids);

    Map<String, Object> selectConfig();

    int insertConfig(Map<String, Object> config);

    int updateConfig(Map<String, Object> config);
}
