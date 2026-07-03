package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.repository.primarydb.data.ProjectPermissionRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 项目权限 Service：权限记录(授权/审批/撤销) + 权限模板，真实 DB 存储。
 * （原 /project/permission/* 后端完全没有实现，前端整页 404——本类补齐。）
 */
@Slf4j
@Service
public class ProjectPermissionService {

    @Autowired
    private ProjectPermissionRepository permissionRepository;

    public BaseResultEntity findProjectPermissionPage(String projectName, String organName, String permissionType,
                                                      Integer permissionStatus, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("projectName", projectName);
            params.put("organName", organName);
            params.put("permissionType", permissionType);
            params.put("permissionStatus", permissionStatus);

            int total = permissionRepository.selectPermissionCount(params);
            PageParam pageParam = new PageParam(pageNum == null ? 1 : pageNum, pageSize == null ? 10 : pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<Map<String, Object>> list = permissionRepository.selectPermissionPage(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询项目权限列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addProjectPermission(Map<String, Object> data, Long userId, String userName) {
        try {
            if (data == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "参数不能为空");
            String projectId = str(data.get("projectId"));
            String organId = str(data.get("organId"));
            String permissionType = str(data.get("permissionType"));
            if (projectId == null || projectId.isEmpty())
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "请选择项目");
            if (organId == null || organId.isEmpty())
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "请选择授权机构");
            if (permissionType == null || permissionType.isEmpty())
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "请选择权限类型");

            Map<String, Object> p = new HashMap<>();
            p.put("projectId", projectId);
            p.put("projectName", resolveName(str(data.get("projectName")), permissionRepository.selectProjectName(projectId), projectId));
            p.put("organId", organId);
            p.put("organName", resolveName(str(data.get("organName")), permissionRepository.selectOrganName(organId), organId));
            p.put("permissionType", permissionType);
            p.put("permissionStatus", 0); // 新增默认待授权
            p.put("templateId", toLong(data.get("templateId")));
            p.put("resourceIds", joinList(data.get("resourceIds")));
            p.put("expireDate", data.get("expireDate"));
            p.put("grantUserId", userId);
            p.put("grantUserName", userName);
            p.put("remark", data.get("remark"));
            permissionRepository.insertPermission(p);
            Map<String, Object> r = new HashMap<>();
            r.put("id", p.get("id"));
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("新增项目权限失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "新增失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateProjectPermission(Map<String, Object> data) {
        try {
            if (data == null || data.get("id") == null)
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            Long id = toLong(data.get("id"));
            if (permissionRepository.selectPermissionById(id) == null)
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "权限记录不存在");
            Map<String, Object> p = new HashMap<>();
            p.put("id", id);
            p.put("permissionType", data.get("permissionType"));
            p.put("expireDate", data.get("expireDate"));
            p.put("remark", data.get("remark"));
            if (data.get("resourceIds") != null) p.put("resourceIds", joinList(data.get("resourceIds")));
            if (data.get("permissionStatus") != null) p.put("permissionStatus", toInt(data.get("permissionStatus")));
            permissionRepository.updatePermission(p);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新项目权限失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity revokeProjectPermission(Long id, Long userId, String userName) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("id", id);
            params.put("userId", userId);
            params.put("userName", userName);
            int n = permissionRepository.revokePermission(params);
            if (n <= 0) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "权限记录不存在");
            return BaseResultEntity.success("撤销成功");
        } catch (Exception e) {
            log.error("撤销项目权限失败, id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "撤销失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchRevokeProjectPermission(List<Long> ids, Long userId, String userName) {
        try {
            if (ids == null || ids.isEmpty())
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            Map<String, Object> params = new HashMap<>();
            params.put("ids", ids);
            params.put("userId", userId);
            params.put("userName", userName);
            int n = permissionRepository.batchRevokePermission(params);
            return BaseResultEntity.success("成功撤销" + n + "条权限");
        } catch (Exception e) {
            log.error("批量撤销项目权限失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量撤销失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity approveProjectPermission(Long id, Long userId, String userName) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("id", id);
            params.put("userId", userId);
            params.put("userName", userName);
            int n = permissionRepository.approvePermission(params);
            if (n <= 0) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "权限记录不存在");
            return BaseResultEntity.success("审批通过");
        } catch (Exception e) {
            log.error("审批项目权限失败, id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "审批失败");
        }
    }

    // ===== 权限模板 =====

    public BaseResultEntity findPermissionTemplates() {
        try {
            List<Map<String, Object>> list = permissionRepository.selectTemplates();
            for (Map<String, Object> t : list) {
                t.put("permissions", splitList(str(t.get("permissions")))); // 逗号串 → 数组，前端 v-for 用
            }
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询权限模板失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addPermissionTemplate(Map<String, Object> data, Long userId) {
        try {
            if (data == null || str(data.get("templateName")) == null || str(data.get("templateName")).trim().isEmpty())
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "模板名称不能为空");
            Map<String, Object> t = new HashMap<>();
            t.put("templateName", data.get("templateName"));
            t.put("templateDesc", data.get("templateDesc"));
            t.put("permissions", joinList(data.get("permissions")));
            t.put("createUserId", userId);
            permissionRepository.insertTemplate(t);
            Map<String, Object> r = new HashMap<>();
            r.put("id", t.get("id"));
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("新增权限模板失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "新增失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updatePermissionTemplate(Map<String, Object> data) {
        try {
            if (data == null || data.get("id") == null)
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            Long id = toLong(data.get("id"));
            if (permissionRepository.selectTemplateById(id) == null)
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "模板不存在");
            Map<String, Object> t = new HashMap<>();
            t.put("id", id);
            t.put("templateName", data.get("templateName"));
            t.put("templateDesc", data.get("templateDesc"));
            if (data.get("permissions") != null) t.put("permissions", joinList(data.get("permissions")));
            permissionRepository.updateTemplate(t);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新权限模板失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deletePermissionTemplate(Long id) {
        try {
            int n = permissionRepository.deleteTemplate(id);
            if (n <= 0) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "模板不存在");
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除权限模板失败, id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ---------- helpers ----------

    private String resolveName(String provided, String looked, String fallback) {
        if (provided != null && !provided.trim().isEmpty()) return provided;
        if (looked != null && !looked.trim().isEmpty()) return looked;
        return fallback;
    }

    @SuppressWarnings("unchecked")
    private String joinList(Object o) {
        if (o == null) return null;
        if (o instanceof List) {
            List<Object> l = (List<Object>) o;
            StringBuilder sb = new StringBuilder();
            for (Object x : l) { if (sb.length() > 0) sb.append(','); sb.append(String.valueOf(x)); }
            return sb.toString();
        }
        return String.valueOf(o);
    }

    private List<String> splitList(String s) {
        List<String> out = new ArrayList<>();
        if (s != null && !s.isEmpty()) {
            for (String p : s.split(",")) if (!p.trim().isEmpty()) out.add(p.trim());
        }
        return out;
    }

    private String str(Object o) { return o == null ? null : String.valueOf(o); }
    private Long toLong(Object o) { try { return o == null ? null : Long.valueOf(String.valueOf(o)); } catch (Exception e) { return null; } }
    private Integer toInt(Object o) { try { return o == null ? null : Integer.valueOf(String.valueOf(o)); } catch (Exception e) { return null; } }
}
