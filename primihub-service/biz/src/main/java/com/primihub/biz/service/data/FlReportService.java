package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.DataTask;
import com.primihub.biz.entity.data.po.FederatedLearning;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import com.primihub.biz.repository.secondarydb.data.FederatedLearningRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 联邦学习 训练曲线 / 模型报告 / 日志 —— 真实实现（原为 rand() 合成的 mock，已根除）。
 * 指标真源 = FlMetricsResolver（引擎 indicatorFileName.json + data_task）；参数调优在 FlTuningService。
 * 诚实边界：引擎只产出**最终**指标，无逐轮训练历史 → iterations/曲线返回空（前端有空态文案），
 * 绝不再合成假曲线；报告/日志字段拿不到真值就为 null/缺省，绝不编造。
 */
@Slf4j
@Service
public class FlReportService {

    @Autowired
    private FederatedLearningRepository federatedLearningRepository;
    @Autowired
    private FlMetricsResolver metricsResolver;

    // 后端 algorithmType（int）↔ 展示名，与前端 constants.js ALGORITHM_LABELS 一致
    private static final Map<Integer, String> ALGORITHM_LABELS = new HashMap<>();
    static {
        ALGORITHM_LABELS.put(9, "线性回归");
        ALGORITHM_LABELS.put(5, "逻辑回归");
        ALGORITHM_LABELS.put(2, "XGBoost");
        ALGORITHM_LABELS.put(3, "横向LR");
    }

    // ===== 训练曲线（诚实：引擎无逐轮历史，只有最终指标）=====

    public BaseResultEntity trainingIterations(String taskId) {
        // 引擎不产出 per-epoch 历史，返回空由前端空态文案说明，绝不合成假轮次
        return BaseResultEntity.success(new ArrayList<>());
    }

    public BaseResultEntity trainingMetrics(String taskId) {
        try {
            FederatedLearningTask flt = federatedLearningRepository.selectTaskByTaskId(taskId);
            if (flt == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在: " + taskId);
            }
            Map<String, Object> ind = metricsResolver.readIndicator(metricsResolver.resolveDataTask(flt));
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("accuracy", ind == null ? null : ind.get("train_acc"));
            m.put("loss", flt.getLoss());
            m.put("auc", ind == null ? null : ind.get("train_auc"));
            m.put("precision", ind == null ? null : ind.get("train_precision"));
            m.put("recall", ind == null ? null : ind.get("train_recall"));
            m.put("f1", ind == null ? null : ind.get("train_f1"));
            m.put("ks", ind == null ? null : ind.get("train_ks"));
            m.put("epoch", flt.getTotalRounds());
            m.put("taskState", flt.getTaskState());
            return BaseResultEntity.success(m);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity lossCurve(String taskId) { return emptyCurve("loss"); }

    public BaseResultEntity accuracyCurve(String taskId) { return emptyCurve("accuracy"); }

    private BaseResultEntity emptyCurve(String name) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("epochs", new ArrayList<>());
        r.put("values", new ArrayList<>());
        r.put("series", Collections.singletonList(mapOf("name", name, "data", new ArrayList<>())));
        return BaseResultEntity.success(r);
    }

    public BaseResultEntity trainingLogs(String taskId) { return taskLogs(taskId); }

    // ===== 模型报告（真实：fl 审计行 + data_task + 引擎指标文件）=====

    public BaseResultEntity reportDetail(String taskId) {
        try {
            FederatedLearningTask flt = federatedLearningRepository.selectTaskByTaskId(taskId);
            if (flt == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在: " + taskId);
            }
            FederatedLearning fl = flt.getFlId() == null ? null : federatedLearningRepository.selectById(flt.getFlId());
            DataTask dt = metricsResolver.resolveDataTask(flt);
            Map<String, Object> ind = metricsResolver.readIndicator(dt);

            Map<String, Object> r = new LinkedHashMap<>();
            r.put("taskId", taskId);
            r.put("taskName", fl != null ? fl.getTaskName() : (dt != null ? dt.getTaskName() : null));
            Integer algo = fl == null ? null : fl.getAlgorithmType();
            r.put("algorithmType", algo == null ? null : ALGORITHM_LABELS.getOrDefault(algo, String.valueOf(algo)));
            Integer fedType = fl == null ? null : fl.getFederatedType();
            r.put("learningType", fedType == null ? null : (fedType == 1 ? "HORIZONTAL" : "VERTICAL"));
            r.put("accuracy", ind == null ? null : ind.get("train_acc"));
            r.put("auc", ind == null ? null : ind.get("train_auc"));
            r.put("precision", ind == null ? null : ind.get("train_precision"));
            r.put("recall", ind == null ? null : ind.get("train_recall"));
            r.put("f1Score", ind == null ? null : ind.get("train_f1"));
            r.put("ks", ind == null ? null : ind.get("train_ks"));
            r.put("totalIterations", flt.getTotalRounds());
            if (dt != null && dt.getTaskStartTime() != null && dt.getTaskEndTime() != null
                    && dt.getTaskEndTime() > dt.getTaskStartTime()) {
                r.put("trainingTime", ((dt.getTaskEndTime() - dt.getTaskStartTime()) / 1000) + "s");
            } else {
                r.put("trainingTime", null);
            }
            long bytes = metricsResolver.modelBytes(dt);
            r.put("modelSize", bytes < 0 ? null
                    : bytes < 1048576 ? String.format("%.1fKB", bytes / 1024.0)
                    : String.format("%.2fMB", bytes / 1048576.0));
            r.put("taskState", flt.getTaskState());
            return BaseResultEntity.success(r);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity reportEvaluation(String taskId) {
        try {
            FederatedLearningTask flt = federatedLearningRepository.selectTaskByTaskId(taskId);
            if (flt == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在: " + taskId);
            }
            Map<String, Object> ind = metricsResolver.readIndicator(metricsResolver.resolveDataTask(flt));
            Map<String, Object> r = new LinkedHashMap<>();
            // 引擎不产出混淆矩阵计数，诚实置 null（原 mock 曾编造 TP/FN）
            r.put("confusionMatrix", null);
            r.put("auc", ind == null ? null : ind.get("train_auc"));
            r.put("ks", ind == null ? null : ind.get("train_ks"));
            List<Map<String, Object>> roc = new ArrayList<>();
            if (ind != null && ind.get("train_fpr") instanceof List && ind.get("train_tpr") instanceof List) {
                List<?> fpr = (List<?>) ind.get("train_fpr");
                List<?> tpr = (List<?>) ind.get("train_tpr");
                for (int i = 0; i < Math.min(fpr.size(), tpr.size()); i++) {
                    roc.add(mapOf("fpr", fpr.get(i), "tpr", tpr.get(i)));
                }
            }
            r.put("roc", roc);
            return BaseResultEntity.success(r);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity featureImportance(String taskId) {
        // 引擎不产出特征重要性，诚实返回空列表（原 mock 曾编造 10 个特征）
        return BaseResultEntity.success(new ArrayList<>());
    }

    public BaseResultEntity generateReport(String taskId) {
        FederatedLearningTask flt = taskId == null ? null : federatedLearningRepository.selectTaskByTaskId(taskId);
        if (flt == null) {
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在: " + taskId);
        }
        if (flt.getTaskState() == null || flt.getTaskState() != 1) {
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务未成功完成，暂无真实指标可出报告");
        }
        return BaseResultEntity.success("报告数据即训练真实产出，已就绪");
    }

    public void exportReport(String taskId, HttpServletResponse response) {
        try {
            BaseResultEntity r = reportDetail(taskId);
            if (r.getCode() != 0 || !(r.getResult() instanceof Map)) {
                response.setContentType("application/json;charset=UTF-8");
                response.getOutputStream().write(("{\"code\":-1,\"msg\":\"" + r.getMsg() + "\"}").getBytes(StandardCharsets.UTF_8));
                return;
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> d = (Map<String, Object>) r.getResult();
            StringBuilder sb = new StringBuilder("指标,值\r\n");
            for (Map.Entry<String, Object> e : d.entrySet()) {
                sb.append(csv(e.getKey())).append(',')
                  .append(csv(e.getValue() == null ? "-" : String.valueOf(e.getValue()))).append("\r\n");
            }
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("fl_report_" + taskId + ".csv", StandardCharsets.UTF_8.name()));
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(sb.toString().getBytes(StandardCharsets.UTF_8));
            response.getOutputStream().flush();
        } catch (Exception e) {
            log.error("导出报告失败", e);
            try { response.setContentType("application/json;charset=UTF-8"); response.getOutputStream().write("{\"code\":-1,\"msg\":\"导出失败\"}".getBytes(StandardCharsets.UTF_8)); } catch (Exception ignore) {}
        }
    }

    // ===== 日志（真实事件流：审计行 + 派发信息 + data_task 终态）=====

    public BaseResultEntity logs(Map<String, Object> query) {
        try {
            String taskId = str(query == null ? null : query.get("taskId"));
            String logType = str(query == null ? null : query.get("logType"));
            Long projectId = longVal(query == null ? null : query.get("projectId"));
            int pageNum = toInt(query == null ? null : firstNonNull(query.get("pageNum"), query.get("pageNo")), 1);
            int pageSize = toInt(query == null ? null : query.get("pageSize"), 10);

            List<Map<String, Object>> all = new ArrayList<>();
            if (taskId != null && !taskId.isEmpty()) {
                FederatedLearningTask flt = federatedLearningRepository.selectTaskByTaskId(taskId);
                if (flt != null) all.addAll(buildTaskEvents(flt, taskNameOf(flt)));
            } else {
                // 多任务视图：按项目取最近任务（上限 50，防对每任务的 data_task 解析放大）
                Map<String, Object> params = new HashMap<>();
                params.put("projectId", projectId);
                params.put("offset", 0);
                params.put("pageSize", 50);
                for (Map<String, Object> row : federatedLearningRepository.selectTaskPage(params)) {
                    FederatedLearningTask flt = federatedLearningRepository.selectTaskByTaskId(str(row.get("taskId")));
                    if (flt != null) all.addAll(buildTaskEvents(flt, str(row.get("taskName"))));
                }
            }
            if (logType != null && !logType.isEmpty()) {
                all.removeIf(e -> !logType.equals(e.get("logType")));
            }
            all.sort((a, b) -> String.valueOf(b.get("createTime")).compareTo(String.valueOf(a.get("createTime"))));
            int from = Math.max(0, (pageNum - 1) * pageSize);
            int to = Math.min(all.size(), from + pageSize);
            List<Map<String, Object>> page = from < all.size() ? all.subList(from, to) : new ArrayList<>();
            return BaseResultEntity.success(mapOf("list", page, "data", page, "total", all.size()));
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity taskLogs(String taskId) {
        try {
            FederatedLearningTask flt = taskId == null ? null : federatedLearningRepository.selectTaskByTaskId(taskId);
            if (flt == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在: " + taskId);
            }
            List<Map<String, Object>> events = buildTaskEvents(flt, taskNameOf(flt));
            return BaseResultEntity.success(mapOf("list", events, "data", events, "total", events.size()));
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    /** 单任务的真实事件行：创建 / 真实派发(modelId) / data_task 终态（成功·失败·取消） */
    private List<Map<String, Object>> buildTaskEvents(FederatedLearningTask flt, String taskName) {
        List<Map<String, Object>> events = new ArrayList<>();
        SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String tid = flt.getTaskId();
        int seq = 0;
        if (flt.getCreateDate() != null) {
            events.add(logRow(tid, taskName, ++seq, "INFO", "联邦学习任务创建", fmt.format(flt.getCreateDate()), null));
        }
        Long modelId = null;
        String logJson = flt.getExecutionLog();
        if (logJson != null && logJson.contains("modelId")) {
            try {
                int cut = logJson.indexOf(" | ");
                Object m = JSON.parseObject(cut > 0 ? logJson.substring(0, cut) : logJson).get("modelId");
                if (m != null) modelId = Long.valueOf(m.toString());
            } catch (Exception ignore) {}
        }
        if (modelId != null && flt.getCreateDate() != null) {
            events.add(logRow(tid, taskName, ++seq, "INFO",
                    "已派发真实联邦训练（model-DAG → node gRPC，modelId=" + modelId + "）",
                    fmt.format(flt.getCreateDate()), null));
        }
        DataTask dt = metricsResolver.resolveDataTask(flt);
        if (dt != null && dt.getTaskState() != null && dt.getTaskEndTime() != null) {
            String endTime = fmt.format(new Date(dt.getTaskEndTime()));
            long secs = dt.getTaskStartTime() != null && dt.getTaskEndTime() > dt.getTaskStartTime()
                    ? (dt.getTaskEndTime() - dt.getTaskStartTime()) / 1000 : -1;
            switch (dt.getTaskState()) {
                case 1:
                    events.add(logRow(tid, taskName, ++seq, "INFO",
                            "训练完成" + (secs >= 0 ? "（耗时 " + secs + "s）" : ""), endTime, null));
                    break;
                case 3:
                    events.add(logRow(tid, taskName, ++seq, "ERROR",
                            "训练失败" + (dt.getTaskErrorMsg() != null ? ": " + dt.getTaskErrorMsg() : ""),
                            endTime, dt.getTaskErrorMsg()));
                    break;
                case 4:
                    events.add(logRow(tid, taskName, ++seq, "WARN", "任务已取消", endTime, null));
                    break;
                default:
            }
        }
        return events;
    }

    private Map<String, Object> logRow(String taskId, String taskName, int seq,
                                       String type, String content, String time, String stackTrace) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("logId", taskId.length() >= 8 ? taskId.substring(0, 8) + "-" + seq : taskId + "-" + seq);
        r.put("taskId", taskId);
        r.put("taskName", taskName);
        r.put("logType", type);
        r.put("content", content);
        r.put("createTime", time);
        if (stackTrace != null) r.put("stackTrace", stackTrace);
        return r;
    }

    /** 导出日志（真实行 CSV；FlLogs 的 batchExportLogs 原全 404） */
    public void exportLogs(Map<String, Object> data, HttpServletResponse response) {
        try {
            Map<String, Object> query = new HashMap<>();
            if (data != null) {
                query.put("taskId", data.get("taskId"));
                query.put("projectId", data.get("projectId"));
                query.put("pageNo", 1);
                query.put("pageSize", 1000);
            }
            BaseResultEntity r = logs(query);
            List<?> rows = new ArrayList<>();
            if (r.getCode() == 0 && r.getResult() instanceof Map) {
                Object l = ((Map<?, ?>) r.getResult()).get("list");
                if (l instanceof List) rows = (List<?>) l;
            }
            // 选中导出：按 logIds 过滤
            if (data != null && data.get("logIds") instanceof List && !((List<?>) data.get("logIds")).isEmpty()) {
                Set<String> ids = new HashSet<>();
                for (Object o : (List<?>) data.get("logIds")) ids.add(String.valueOf(o));
                List<Object> filtered = new ArrayList<>();
                for (Object o : rows) {
                    if (o instanceof Map && ids.contains(String.valueOf(((Map<?, ?>) o).get("logId")))) filtered.add(o);
                }
                rows = filtered;
            }
            StringBuilder sb = new StringBuilder("logId,taskId,taskName,logType,content,createTime\r\n");
            for (Object o : rows) {
                if (!(o instanceof Map)) continue;
                Map<?, ?> m = (Map<?, ?>) o;
                sb.append(csv(str(m.get("logId")))).append(',')
                  .append(csv(str(m.get("taskId")))).append(',')
                  .append(csv(str(m.get("taskName")))).append(',')
                  .append(csv(str(m.get("logType")))).append(',')
                  .append(csv(str(m.get("content")))).append(',')
                  .append(csv(str(m.get("createTime")))).append("\r\n");
            }
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode("fl_logs.csv", StandardCharsets.UTF_8.name()));
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(sb.toString().getBytes(StandardCharsets.UTF_8));
            response.getOutputStream().flush();
        } catch (Exception e) {
            log.error("导出日志失败", e);
            try { response.setContentType("application/json;charset=UTF-8"); response.getOutputStream().write("{\"code\":-1,\"msg\":\"导出失败\"}".getBytes(StandardCharsets.UTF_8)); } catch (Exception ignore) {}
        }
    }

    // ===== internal =====

    private String taskNameOf(FederatedLearningTask flt) {
        try {
            if (flt.getFlId() != null) {
                FederatedLearning fl = federatedLearningRepository.selectById(flt.getFlId());
                if (fl != null && fl.getTaskName() != null) return fl.getTaskName();
            }
        } catch (Exception ignore) {}
        return flt.getTaskId();
    }

    private Map<String, Object> mapOf(Object... kv) { Map<String, Object> m = new LinkedHashMap<>(); for (int i = 0; i + 1 < kv.length; i += 2) m.put(String.valueOf(kv[i]), kv[i + 1]); return m; }
    private String csv(String s) { if (s == null) return ""; return (s.contains(",") || s.contains("\"") || s.contains("\n")) ? "\"" + s.replace("\"", "\"\"") + "\"" : s; }
    private Object firstNonNull(Object... vs) { for (Object v : vs) if (v != null && !String.valueOf(v).isEmpty()) return v; return null; }
    private String str(Object o) { return o == null ? null : String.valueOf(o); }
    private Long longVal(Object o) {
        if (o == null || String.valueOf(o).isEmpty()) return null;
        if (o instanceof Number) return ((Number) o).longValue();
        try { return Long.valueOf(String.valueOf(o)); } catch (Exception e) { return null; }
    }
    private int toInt(Object o, int def) { try { return o == null ? def : Integer.parseInt(String.valueOf(o)); } catch (Exception e) { return def; } }
    private BaseResultEntity fail(Exception e, String msg) { log.error(msg, e); return BaseResultEntity.failure(BaseResultEnum.FAILURE, msg); }
}
