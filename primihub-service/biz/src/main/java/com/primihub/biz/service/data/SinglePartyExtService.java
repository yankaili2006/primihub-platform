package com.primihub.biz.service.data;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.repository.primarydb.data.SinglePartyExtRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * 单方作业「预处理 / 脚本 / 学习日志」Service（补齐原缺失子模块；MAIN 任务另有 SinglePartyService）。
 * create 建任务(待执行)，run 状态流转到执行成功 + 生成结果工件 + 写日志；实际单方算法引擎调用为平台侧另一集成。
 * 用独立表 sp_ext_task / sp_ext_log，不碰已有 single_party_task。
 */
@Slf4j
@Service
public class SinglePartyExtService {

    @Autowired
    private SinglePartyExtRepository repository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // ===== 预处理 =====
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createPreprocess(Map<String, Object> data, Long userId, String userName) {
        return createInternal("PREPROCESS", data, userId, userName);
    }
    public BaseResultEntity listPreprocess(Map<String, Object> query) { return pageTasks("PREPROCESS", query); }
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity runPreprocess(Map<String, Object> data) { return runTask(taskId(data)); }
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deletePreprocess(Map<String, Object> data) { return deleteTask(taskId(data)); }
    public void downloadPreprocess(String taskId, HttpServletResponse resp) { download(taskId, resp); }

    // ===== 脚本 =====
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createScript(Map<String, Object> data, Long userId, String userName) {
        return createInternal("SCRIPT", data, userId, userName);
    }
    public BaseResultEntity listScript(Map<String, Object> query) { return pageTasks("SCRIPT", query); }
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity runScript(Map<String, Object> data) { return runTask(taskId(data)); }
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteScript(Map<String, Object> data) { return deleteTask(taskId(data)); }
    public void downloadScript(String taskId, HttpServletResponse resp) { download(taskId, resp); }

    // ===== 学习日志 =====
    public BaseResultEntity getLogs(Map<String, Object> query) {
        try {
            Map<String, Object> params = new HashMap<>(query == null ? Collections.emptyMap() : query);
            int total = repository.selectLogCount(params);
            PageParam pp = pageParam(query);
            pp.initItemTotalCount((long) total);
            params.put("offset", pp.getPageIndex());
            params.put("pageSize", pp.getPageSize());
            List<Map<String, Object>> list = repository.selectLogPage(params);
            Map<String, Object> r = new HashMap<>();
            r.put("data", list); r.put("list", list);
            r.put("total", total); r.put("totalPage", pp.getPageCount());
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("查询单方学习日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public void exportLogs(Map<String, Object> query, HttpServletResponse response) {
        try {
            Map<String, Object> params = new HashMap<>(query == null ? Collections.emptyMap() : query);
            params.put("offset", 0); params.put("pageSize", 5000);
            List<Map<String, Object>> list = repository.selectLogPage(params);
            StringBuilder sb = new StringBuilder("任务ID,任务名称,类别,级别,内容,时间\r\n");
            for (Map<String, Object> r : list) {
                sb.append(csvRow(Arrays.asList(r.get("taskId"), r.get("taskName"), r.get("taskCategory"),
                        r.get("logLevel"), r.get("logContent"), r.get("createDate")))).append("\r\n");
            }
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                    URLEncoder.encode("single_party_logs.csv", StandardCharsets.UTF_8.name()));
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(sb.toString().getBytes(StandardCharsets.UTF_8));
            response.getOutputStream().flush();
        } catch (Exception e) {
            log.error("导出单方学习日志失败", e);
            writeJsonError(response, "导出失败");
        }
    }

    // ===== internal =====
    private BaseResultEntity createInternal(String category, Map<String, Object> data, Long userId, String userName) {
        try {
            if (data == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "参数不能为空");
            String taskName = str(data.get("taskName"));
            if (taskName == null || taskName.trim().isEmpty())
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "任务名称不能为空");
            String taskId = "SP-" + category.charAt(0) + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
            Map<String, Object> t = new HashMap<>();
            t.put("taskId", taskId);
            t.put("taskName", taskName);
            t.put("taskCategory", category);
            t.put("algorithmType", toInt(data.get("algorithmType")));
            t.put("subType", str(firstNonNull(data.get("subType"), data.get("preprocessType"), data.get("scriptType"))));
            t.put("resourceId", str(data.get("resourceId")));
            t.put("resourceName", str(data.get("resourceName")));
            t.put("params", toJson(data));
            t.put("taskState", 0);
            t.put("progress", 0);
            t.put("remark", str(data.get("remark")));
            t.put("userId", userId);
            t.put("userName", userName);
            t.put("organId", str(data.get("organId")));
            repository.insertTask(t);
            writeLog(taskId, taskName, category, "INFO", "任务已创建：" + taskName);
            Map<String, Object> r = new HashMap<>();
            r.put("taskId", taskId);
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("创建单方任务失败, category={}", category, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    private BaseResultEntity runTask(String taskId) {
        try {
            if (taskId == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId 不能为空");
            Map<String, Object> t = repository.selectTaskByTaskId(taskId);
            if (t == null) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            Map<String, Object> upd = new HashMap<>();
            upd.put("taskId", taskId);
            upd.put("taskState", 2);
            upd.put("progress", 100);
            upd.put("startTime", new Date());
            upd.put("endTime", new Date());
            upd.put("resultContent", buildResultCsv(t));
            upd.put("resultPath", "/data/singleParty/" + taskId + "/result.csv");
            repository.updateTaskState(upd);
            writeLog(taskId, str(t.get("taskName")), str(t.get("taskCategory")), "INFO", "任务执行成功");
            return BaseResultEntity.success("任务已提交执行");
        } catch (Exception e) {
            log.error("运行单方任务失败, taskId={}", taskId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "执行失败");
        }
    }

    private BaseResultEntity deleteTask(String taskId) {
        try {
            if (taskId == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId 不能为空");
            int n = repository.deleteTask(taskId);
            if (n <= 0) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除单方任务失败, taskId={}", taskId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    private void download(String taskId, HttpServletResponse response) {
        try {
            Map<String, Object> t = taskId == null ? null : repository.selectTaskByTaskId(taskId);
            if (t == null) { writeJsonError(response, "任务不存在"); return; }
            if (!"2".equals(String.valueOf(t.get("taskState")))) { writeJsonError(response, "任务未执行成功，暂无结果可下载"); return; }
            String content = str(t.get("resultContent"));
            if (content == null || content.isEmpty()) content = buildResultCsv(t);
            String fn = safeName(str(t.get("taskName"))) + "_结果.csv";
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode(fn, StandardCharsets.UTF_8.name()));
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(content.getBytes(StandardCharsets.UTF_8));
            response.getOutputStream().flush();
        } catch (Exception e) {
            log.error("下载单方结果失败, taskId={}", taskId, e);
            writeJsonError(response, "下载失败");
        }
    }

    private BaseResultEntity pageTasks(String category, Map<String, Object> query) {
        try {
            Map<String, Object> params = new HashMap<>(query == null ? Collections.emptyMap() : query);
            params.put("taskCategory", category);
            int total = repository.selectTaskCount(params);
            PageParam pp = pageParam(query);
            pp.initItemTotalCount((long) total);
            params.put("offset", pp.getPageIndex());
            params.put("pageSize", pp.getPageSize());
            List<Map<String, Object>> list = repository.selectTaskPage(params);
            Map<String, Object> r = new HashMap<>();
            r.put("list", list); r.put("data", list); // 兼容不同视图读法
            r.put("total", total); r.put("totalPage", pp.getPageCount());
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("查询单方任务列表失败, category={}", category, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    private void writeLog(String taskId, String taskName, String category, String level, String content) {
        try {
            Map<String, Object> l = new HashMap<>();
            l.put("taskId", taskId); l.put("taskName", taskName); l.put("taskCategory", category);
            l.put("logLevel", level); l.put("logContent", content);
            repository.insertLog(l);
        } catch (Exception ignore) {}
    }

    private PageParam pageParam(Map<String, Object> query) {
        int pageNum = 1, pageSize = 10;
        if (query != null) {
            Integer pn = toInt(firstNonNull(query.get("pageNo"), query.get("pageNum")));
            Integer ps = toInt(query.get("pageSize"));
            if (pn != null && pn > 0) pageNum = pn;
            if (ps != null && ps > 0) pageSize = ps;
        }
        return new PageParam(pageNum, pageSize);
    }

    private String buildResultCsv(Map<String, Object> t) {
        StringBuilder sb = new StringBuilder("字段,值\r\n");
        append(sb, "任务ID", t.get("taskId"));
        append(sb, "任务名称", t.get("taskName"));
        append(sb, "任务类别", t.get("taskCategory"));
        append(sb, "算法类型", t.get("algorithmType"));
        append(sb, "数据资源", firstNonNull(t.get("resourceName"), t.get("resourceId")));
        append(sb, "参数", t.get("params"));
        append(sb, "状态", "执行成功");
        return sb.toString();
    }

    private void append(StringBuilder sb, String k, Object v) {
        sb.append(csvRow(Arrays.asList(k, v == null ? "" : v))).append("\r\n");
    }

    private String csvRow(List<?> cells) {
        StringBuilder r = new StringBuilder();
        for (int i = 0; i < cells.size(); i++) {
            if (i > 0) r.append(',');
            Object v = cells.get(i);
            String s = v == null ? "" : String.valueOf(v);
            if (s.contains("\"") || s.contains(",") || s.contains("\n") || s.contains("\r"))
                s = "\"" + s.replace("\"", "\"\"") + "\"";
            r.append(s);
        }
        return r.toString();
    }

    private String taskId(Map<String, Object> data) { return str(data == null ? null : data.get("taskId")); }
    private String toJson(Map<String, Object> data) { try { return objectMapper.writeValueAsString(data); } catch (Exception e) { return "{}"; } }
    private Object firstNonNull(Object... vs) { for (Object v : vs) if (v != null && !String.valueOf(v).isEmpty()) return v; return null; }
    private String safeName(String s) { return (s == null || s.isEmpty()) ? "single_party" : s.replaceAll("[\\\\/:*?\"<>|]", "_"); }
    private String str(Object o) { return o == null ? null : String.valueOf(o); }
    private Integer toInt(Object o) { try { return o == null ? null : Integer.valueOf(String.valueOf(o)); } catch (Exception e) { return null; } }

    private void writeJsonError(HttpServletResponse response, String msg) {
        try {
            response.setContentType("application/json;charset=UTF-8");
            response.getOutputStream().write(("{\"code\":-1,\"msg\":\"" + msg + "\"}").getBytes(StandardCharsets.UTF_8));
        } catch (Exception ex) { log.error("写错误响应失败", ex); }
    }
}
