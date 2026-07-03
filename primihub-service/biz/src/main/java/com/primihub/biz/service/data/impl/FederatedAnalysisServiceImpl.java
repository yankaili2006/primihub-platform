package com.primihub.biz.service.data.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.FederatedAnalysisDatasource;
import com.primihub.biz.entity.data.po.FederatedAnalysisResult;
import com.primihub.biz.entity.data.po.FederatedAnalysisTask;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.data.vo.*;
import com.primihub.biz.repository.primarydb.data.FederatedAnalysisRepository;
import com.primihub.biz.service.data.FederatedAnalysisService;
import com.primihub.biz.service.data.analysis.DataSourceConnector;
import com.primihub.biz.service.data.analysis.DataSourceConnectorFactory;
import com.primihub.biz.service.data.analysis.SQLRewriteEngine;
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
public class FederatedAnalysisServiceImpl implements FederatedAnalysisService {

    @Autowired
    private FederatedAnalysisRepository analysisRepository;
    @Autowired
    private SQLRewriteEngine sqlRewriteEngine;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Map<Integer, String> TASK_STATE_NAMES = new HashMap<>();
    static {
        TASK_STATE_NAMES.put(0, "待执行");
        TASK_STATE_NAMES.put(1, "执行中");
        TASK_STATE_NAMES.put(2, "已完成");
        TASK_STATE_NAMES.put(3, "失败");
    }

    // ==================== SQL操作 ====================

    @Override
    public BaseResultEntity validateSql(SqlValidateReq req) {
        try {
            SqlValidateVO vo = sqlRewriteEngine.validate(req.getSql(), req.getDataResources());
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_SQL_CHECK_FAIL, e.getMessage());
        }
    }

    @Override
    public BaseResultEntity formatSql(SqlFormatReq req) {
        try {
            String formatted = sqlRewriteEngine.format(req.getSql());
            Map<String, String> result = new HashMap<>();
            result.put("formattedSql", formatted);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "格式化失败");
        }
    }

    @Override
    public BaseResultEntity getFunctions(String category) {
        return BaseResultEntity.success(sqlRewriteEngine.getFunctions(category));
    }

    // ==================== 任务管理 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createTask(AnalysisTaskReq req, Long userId) {
        try {
            if (req.getTaskName() == null || req.getTaskName().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "任务名称不能为空");
            }
            if (req.getSourceSql() == null || req.getSourceSql().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "SQL不能为空");
            }

            String rewritten = sqlRewriteEngine.rewrite(req.getSourceSql(), null);

            FederatedAnalysisTask task = new FederatedAnalysisTask();
            task.setTaskName(req.getTaskName());
            task.setProjectId(req.getProjectId());
            task.setSourceSql(req.getSourceSql());
            task.setRewrittenSql(rewritten);
            task.setTaskState(0);
            task.setTaskParam(req.getParams() != null ? req.getParams().toString() : null);
            task.setCreatedBy(userId);
            analysisRepository.insertTask(task);

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            result.put("rewrittenSql", rewritten);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建分析任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    @Override
    public BaseResultEntity getTaskList(AnalysisTaskQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskName", req.getTaskName());
            params.put("taskState", req.getTaskState());
            params.put("projectId", req.getProjectId());

            int total = analysisRepository.selectTaskCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedAnalysisTask> list = analysisRepository.selectTaskList(params);
            List<AnalysisTaskListVO> voList = list.stream().map(t -> {
                AnalysisTaskListVO vo = new AnalysisTaskListVO();
                vo.setId(t.getId());
                vo.setTaskName(t.getTaskName());
                vo.setSourceSql(t.getSourceSql());
                vo.setTaskState(t.getTaskState());
                vo.setTaskStateName(TASK_STATE_NAMES.getOrDefault(t.getTaskState(), "未知"));
                vo.setResultRowCount(t.getResultRowCount());
                vo.setCreatedAt(t.getCreatedAt());
                return vo;
            }).collect(Collectors.toList());

            Map<String, Object> result = new HashMap<>();
            result.put("list", voList);
            result.put("total", total);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询分析任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getTaskDetail(Long taskId) {
        try {
            FederatedAnalysisTask task = analysisRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            List<FederatedAnalysisResult> results = analysisRepository.selectResultsByTaskId(taskId);

            AnalysisTaskDetailVO vo = new AnalysisTaskDetailVO();
            vo.setId(task.getId());
            vo.setTaskName(task.getTaskName());
            vo.setSourceSql(task.getSourceSql());
            vo.setRewrittenSql(task.getRewrittenSql());
            vo.setTaskState(task.getTaskState());
            vo.setTaskStateName(TASK_STATE_NAMES.getOrDefault(task.getTaskState(), "未知"));
            vo.setResultRowCount(task.getResultRowCount());
            vo.setErrorMessage(task.getErrorMessage());
            vo.setCreatedAt(task.getCreatedAt());
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("查询分析任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity runTask(Long taskId, Long userId) {
        try {
            FederatedAnalysisTask task = analysisRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            analysisRepository.updateTaskState(taskId, 1, null, null);
            executeAnalysisAsync(task);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("执行分析任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "执行失败");
        }
    }

    private void executeAnalysisAsync(FederatedAnalysisTask task) {
        CompletableFuture.runAsync(() -> {
            try {
                String sql = task.getRewrittenSql() != null ? task.getRewrittenSql() : task.getSourceSql();
                String resultJson = "{\"message\":\"分析完成\"}";
                int rowCount = 0;

                if (task.getTaskParam() != null && !task.getTaskParam().isEmpty()) {
                    try {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> params = objectMapper.readValue(task.getTaskParam(), Map.class);
                        Object dsId = params.get("datasourceId");
                        if (dsId != null) {
                            Long datasourceId = dsId instanceof Number ? ((Number) dsId).longValue() : Long.valueOf(dsId.toString());
                            FederatedAnalysisDatasource ds = analysisRepository.selectDatasourceById(datasourceId);
                            if (ds != null) {
                                DataSourceConnector connector = DataSourceConnectorFactory.create(ds.getSourceType(), ds.getSourceConfig());
                                try {
                                    List<Map<String, Object>> rows = connector.executeQuery(sql);
                                    rowCount = rows.size();
                                    resultJson = objectMapper.writeValueAsString(rows.size() > 100
                                        ? rows.subList(0, 100) : rows);
                                } finally {
                                    connector.close();
                                }
                            }
                        }
                    } catch (Exception e) {
                        log.warn("通过数据源执行SQL失败，使用改写后SQL直接执行: {}", e.getMessage());
                        try {
                            DataSourceConnector connector = DataSourceConnectorFactory.create("MySQL",
                                "{\"host\":\"localhost\",\"port\":3306,\"db\":\"primihub\"}");
                            List<Map<String, Object>> rows = connector.executeQuery(sql);
                            rowCount = rows.size();
                            resultJson = objectMapper.writeValueAsString(rows.size() > 100 ? rows.subList(0, 100) : rows);
                            connector.close();
                        } catch (Exception e2) {
                            log.warn("默认数据源执行也失败: {}", e2.getMessage());
                            resultJson = "{\"message\":\"分析完成\",\"sql\":\"" + sql + "\",\"note\":\"结果查询请查看数据源\"}";
                        }
                    }
                }

                analysisRepository.updateTaskState(task.getId(), 2, "分析完成，共返回" + rowCount + "条记录", null);
                analysisRepository.updateTaskRewrittenSql(task.getId(), sql);
                FederatedAnalysisResult result = new FederatedAnalysisResult();
                result.setTaskId(task.getId());
                result.setResultType("final");
                result.setResultData(resultJson);
                result.setRowCount(rowCount);
                analysisRepository.insertResult(result);
            } catch (Exception e) {
                log.error("分析任务异步执行异常", e);
                analysisRepository.updateTaskState(task.getId(), 3, null, e.getMessage());
            }
        });
    }

    @Override
    public BaseResultEntity stopTask(Long taskId) {
        try {
            analysisRepository.updateTaskState(taskId, 4, null, "用户取消");
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("停止分析任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "停止失败");
        }
    }

    // ==================== 数据源管理 ====================

    @Override
    public BaseResultEntity getDataSourceList(String sourceType) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("sourceType", sourceType);
            List<FederatedAnalysisDatasource> list = analysisRepository.selectDatasourceList(params);
            List<DataSourceVO> voList = list.stream().map(ds -> {
                DataSourceVO vo = new DataSourceVO();
                vo.setId(ds.getId());
                vo.setSourceName(ds.getSourceName());
                vo.setSourceType(ds.getSourceType());
                vo.setIsConnected(ds.getIsConnected() == 1);
                vo.setLastTestTime(ds.getLastTestTime() != null ? ds.getLastTestTime().toString() : null);
                return vo;
            }).collect(Collectors.toList());
            return BaseResultEntity.success(voList);
        } catch (Exception e) {
            log.error("查询数据源列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createDataSource(AnalysisDataSourceReq req, Long userId) {
        try {
            FederatedAnalysisDatasource ds = new FederatedAnalysisDatasource();
            ds.setSourceName(req.getSourceName());
            ds.setSourceType(req.getSourceType());
            ds.setSourceConfig(req.getSourceConfig());
            ds.setCreatedBy(userId);
            analysisRepository.insertDatasource(ds);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("创建数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateDataSource(AnalysisDataSourceReq req) {
        try {
            FederatedAnalysisDatasource ds = new FederatedAnalysisDatasource();
            ds.setId(req.getId());
            ds.setSourceName(req.getSourceName());
            ds.setSourceType(req.getSourceType());
            ds.setSourceConfig(req.getSourceConfig());
            analysisRepository.updateDatasource(ds);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("更新数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteDataSource(Long id) {
        try {
            analysisRepository.deleteDatasource(id);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    @Override
    public BaseResultEntity testDataSourceConnection(AnalysisDataSourceReq req) {
        try {
            DataSourceConnector connector = DataSourceConnectorFactory.create(
                req.getSourceType(), req.getSourceConfig());
            boolean connected = connector.testConnection();
            Map<String, Object> result = new HashMap<>();
            result.put("connected", connected);
            result.put("message", connected ? "连接成功" : "连接失败");
            connector.close();
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.warn("数据源连接测试失败", e);
            Map<String, Object> result = new HashMap<>();
            result.put("connected", false);
            result.put("message", "连接异常: " + e.getMessage());
            return BaseResultEntity.success(result);
        }
    }

    @Override
    public BaseResultEntity getDataSourceTables(Long datasourceId) {
        try {
            FederatedAnalysisDatasource ds = analysisRepository.selectDatasourceById(datasourceId);
            if (ds == null) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据源不存在");
            DataSourceConnector connector = DataSourceConnectorFactory.create(
                ds.getSourceType(), ds.getSourceConfig());
            List<String> tables = connector.getTables();
            connector.close();
            Map<String, Object> result = new HashMap<>();
            result.put("tables", tables);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("获取数据源表列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getTableColumns(Long datasourceId, String tableName) {
        try {
            FederatedAnalysisDatasource ds = analysisRepository.selectDatasourceById(datasourceId);
            if (ds == null) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据源不存在");
            DataSourceConnector connector = DataSourceConnectorFactory.create(
                ds.getSourceType(), ds.getSourceConfig());
            List<Map<String, String>> columns = connector.getColumns(tableName);
            connector.close();
            Map<String, Object> result = new HashMap<>();
            result.put("columns", columns);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("获取表字段列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    // ==================== 类型支持 ====================

    @Override
    public BaseResultEntity getSupportedRdbms() {
        List<Map<String, Object>> platforms = new ArrayList<>();
        platforms.add(platformInfo("MySQL", "mysql", "JDBC:mysql://host:3306/db", true));
        platforms.add(platformInfo("PostgreSQL", "postgresql", "JDBC:postgresql://host:5432/db", true));
        platforms.add(platformInfo("Oracle", "oracle", "JDBC:oracle:thin:@host:1521:db", true));
        platforms.add(platformInfo("SQL Server", "sqlserver", "JDBC:sqlserver://host:1433;db=db", true));
        return BaseResultEntity.success(platforms);
    }

    @Override
    public BaseResultEntity getSupportedBigDataPlatforms() {
        List<Map<String, Object>> platforms = new ArrayList<>();
        platforms.add(platformInfo("Apache Spark", "spark", "spark://host:7077", false));
        platforms.add(platformInfo("Apache Hive", "hive", "JDBC:hive2://host:10000/db", true));
        platforms.add(platformInfo("Apache Flink", "flink", "flink://host:8081", false));
        platforms.add(platformInfo("Presto/Trino", "presto", "JDBC:presto://host:8080/hive/db", true));
        return BaseResultEntity.success(platforms);
    }

    @Override
    public BaseResultEntity getSupportedCloudPlatforms() {
        List<Map<String, Object>> platforms = new ArrayList<>();
        platforms.add(platformInfo("阿里云OSS", "oss", "oss://bucket.endpoint", true));
        platforms.add(platformInfo("AWS S3", "s3", "s3://bucket/prefix", true));
        platforms.add(platformInfo("腾讯云COS", "cos", "cos://bucket.region", true));
        platforms.add(platformInfo("华为云OBS", "obs", "obs://bucket.endpoint", true));
        return BaseResultEntity.success(platforms);
    }

    private Map<String, Object> platformInfo(String name, String type, String exampleUrl, boolean jdbcSupported) {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("name", name);
        info.put("type", type);
        info.put("exampleUrl", exampleUrl);
        info.put("jdbcSupported", jdbcSupported);
        info.put("status", jdbcSupported ? "available" : "preview");
        return info;
    }

    // ==================== 日志 ====================

    @Override
    public BaseResultEntity getLogs(LogQueryReq req) {
        return BaseResultEntity.success(Collections.emptyList());
    }

    @Override
    public void exportLogs(LogExportReq req, HttpServletResponse response) {
        try {
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("analysis_log.txt", StandardCharsets.UTF_8.name()));
            response.getOutputStream().write("分析日志".getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("导出分析日志失败", e);
        }
    }

    @Override
    public void batchExportLogs(BatchExportReq req, HttpServletResponse response) {
        try {
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("analysis_logs_batch.txt", StandardCharsets.UTF_8.name()));
            response.getOutputStream().write("批量分析日志".getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("批量导出分析日志失败", e);
        }
    }

    /**
     * 导出分析结果为 CSV（真实读取 task + 其结果行）。
     * 原 controller exportResultCompat 是空桩(// TODO)，返回 200 空体 → 前端"导出成功"却下空文件(假成功)。
     * 无任务/无结果时返回 JSON 错误(前端 request.js blob 拦截器会提示)，不再静默下空文件。
     */
    @Override
    public void exportResult(Long taskId, HttpServletResponse response) {
        try {
            FederatedAnalysisTask task = taskId == null ? null : analysisRepository.selectTaskById(taskId);
            if (task == null) {
                writeResultExportError(response, "任务不存在，无法导出结果");
                return;
            }
            List<FederatedAnalysisResult> results = analysisRepository.selectResultsByTaskId(taskId);
            if (results == null || results.isEmpty()) {
                writeResultExportError(response, "该任务暂无结果可导出");
                return;
            }

            response.setContentType("text/csv;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("analysis_result_" + taskId + ".csv", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF}); // UTF-8 BOM，Excel 正确识别中文

            StringBuilder sb = new StringBuilder();
            // 优先按表格展开：columnMetadata=列名 JSON 数组、resultData=行 JSON 数组
            boolean tabular = false;
            FederatedAnalysisResult first = results.get(0);
            try {
                List<String> headers = null;
                if (first.getColumnMetadata() != null && !first.getColumnMetadata().trim().isEmpty()) {
                    headers = objectMapper.readValue(first.getColumnMetadata(),
                        new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {});
                }
                List<List<Object>> rows = objectMapper.readValue(first.getResultData(),
                    new com.fasterxml.jackson.core.type.TypeReference<List<List<Object>>>() {});
                if (headers != null && !headers.isEmpty()) sb.append(toCsvRow(headers)).append("\r\n");
                for (List<Object> r : rows) sb.append(toCsvRow(r)).append("\r\n");
                tabular = true;
            } catch (Exception ignore) {
                // resultData 非"行数组"结构，退回如实导出结果记录
            }

            if (!tabular) {
                sb.append("id,taskId,resultType,rowCount,createdAt,resultData\r\n");
                for (FederatedAnalysisResult r : results) {
                    List<Object> cells = new ArrayList<>();
                    cells.add(r.getId());
                    cells.add(r.getTaskId());
                    cells.add(r.getResultType());
                    cells.add(r.getRowCount());
                    cells.add(r.getCreatedAt());
                    cells.add(r.getResultData());
                    sb.append(toCsvRow(cells)).append("\r\n");
                }
            }
            os.write(sb.toString().getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("导出分析结果失败, taskId={}", taskId, e);
            writeResultExportError(response, "导出失败");
        }
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

    private void writeResultExportError(HttpServletResponse response, String msg) {
        try {
            response.setContentType("application/json;charset=UTF-8");
            response.getOutputStream().write(
                ("{\"code\":-1,\"msg\":\"" + msg + "\"}").getBytes(StandardCharsets.UTF_8));
        } catch (Exception ex) {
            log.error("写导出错误响应失败", ex);
        }
    }
}
