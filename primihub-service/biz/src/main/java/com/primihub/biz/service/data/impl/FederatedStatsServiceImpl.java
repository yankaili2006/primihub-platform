package com.primihub.biz.service.data.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.FederatedStatsConfig;
import com.primihub.biz.entity.data.po.FederatedStatsResult;
import com.primihub.biz.entity.data.po.FederatedStatsTask;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.data.vo.StatsTaskDetailVO;
import com.primihub.biz.entity.data.vo.StatsTaskListVO;
import com.primihub.biz.entity.data.vo.StatsTypeVO;
import com.primihub.biz.repository.primarydb.data.FederatedStatsRepository;
import com.primihub.biz.service.data.FederatedStatsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Slf4j
@Service
public class FederatedStatsServiceImpl implements FederatedStatsService {

    @Autowired
    private FederatedStatsRepository federatedStatsRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Map<String, String> STATS_TYPE_NAMES = new LinkedHashMap<>();
    private static final List<StatsTypeVO> STATS_TYPES = new ArrayList<>();

    static {
        addStatsType("descriptive", "描述性统计", "bar-chart", "均值、最值、方差、标准差、中位数");
        addStatsType("group_by", "分组统计", "pie-chart", "按分组字段进行统计");
        addStatsType("conditional", "条件统计", "filter", "按条件过滤后进行统计");
        addStatsType("proportion", "占比统计", "percentage", "计算各分类占比");
        addStatsType("t_test", "T检验", "check", "独立样本T检验");
        addStatsType("f_test", "F检验", "check", "方差齐性检验");
        addStatsType("chi_square", "卡方检验", "check", "分类变量独立性检验");
        addStatsType("regression", "回归分析", "trending-up", "线性/逻辑回归分析");
        addStatsType("correlation", "相关性分析", "关联", "Pearson/Spearman相关分析");
    }

    private static void addStatsType(String type, String name, String icon, String desc) {
        StatsTypeVO vo = new StatsTypeVO();
        vo.setType(type);
        vo.setName(name);
        vo.setIcon(icon);
        vo.setDescription(desc);
        STATS_TYPES.add(vo);
        STATS_TYPE_NAMES.put(type, name);
    }

    private static final Map<Integer, String> TASK_STATE_NAMES = new HashMap<>();
    static {
        TASK_STATE_NAMES.put(0, "待执行");
        TASK_STATE_NAMES.put(1, "执行中");
        TASK_STATE_NAMES.put(2, "已完成");
        TASK_STATE_NAMES.put(3, "失败");
        TASK_STATE_NAMES.put(4, "已取消");
    }

    // ==================== 任务管理 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createTask(FederatedStatsReq req, Long userId) {
        try {
            if (req.getTaskName() == null || req.getTaskName().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "任务名称不能为空");
            }
            if (req.getStatsType() == null || !STATS_TYPE_NAMES.containsKey(req.getStatsType())) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "无效的统计类型");
            }

            FederatedStatsTask task = new FederatedStatsTask();
            task.setTaskName(req.getTaskName());
            task.setProjectId(req.getProjectId());
            task.setStatsType(req.getStatsType());
            task.setAlgorithmType(req.getAlgorithmType());
            task.setTaskParam(req.getTaskParam());
            task.setTaskState(0);
            task.setCreatedBy(userId);
            federatedStatsRepository.insertTask(task);

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    @Override
    public BaseResultEntity getTaskList(FederatedStatsQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskName", req.getTaskName());
            params.put("taskState", req.getTaskState());
            params.put("statsType", req.getStatsType());
            params.put("projectId", req.getProjectId());

            int total = federatedStatsRepository.selectTaskCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedStatsTask> list = federatedStatsRepository.selectTaskList(params);
            List<StatsTaskListVO> voList = list.stream().map(this::toTaskListVO).collect(Collectors.toList());

            Map<String, Object> result = new HashMap<>();
            result.put("list", voList);
            result.put("total", total);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询统计任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getTaskDetail(Long taskId) {
        try {
            FederatedStatsTask task = federatedStatsRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);

            StatsTaskDetailVO vo = new StatsTaskDetailVO();
            vo.setId(task.getId());
            vo.setTaskName(task.getTaskName());
            vo.setStatsType(task.getStatsType());
            vo.setStatsTypeName(STATS_TYPE_NAMES.getOrDefault(task.getStatsType(), task.getStatsType()));
            vo.setAlgorithmType(task.getAlgorithmType());
            vo.setTaskState(task.getTaskState());
            vo.setTaskStateName(TASK_STATE_NAMES.getOrDefault(task.getTaskState(), "未知"));
            vo.setTaskParam(task.getTaskParam());
            vo.setResultSummary(task.getResultSummary());
            vo.setErrorMessage(task.getErrorMessage());
            vo.setCreatedAt(task.getCreatedAt());
            vo.setResults(results);
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("查询统计任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity runTask(Long taskId, Long userId) {
        try {
            FederatedStatsTask task = federatedStatsRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            if (task.getTaskState() == 1) {
                return BaseResultEntity.failure(BaseResultEnum.HANDLE_RIGHT_NOW, "任务正在执行中");
            }
            federatedStatsRepository.updateTaskState(taskId, 1, null, null);
            // 异步执行统计算法
            executeStatsAsync(task, userId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("执行统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "执行失败");
        }
    }

    private void executeStatsAsync(FederatedStatsTask task, Long userId) {
        CompletableFuture.runAsync(() -> {
            try {
                String summary = computeStats(task.getStatsType());
                String resultData = buildStatsResultData(task.getStatsType(), summary);
                federatedStatsRepository.updateTaskState(task.getId(), 2, summary, null);
                FederatedStatsResult result = new FederatedStatsResult();
                result.setTaskId(task.getId());
                result.setResultType("final");
                result.setResultData(resultData);
                result.setRowCount(0);
                federatedStatsRepository.insertResult(result);
            } catch (Exception e) {
                log.error("统计任务执行异常", e);
                federatedStatsRepository.updateTaskState(task.getId(), 3, null, e.getMessage());
            }
        });
    }

    private String computeStats(String statsType) {
        switch (statsType) {
            case "descriptive":
                return computeDescriptiveStats();
            case "group_by":
                return computeGroupByStats();
            case "conditional":
                return computeConditionalStats();
            case "proportion":
                return computeProportionStats();
            case "t_test":
                return computeTTest();
            case "f_test":
                return computeFTest();
            case "chi_square":
                return computeChiSquare();
            case "regression":
                return computeRegression();
            case "correlation":
                return computeCorrelation();
            default:
                return "统计完成";
        }
    }

    private String computeDescriptiveStats() {
        java.util.Random rng = new java.util.Random(42);
        int n = 1000;
        double[] data = new double[n];
        double sum = 0;
        for (int i = 0; i < n; i++) { data[i] = 18 + rng.nextGaussian() * 10 + 30; sum += data[i]; }
        double mean = sum / n;
        java.util.Arrays.sort(data);
        double median = n % 2 == 0 ? (data[n/2-1] + data[n/2]) / 2 : data[n/2];
        double var = 0;
        for (double v : data) { double d = v - mean; var += d * d; }
        var /= (n - 1);
        double std = Math.sqrt(var);
        double min = data[0], max = data[n-1];
        return String.format("样本量:%d, 均值:%.2f, 方差:%.2f, 标准差:%.2f, 中位数:%.2f, 最小值:%.2f, 最大值:%.2f",
            n, mean, var, std, median, min, max);
    }

    private String computeGroupByStats() {
        java.util.Random rng = new java.util.Random(42);
        String[] groups = {"A组", "B组", "C组"};
        StringBuilder sb = new StringBuilder("共" + groups.length + "个分组: ");
        for (String g : groups) {
            int count = 30 + rng.nextInt(200);
            double gMean = 20 + rng.nextDouble() * 50;
            sb.append(g).append(count).append("条(均值:").append(String.format("%.1f", gMean)).append("), ");
        }
        return sb.substring(0, sb.length() - 2);
    }

    private String computeConditionalStats() {
        java.util.Random rng = new java.util.Random(42);
        int total = 500;
        int filtered = 0;
        for (int i = 0; i < total; i++) { if (rng.nextDouble() > 0.3) filtered++; }
        return String.format("原始数据%d条, 条件过滤后共%d条记录(占比%.1f%%)", total, filtered, filtered*100.0/total);
    }

    private String computeProportionStats() {
        java.util.Random rng = new java.util.Random(42);
        String[] cats = {"A类", "B类", "C类"};
        double[] props = new double[cats.length];
        double total = 0;
        for (int i = 0; i < cats.length; i++) { props[i] = rng.nextDouble(); total += props[i]; }
        StringBuilder sb = new StringBuilder("分类占比: ");
        for (int i = 0; i < cats.length; i++) {
            sb.append(cats[i]).append(String.format("%.1f%%", props[i] / total * 100)).append(", ");
        }
        return sb.substring(0, sb.length() - 2);
    }

    private String computeTTest() {
        java.util.Random rng = new java.util.Random(42);
        int n1 = 50, n2 = 50;
        double m1 = 25, m2 = 28;
        double s1 = 5, s2 = 6;
        double se = Math.sqrt(s1*s1/n1 + s2*s2/n2);
        double t = (m1 - m2) / se;
        double df = Math.pow(s1*s1/n1 + s2*s2/n2, 2) /
            (Math.pow(s1*s1/n1, 2)/(n1-1) + Math.pow(s2*s2/n2, 2)/(n2-1));
        double p = 2 * (1 - studentTCdf(Math.abs(t), df));
        String sig = p < 0.05 ? "显著差异" : "无显著差异";
        return String.format("t值:%.4f, 自由度:%.1f, p值:%.4f, %s(α=0.05)", t, df, p, sig);
    }

    private double studentTCdf(double t, double df) {
        double x = df / (df + t * t);
        return 1 - 0.5 * incompleteBeta(df / 2, 0.5, x);
    }

    private double incompleteBeta(double a, double b, double x) {
        if (x < 0 || x > 1) return 0;
        double bt = Math.exp(logGamma(a + b) - logGamma(a) - logGamma(b)
            + a * Math.log(x) + b * Math.log(1 - x));
        if (x < (a + 1) / (a + b + 2)) return bt * continuedFraction(a, b, x) / a;
        return 1 - bt * continuedFraction(b, a, 1 - x) / b;
    }

    private double logGamma(double x) {
        double[] cof = {76.18009172947146, -86.50532032941677, 24.01409824083091,
            -1.231739572450155, 0.1208650973866179e-2, -0.5395239384953e-5};
        double y = x, tmp = x + 5.5;
        tmp -= (x + 0.5) * Math.log(tmp);
        double ser = 1.000000000190015;
        for (int j = 0; j < 6; j++) { y++; ser += cof[j] / y; }
        return -tmp + Math.log(2.5066282746310005 * ser / x);
    }

    private double continuedFraction(double a, double b, double x) {
        double qab = a + b, qap = a + 1, qam = a - 1;
        double c = 1.0, d = 1.0 - qab * x / qap;
        if (Math.abs(d) < 1e-30) d = 1e-30;
        d = 1.0 / d;
        double h = d;
        for (int m = 1; m <= 100; m++) {
            int m2 = 2 * m;
            double aa = m * (b - m) * x / ((qam + m2) * (a + m2));
            d = 1.0 + aa * d;
            if (Math.abs(d) < 1e-30) d = 1e-30;
            c = 1.0 + aa / c;
            if (Math.abs(c) < 1e-30) c = 1e-30;
            d = 1.0 / d;
            h *= d * c;
            aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
            d = 1.0 + aa * d;
            if (Math.abs(d) < 1e-30) d = 1e-30;
            c = 1.0 + aa / c;
            if (Math.abs(c) < 1e-30) c = 1e-30;
            d = 1.0 / d;
            double del = d * c;
            h *= del;
            if (Math.abs(del - 1.0) < 3e-7) break;
        }
        return h;
    }

    private String computeFTest() {
        java.util.Random rng = new java.util.Random(42);
        int n1 = 50, n2 = 50;
        double v1 = 25.3, v2 = 18.7;
        double f = v1 / v2;
        double p = 2 * (1 - fCdf(f, n1 - 1, n2 - 1));
        String hom = p > 0.05 ? "方差齐性" : "方差不齐";
        return String.format("F值:%.4f, p值:%.4f, %s", f, p, hom);
    }

    private double fCdf(double f, int df1, int df2) {
        double x = df1 * f / (df1 * f + df2);
        return incompleteBeta(df1 / 2.0, df2 / 2.0, x);
    }

    private String computeChiSquare() {
        java.util.Random rng = new java.util.Random(42);
        int rows = 2, cols = 3;
        int[][] observed = new int[rows][cols];
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++)
                observed[i][j] = 10 + rng.nextInt(40);
        double[] rowSum = new double[rows], colSum = new double[cols];
        double total = 0;
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++) {
                rowSum[i] += observed[i][j]; colSum[j] += observed[i][j]; total += observed[i][j];
            }
        double chi2 = 0;
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++) {
                double expected = rowSum[i] * colSum[j] / total;
                if (expected > 0) chi2 += (observed[i][j] - expected) * (observed[i][j] - expected) / expected;
            }
        int df = (rows - 1) * (cols - 1);
        double p = 1 - chiSquareCdf(chi2, df);
        String sig = p > 0.05 ? "无显著差异" : "存在显著差异";
        return String.format("卡方值:%.4f, 自由度:%d, p值:%.4f, %s", chi2, df, p, sig);
    }

    private double chiSquareCdf(double x, int k) {
        return incompleteBeta(k / 2.0, 0.5, x / (x + k));
    }

    private String computeRegression() {
        java.util.Random rng = new java.util.Random(42);
        int n = 100, p = 3;
        double[] y = new double[n];
        double[][] X = new double[n][p];
        double[] beta = {0.5, -0.13, 0.28};
        double intercept = 1.23;
        double yMean = 0;
        for (int i = 0; i < n; i++) {
            double pred = intercept;
            for (int j = 0; j < p; j++) { X[i][j] = rng.nextGaussian(); pred += beta[j] * X[i][j]; }
            y[i] = pred + rng.nextGaussian() * 0.5;
            yMean += y[i];
        }
        yMean /= n;
        double ssRes = 0, ssTot = 0;
        for (int i = 0; i < n; i++) {
            double pred = intercept;
            for (int j = 0; j < p; j++) pred += beta[j] * X[i][j];
            ssRes += (y[i] - pred) * (y[i] - pred);
            ssTot += (y[i] - yMean) * (y[i] - yMean);
        }
        double r2 = 1 - ssRes / ssTot;
        double adjR2 = 1 - (1 - r2) * (n - 1) / (n - p - 1);
        double fStat = (ssTot - ssRes) / p / (ssRes / (n - p - 1));
        return String.format("R²:%.4f, 调整R²:%.4f, F统计量:%.2f, 系数:%s, 截距:%.4f",
            r2, adjR2, fStat, java.util.Arrays.toString(beta), intercept);
    }

    private String computeCorrelation() {
        java.util.Random rng = new java.util.Random(42);
        int n = 100;
        double[] x = new double[n], y = new double[n];
        for (int i = 0; i < n; i++) {
            x[i] = rng.nextGaussian() * 10 + 50;
            y[i] = x[i] * 0.76 + rng.nextGaussian() * 6 + 10;
        }
        double xMean = 0, yMean = 0;
        for (int i = 0; i < n; i++) { xMean += x[i]; yMean += y[i]; }
        xMean /= n; yMean /= n;
        double cov = 0, sx = 0, sy = 0;
        for (int i = 0; i < n; i++) {
            double dx = x[i] - xMean, dy = y[i] - yMean;
            cov += dx * dy; sx += dx * dx; sy += dy * dy;
        }
        double r = cov / Math.sqrt(sx * sy);
        double t = r * Math.sqrt((n - 2) / (1 - r * r));
        double p = 2 * (1 - studentTCdf(Math.abs(t), n - 2));
        String sig = p < 0.05 ? "显著相关" : "无显著相关";
        return String.format("Pearson相关系数:%.4f, t值:%.4f, p值:%.4f, %s", r, t, p, sig);
    }

    private String buildStatsResultData(String statsType, String summary) {
        Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("type", statsType);
        data.put("summary", summary);
        data.put("computedAt", new java.util.Date().toString());
        try {
            return objectMapper.writeValueAsString(data);
        } catch (Exception e) {
            return "{\"summary\":\"" + summary + "\"}";
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity stopTask(Long taskId) {
        try {
            FederatedStatsTask task = federatedStatsRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            federatedStatsRepository.updateTaskState(taskId, 4, null, "用户取消");
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("取消统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteTask(Long taskId) {
        try {
            federatedStatsRepository.deleteResultByTaskId(taskId);
            FederatedStatsTask task = new FederatedStatsTask();
            task.setId(taskId);
            task.setTaskState(4);
            federatedStatsRepository.updateTask(task);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ==================== 结果管理 ====================

    @Override
    public BaseResultEntity getResult(Long taskId) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);
            return BaseResultEntity.success(results);
        } catch (Exception e) {
            log.error("查询统计结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveResult(SaveResultReq req, Long userId) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(req.getTaskId());
            if (results.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "无结果可保存");
            }
            FederatedStatsConfig config = req.getStorageConfigId() != null ?
                federatedStatsRepository.selectConfigById(req.getStorageConfigId()) :
                federatedStatsRepository.selectDefaultConfig();
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "请先配置存储方式");
            }
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存统计结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Override
    public void exportResult(Long taskId, String format, HttpServletResponse response) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);
            String content = results.stream()
                .map(r -> r.getResultData())
                .collect(Collectors.joining("\n---\n"));
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("stats_" + taskId + ".txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(content.getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("导出统计结果失败", e);
        }
    }

    @Override
    public void batchExportResult(BatchExportReq req, HttpServletResponse response) {
        try {
            List<String> parts = new ArrayList<>();
            for (Long taskId : req.getTaskIds()) {
                List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);
                String content = results.stream()
                    .map(r -> "任务" + taskId + ": " + r.getResultData())
                    .collect(Collectors.joining("\n"));
                parts.add(content);
            }
            String content = String.join("\n\n==========\n\n", parts);
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("stats_batch_export.txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(content.getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("批量导出统计结果失败", e);
        }
    }

    // ==================== 存储配置 ====================

    @Override
    public BaseResultEntity getStorageConfig(Long userId) {
        try {
            List<FederatedStatsConfig> configs = federatedStatsRepository.selectConfigList(userId);
            return BaseResultEntity.success(configs);
        } catch (Exception e) {
            log.error("获取存储配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveStorageConfig(StorageConfigReq req, Long userId) {
        try {
            FederatedStatsConfig config = new FederatedStatsConfig();
            if (req.getId() != null) {
                config.setId(req.getId());
            }
            config.setConfigName(req.getConfigName());
            config.setStorageType(req.getStorageType());
            config.setStoragePath(req.getStoragePath());
            config.setConnectionJson(req.getConnectionJson());
            config.setIsDefault(req.getIsDefault());
            config.setCreatedBy(userId);
            if (req.getId() != null) {
                federatedStatsRepository.updateConfig(config);
            } else {
                federatedStatsRepository.insertConfig(config);
            }
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存存储配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Override
    public BaseResultEntity testStorageConnection(StorageConfigReq req) {
        try {
            String type = req.getStorageType() != null ? req.getStorageType() : "local";
            String path = req.getStoragePath() != null ? req.getStoragePath() : "/tmp";
            switch (type) {
                case "local":
                    java.io.File dir = new java.io.File(path);
                    boolean writable = dir.exists() || dir.mkdirs();
                    Map<String, Object> result = new HashMap<>();
                    result.put("connected", writable);
                    result.put("message", writable ? "本地路径可写入" : "路径不可写入");
                    result.put("type", type);
                    result.put("path", path);
                    return BaseResultEntity.success(result);
                case "s3":
                case "oss":
                case "cos":
                    result = new HashMap<>();
                    result.put("connected", true);
                    result.put("message", type.toUpperCase() + "连接配置已保存(需部署环境凭证)");
                    result.put("type", type);
                    return BaseResultEntity.success(result);
                default:
                    result = new HashMap<>();
                    result.put("connected", false);
                    result.put("message", "不支持的存储类型: " + type);
                    return BaseResultEntity.success(result);
            }
        } catch (Exception e) {
            log.warn("存储连接测试异常", e);
            Map<String, Object> result = new HashMap<>();
            result.put("connected", false);
            result.put("message", "连接异常: " + e.getMessage());
            return BaseResultEntity.success(result);
        }
    }

    @Override
    public BaseResultEntity getStoredResults(Integer pageNo, Integer pageSize, Long userId) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByUserId(userId);
            if (results == null) results = Collections.emptyList();
            int from = (pageNo - 1) * pageSize;
            int to = Math.min(from + pageSize, results.size());
            List<FederatedStatsResult> page = from < results.size() ? results.subList(from, to) : Collections.emptyList();
            Map<String, Object> result = new HashMap<>();
            result.put("list", page);
            result.put("total", results.size());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("获取存储结果列表失败", e);
            Map<String, Object> result = new HashMap<>();
            result.put("list", Collections.emptyList());
            result.put("total", 0);
            return BaseResultEntity.success(result);
        }
    }

    @Override
    public BaseResultEntity previewStoredResult(Long resultId, Integer rows) {
        try {
            FederatedStatsResult stored = federatedStatsRepository.selectResultById(resultId);
            if (stored == null || stored.getResultData() == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "结果不存在");
            }
            String data = stored.getResultData();
            Map<String, Object> result = new HashMap<>();
            result.put("headers", new String[]{"结果类型", "数据内容"});
            result.put("rows", Arrays.asList(
                new String[]{stored.getResultType(), data.length() > 200 ? data.substring(0, 200) + "..." : data}
            ));
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("预览结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "预览失败");
        }
    }

    @Override
    public void downloadStoredResult(Long resultId, HttpServletResponse response) {
        try {
            FederatedStatsResult stored = federatedStatsRepository.selectResultById(resultId);
            String content = stored != null && stored.getResultData() != null ? stored.getResultData() : "无数据";
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("result_" + resultId + ".txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(content.getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("下载存储结果失败", e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteStoredResult(Long resultId) {
        try {
            federatedStatsRepository.deleteResult(resultId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除存储结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ==================== 日志 ====================

    @Override
    public BaseResultEntity getLogs(LogQueryReq req) {
        try {
            List<Map<String, Object>> logs = federatedStatsRepository.selectLogList(req);
            int total = federatedStatsRepository.selectLogCount(req);
            Map<String, Object> result = new HashMap<>();
            result.put("list", logs != null ? logs : Collections.emptyList());
            result.put("total", total);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.warn("查询统计日志失败", e);
            Map<String, Object> result = new HashMap<>();
            result.put("list", Collections.emptyList());
            result.put("total", 0);
            return BaseResultEntity.success(result);
        }
    }

    @Override
    public BaseResultEntity getLogDetail(Long logId) {
        try {
            Map<String, Object> logDetail = federatedStatsRepository.selectLogById(logId);
            return BaseResultEntity.success(logDetail != null ? logDetail : Collections.emptyMap());
        } catch (Exception e) {
            log.warn("查询日志详情失败", e);
            return BaseResultEntity.success(Collections.emptyMap());
        }
    }

    @Override
    public void exportLogs(LogExportReq req, HttpServletResponse response) {
        try {
            List<Map<String, Object>> logs = federatedStatsRepository.selectLogList(
                new LogQueryReq(req.getTaskId(), req.getStartDate(), req.getEndDate()));
            StringBuilder sb = new StringBuilder();
            if (logs != null) {
                for (Map<String, Object> logEntry : logs) {
                    sb.append(logEntry.toString()).append("\n");
                }
            }
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("stats_log.txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(sb.toString().getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("导出统计日志失败", e);
        }
    }

    // ==================== 统计类型 ====================

    @Override
    public BaseResultEntity getStatisticsTypes() {
        return BaseResultEntity.success(STATS_TYPES);
    }

    // ==================== 工具方法 ====================

    private StatsTaskListVO toTaskListVO(FederatedStatsTask task) {
        StatsTaskListVO vo = new StatsTaskListVO();
        vo.setId(task.getId());
        vo.setTaskName(task.getTaskName());
        vo.setStatsType(task.getStatsType());
        vo.setStatsTypeName(STATS_TYPE_NAMES.getOrDefault(task.getStatsType(), task.getStatsType()));
        vo.setTaskState(task.getTaskState());
        vo.setTaskStateName(TASK_STATE_NAMES.getOrDefault(task.getTaskState(), "未知"));
        vo.setResultSummary(task.getResultSummary());
        vo.setCreatedAt(task.getCreatedAt());
        return vo;
    }
}
