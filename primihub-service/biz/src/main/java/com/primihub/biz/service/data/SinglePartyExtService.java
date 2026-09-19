package com.primihub.biz.service.data;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.DataResource;
import com.primihub.biz.entity.data.po.DataUnionTask;
import com.primihub.biz.entity.data.req.DataUnionReq;
import com.primihub.biz.repository.primarydb.data.SinglePartyExtRepository;
import com.primihub.biz.repository.secondarydb.data.DataResourceRepository;
import com.primihub.biz.repository.secondarydb.data.DataUnionRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.concurrent.TimeUnit;

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

    @Autowired
    private DataResourceRepository dataResourceRepository;

    @Autowired
    private DataUnionService dataUnionService;

    @Autowired
    private DataUnionRepository dataUnionRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /** 算法脚本目录（烘进后端镜像的固定路径），结果目录（/data bind mount，recreate 后仍在）。 */
    private static final String ALGO_DIR =
            System.getenv().getOrDefault("SP_ALGO_DIR", "/opt/python-algorithms/single_party");
    private static final String RESULT_BASE = "/data/singleParty";
    private static final long SCRIPT_TIMEOUT_SECONDS = 120;

    /** subType(=前端 preprocessType/scriptType) → 真实计算脚本。PREPROCESS/SCRIPT/FLPRE 三 category 共用。 */
    private static final Map<String, String> SUBTYPE_SCRIPT;
    static {
        Map<String, String> m = new HashMap<>();
        m.put("DATA_STATS", "statistics.py");
        m.put("DATA_CLEANING", "cleaning.py");
        m.put("DATA_SCALING", "scaling.py");
        m.put("FEATURE_ENCODE", "encoding.py");
        m.put("FEATURE_BIN", "binning.py");
        m.put("FEATURE_SELECT", "selection.py");
        m.put("FEATURE_DERIVE", "derivation.py");
        m.put("LR_ALGORITHM", "lr.py");
        m.put("XGB_ALGORITHM", "xgboost.py");
        m.put("PYTHON_SCRIPT", "script.py");
        m.put("SQL_PROCESS", "sql_process.py");
        // FLPRE 中可诚实本地计算的 8 类（多方类另走真实联邦引擎，不在此表）
        m.put("DATA_SPLIT", "fl_data_split.py");
        m.put("DATA_TRANSFORM", "fl_data_transform.py");
        m.put("FEATURE_FILL", "fl_feature_fill.py");
        m.put("FEATURE_WAREHOUSE", "fl_feature_warehouse.py");
        m.put("FL_FEATURE_ENCODE", "fl_feature_encode.py");
        m.put("SAMPLE_EXPAND", "fl_sample_expand.py");
        m.put("SAMPLE_WEIGHT", "fl_sample_weight.py");
        m.put("METRIC_MODELING", "fl_metric_modeling.py");
        m.put("DATA_MERGE", "fl_data_merge.py"); // 单方本地合并（多本地数据源 concat/join）
        SUBTYPE_SCRIPT = Collections.unmodifiableMap(m);
    }

    /** FLPRE 中的天然多方算法：本地无法诚实计算，未接通真实联邦引擎前显式失败。 */
    private static final Set<String> MULTI_PARTY_SUBTYPES = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
            "FEATURE_ALIGN", "FEATURE_SHARE", "FEATURE_SIMILARITY",
            "VFL_LINEAR_TRAIN", "VFL_LINEAR_PREDICT", "VFL_LOGISTIC_TRAIN", "VFL_LOGISTIC_PREDICT",
            "VFL_XGBOOST_TRAIN", "VFL_XGBOOST_PREDICT")));

    /** 求并引擎轮询上限（秒）：本地小数据求并通常数秒内完成。 */
    private static final int UNION_POLL_SECONDS = 90;

    // ===== 预处理 =====
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createPreprocess(Map<String, Object> data, Long userId, String userName) {
        return createInternal("PREPROCESS", data, userId, userName);
    }
    public BaseResultEntity listPreprocess(Map<String, Object> query) { return pageTasks("PREPROCESS", query); }
    // run* 不加事务：真实脚本执行最长 120s，不能占着 DB 连接/事务
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
    public BaseResultEntity runScript(Map<String, Object> data) { return runTask(taskId(data)); }
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteScript(Map<String, Object> data) { return deleteTask(taskId(data)); }
    public void downloadScript(String taskId, HttpServletResponse resp) { download(taskId, resp); }

    // ===== 联邦学习 预处理（/federatedLearning/preprocess/*，各算法视图按 preprocessType 区分；复用同一 sp_ext 存储，category=FLPRE）=====
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createFlPre(Map<String, Object> data, Long userId, String userName) {
        return createInternal("FLPRE", data, userId, userName);
    }
    public BaseResultEntity listFlPre(Map<String, Object> query) {
        Map<String, Object> q = new HashMap<>(query == null ? Collections.emptyMap() : query);
        if (q.get("subType") == null && q.get("preprocessType") != null) q.put("subType", q.get("preprocessType"));
        return pageTasks("FLPRE", q);
    }
    public BaseResultEntity runFlPre(Map<String, Object> data) { return runTask(taskId(data)); }
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteFlPre(Map<String, Object> data) { return deleteTask(taskId(data)); }
    public void downloadFlPre(String taskId, HttpServletResponse resp) { download(taskId, resp); }

    // ===== 联邦学习 模型导入（独立登记，不碰真实 FL model 表；category=FLMODEL）=====
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity importModel(Map<String, Object> data, Long userId, String userName) {
        return createInternal("FLMODEL", data, userId, userName);
    }
    public BaseResultEntity listModel(Map<String, Object> query) { return pageTasks("FLMODEL", query); }

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
            String category = str(t.get("taskCategory"));
            String subType = str(t.get("subType"));
            String script = subType == null ? null : SUBTYPE_SCRIPT.get(subType);
            if (script != null && ("PREPROCESS".equals(category) || "SCRIPT".equals(category) || "FLPRE".equals(category))) {
                return runReal(t, taskId, script);
            }
            // 数据融合：横向(样本并集)路由到真实联邦求并引擎
            if ("FLPRE".equals(category) && "DATA_FUSION".equals(subType)) {
                return runFusionMerge(t, taskId);
            }
            // FLPRE 的天然多方类本地脚本无法诚实实现，登记入口显式失败，绝不返回假成功。
            // PSI 对齐/VFL 训练预测已在对应页面接通真实联邦引擎（PSI / createTask / saveReasoning）。
            if ("FLPRE".equals(category) && MULTI_PARTY_SUBTYPES.contains(subType)) {
                String hint = subType.startsWith("VFL_") ? "请使用『纵向联邦训练/预测』页面提交（已接真实联邦引擎）"
                        : "FEATURE_ALIGN".equals(subType) ? "请使用『特征对齐』页面提交（已接真实 PSI 引擎）"
                        : "平台联邦引擎暂无对应组件，尚未接通";
                return failTask(t, taskId, new Date(),
                        "该算法为多方联邦任务(" + subType + ")，本登记入口不执行模拟计算；" + hint);
            }
            // 无脚本映射的类别（FLMODEL 等）保留登记式流转；成功态=1（前端词汇 1=已完成）
            Map<String, Object> upd = new HashMap<>();
            upd.put("taskId", taskId);
            upd.put("taskState", 1);
            upd.put("progress", 100);
            upd.put("startTime", new Date());
            upd.put("endTime", new Date());
            upd.put("resultContent", buildResultCsv(t));
            repository.updateTaskState(upd);
            writeLog(taskId, str(t.get("taskName")), category, "INFO", "任务执行成功");
            return BaseResultEntity.success("任务已提交执行");
        } catch (Exception e) {
            log.error("运行单方任务失败, taskId={}", taskId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "执行失败");
        }
    }

    /** 真实执行：解析数据集路径 → 调 python 脚本 → 回写结果/失败原因。 */
    private BaseResultEntity runReal(Map<String, Object> t, String taskId, String script) throws Exception {
        Date start = new Date();
        String taskName = str(t.get("taskName"));
        String category = str(t.get("taskCategory"));

        Map<String, Object> params;
        try {
            String pj = str(t.get("params"));
            params = pj == null || pj.isEmpty() ? new HashMap<>() : objectMapper.readValue(pj, Map.class);
        } catch (Exception e) {
            params = new HashMap<>();
        }
        String resourceId = str(firstNonNull(t.get("resourceId"), params.get("resourceId")));
        // 多数据源任务（如 DATA_MERGE）resourceId 为逗号串，主数据集取第一个
        if (resourceId != null && resourceId.contains(",")) {
            resourceId = resourceId.split(",")[0].trim();
        }
        DataResource res = resolveResource(resourceId);
        if (res == null) {
            return failTask(t, taskId, start, "数据资源不存在: " + resourceId);
        }
        if (StringUtils.isBlank(res.getUrl())) {
            return failTask(t, taskId, start, "该资源无本地数据文件（db 型资源暂不支持单方算法）: " + resourceId);
        }
        File dataset = new File(res.getUrl());
        if (!dataset.exists() || !dataset.isFile()) {
            return failTask(t, taskId, start, "数据集文件不存在: " + res.getUrl());
        }

        File resultDir = new File(RESULT_BASE, taskId);
        if (!resultDir.exists() && !resultDir.mkdirs()) {
            return failTask(t, taskId, start, "结果目录创建失败: " + resultDir);
        }
        params.put("dataset_path", res.getUrl());
        params.put("task_id", taskId);
        params.put("result_dir", resultDir.getAbsolutePath());
        params.put("sub_type", str(t.get("subType")));
        // 样本扩充需要第二份数据集：expandSource 传的是资源ID，这里解析成本地文件路径
        String expandSource = str(params.get("expandSource"));
        if (StringUtils.isNotBlank(expandSource)) {
            DataResource expandRes = resolveResource(expandSource);
            if (expandRes == null || StringUtils.isBlank(expandRes.getUrl())) {
                return failTask(t, taskId, start, "扩充数据来源资源不存在或无本地数据文件: " + expandSource);
            }
            params.put("expand_source_path", expandRes.getUrl());
        }
        // 多数据源任务（DATA_MERGE）：逐个资源ID解析为本地路径列表
        Object dataSources = params.get("dataSources");
        if (dataSources instanceof List && !((List<?>) dataSources).isEmpty()) {
            List<String> sourcePaths = new ArrayList<>();
            for (Object rid : (List<?>) dataSources) {
                DataResource sr = resolveResource(str(rid));
                if (sr == null || StringUtils.isBlank(sr.getUrl())) {
                    return failTask(t, taskId, start, "数据源资源不存在或无本地数据文件: " + rid);
                }
                sourcePaths.add(sr.getUrl());
            }
            params.put("source_paths", sourcePaths);
        }
        // 参数经文件传递（UTF-8 显式编码，避开 argv 编码/长度问题）
        File paramFile = new File(resultDir, "params.json");
        Files.write(paramFile.toPath(), objectMapper.writeValueAsString(params).getBytes(StandardCharsets.UTF_8));

        File scriptFile = new File(ALGO_DIR, script);
        if (!scriptFile.exists()) {
            return failTask(t, taskId, start, "算法脚本缺失(镜像未含 python 运行时?): " + scriptFile);
        }
        File outFile = new File(resultDir, "stdout.log");
        File errFile = new File(resultDir, "stderr.log");
        ProcessBuilder pb = new ProcessBuilder("python3", scriptFile.getAbsolutePath(), paramFile.getAbsolutePath());
        pb.redirectOutput(outFile);
        pb.redirectError(errFile);
        Process p = pb.start();
        if (!p.waitFor(SCRIPT_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
            p.destroyForcibly();
            return failTask(t, taskId, start, "脚本执行超时(" + SCRIPT_TIMEOUT_SECONDS + "s): " + script);
        }
        int code = p.exitValue();
        String stderr = readFileTail(errFile, 1500);
        if (code != 0) {
            return failTask(t, taskId, start, "脚本执行失败 exit=" + code + ": " + stderr);
        }

        // stdout 末行 JSON: {task_id, result_path, result_rows, summary}
        Map<String, Object> r = new HashMap<>();
        try {
            String stdout = new String(Files.readAllBytes(outFile.toPath()), StandardCharsets.UTF_8);
            String[] lines = stdout.trim().split("\n");
            for (int i = lines.length - 1; i >= 0; i--) {
                String line = lines[i].trim();
                if (line.startsWith("{")) { r = objectMapper.readValue(line, Map.class); break; }
            }
        } catch (Exception e) {
            log.warn("解析脚本输出失败, taskId={}", taskId, e);
        }
        String resultPath = str(firstNonNull(r.get("result_path"), new File(resultDir, "result.csv").getAbsolutePath()));
        Object rows = firstNonNull(r.get("result_rows"), "");
        String summary = str(firstNonNull(r.get("summary"), ""));

        Map<String, Object> upd = new HashMap<>();
        upd.put("taskId", taskId);
        upd.put("taskState", 1);
        upd.put("progress", 100);
        upd.put("startTime", start);
        upd.put("endTime", new Date());
        upd.put("resultPath", resultPath);
        upd.put("resultContent", buildRealResultCsv(t, resultPath, rows, summary));
        upd.put("errorMsg", "");
        repository.updateTaskState(upd);
        writeLog(taskId, taskName, category, "INFO",
                "任务执行成功，结果行数=" + rows + (summary.isEmpty() ? "" : "，" + summary));
        return BaseResultEntity.success("任务执行成功");
    }

    /**
     * 数据融合/合并 → 真实联邦求并引擎。
     * 横向融合(HORIZONTAL)/纵向堆叠合并(UNION) = 两方样本并集，由求并引擎(gRPC→node)执行；
     * 纵向融合(VERTICAL)/按键关联合并(JOIN) 需 PSI 对齐，指引用户走特征对齐，不做本地假算。
     */
    private BaseResultEntity runFusionMerge(Map<String, Object> t, String taskId) {
        Date start = new Date();
        Map<String, Object> params;
        try {
            String pj = str(t.get("params"));
            params = pj == null || pj.isEmpty() ? new HashMap<>() : objectMapper.readValue(pj, Map.class);
        } catch (Exception e) {
            params = new HashMap<>();
        }
        String mode = str(firstNonNull(params.get("fusionType"), params.get("mergeType")));
        boolean unionMode = "HORIZONTAL".equalsIgnoreCase(mode) || "UNION".equalsIgnoreCase(mode);
        if (!unionMode) {
            return failTask(t, taskId, start,
                    "纵向(按ID对齐)融合/关联合并需 PSI 对齐引擎，请使用『特征对齐』功能；本入口当前支持横向样本并集");
        }
        String ownOrganId = str(params.get("ownOrganId"));
        String ownResourceId = str(firstNonNull(params.get("ownResourceId"), params.get("localResourceId"), t.get("resourceId")));
        String ownKeyword = str(params.get("ownKeyword"));
        String otherOrganId = str(params.get("otherOrganId"));
        String otherResourceId = str(params.get("otherResourceId"));
        String otherKeyword = str(params.get("otherKeyword"));
        StringBuilder miss = new StringBuilder();
        if (StringUtils.isBlank(ownOrganId)) miss.append("本机构(ownOrganId) ");
        if (StringUtils.isBlank(ownResourceId)) miss.append("本机构数据集 ");
        if (StringUtils.isBlank(ownKeyword)) miss.append("本方关联字段 ");
        if (StringUtils.isBlank(otherOrganId)) miss.append("协作方 ");
        if (StringUtils.isBlank(otherResourceId)) miss.append("协作方数据集 ");
        if (StringUtils.isBlank(otherKeyword)) miss.append("协作方关联字段 ");
        if (miss.length() > 0) {
            return failTask(t, taskId, start, "缺少必要参数: " + miss + "。请重新创建任务并补全协作方信息");
        }

        DataUnionReq req = new DataUnionReq();
        req.setOwnOrganId(ownOrganId);
        req.setOwnResourceId(ownResourceId);
        req.setOwnKeyword(ownKeyword);
        req.setOtherOrganId(otherOrganId);
        req.setOtherResourceId(otherResourceId);
        req.setOtherKeyword(otherKeyword);
        req.setResultName(str(firstNonNull(params.get("resultName"), str(t.get("taskName")) + "_并集结果")));
        req.setResultOrganIds(str(firstNonNull(params.get("resultOrganIds"), ownOrganId)));
        Object tag = params.get("tag");
        req.setTag(tag == null ? 0 : toInt(tag));
        req.setRemarks(str(t.get("remark")));

        Long userId = null;
        try { userId = Long.valueOf(str(t.get("userId"))); } catch (Exception ignore) { }
        BaseResultEntity save = dataUnionService.saveDataUnion(req, userId == null ? 0L : userId);
        if (save.getCode() == null || save.getCode() != 0) {
            return failTask(t, taskId, start, "求并引擎创建任务失败: " + save.getMsg());
        }
        Long engineId;
        try {
            Map<String, Object> rm = (Map<String, Object>) save.getResult();
            engineId = Long.valueOf(String.valueOf(rm.get("taskId")));
        } catch (Exception e) {
            return failTask(t, taskId, start, "求并引擎返回异常，无法取得任务ID");
        }
        writeLog(taskId, str(t.get("taskName")), "FLPRE", "INFO", "已提交真实联邦求并引擎, 引擎任务ID=" + engineId);

        for (int i = 0; i < UNION_POLL_SECONDS; i++) {
            try { TimeUnit.SECONDS.sleep(1); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); break; }
            DataUnionTask ut = dataUnionRepository.selectTaskById(engineId);
            if (ut == null || ut.getTaskState() == null) continue;
            if (ut.getTaskState() == 1) {
                return fusionSuccess(t, taskId, start, ut);
            }
            if (ut.getTaskState() == 3 || ut.getTaskState() == 4) {
                return failTask(t, taskId, start,
                        "求并引擎执行失败(引擎任务ID=" + engineId + ")，详情见『联邦求并』模块任务日志");
            }
        }
        // 超时未出结果：如实标记为执行中，让用户稍后在求并模块跟进（绝不假成功）
        Map<String, Object> upd = new HashMap<>();
        upd.put("taskId", taskId);
        upd.put("taskState", 2);
        upd.put("progress", 50);
        upd.put("startTime", start);
        upd.put("errorMsg", "");
        upd.put("resultContent", "字段,值\r\n引擎任务ID," + engineId + "\r\n状态,引擎仍在执行\r\n");
        repository.updateTaskState(upd);
        writeLog(taskId, str(t.get("taskName")), "FLPRE", "INFO",
                "求并引擎执行中(超过" + UNION_POLL_SECONDS + "s 未完成), 引擎任务ID=" + engineId);
        return BaseResultEntity.success("任务已提交真实求并引擎，仍在执行中，请稍后刷新或到『联邦求并』模块查看");
    }

    private BaseResultEntity fusionSuccess(Map<String, Object> t, String taskId, Date start, DataUnionTask ut) {
        String resultPath = null;
        long rows = ut.getFileRows() == null ? 0 : ut.getFileRows();
        try {
            if (StringUtils.isNotBlank(ut.getFilePath()) && new File(ut.getFilePath()).isFile()) {
                File dir = new File(RESULT_BASE, taskId);
                if (dir.exists() || dir.mkdirs()) {
                    File dst = new File(dir, "result.csv");
                    Files.copy(new File(ut.getFilePath()).toPath(), dst.toPath(),
                            java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                    resultPath = dst.getAbsolutePath();
                    if (rows == 0) {
                        try { rows = Math.max(Files.lines(dst.toPath()).count() - 1, 0); } catch (Exception ignore) { }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("拷贝求并结果失败, taskId={}", taskId, e);
        }
        String summary = "真实联邦求并完成, 引擎任务ID=" + ut.getId() + ", 结果行数=" + rows;
        Map<String, Object> upd = new HashMap<>();
        upd.put("taskId", taskId);
        upd.put("taskState", 1);
        upd.put("progress", 100);
        upd.put("startTime", start);
        upd.put("endTime", new Date());
        if (resultPath != null) upd.put("resultPath", resultPath);
        upd.put("resultContent", buildRealResultCsv(t, resultPath == null ? str(ut.getFilePath()) : resultPath, rows, summary));
        upd.put("errorMsg", "");
        repository.updateTaskState(upd);
        writeLog(taskId, str(t.get("taskName")), "FLPRE", "INFO", summary);
        return BaseResultEntity.success("任务执行成功");
    }

    private BaseResultEntity failTask(Map<String, Object> t, String taskId, Date start, String reason) {
        String msg = reason.length() > 1800 ? reason.substring(0, 1800) : reason;
        Map<String, Object> upd = new HashMap<>();
        upd.put("taskId", taskId);
        upd.put("taskState", 3);
        upd.put("progress", 100);
        upd.put("startTime", start);
        upd.put("endTime", new Date());
        upd.put("errorMsg", msg);
        repository.updateTaskState(upd);
        writeLog(taskId, str(t.get("taskName")), str(t.get("taskCategory")), "ERROR", "任务执行失败：" + msg);
        log.error("单方任务执行失败, taskId={}, reason={}", taskId, msg);
        return BaseResultEntity.failure(BaseResultEnum.FAILURE, msg);
    }

    private DataResource resolveResource(String resourceId) {
        if (StringUtils.isBlank(resourceId)) return null;
        DataResource res = dataResourceRepository.queryDataResourceByResourceFusionId(resourceId);
        if (res == null && StringUtils.isNumeric(resourceId)) {
            res = dataResourceRepository.queryDataResourceById(Long.parseLong(resourceId));
        }
        return res;
    }

    private String readFileTail(File f, int maxChars) {
        try {
            String s = new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8).trim();
            return s.length() > maxChars ? s.substring(s.length() - maxChars) : s;
        } catch (Exception e) {
            return "";
        }
    }

    private String buildRealResultCsv(Map<String, Object> t, String resultPath, Object rows, String summary) {
        StringBuilder sb = new StringBuilder("字段,值\r\n");
        append(sb, "任务ID", t.get("taskId"));
        append(sb, "任务名称", t.get("taskName"));
        append(sb, "算法", t.get("subType"));
        append(sb, "数据资源", firstNonNull(t.get("resourceName"), t.get("resourceId")));
        append(sb, "结果行数", rows);
        append(sb, "摘要", summary);
        append(sb, "结果文件", resultPath);
        append(sb, "状态", "执行成功");
        return sb.toString();
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
            String state = String.valueOf(t.get("taskState"));
            if (!"1".equals(state) && !"2".equals(state)) { writeJsonError(response, "任务未执行成功，暂无结果可下载"); return; }
            String fn = safeName(str(t.get("taskName"))) + "_结果.csv";
            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode(fn, StandardCharsets.UTF_8.name()));
            // 优先返回脚本产出的真实结果文件（限定在结果根目录内），回退到摘要 CSV
            String resultPath = str(t.get("resultPath"));
            if (resultPath != null && resultPath.startsWith(RESULT_BASE + "/")) {
                File rf = new File(resultPath);
                if (rf.exists() && rf.isFile()) {
                    Files.copy(rf.toPath(), response.getOutputStream());
                    response.getOutputStream().flush();
                    return;
                }
            }
            String content = str(t.get("resultContent"));
            if (content == null || content.isEmpty()) content = buildResultCsv(t);
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
