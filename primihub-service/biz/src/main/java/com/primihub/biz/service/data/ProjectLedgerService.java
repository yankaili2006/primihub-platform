package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.repository.primarydb.data.ProjectLedgerRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * 项目台账 Service。列表/详情是对 data_project 的真实聚合；导出生成 CSV、落 project_ledger_export、可下载/重试。
 * （原 /project/ledger/* 后端完全没有实现，前端整页 404——本类补齐。）
 */
@Slf4j
@Service
public class ProjectLedgerService {

    @Autowired
    private ProjectLedgerRepository ledgerRepository;

    private static final Map<Integer, String> STATUS_NAMES = new HashMap<>();
    static {
        STATUS_NAMES.put(1, "进行中");
        STATUS_NAMES.put(2, "已完成");
        STATUS_NAMES.put(3, "已暂停");
        STATUS_NAMES.put(4, "已关闭");
    }

    public BaseResultEntity findProjectLedgerPage(String projectName, Integer status, String startDate,
                                                  String endDate, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("projectName", projectName);
            params.put("status", status);
            params.put("startDate", startDate);
            params.put("endDate", endDate);

            int total = ledgerRepository.selectLedgerCount(params);
            PageParam pageParam = new PageParam(pageNum == null ? 1 : pageNum, pageSize == null ? 10 : pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<Map<String, Object>> list = ledgerRepository.selectLedgerPage(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询项目台账列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getProjectLedgerDetail(String projectId) {
        try {
            Map<String, Object> row = ledgerRepository.selectLedgerByProjectId(projectId);
            if (row == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "项目台账不存在");
            }
            row.put("resourceList", ledgerRepository.selectProjectResources(projectId));
            return BaseResultEntity.success(row);
        } catch (Exception e) {
            log.error("查询项目台账详情失败, projectId={}", projectId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 创建导出：解析待导出台账行→生成 CSV→落 project_ledger_export→返回 exportId。
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createExport(String exportType, String exportFormat, List<String> projectIds,
                                         Long userId, String userName) {
        try {
            if (exportType == null || exportType.trim().isEmpty()) {
                exportType = "BATCH";
            }
            if (exportFormat == null || exportFormat.trim().isEmpty()) {
                exportFormat = "CSV";
            }
            List<Map<String, Object>> rows = resolveRows(exportType, projectIds);
            if (rows.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "没有可导出的项目台账");
            }
            String csv = buildCsv(rows);
            String fileName = "project_ledger_" + System.currentTimeMillis() + ".csv";

            Map<String, Object> export = new HashMap<>();
            export.put("exportType", exportType);
            export.put("exportFormat", exportFormat);
            export.put("projectCount", rows.size());
            export.put("projectIds", joinProjectIds(rows));
            export.put("exportStatus", 1); // 1=已完成
            export.put("exportUserId", userId);
            export.put("exportUserName", userName);
            export.put("fileName", fileName);
            export.put("fileContent", csv);
            export.put("errorMsg", null);
            ledgerRepository.insertExport(export);

            Map<String, Object> result = new HashMap<>();
            result.put("exportId", export.get("exportId"));
            result.put("fileName", fileName);
            result.put("projectCount", rows.size());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建项目台账导出失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "导出失败");
        }
    }

    public BaseResultEntity getExportHistory(Long userId) {
        try {
            return BaseResultEntity.success(ledgerRepository.selectExportHistory(userId));
        } catch (Exception e) {
            log.error("查询导出历史失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity retryExport(Long exportId, Long userId, String userName) {
        try {
            Map<String, Object> exp = ledgerRepository.selectExportById(exportId);
            if (exp == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "导出记录不存在");
            }
            String exportType = str(exp.get("exportType"));
            List<String> projectIds = splitProjectIds(str(exp.get("projectIds")));
            List<Map<String, Object>> rows = resolveRows(exportType, projectIds);

            Map<String, Object> upd = new HashMap<>();
            upd.put("exportId", exportId);
            if (rows.isEmpty()) {
                upd.put("exportStatus", 2); // 失败
                upd.put("errorMsg", "重试时无可导出项目");
                ledgerRepository.updateExport(upd);
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "重试失败：无可导出项目");
            }
            upd.put("exportStatus", 1);
            upd.put("projectCount", rows.size());
            upd.put("fileContent", buildCsv(rows));
            upd.put("fileName", "project_ledger_" + System.currentTimeMillis() + ".csv");
            upd.put("errorMsg", "");
            ledgerRepository.updateExport(upd);
            return BaseResultEntity.success("重试成功");
        } catch (Exception e) {
            log.error("重试导出失败, exportId={}", exportId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "重试失败");
        }
    }

    public void downloadExportFile(Long exportId, HttpServletResponse response) {
        try {
            Map<String, Object> exp = exportId == null ? null : ledgerRepository.selectExportById(exportId);
            if (exp == null) {
                writeJsonError(response, "导出记录不存在");
                return;
            }
            Object st = exp.get("exportStatus");
            if (st == null || !"1".equals(String.valueOf(st))) {
                writeJsonError(response, "该导出尚未完成，无法下载");
                return;
            }
            String content = str(exp.get("fileContent"));
            String fileName = exp.get("fileName") == null ? ("project_ledger_" + exportId + ".csv")
                    : str(exp.get("fileName"));
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                    URLEncoder.encode(fileName, StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF}); // UTF-8 BOM
            os.write(content.getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("下载导出文件失败, exportId={}", exportId, e);
            writeJsonError(response, "下载失败");
        }
    }

    // ---------- helpers ----------

    private List<Map<String, Object>> resolveRows(String exportType, List<String> projectIds) {
        List<Map<String, Object>> rows = new ArrayList<>();
        if ("ALL".equalsIgnoreCase(exportType)) {
            Map<String, Object> params = new HashMap<>(); // 无 offset/pageSize → 不分页，导出全部
            rows = ledgerRepository.selectLedgerPage(params);
        } else if (projectIds != null) {
            for (String pid : projectIds) {
                if (pid == null || pid.trim().isEmpty()) continue;
                Map<String, Object> r = ledgerRepository.selectLedgerByProjectId(pid.trim());
                if (r != null) rows.add(r);
            }
        }
        return rows;
    }

    private String buildCsv(List<Map<String, Object>> rows) {
        StringBuilder sb = new StringBuilder();
        sb.append("项目ID,项目名称,项目状态,任务数量,完成任务,参与方数,资源数量,负责人,参与机构,创建时间,更新时间\r\n");
        for (Map<String, Object> r : rows) {
            Integer status = toInt(r.get("projectStatus"));
            List<Object> cells = Arrays.asList(
                    r.get("projectId"), r.get("projectName"),
                    STATUS_NAMES.getOrDefault(status, status == null ? "" : String.valueOf(status)),
                    r.get("taskCount"), r.get("completedTaskCount"),
                    r.get("participantCount"), r.get("resourceCount"),
                    r.get("ownerName"), r.get("providerOrganNames"),
                    r.get("createDate"), r.get("updateDate"));
            sb.append(toCsvRow(cells)).append("\r\n");
        }
        return sb.toString();
    }

    private String toCsvRow(List<?> cells) {
        StringBuilder r = new StringBuilder();
        for (int i = 0; i < cells.size(); i++) {
            if (i > 0) r.append(',');
            Object v = cells.get(i);
            String s = v == null ? "" : String.valueOf(v);
            if (s.contains("\"") || s.contains(",") || s.contains("\n") || s.contains("\r")) {
                s = "\"" + s.replace("\"", "\"\"") + "\"";
            }
            r.append(s);
        }
        return r.toString();
    }

    private String joinProjectIds(List<Map<String, Object>> rows) {
        StringBuilder sb = new StringBuilder();
        for (Map<String, Object> r : rows) {
            if (sb.length() > 0) sb.append(',');
            sb.append(str(r.get("projectId")));
        }
        String s = sb.toString();
        return s.length() > 3900 ? s.substring(0, 3900) : s;
    }

    private List<String> splitProjectIds(String s) {
        List<String> out = new ArrayList<>();
        if (s != null && !s.isEmpty()) {
            for (String p : s.split(",")) if (!p.trim().isEmpty()) out.add(p.trim());
        }
        return out;
    }

    private String str(Object o) { return o == null ? null : String.valueOf(o); }

    private Integer toInt(Object o) {
        if (o == null) return null;
        try { return Integer.valueOf(String.valueOf(o)); } catch (Exception e) { return null; }
    }

    private void writeJsonError(HttpServletResponse response, String msg) {
        try {
            response.setContentType("application/json;charset=UTF-8");
            response.getOutputStream().write(("{\"code\":-1,\"msg\":\"" + msg + "\"}").getBytes(StandardCharsets.UTF_8));
        } catch (Exception ex) {
            log.error("写下载错误响应失败", ex);
        }
    }
}
