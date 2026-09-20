package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.FederatedLearning;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import com.primihub.biz.entity.data.po.FederatedLearningTuning;
import com.primihub.biz.entity.data.req.FederatedLearningReq;
import com.primihub.biz.repository.primarydb.data.FederatedLearningTuningPrRepository;
import com.primihub.biz.repository.secondarydb.data.FederatedLearningRepository;
import com.primihub.biz.repository.secondarydb.data.FederatedLearningTuningRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 联邦学习参数调优 —— 真实实现（替代 FlReportService 的 mock）。
 * 每个试验 = 一次真实 FederatedLearningService.createTask（model-DAG → node gRPC），
 * 指标 = getTrainingProgress 回读 + 试验完成后从引擎产出的 indicatorFileName.json
 * 读真实 train_acc/train_auc（/data 卷 application 与 node 共享）。
 * 诚实边界：指标文件缺失/训练未完成 → accuracy/auc 保持 null（前端显示 -），绝不编造；
 * 应用参数只把选中试验标记为 applied，不改动基础任务。
 */
@Slf4j
@Service
public class FlTuningService {

    /**
     * 单次调优真实试验数上限（每个试验都是真实多方 FL 训练，成本高）
     */
    private static final int MAX_TRIALS = 8;
    private static final int DEFAULT_RANDOM_TRIALS = 4;

    @Autowired
    private FederatedLearningService federatedLearningService;
    @Autowired
    private FederatedLearningRepository federatedLearningRepository;
    @Autowired
    private FederatedLearningTuningRepository tuningRepository;
    @Autowired
    private FederatedLearningTuningPrRepository tuningPrRepository;
    @Autowired
    private com.primihub.biz.repository.secondarydb.data.DataModelRepository dataModelRepository;
    @Autowired
    private com.primihub.biz.repository.secondarydb.data.DataTaskRepository dataTaskRepository;

    // ===== 创建调优运行 =====

    public BaseResultEntity create(Map<String, Object> data, Long userId) {
        try {
            String baseTaskId = str(data == null ? null : data.get("taskId"));
            if (baseTaskId == null || baseTaskId.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "taskId");
            }
            FederatedLearningTask baseTask = federatedLearningRepository.selectTaskByTaskId(baseTaskId);
            FederatedLearning baseFl = (baseTask == null || baseTask.getFlId() == null)
                    ? null : federatedLearningRepository.selectById(baseTask.getFlId());
            if (baseFl == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE,
                        "基础任务审计记录缺失（taskId=" + baseTaskId + "），无法派生调优试验");
            }

            String searchMethod = str(data.get("searchMethod"));
            searchMethod = searchMethod == null ? "GRID" : searchMethod.toUpperCase();
            double[] lrRange = doubleRange(data.get("learningRateRange"), 0.001, 0.01);
            int[] iterRange = intRange(data.get("iterationsRange"), 50, 200);
            List<Integer> batchSizes = intList(data.get("batchSizes"));
            if (batchSizes.isEmpty()) batchSizes.add(32);

            String note = null;
            if ("BAYESIAN".equals(searchMethod)) {
                // 平台无贝叶斯优化器，诚实降级为随机搜索并明示，而非假装贝叶斯
                note = "BAYESIAN 暂按 RANDOM 随机搜索执行";
                log.info("参数调优 {}: {}", baseTaskId, note);
            }
            List<double[]> combos = buildCombos(searchMethod, lrRange, iterRange, batchSizes, data.get("trials"));
            if (combos.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "搜索空间为空，无法派生试验");
            }

            Long uid = (userId != null && userId > 0) ? userId : baseFl.getUserId();
            Long projectId = longVal(data.get("projectId"));
            if (projectId == null) projectId = baseFl.getProjectId();
            String tuningId = "FT-" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);

            int launched = 0, failed = 0;
            for (int i = 0; i < combos.size(); i++) {
                double[] c = combos.get(i);
                FederatedLearningTuning trial = new FederatedLearningTuning();
                trial.setTuningId(tuningId);
                trial.setBaseTaskId(baseTaskId);
                trial.setProjectId(projectId);
                trial.setSearchMethod(searchMethod);
                trial.setLearningRate(round6(c[0]));
                trial.setIterations((int) c[1]);
                trial.setBatchSize((int) c[2]);
                trial.setUserId(uid);
                try {
                    FederatedLearningReq req = buildTrialReq(baseFl, trial, i + 1);
                    BaseResultEntity r = federatedLearningService.createTask(req, uid);
                    Object childTaskId = (r.getCode() == 0 && r.getResult() instanceof Map)
                            ? ((Map<?, ?>) r.getResult()).get("taskId") : null;
                    if (childTaskId != null) {
                        trial.setChildTaskId(String.valueOf(childTaskId));
                        trial.setTaskState(2);
                        launched++;
                    } else {
                        trial.setTaskState(3);
                        failed++;
                        log.warn("调优试验派发失败 {} #{}: {}", tuningId, i + 1, r.getMsg());
                    }
                } catch (Exception trialEx) {
                    trial.setTaskState(3);
                    failed++;
                    log.error("调优试验派发异常 " + tuningId + " #" + (i + 1), trialEx);
                }
                tuningPrRepository.saveTrial(trial);
            }
            log.info("参数调优运行创建: tuningId={}, base={}, method={}, 派发 {} 成功 / {} 失败",
                    tuningId, baseTaskId, searchMethod, launched, failed);

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("tuningId", tuningId);
            result.put("trials", combos.size());
            result.put("launched", launched);
            result.put("failed", failed);
            result.put("searchMethod", searchMethod);
            if (note != null) result.put("note", note);
            if (launched == 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE,
                        "全部 " + combos.size() + " 个试验派发失败，详见服务日志");
            }
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建参数调优失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建参数调优失败: " + e.getMessage());
        }
    }

    /**
     * 由基础任务的真实配置派生试验请求，仅覆盖超参三项。
     * BeanUtils 会跳过类型不匹配的 trainingParams(String)，随后用基础任务的 JSON 做底、覆盖搜索项。
     */
    private FederatedLearningReq buildTrialReq(FederatedLearning baseFl, FederatedLearningTuning trial, int seq) {
        FederatedLearningReq req = new FederatedLearningReq();
        BeanUtils.copyProperties(baseFl, req);
        FederatedLearningReq.TrainingParams tp = null;
        try {
            if (baseFl.getTrainingParams() != null && !baseFl.getTrainingParams().isEmpty()) {
                tp = JSON.parseObject(baseFl.getTrainingParams(), FederatedLearningReq.TrainingParams.class);
            }
        } catch (Exception e) {
            log.warn("基础任务 trainingParams 解析失败，用默认值打底: {}", e.getMessage());
        }
        if (tp == null) tp = new FederatedLearningReq.TrainingParams();
        tp.setLearningRate(trial.getLearningRate());
        tp.setEpochs(trial.getIterations());
        tp.setBatchSize(trial.getBatchSize());
        req.setTrainingParams(tp);
        req.setTaskType(1);
        String baseName = (baseFl.getTaskName() != null && !baseFl.getTaskName().isEmpty())
                ? baseFl.getTaskName() : "fl";
        req.setTaskName(baseName + "-tune-" + seq);
        return req;
    }

    /**
     * 展开搜索空间为参数组合 [lr, iterations, batchSize]，上限 MAX_TRIALS。
     * GRID 超限时等距抽样并 log 说明丢弃数，绝不静默截断。
     */
    private List<double[]> buildCombos(String method, double[] lr, int[] iter, List<Integer> batches, Object trialsReq) {
        List<double[]> combos = new ArrayList<>();
        if ("GRID".equals(method)) {
            double[] lrPoints = lr[0] == lr[1] ? new double[]{lr[0]} : new double[]{lr[0], lr[1]};
            int[] iterPoints = iter[0] == iter[1] ? new int[]{iter[0]} : new int[]{iter[0], iter[1]};
            for (double l : lrPoints) {
                for (int it : iterPoints) {
                    for (int b : new LinkedHashSet<>(batches)) {
                        combos.add(new double[]{l, it, b});
                    }
                }
            }
            if (combos.size() > MAX_TRIALS) {
                List<double[]> sampled = new ArrayList<>();
                for (int i = 0; i < MAX_TRIALS; i++) {
                    sampled.add(combos.get(i * combos.size() / MAX_TRIALS));
                }
                log.info("GRID 组合 {} 个超过上限 {}，等距抽样丢弃 {} 个",
                        combos.size(), MAX_TRIALS, combos.size() - MAX_TRIALS);
                combos = sampled;
            }
        } else {
            // RANDOM（含 BAYESIAN 降级）：均匀采样
            int n = DEFAULT_RANDOM_TRIALS;
            Long reqN = longVal(trialsReq);
            if (reqN != null && reqN > 0) n = (int) Math.min(reqN, MAX_TRIALS);
            Random rnd = new Random();
            for (int i = 0; i < n; i++) {
                double l = lr[0] + (lr[1] - lr[0]) * rnd.nextDouble();
                int it = iter[0] + (iter[1] > iter[0] ? rnd.nextInt(iter[1] - iter[0] + 1) : 0);
                int b = batches.get(rnd.nextInt(batches.size()));
                combos.add(new double[]{l, it, b});
            }
        }
        return combos;
    }

    // ===== 调优结果（真实指标回读 + 排名） =====

    public BaseResultEntity result(String taskId) {
        try {
            if (taskId == null || taskId.isEmpty()) {
                return BaseResultEntity.success(new ArrayList<>());
            }
            String tuningId = taskId.startsWith("FT-")
                    ? taskId : tuningRepository.selectLatestTuningIdByBaseTaskId(taskId);
            if (tuningId == null) {
                return BaseResultEntity.success(new ArrayList<>());
            }
            List<FederatedLearningTuning> trials = tuningRepository.selectByTuningId(tuningId);

            // 逐试验从真实训练进度回读指标（getTrainingProgress 内部会懒同步终态）
            for (FederatedLearningTuning t : trials) {
                if (t.getChildTaskId() == null) continue;
                try {
                    BaseResultEntity p = federatedLearningService.getTrainingProgress(t.getChildTaskId());
                    if (p.getCode() == 0 && p.getResult() instanceof Map) {
                        Map<?, ?> m = (Map<?, ?>) p.getResult();
                        Double acc = dbl(m.get("accuracy"));
                        Double loss = dbl(m.get("loss"));
                        Long st = longVal(m.get("taskState"));
                        if (acc != null) t.setAccuracy(acc);
                        if (loss != null) t.setLoss(loss);
                        if (st != null) t.setTaskState(st.intValue());
                    }
                } catch (Exception e) {
                    log.warn("回读试验进度失败 {}: {}", t.getChildTaskId(), e.getMessage());
                }
                backfillRealMetrics(t);
            }
            // 有真实 accuracy 的按降序排名，其余 rank 为 null
            List<FederatedLearningTuning> ranked = new ArrayList<>();
            for (FederatedLearningTuning t : trials) if (t.getAccuracy() != null) ranked.add(t);
            ranked.sort((a, b) -> Double.compare(b.getAccuracy(), a.getAccuracy()));
            for (FederatedLearningTuning t : trials) t.setRankNo(null);
            for (int i = 0; i < ranked.size(); i++) ranked.get(i).setRankNo(i + 1);
            for (FederatedLearningTuning t : trials) {
                try { tuningPrRepository.updateTrialMetrics(t); } catch (Exception ignore) {}
            }

            trials.sort(Comparator.comparing(FederatedLearningTuning::getRankNo,
                    Comparator.nullsLast(Comparator.naturalOrder()))
                    .thenComparing(FederatedLearningTuning::getId));
            List<Map<String, Object>> rows = new ArrayList<>();
            for (FederatedLearningTuning t : trials) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", t.getId());
                row.put("tuningId", t.getTuningId());
                row.put("childTaskId", t.getChildTaskId());
                row.put("rank", t.getRankNo());
                row.put("learningRate", t.getLearningRate());
                row.put("iterations", t.getIterations());
                row.put("batchSize", t.getBatchSize());
                row.put("accuracy", t.getAccuracy());
                row.put("loss", t.getLoss());
                row.put("auc", t.getAuc());
                row.put("taskState", t.getTaskState());
                row.put("applied", t.getApplied());
                rows.add(row);
            }
            return BaseResultEntity.success(rows);
        } catch (Exception e) {
            log.error("查询调优结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询调优结果失败: " + e.getMessage());
        }
    }

    /**
     * 试验完成后从引擎真实产出的 indicatorFileName.json 回填 train_acc/train_auc。
     * fl_task.accuracy 桥接链路不落值，指标真源是 node 引擎写在共享 /data 卷的指标文件；
     * 任何一环缺失（未完成/文件不存在）都保持 null，绝不编造。
     */
    private void backfillRealMetrics(FederatedLearningTuning t) {
        if (t.getChildTaskId() == null || t.getAccuracy() != null) return;
        if (t.getTaskState() == null || t.getTaskState() != 1) return;
        try {
            com.primihub.biz.entity.data.po.FederatedLearningTask flt =
                    federatedLearningRepository.selectTaskByTaskId(t.getChildTaskId());
            if (flt == null || flt.getExecutionLog() == null || !flt.getExecutionLog().contains("modelId")) return;
            String logJson = flt.getExecutionLog();
            int cut = logJson.indexOf(" | ");
            Object modelIdObj = JSON.parseObject(cut > 0 ? logJson.substring(0, cut) : logJson).get("modelId");
            if (modelIdObj == null) return;
            Map<String, Object> q = new HashMap<>();
            q.put("modelId", Long.valueOf(modelIdObj.toString()));
            q.put("offset", 0);
            q.put("pageSize", 1);
            List<com.primihub.biz.entity.data.po.DataModelTask> mts = dataModelRepository.queryModelTaskByModelId(q);
            if (mts == null || mts.isEmpty()) return;
            com.primihub.biz.entity.data.po.DataTask dt = dataTaskRepository.selectDataTaskByTaskId(mts.get(0).getTaskId());
            if (dt == null || dt.getTaskResultContent() == null) return;
            Object ind = JSON.parseObject(dt.getTaskResultContent()).get("indicatorFileName");
            if (ind == null) return;
            java.io.File f = new java.io.File(String.valueOf(ind));
            if (!f.exists()) return;
            Map<?, ?> m = JSON.parseObject(new String(
                    java.nio.file.Files.readAllBytes(f.toPath()), java.nio.charset.StandardCharsets.UTF_8));
            Double acc = dbl(m.get("train_acc"));
            Double auc = dbl(m.get("train_auc"));
            if (acc != null) t.setAccuracy(acc);
            if (auc != null) t.setAuc(auc);
        } catch (Exception e) {
            log.warn("回填真实指标失败(保持 null) {}: {}", t.getChildTaskId(), e.getMessage());
        }
    }

    // ===== 应用参数（只记录选中试验，不改动基础任务） =====

    public BaseResultEntity apply(Map<String, Object> data) {
        try {
            Long id = longVal(data == null ? null : data.get("id"));
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id（请从调优结果表的行发起应用）");
            }
            FederatedLearningTuning trial = tuningRepository.selectTrialById(id);
            if (trial == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "调优试验不存在: id=" + id);
            }
            tuningPrRepository.clearApplied(trial.getTuningId());
            tuningPrRepository.markApplied(id);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("id", id);
            result.put("tuningId", trial.getTuningId());
            result.put("learningRate", trial.getLearningRate());
            result.put("iterations", trial.getIterations());
            result.put("batchSize", trial.getBatchSize());
            result.put("childTaskId", trial.getChildTaskId());
            result.put("message", "已记录为本次调优的应用参数（不修改基础任务）");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("应用调优参数失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "应用调优参数失败: " + e.getMessage());
        }
    }

    // ===== 调优运行列表 =====

    public BaseResultEntity list(Map<String, Object> query) {
        try {
            int pageNo = toInt(query == null ? null : firstNonNull(query.get("pageNo"), query.get("pageNum")), 1);
            int pageSize = toInt(query == null ? null : query.get("pageSize"), 10);
            Map<String, Object> params = new HashMap<>();
            params.put("projectId", longVal(query == null ? null : query.get("projectId")));
            params.put("baseTaskId", str(query == null ? null : query.get("taskId")));
            params.put("offset", (pageNo - 1) * pageSize);
            params.put("pageSize", pageSize);
            List<Map<String, Object>> runs = tuningRepository.selectRuns(params);
            Long total = tuningRepository.selectRunsCount(params);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("list", runs);
            result.put("data", runs);
            result.put("total", total);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询调优列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询调优列表失败: " + e.getMessage());
        }
    }

    // ===== helpers =====

    private double[] doubleRange(Object o, double defMin, double defMax) {
        List<Double> vs = new ArrayList<>();
        if (o instanceof List) for (Object v : (List<?>) o) { Double d = dbl(v); if (d != null) vs.add(d); }
        if (vs.size() < 2) return new double[]{defMin, defMax};
        double a = vs.get(0), b = vs.get(1);
        return new double[]{Math.min(a, b), Math.max(a, b)};
    }

    private int[] intRange(Object o, int defMin, int defMax) {
        double[] d = doubleRange(o, defMin, defMax);
        return new int[]{(int) d[0], (int) d[1]};
    }

    private List<Integer> intList(Object o) {
        List<Integer> vs = new ArrayList<>();
        if (o instanceof List) for (Object v : (List<?>) o) { Double d = dbl(v); if (d != null) vs.add(d.intValue()); }
        return vs;
    }

    private Double dbl(Object o) {
        if (o == null) return null;
        if (o instanceof Number) return ((Number) o).doubleValue();
        try { return Double.valueOf(String.valueOf(o)); } catch (Exception e) { return null; }
    }

    private Long longVal(Object o) {
        if (o == null || String.valueOf(o).isEmpty()) return null;
        if (o instanceof Number) return ((Number) o).longValue();
        try { return Long.valueOf(String.valueOf(o)); } catch (Exception e) { return null; }
    }

    private double round6(double v) { return Math.round(v * 1e6) / 1e6; }
    private String str(Object o) { return o == null ? null : String.valueOf(o); }
    private Object firstNonNull(Object... vs) { for (Object v : vs) if (v != null && !String.valueOf(v).isEmpty()) return v; return null; }
    private int toInt(Object o, int def) { try { return o == null ? def : Integer.parseInt(String.valueOf(o)); } catch (Exception e) { return def; } }
}
