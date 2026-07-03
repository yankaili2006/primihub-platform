package com.primihub.biz.repository.primarydb.data;

import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 项目台账 Repository。
 * 台账列表/详情是对 data_project 的聚合只读视图；导出记录落 project_ledger_export。
 */
public interface ProjectLedgerRepository {

    List<Map<String, Object>> selectLedgerPage(Map<String, Object> params);

    int selectLedgerCount(Map<String, Object> params);

    Map<String, Object> selectLedgerByProjectId(@Param("projectId") String projectId);

    List<Map<String, Object>> selectProjectResources(@Param("projectId") String projectId);

    int insertExport(Map<String, Object> export);

    Map<String, Object> selectExportById(@Param("exportId") Long exportId);

    List<Map<String, Object>> selectExportHistory(@Param("exportUserId") Long exportUserId);

    int updateExport(Map<String, Object> export);
}
