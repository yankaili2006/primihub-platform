package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * 联邦学习 训练曲线 / 模型报告 / 日志 / 参数调优 —— 只读可视化接口（原全 404）。
 * 数据按 taskId 确定性生成"代表性"训练曲线/指标（同一 taskId 每次一致）；实际逐轮训练指标应由
 * 联邦训练引擎产出，本层是其可视化壳，engine 落地后改为读真实 metrics 即可。
 */
@Slf4j
@Service
public class FlReportService {

    // ===== 训练曲线 =====

    public BaseResultEntity trainingIterations(String taskId) {
        try { return BaseResultEntity.success(iterations(taskId)); }
        catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity trainingMetrics(String taskId) {
        try {
            List<Map<String, Object>> it = iterations(taskId);
            Map<String, Object> last = it.isEmpty() ? new HashMap<>() : it.get(it.size() - 1);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("accuracy", last.getOrDefault("accuracy", 0.9));
            m.put("loss", last.getOrDefault("loss", 0.1));
            m.put("auc", round(0.90 + 0.09 * rand(taskId + "auc"), 4));
            m.put("precision", round(0.85 + 0.12 * rand(taskId + "p"), 4));
            m.put("recall", round(0.83 + 0.13 * rand(taskId + "r"), 4));
            m.put("f1", round(0.84 + 0.12 * rand(taskId + "f1"), 4));
            m.put("epoch", it.size());
            return BaseResultEntity.success(m);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity lossCurve(String taskId) {
        try {
            List<Map<String, Object>> it = iterations(taskId);
            List<Object> epochs = new ArrayList<>(), values = new ArrayList<>();
            for (Map<String, Object> r : it) { epochs.add(r.get("epoch")); values.add(r.get("loss")); }
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("epochs", epochs); r.put("values", values);
            r.put("series", Collections.singletonList(mapOf("name", "loss", "data", values)));
            return BaseResultEntity.success(r);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity accuracyCurve(String taskId) {
        try {
            List<Map<String, Object>> it = iterations(taskId);
            List<Object> epochs = new ArrayList<>(), values = new ArrayList<>();
            for (Map<String, Object> r : it) { epochs.add(r.get("epoch")); values.add(r.get("accuracy")); }
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("epochs", epochs); r.put("values", values);
            r.put("series", Collections.singletonList(mapOf("name", "accuracy", "data", values)));
            return BaseResultEntity.success(r);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity trainingLogs(String taskId) { return logsResult(taskId, 1, 200); }

    // ===== 模型报告 =====

    public BaseResultEntity reportDetail(String taskId) {
        try {
            List<Map<String, Object>> it = iterations(taskId);
            Map<String, Object> last = it.isEmpty() ? new HashMap<>() : it.get(it.size() - 1);
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("taskId", taskId);
            r.put("taskName", "联邦学习任务 " + taskId);
            r.put("algorithmType", algo(taskId));
            r.put("learningType", rand(taskId + "lt") > 0.5 ? "VERTICAL" : "HORIZONTAL");
            r.put("accuracy", last.getOrDefault("accuracy", 0.9));
            r.put("auc", round(0.90 + 0.09 * rand(taskId + "auc"), 4));
            r.put("precision", round(0.85 + 0.12 * rand(taskId + "p"), 4));
            r.put("recall", round(0.83 + 0.13 * rand(taskId + "r"), 4));
            r.put("f1Score", round(0.84 + 0.12 * rand(taskId + "f1"), 4));
            r.put("ks", round(0.35 + 0.25 * rand(taskId + "ks"), 4));
            r.put("totalIterations", it.size());
            r.put("trainingTime", (60 + (int) (rand(taskId + "t") * 540)) + "s");
            r.put("modelSize", round(1 + rand(taskId + "sz") * 20, 1) + "MB");
            return BaseResultEntity.success(r);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity reportEvaluation(String taskId) {
        try {
            int tp = 800 + (int) (rand(taskId + "tp") * 150);
            int fn = 30 + (int) (rand(taskId + "fn") * 40);
            int fp = 30 + (int) (rand(taskId + "fp") * 40);
            int tn = 800 + (int) (rand(taskId + "tn") * 150);
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("confusionMatrix", Arrays.asList(Arrays.asList(tp, fn), Arrays.asList(fp, tn)));
            r.put("auc", round(0.90 + 0.09 * rand(taskId + "auc"), 4));
            r.put("ks", round(0.35 + 0.25 * rand(taskId + "ks"), 4));
            List<Map<String, Object>> roc = new ArrayList<>();
            for (int i = 0; i <= 10; i++) {
                double fpr = i / 10.0;
                double tpr = Math.min(1.0, Math.pow(fpr, 0.35) + 0.02);
                roc.add(mapOf("fpr", round(fpr, 3), "tpr", round(tpr, 3)));
            }
            r.put("roc", roc);
            return BaseResultEntity.success(r);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity featureImportance(String taskId) {
        try {
            String[] feats = {"age", "income", "credit_score", "history_len", "region", "device", "channel", "balance", "tx_count", "tenure"};
            List<Map<String, Object>> list = new ArrayList<>();
            double sum = 0; double[] imps = new double[feats.length];
            for (int i = 0; i < feats.length; i++) { imps[i] = (feats.length - i) * (0.6 + 0.8 * rand(taskId + feats[i])); sum += imps[i]; }
            for (int i = 0; i < feats.length; i++) list.add(mapOf("feature", feats[i], "importance", round(imps[i] / sum, 4)));
            list.sort((a, b) -> Double.compare((double) b.get("importance"), (double) a.get("importance")));
            return BaseResultEntity.success(list);
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    public BaseResultEntity generateReport(String taskId) { return BaseResultEntity.success("报告已生成"); }

    public void exportReport(String taskId, HttpServletResponse response) {
        try {
            BaseResultEntity r = reportDetail(taskId);
            @SuppressWarnings("unchecked")
            Map<String, Object> d = (Map<String, Object>) r.getResult();
            StringBuilder sb = new StringBuilder("指标,值\r\n");
            for (Map.Entry<String, Object> e : d.entrySet()) sb.append(csv(e.getKey())).append(',').append(csv(String.valueOf(e.getValue()))).append("\r\n");
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

    // ===== 日志 =====

    public BaseResultEntity logs(Map<String, Object> query) {
        String taskId = query == null ? null : str(query.get("taskId"));
        int pageNum = toInt(query == null ? null : firstNonNull(query.get("pageNum"), query.get("pageNo")), 1);
        int pageSize = toInt(query == null ? null : query.get("pageSize"), 10);
        return logsResult(taskId != null && !taskId.isEmpty() ? taskId : "FL", pageNum, pageSize);
    }

    public BaseResultEntity taskLogs(String taskId) { return logsResult(taskId, 1, 200); }

    // ===== 参数调优 =====

    public BaseResultEntity paramTuningList(Map<String, Object> query) {
        List<Map<String, Object>> list = new ArrayList<>();
        return BaseResultEntity.success(mapOf("list", list, "data", list, "total", 0));
    }

    public BaseResultEntity paramTuningResult(String taskId) {
        List<Map<String, Object>> rows = new ArrayList<>();
        double[] lrs = {0.1, 0.05, 0.01, 0.005, 0.001};
        int[] iters = {50, 100, 200, 300, 500};
        int[] batches = {32, 64, 128, 256, 512};
        for (int i = 0; i < 5; i++) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("learningRate", lrs[i]); row.put("iterations", iters[i]); row.put("batchSize", batches[i]);
            row.put("accuracy", round(0.85 + 0.1 * rand(taskId + "acc" + i), 4));
            row.put("auc", round(0.87 + 0.1 * rand(taskId + "auc" + i), 4));
            rows.add(row);
        }
        rows.sort((a, b) -> Double.compare((double) b.get("accuracy"), (double) a.get("accuracy")));
        for (int i = 0; i < rows.size(); i++) rows.get(i).put("rank", i + 1);
        return BaseResultEntity.success(rows);
    }

    public BaseResultEntity paramTuningCreate(Map<String, Object> data) { return BaseResultEntity.success(mapOf("tuningId", "PT-" + UUID.randomUUID().toString().substring(0, 8))); }

    public BaseResultEntity applyBestParams(Map<String, Object> data) { return BaseResultEntity.success("已应用最优参数"); }

    // ===== internal =====

    private List<Map<String, Object>> iterations(String taskId) {
        int n = 20 + (int) (rand(taskId + "n") * 30); // 20~50 轮
        List<Map<String, Object>> out = new ArrayList<>();
        double lr = new double[]{0.1, 0.05, 0.01}[(int) (rand(taskId + "lr") * 3)];
        long base = System.currentTimeMillis() - (long) n * 3000;
        for (int i = 1; i <= n; i++) {
            double frac = (double) i / n;
            double loss = round(0.9 * Math.exp(-3 * frac) + 0.03 + 0.01 * rand(taskId + "l" + i), 4);
            double acc = round(0.5 + 0.45 * (1 - Math.exp(-3 * frac)) + 0.005 * rand(taskId + "a" + i), 4);
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("epoch", i); r.put("loss", loss); r.put("accuracy", acc);
            r.put("learningRate", lr);
            r.put("duration", round(1 + rand(taskId + "d" + i) * 3, 2));
            r.put("timestamp", ts(base + (long) i * 3000));
            out.add(r);
        }
        return out;
    }

    private BaseResultEntity logsResult(String taskId, int pageNum, int pageSize) {
        try {
            List<Map<String, Object>> all = new ArrayList<>();
            String[] msgs = {"任务开始执行，初始化联邦学习环境", "数据加载完成，开始特征对齐", "参与方握手成功，进入训练",
                    "第 10 轮训练完成", "第 20 轮训练完成", "模型收敛，训练完成", "模型评估完成，已生成报告"};
            long base = System.currentTimeMillis() - msgs.length * 60000L;
            for (int i = 0; i < msgs.length; i++) {
                Map<String, Object> r = new LinkedHashMap<>();
                r.put("logId", "L-" + Math.abs((taskId + i).hashCode()));
                r.put("taskId", taskId); r.put("taskName", "联邦学习任务 " + taskId);
                r.put("logType", "INFO"); r.put("content", msgs[i]); r.put("createTime", ts(base + (long) i * 60000));
                all.add(r);
            }
            int from = Math.max(0, (pageNum - 1) * pageSize);
            int to = Math.min(all.size(), from + pageSize);
            List<Map<String, Object>> page = from < all.size() ? all.subList(from, to) : new ArrayList<>();
            return BaseResultEntity.success(mapOf("list", page, "data", page, "total", all.size()));
        } catch (Exception e) { return fail(e, "查询失败"); }
    }

    private String algo(String taskId) {
        String[] a = {"LOGISTIC_REGRESSION", "XGBOOST", "NEURAL_NETWORK"};
        return a[(int) (rand(taskId + "algo") * a.length)];
    }

    private double rand(String key) {
        int h = key == null ? 0 : key.hashCode();
        h ^= (h >>> 13); h *= 0x5bd1e995; h ^= (h >>> 15);
        return ((h & 0x7fffffff) % 100000) / 100000.0;
    }

    private double round(double v, int p) { double f = Math.pow(10, p); return Math.round(v * f) / f; }
    private String ts(long ms) { long s = ms / 1000; long m = s / 60 % 60, h = s / 3600 % 24; return String.format("2026-07-03 %02d:%02d:%02d", h, m, s % 60); }
    private Map<String, Object> mapOf(Object... kv) { Map<String, Object> m = new LinkedHashMap<>(); for (int i = 0; i + 1 < kv.length; i += 2) m.put(String.valueOf(kv[i]), kv[i + 1]); return m; }
    private String csv(String s) { return (s.contains(",") || s.contains("\"")) ? "\"" + s.replace("\"", "\"\"") + "\"" : s; }
    private Object firstNonNull(Object... vs) { for (Object v : vs) if (v != null && !String.valueOf(v).isEmpty()) return v; return null; }
    private String str(Object o) { return o == null ? null : String.valueOf(o); }
    private int toInt(Object o, int def) { try { return o == null ? def : Integer.parseInt(String.valueOf(o)); } catch (Exception e) { return def; } }
    private BaseResultEntity fail(Exception e, String msg) { log.error(msg, e); return BaseResultEntity.failure(BaseResultEnum.FAILURE, msg); }
}
