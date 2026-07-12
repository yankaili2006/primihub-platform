package com.primihub.biz.repository.primarydb.data;

import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 项目权限 Repository：权限记录(授权/审批/撤销) + 权限模板。
 */
public interface ProjectPermissionRepository {

    List<Map<String, Object>> selectPermissionPage(Map<String, Object> params);

    int selectPermissionCount(Map<String, Object> params);

    Map<String, Object> selectPermissionById(@Param("id") Long id);

    int insertPermission(Map<String, Object> permission);

    int updatePermission(Map<String, Object> permission);

    int revokePermission(Map<String, Object> params);

    int batchRevokePermission(Map<String, Object> params);

    int approvePermission(Map<String, Object> params);

    // 名称解析
    String selectProjectName(@Param("projectId") String projectId);

    String selectOrganName(@Param("organId") String organId);

    // 模板
    List<Map<String, Object>> selectTemplates();

    Map<String, Object> selectTemplateById(@Param("id") Long id);

    int insertTemplate(Map<String, Object> template);

    int updateTemplate(Map<String, Object> template);

    int deleteTemplate(@Param("id") Long id);
}
