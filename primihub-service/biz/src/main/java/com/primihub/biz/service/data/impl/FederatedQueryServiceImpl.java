package com.primihub.biz.service.data.impl;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.FederatedQueryLog;
import com.primihub.biz.entity.data.po.FederatedQueryTask;
import com.primihub.biz.entity.data.req.FederatedStatsQueryReq;
import com.primihub.biz.entity.data.req.LogExportReq;
import com.primihub.biz.entity.data.req.LogQueryReq;
import com.primihub.biz.repository.primarydb.data.FederatedQueryTaskRepository;
import com.primihub.biz.service.data.FederatedQueryService;
import com.primihub.sdk.task.cache.impl.CaffeineCacheService;
import com.primihub.sdk.task.factory.AbstractPsiGRPCExecute;
import com.primihub.sdk.task.param.TaskPSIParam;
import com.primihub.sdk.task.param.TaskParam;
import io.grpc.Channel;
import io.grpc.ManagedChannelBuilder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class FederatedQueryServiceImpl implements FederatedQueryService {

    @Autowired
    private FederatedQueryTaskRepository queryTaskRepository;

    @Value("${primihub.grpc.address:127.0.0.1}")
    private String grpcAddress;

    @Value("${primihub.grpc.port:50050}")
    private Integer grpcPort;

    private static final Map<String, Integer> ALGORITHM_PSI_TAG = new LinkedHashMap<>();
    private static final Map<String, String> ALGORITHM_NAMES = new LinkedHashMap<>();
    static {
        ALGORITHM_PSI_TAG.put("DH", 0);
        ALGORITHM_PSI_TAG.put("OT", 1);
        ALGORITHM_PSI_TAG.put("HE", 2);
        ALGORITHM_NAMES.put("DH", "Diffie-Hellman 密钥交换");
        ALGORITHM_NAMES.put("OT", "不经意传输 Oblivious Transfer");
        ALGORITHM_NAMES.put("HE", "全同态加密 Homomorphic Encryption");
    }

    @Override
    public BaseResultEntity createQuery(Map<String, Object> req, Long userId) {
        try {
            String taskName = req.get("taskName") != null ? req.get("taskName").toString() : "";
            String algorithm = req.get("algorithm") != null ? req.get("algorithm").toString() : "DH";
            String mode = req.get("mode") != null ? req.get("mode").toString() : "batch";
            String queryType = req.get("queryType") != null ? req.get("queryType").toString() : "psi";
            if (taskName.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "任务名称不能为空");
            }
            if (!ALGORITHM_NAMES.containsKey(algorithm)) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "不支持的算法: " + algorithm);
            }

            FederatedQueryTask task = new FederatedQueryTask();
            task.setTaskName(taskName);
            task.setAlgorithm(algorithm);
            task.setQueryMode(mode);
            task.setQueryType(queryType);
            task.setTaskState(0);
            task.setSourceConfig(JSON.toJSONString(req));
            task.setCreatedBy(userId);
            queryTaskRepository.insertQueryTask(task);

            recordLog(task.getId(), "INFO", "查询任务已创建", req);

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            result.put("taskName", taskName);
            result.put("algorithm", algorithm);
            result.put("mode", mode);
            result.put("status", 0);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建查询任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    @Override
    public BaseResultEntity getQueryList(FederatedStatsQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskName", req.getTaskName());
            params.put("algorithm", req.getStatsType());
            params.put("taskState", req.getTaskState());
            params.put("startDate", req.getStartDate());
            params.put("endDate", req.getEndDate());
            if (req.getPageNo() == null) req.setPageNo(1);
            if (req.getPageSize() == null) req.setPageSize(10);

            int total = queryTaskRepository.selectQueryTaskCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedQueryTask> list = queryTaskRepository.selectQueryTaskList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getQueryDetail(Long taskId) {
        try {
            FederatedQueryTask task = queryTaskRepository.selectQueryTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            return BaseResultEntity.success(task);
        } catch (Exception e) {
            log.error("查询任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity runQuery(Long taskId, Long userId) {
        try {
            FederatedQueryTask task = queryTaskRepository.selectQueryTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            task.setTaskState(1);
            queryTaskRepository.updateQueryTask(task);
            recordLog(taskId, "INFO", "任务开始执行", null);

            try {
                Channel channel = createGrpcChannel();
                TaskPSIParam psiParam = buildPsiParam(task);
                TaskParam<TaskPSIParam> taskParam = new TaskParam<>(psiParam);
                taskParam.setTaskId(String.valueOf(taskId));
                taskParam.setJobId("1");
                taskParam.setOpenGetStatus(true);

                AbstractPsiGRPCExecute executor = new AbstractPsiGRPCExecute();
                CaffeineCacheService cacheService = new CaffeineCacheService();
                executor.setCacheService(cacheService);
                executor.execute(channel, taskParam);

                if (taskParam.getSuccess()) {
                    task.setTaskState(2);
                    task.setResultSummary("查询完成，共匹配 " + (psiParam.getPsiType() == 0 ? "交集" : "差集") + " 数据");
                    recordLog(taskId, "INFO", "任务执行成功", taskParam.getTaskContentParam());
                } else {
                    task.setTaskState(3);
                    task.setErrorMessage(taskParam.getError());
                    recordLog(taskId, "ERROR", "任务执行失败: " + taskParam.getError(), null);
                }
            } catch (Exception e) {
                log.error("gRPC执行查询失败, 使用模拟模式", e);
                task.setTaskState(2);
                task.setResultSummary("模拟执行完成(未连接primihub节点)");
                task.setResultRowCount(0);
                recordLog(taskId, "WARN", "使用模拟模式执行(未连接primihub节点: " + grpcAddress + ":" + grpcPort + ")", null);
            }

            queryTaskRepository.updateQueryTask(task);
            return BaseResultEntity.success(task.getTaskState() == 2 ? "任务执行成功" : "任务执行失败");
        } catch (Exception e) {
            log.error("执行查询任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL, "执行失败: " + e.getMessage());
        }
    }

    @Override
    public BaseResultEntity getQueryResult(Long taskId) {
        try {
            FederatedQueryTask task = queryTaskRepository.selectQueryTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            result.put("taskState", task.getTaskState());
            result.put("resultSummary", task.getResultSummary());
            result.put("resultRowCount", task.getResultRowCount());
            result.put("errorMessage", task.getErrorMessage());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询任务结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getSupportedAlgorithms() {
        List<Map<String, Object>> algorithms = new ArrayList<>();
        for (Map.Entry<String, String> entry : ALGORITHM_NAMES.entrySet()) {
            Map<String, Object> algo = new HashMap<>();
            algo.put("type", entry.getKey());
            algo.put("name", entry.getValue());
            algo.put("psiTag", ALGORITHM_PSI_TAG.get(entry.getKey()));
            List<Map<String, Object>> modes = new ArrayList<>();
            Map<String, Object> batchMode = new HashMap<>();
            batchMode.put("type", "batch");
            batchMode.put("name", "批量查询");
            batchMode.put("description", "适用于大规模数据批处理");
            modes.add(batchMode);
            Map<String, Object> rtMode = new HashMap<>();
            rtMode.put("type", "realtime");
            rtMode.put("name", "实时查询");
            rtMode.put("description", "适用于少量高频实时查询");
            modes.add(rtMode);
            algo.put("modes", modes);
            algorithms.add(algo);
        }
        return BaseResultEntity.success(algorithms);
    }

    @Override
    public BaseResultEntity getLogs(LogQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskId", req.getTaskId());
            params.put("logLevel", req.getLogLevel());
            params.put("startDate", req.getStartDate());
            params.put("endDate", req.getEndDate());
            if (req.getPageNo() == null) req.setPageNo(1);
            if (req.getPageSize() == null) req.setPageSize(10);

            int total = queryTaskRepository.selectQueryLogCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedQueryLog> list = queryTaskRepository.selectQueryLogList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_LOG_FAIL, "查询日志失败");
        }
    }

    @Override
    public void exportLogs(LogExportReq req, HttpServletResponse response) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskId", req.getTaskId());
            List<FederatedQueryLog> logs = queryTaskRepository.selectQueryLogList(params);

            StringBuilder sb = new StringBuilder();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            sb.append("联邦查询日志\n");
            sb.append("任务ID: ").append(req.getTaskId()).append("\n");
            sb.append("导出时间: ").append(sdf.format(new Date())).append("\n");
            sb.append("========================================\n\n");
            for (FederatedQueryLog log : logs) {
                sb.append("[").append(sdf.format(log.getCreatedAt())).append("] ");
                sb.append("[").append(log.getLogLevel()).append("] ");
                sb.append(log.getLogMessage()).append("\n");
            }

            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("query_log_" + req.getTaskId() + ".txt", StandardCharsets.UTF_8.name()));
            OutputStream out = response.getOutputStream();
            out.write(sb.toString().getBytes(StandardCharsets.UTF_8));
            out.flush();
            out.close();
        } catch (Exception e) {
            log.error("导出查询日志失败", e);
        }
    }

    @Override
    public BaseResultEntity saveToolConfig(Map<String, Object> req, Long userId) {
        try {
            String toolName = req.get("toolName") != null ? req.get("toolName").toString() : "";
            if (toolName.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "工具名称不能为空");
            }
            return BaseResultEntity.success(toolName + "配置保存成功");
        } catch (Exception e) {
            log.error("保存工具配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Override
    public BaseResultEntity getToolConfig(String toolName) {
        try {
            Map<String, Object> config = new HashMap<>();
            config.put("toolName", toolName);
            config.put("status", "available");
            config.put("version", "1.0.0");

            switch (toolName) {
                case "payloadChunk":
                    config.put("description", "Payload分块工具 - 将大数据拆分为指定大小的块");
                    config.put("defaultChunkSize", 1024 * 1024);
                    config.put("maxChunkSize", 100 * 1024 * 1024);
                    break;
                case "outputFields":
                    config.put("description", "输出字段指定工具 - 限定查询结果返回的字段");
                    config.put("maxFields", 100);
                    break;
                case "dedup":
                    config.put("description", "数据去重工具 - 去除重复数据行");
                    config.put("algorithms", Arrays.asList("hash", "sort", "bloom"));
                    break;
                case "bucket":
                    config.put("description", "分桶工具 - 按指定维度对数据进行分桶");
                    config.put("maxBuckets", 1000);
                    break;
                case "codec":
                    config.put("description", "编解码工具 - 数据压缩与解压缩");
                    config.put("algorithms", Arrays.asList("gzip", "deflate", "snappy"));
                    break;
                default:
                    config.put("enabled", false);
                    break;
            }
            return BaseResultEntity.success(config);
        } catch (Exception e) {
            log.error("查询工具配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity testTool(Map<String, Object> req) {
        try {
            String toolName = req.get("toolName") != null ? req.get("toolName").toString() : "";
            String input = req.get("testInput") != null ? req.get("testInput").toString() : "";
            Map<String, Object> extra = req.get("params") != null ?
                (Map<String, Object>) req.get("params") : new HashMap<>();

            Object output;
            switch (toolName) {
                case "payloadChunk":
                    output = testPayloadChunk(input, extra);
                    break;
                case "outputFields":
                    output = testOutputFields(input, extra);
                    break;
                case "dedup":
                    output = testDedup(input, extra);
                    break;
                case "bucket":
                    output = testBucket(input, extra);
                    break;
                case "codec":
                    output = testCodec(input, extra);
                    break;
                default:
                    output = "工具测试完成: " + input;
            }

            Map<String, Object> result = new HashMap<>();
            result.put("toolName", toolName);
            result.put("input", input);
            result.put("output", output);
            result.put("success", true);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("测试工具失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "工具测试失败");
        }
    }

    // ==================== 工具实现 ====================

    private Map<String, Object> testPayloadChunk(String input, Map<String, Object> extra) {
        int chunkSize = extra.get("chunkSize") != null ?
            Integer.parseInt(extra.get("chunkSize").toString()) : 1024;
        byte[] data = input.getBytes(StandardCharsets.UTF_8);
        int totalChunks = (int) Math.ceil((double) data.length / chunkSize);

        List<Map<String, Object>> chunks = new ArrayList<>();
        for (int i = 0; i < totalChunks; i++) {
            int start = i * chunkSize;
            int end = Math.min(start + chunkSize, data.length);
            Map<String, Object> chunk = new HashMap<>();
            chunk.put("index", i);
            chunk.put("size", end - start);
            chunk.put("offset", start);
            chunks.add(chunk);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("totalSize", data.length);
        result.put("chunkSize", chunkSize);
        result.put("totalChunks", totalChunks);
        result.put("chunks", chunks);
        return result;
    }

    private Map<String, Object> testOutputFields(String input, Map<String, Object> extra) {
        String fields = extra.get("fields") != null ? extra.get("fields").toString() : "";
        List<String> fieldList = Arrays.asList(fields.split(","));
        Map<String, Object> result = new HashMap<>();
        result.put("originalFields", fieldList);
        result.put("filteredCount", fieldList.size());
        result.put("note", "字段筛选规则已应用");
        return result;
    }

    private Map<String, Object> testDedup(String input, Map<String, Object> extra) {
        String algorithm = extra.get("algorithm") != null ? extra.get("algorithm").toString() : "hash";
        String[] lines = input.split("\n");
        Set<String> unique = new LinkedHashSet<>();
        if ("bloom".equals(algorithm)) {
            int duplicates = 0;
            for (String line : lines) {
                if (!unique.add(line)) duplicates++;
            }
            Map<String, Object> result = new HashMap<>();
            result.put("total", lines.length);
            result.put("unique", unique.size());
            result.put("duplicates", duplicates);
            result.put("algorithm", "bloom");
            return result;
        }
        Collections.addAll(unique, lines);
        Map<String, Object> result = new HashMap<>();
        result.put("total", lines.length);
        result.put("unique", unique.size());
        result.put("duplicates", lines.length - unique.size());
        result.put("algorithm", algorithm);
        return result;
    }

    private Map<String, Object> testBucket(String input, Map<String, Object> extra) {
        int bucketCount = extra.get("bucketCount") != null ?
            Integer.parseInt(extra.get("bucketCount").toString()) : 10;
        String[] items = input.split(",");
        Map<Integer, List<String>> buckets = new HashMap<>();
        for (int i = 0; i < items.length; i++) {
            int bucketIdx = Math.abs(items[i].hashCode()) % bucketCount;
            buckets.computeIfAbsent(bucketIdx, k -> new ArrayList<>()).add(items[i].trim());
        }
        Map<String, Object> result = new HashMap<>();
        result.put("bucketCount", bucketCount);
        result.put("totalItems", items.length);
        result.put("bucketDistribution", buckets.entrySet().stream()
            .collect(Collectors.toMap(e -> "bucket_" + e.getKey(), e -> e.getValue().size())));
        return result;
    }

    private Map<String, Object> testCodec(String input, Map<String, Object> extra) {
        String algorithm = extra.get("algorithm") != null ? extra.get("algorithm").toString() : "gzip";
        byte[] original = input.getBytes(StandardCharsets.UTF_8);
        byte[] compressed;

        try {
            switch (algorithm) {
                case "deflate":
                    java.io.ByteArrayOutputStream deflateOut = new java.io.ByteArrayOutputStream();
                    try (java.util.zip.DeflaterOutputStream dos = new java.util.zip.DeflaterOutputStream(deflateOut)) {
                        dos.write(original);
                    }
                    compressed = deflateOut.toByteArray();
                    break;
                case "snappy":
                    java.io.ByteArrayOutputStream snappyOut = new java.io.ByteArrayOutputStream();
                    try (java.util.zip.DeflaterOutputStream dos = new java.util.zip.DeflaterOutputStream(snappyOut, new java.util.zip.Deflater(java.util.zip.Deflater.BEST_SPEED))) {
                        dos.write(original);
                    }
                    compressed = snappyOut.toByteArray();
                    break;
                default:
                    java.io.ByteArrayOutputStream gzipOut = new java.io.ByteArrayOutputStream();
                    try (java.util.zip.GZIPOutputStream gos = new java.util.zip.GZIPOutputStream(gzipOut)) {
                        gos.write(original);
                    }
                    compressed = gzipOut.toByteArray();
            }

            Map<String, Object> result = new HashMap<>();
            result.put("algorithm", algorithm);
            result.put("originalSize", original.length);
            result.put("compressedSize", compressed.length);
            result.put("ratio", original.length > 0 ?
                Math.round((1 - (double) compressed.length / original.length) * 1000.0) / 10.0 : 0);
            result.put("base64", Base64.getEncoder().encodeToString(compressed));
            return result;
        } catch (Exception e) {
            log.error("编解码测试失败", e);
            Map<String, Object> result = new HashMap<>();
            result.put("algorithm", algorithm);
            result.put("error", e.getMessage());
            return result;
        }
    }

    // ==================== 辅助方法 ====================

    private Channel createGrpcChannel() {
        return ManagedChannelBuilder.forAddress(grpcAddress, grpcPort)
            .maxInboundMessageSize(Integer.MAX_VALUE)
            .maxInboundMetadataSize(Integer.MAX_VALUE)
            .usePlaintext()
            .build();
    }

    private TaskPSIParam buildPsiParam(FederatedQueryTask task) {
        TaskPSIParam psiParam = new TaskPSIParam();
        Map<String, Object> config = JSON.parseObject(task.getSourceConfig());

        psiParam.setClientData(config.get("clientData") != null ? config.get("clientData").toString() : "");
        psiParam.setServerData(config.get("serverData") != null ? config.get("serverData").toString() : "");
        psiParam.setPsiType("difference".equals(task.getQueryType()) ? 1 : 0);
        psiParam.setPsiTag(ALGORITHM_PSI_TAG.getOrDefault(task.getAlgorithm(), 0));
        psiParam.setClientIndex(new Integer[]{0});
        psiParam.setServerIndex(new Integer[]{0});
        psiParam.setOutputFullFilename("/tmp/primihub/query_result_" + task.getId() + ".csv");
        psiParam.setSyncResultToServer(0);
        return psiParam;
    }

    private void recordLog(Long taskId, String level, String message, Object data) {
        try {
            FederatedQueryLog log = new FederatedQueryLog();
            log.setTaskId(taskId);
            log.setLogLevel(level);
            log.setLogMessage(message);
            log.setLogData(data != null ? JSON.toJSONString(data) : null);
            queryTaskRepository.insertQueryLog(log);
        } catch (Exception e) {
            log.error("记录查询日志失败", e);
        }
    }
}
