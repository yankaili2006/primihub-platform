package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.repository.primarydb.data.ProjectResultRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * 项目结果保存 Service。真实 DB 存储：结果记录的分页/保存/批量保存/删除/下载 + 一份保存配置。
 * （原 /project/result/* 后端完全没有实现，前端整页 404——本类补齐。）
 */
@Slf4j
@Service
public class ProjectResultService {

    @Autowired
    private ProjectResultRepository resultRepository;

    public BaseResultEntity findProjectResultPage(String projectName, String taskName, String resultType,
                                                  Integer saveStatus, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("projectName", projectName);
            params.put("taskName", taskName);
            params.put("resultType", resultType);
            params.put("saveStatus", saveStatus);

            int total = resultRepository.selectResultCount(params);
            PageParam pageParam = new PageParam(pageNum == null ? 1 : pageNum, pageSize == null ? 10 : pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<Map<String, Object>> list = resultRepository.selectResultPage(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询项目结果列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 保存项目结果：带 id → 更新为"已保存"（生成保存路径 + 可下载内容）；无 id → 新建一条已保存记录。
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveProjectResult(Map<String, Object> data, Long userId) {
        try {
            if (data == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "参数不能为空");
            }
            Long id = toLong(data.get("id"));
            String saveDirectory = str(data.getOrDefault("saveDirectory", "/data/results"));
            String fileName = str(data.get("fileName"));
            String saveFormat = str(data.getOrDefault("saveFormat", "ORIGINAL"));
            String remark = str(data.get("remark"));

            if (id != null) {
                Map<String, Object> existing = resultRepository.selectResultById(id);
                if (existing == null) {
                    return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "结果记录不存在");
                }
                if (fileName == null || fileName.trim().isEmpty()) {
                    fileName = str(existing.get("resultName"));
                }
                String savePath = trimSlash(saveDirectory) + "/" + fileName;
                Map<String, Object> upd = new HashMap<>();
                upd.put("id", id);
                upd.put("saveStatus", 1);
                upd.put("saveDirectory", saveDirectory);
                upd.put("fileName", fileName);
                upd.put("saveFormat", saveFormat);
                upd.put("savePath", savePath);
                upd.put("remark", remark);
                upd.put("resultName", data.get("resultName"));
                upd.put("saveDate", new Date());
                upd.put("fileContent", buildResultCsv(existing, savePath));
                resultRepository.updateResult(upd);
                Map<String, Object> r = new HashMap<>();
                r.put("id", id);
                return BaseResultEntity.success(r);
            }

            // 无 id：新建一条已保存记录（内容驱动）
            String resultName = str(data.get("resultName"));
            if (resultName == null || resultName.trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "结果名称不能为空");
            }
            if (fileName == null || fileName.trim().isEmpty()) fileName = resultName;
            String savePath = trimSlash(saveDirectory) + "/" + fileName;
            Map<String, Object> ins = new HashMap<>();
            ins.put("projectId", data.get("projectId"));
            ins.put("projectName", data.get("projectName"));
            ins.put("taskId", data.get("taskId"));
            ins.put("taskName", data.get("taskName"));
            ins.put("resultType", data.getOrDefault("resultType", "COMPUTE"));
            ins.put("resultName", resultName);
            ins.put("resultDesc", data.get("resultDesc"));
            ins.put("saveStatus", 1);
            ins.put("fileSize", data.get("fileSize"));
            ins.put("fileMd5", data.get("fileMd5"));
            ins.put("saveDirectory", saveDirectory);
            ins.put("fileName", fileName);
            ins.put("saveFormat", saveFormat);
            ins.put("savePath", savePath);
            ins.put("remark", remark);
            ins.put("userId", userId);
            ins.put("organId", data.get("organId"));
            ins.put("saveDate", new Date());
            ins.put("fileContent", buildResultCsv(ins, savePath));
            resultRepository.insertResult(ins);
            Map<String, Object> r = new HashMap<>();
            r.put("id", ins.get("id"));
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("保存项目结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchSaveProjectResult(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }
            int n = resultRepository.markSaved(Collections.singletonMap("ids", ids));
            return BaseResultEntity.success("成功保存" + n + "条结果");
        } catch (Exception e) {
            log.error("批量保存项目结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量保存失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteProjectResult(Long id) {
        try {
            int n = resultRepository.deleteResult(id);
            if (n <= 0) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "结果记录不存在");
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除项目结果失败, id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteProjectResult(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }
            int n = resultRepository.batchDeleteResult(ids);
            return BaseResultEntity.success("成功删除" + n + "条结果");
        } catch (Exception e) {
            log.error("批量删除项目结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量删除失败");
        }
    }

    public void downloadProjectResult(Long id, HttpServletResponse response) {
        try {
            Map<String, Object> row = id == null ? null : resultRepository.selectResultById(id);
            if (row == null) {
                writeJsonError(response, "结果记录不存在");
                return;
            }
            if (!"1".equals(String.valueOf(row.get("saveStatus")))) {
                writeJsonError(response, "该结果尚未保存，无法下载");
                return;
            }
            String content = str(row.get("fileContent"));
            if (content == null || content.isEmpty()) {
                content = buildResultCsv(row, str(row.get("savePath")));
            }
            String fileName = str(row.get("fileName"));
            if (fileName == null || fileName.isEmpty()) fileName = "project_result_" + id;
            if (!fileName.toLowerCase().endsWith(".csv")) fileName = fileName + ".csv";
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                    URLEncoder.encode(fileName, StandardCharsets.UTF_8.name()));
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(content.getBytes(StandardCharsets.UTF_8));
            response.getOutputStream().flush();
        } catch (Exception e) {
            log.error("下载项目结果失败, id={}", id, e);
            writeJsonError(response, "下载失败");
        }
    }

    public BaseResultEntity getResultConfig() {
        try {
            Map<String, Object> cfg = resultRepository.selectConfig();
            if (cfg == null) {
                cfg = new LinkedHashMap<>();
                cfg.put("defaultPath", "/data/results");
                cfg.put("autoSave", false);
                cfg.put("retentionDays", 30);
                cfg.put("maxStorageGB", 100);
                Map<String, Object> seed = new HashMap<>(cfg);
                seed.put("autoSave", 0);
                try { resultRepository.insertConfig(seed); } catch (Exception ignore) {}
            } else {
                cfg.put("autoSave", "1".equals(String.valueOf(cfg.get("autoSave")))); // tinyint→boolean
            }
            return BaseResultEntity.success(cfg);
        } catch (Exception e) {
            log.error("查询结果保存配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateResultConfig(Map<String, Object> data) {
        try {
            if (data == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "参数不能为空");
            Map<String, Object> cfg = new HashMap<>();
            cfg.put("defaultPath", data.get("defaultPath"));
            Object autoSave = data.get("autoSave");
            cfg.put("autoSave", (autoSave != null && (Boolean.TRUE.equals(autoSave) || "true".equals(String.valueOf(autoSave)) || "1".equals(String.valueOf(autoSave)))) ? 1 : 0);
            cfg.put("retentionDays", data.get("retentionDays"));
            cfg.put("maxStorageGB", data.get("maxStorageGB"));
            if (resultRepository.selectConfig() == null) {
                resultRepository.insertConfig(cfg);
            } else {
                resultRepository.updateConfig(cfg);
            }
            return BaseResultEntity.success("配置保存成功");
        } catch (Exception e) {
            log.error("更新结果保存配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "配置保存失败");
        }
    }

    // ---------- helpers ----------

    private String buildResultCsv(Map<String, Object> row, String savePath) {
        StringBuilder sb = new StringBuilder();
        sb.append("字段,值\r\n");
        appendRow(sb, "项目名称", row.get("projectName"));
        appendRow(sb, "任务名称", row.get("taskName"));
        appendRow(sb, "任务ID", row.get("taskId"));
        appendRow(sb, "结果类型", row.get("resultType"));
        appendRow(sb, "结果名称", row.get("resultName"));
        appendRow(sb, "结果描述", row.get("resultDesc"));
        appendRow(sb, "保存路径", savePath);
        appendRow(sb, "保存格式", row.get("saveFormat"));
        return sb.toString();
    }

    private void appendRow(StringBuilder sb, String k, Object v) {
        sb.append(csv(k)).append(',').append(csv(v == null ? "" : String.valueOf(v))).append("\r\n");
    }

    private String csv(String s) {
        if (s.contains("\"") || s.contains(",") || s.contains("\n") || s.contains("\r")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    private String trimSlash(String s) {
        if (s == null) return "/data/results";
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }

    private String str(Object o) { return o == null ? null : String.valueOf(o); }

    private Long toLong(Object o) {
        if (o == null) return null;
        try { return Long.valueOf(String.valueOf(o)); } catch (Exception e) { return null; }
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
