package com.primihub.biz.service.data.impl;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.FederatedQueryLog;
import com.primihub.biz.entity.data.po.FederatedQueryTask;
import com.primihub.biz.entity.data.req.FederatedStatsQueryReq;
import com.primihub.biz.entity.data.req.LogExportReq;
import com.primihub.biz.entity.data.req.LogQueryReq;
import com.primihub.biz.repository.primarydb.data.FederatedQueryTaskRepository;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.*;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class FederatedQueryServiceImplTest {

    @Mock
    private FederatedQueryTaskRepository queryTaskRepository;

    @InjectMocks
    private FederatedQueryServiceImpl federatedQueryService;

    @Captor
    private ArgumentCaptor<FederatedQueryTask> taskCaptor;

    @Captor
    private ArgumentCaptor<FederatedQueryLog> logCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;
    private static final Long LOG_ID = 200L;

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private FederatedQueryTask createTask(Long id, String algorithm, String mode, String queryType, Integer state) {
        FederatedQueryTask task = new FederatedQueryTask();
        task.setId(id);
        task.setTaskName("query-task");
        task.setAlgorithm(algorithm);
        task.setQueryMode(mode);
        task.setQueryType(queryType);
        task.setTaskState(state);
        task.setSourceConfig("{\"clientData\":\"data.csv\",\"serverData\":\"ref.csv\"}");
        task.setCreatedBy(USER_ID);
        task.setCreatedAt(new Date());
        return task;
    }

    private FederatedQueryLog createLog(Long id, Long taskId, String level, String message) {
        FederatedQueryLog log = new FederatedQueryLog();
        log.setId(id);
        log.setTaskId(taskId);
        log.setLogLevel(level);
        log.setLogMessage(message);
        log.setCreatedAt(new Date());
        return log;
    }

    // ==================== createQuery ====================

    @Test
    public void createQuery_withValidParams_savesAndReturnsSuccess() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "psi-query");
        req.put("algorithm", "DH");
        req.put("mode", "batch");
        req.put("queryType", "psi");
        req.put("clientData", "data.csv");

        doAnswer(invocation -> {
            FederatedQueryTask task = invocation.getArgument(0);
            task.setId(TASK_ID);
            return null;
        }).when(queryTaskRepository).insertQueryTask(taskCaptor.capture());

        BaseResultEntity result = federatedQueryService.createQuery(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(TASK_ID, map.get("taskId"));
        assertEquals("psi-query", map.get("taskName"));
        assertEquals("DH", map.get("algorithm"));
        assertEquals("batch", map.get("mode"));
        assertEquals(0, map.get("status"));

        FederatedQueryTask captured = taskCaptor.getValue();
        assertEquals("psi-query", captured.getTaskName());
        assertEquals("DH", captured.getAlgorithm());
        assertEquals("batch", captured.getQueryMode());
        assertEquals("psi", captured.getQueryType());
        assertEquals(Integer.valueOf(0), captured.getTaskState());
        assertEquals(USER_ID, captured.getCreatedBy());

        verify(queryTaskRepository).insertQueryLog(any());
    }

    @Test
    public void createQuery_emptyName_returnsLackOfParam() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "");
        req.put("algorithm", "DH");

        BaseResultEntity result = federatedQueryService.createQuery(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(queryTaskRepository, never()).insertQueryTask(any());
    }

    @Test
    public void createQuery_unsupportedAlgorithm_returnsParamInvalidation() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "test");
        req.put("algorithm", "UNKNOWN");

        BaseResultEntity result = federatedQueryService.createQuery(req, USER_ID);

        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), result.getCode());
        verify(queryTaskRepository, never()).insertQueryTask(any());
    }

    @Test
    public void createQuery_defaultAlgorithmIsDH() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "test");

        doAnswer(invocation -> {
            ((FederatedQueryTask) invocation.getArgument(0)).setId(TASK_ID);
            return null;
        }).when(queryTaskRepository).insertQueryTask(taskCaptor.capture());

        federatedQueryService.createQuery(req, USER_ID);

        assertEquals("DH", taskCaptor.getValue().getAlgorithm());
    }

    @Test
    public void createQuery_supportedAlgorithmsAllSucceed() {
        for (String algo : Arrays.asList("DH", "OT", "HE")) {
            Map<String, Object> req = new HashMap<>();
            req.put("taskName", "test-" + algo);
            req.put("algorithm", algo);
            doAnswer(inv -> {
                ((FederatedQueryTask) inv.getArgument(0)).setId(TASK_ID);
                return null;
            }).when(queryTaskRepository).insertQueryTask(any());
            BaseResultEntity result = federatedQueryService.createQuery(req, USER_ID);
            assertEquals(algo + " should succeed", 0, result.getCode().intValue());
        }
    }

    @Test
    public void createQuery_repositoryThrows_returnsFailure() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "test");
        req.put("algorithm", "DH");
        doThrow(new RuntimeException("DB error")).when(queryTaskRepository).insertQueryTask(any());

        BaseResultEntity result = federatedQueryService.createQuery(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getQueryList ====================

    @Test
    public void getQueryList_returnsPaginatedResults() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setTaskName("test");
        req.setStatsType("DH");
        req.setTaskState(0);
        req.setPageNo(1);
        req.setPageSize(10);

        FederatedQueryTask task = createTask(TASK_ID, "DH", "batch", "psi", 0);
        when(queryTaskRepository.selectQueryTaskCount(any())).thenReturn(1);
        when(queryTaskRepository.selectQueryTaskList(any())).thenReturn(Collections.singletonList(task));

        BaseResultEntity result = federatedQueryService.getQueryList(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("pageParam"));
        List<?> list = (List<?>) map.get("list");
        assertEquals(1, list.size());
    }

    @Test
    public void getQueryList_empty_returnsEmpty() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(queryTaskRepository.selectQueryTaskCount(any())).thenReturn(0);
        when(queryTaskRepository.selectQueryTaskList(any())).thenReturn(Collections.emptyList());

        BaseResultEntity result = federatedQueryService.getQueryList(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0, ((List<?>) map.get("list")).size());
    }

    @Test
    public void getQueryList_defaultsPagination() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(queryTaskRepository.selectQueryTaskCount(any())).thenReturn(0);
        when(queryTaskRepository.selectQueryTaskList(any())).thenReturn(Collections.emptyList());

        federatedQueryService.getQueryList(req);

        assertEquals(Integer.valueOf(1), req.getPageNo());
        assertEquals(Integer.valueOf(10), req.getPageSize());
    }

    @Test
    public void getQueryList_repositoryThrows_returnsFailure() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(queryTaskRepository.selectQueryTaskCount(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedQueryService.getQueryList(req);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getQueryDetail ====================

    @Test
    public void getQueryDetail_existingTask_returnsTask() {
        FederatedQueryTask task = createTask(TASK_ID, "DH", "batch", "psi", 0);
        when(queryTaskRepository.selectQueryTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedQueryService.getQueryDetail(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        FederatedQueryTask returned = (FederatedQueryTask) result.getResult();
        assertEquals(TASK_ID, returned.getId());
        assertEquals("DH", returned.getAlgorithm());
    }

    @Test
    public void getQueryDetail_nullTask_returnsDataQueryNull() {
        when(queryTaskRepository.selectQueryTaskById(999L)).thenReturn(null);

        BaseResultEntity result = federatedQueryService.getQueryDetail(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void getQueryDetail_repositoryThrows_returnsFailure() {
        when(queryTaskRepository.selectQueryTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedQueryService.getQueryDetail(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== runQuery ====================

    @Test
    public void runQuery_taskNotFound_returnsDataQueryNull() {
        when(queryTaskRepository.selectQueryTaskById(999L)).thenReturn(null);

        BaseResultEntity result = federatedQueryService.runQuery(999L, USER_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(queryTaskRepository, never()).updateQueryTask(any());
    }

    @Test
    public void runQuery_gRpcFallsBackToSimulatedMode() {
        FederatedQueryTask task = createTask(TASK_ID, "DH", "batch", "psi", 0);
        when(queryTaskRepository.selectQueryTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedQueryService.runQuery(TASK_ID, USER_ID);

        assertEquals(0, result.getCode().intValue());

        // updateQueryTask 被调用2次(状态 1→2)。注意: captor 捕获的是同一个被复用的 task 引用,
        // 两次取值都反映最终状态(2), 无法断言中间态1(Mockito captor 引用捕获局限)。
        verify(queryTaskRepository, times(2)).updateQueryTask(taskCaptor.capture());
        List<FederatedQueryTask> capturedTasks = taskCaptor.getAllValues();
        assertEquals(Integer.valueOf(2), capturedTasks.get(1).getTaskState());
        assertNotNull(capturedTasks.get(1).getResultSummary());

        verify(queryTaskRepository, atLeast(1)).insertQueryLog(logCaptor.capture());
        List<FederatedQueryLog> logs = logCaptor.getAllValues();
        boolean hasWarnLog = logs.stream().anyMatch(l -> "WARN".equals(l.getLogLevel()));
        assertTrue("Expected WARN log for simulated mode", hasWarnLog);
    }

    @Test
    public void runQuery_withDifferenceQueryType_succeeds() {
        FederatedQueryTask task = createTask(TASK_ID, "OT", "realtime", "difference", 0);
        when(queryTaskRepository.selectQueryTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedQueryService.runQuery(TASK_ID, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(queryTaskRepository, times(2)).updateQueryTask(any());
    }

    @Test
    public void runQuery_outerCatch_returnsFailure() {
        when(queryTaskRepository.selectQueryTaskById(TASK_ID))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedQueryService.runQuery(TASK_ID, USER_ID);

        assertEquals(BaseResultEnum.DATA_RUN_TASK_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== getQueryResult ====================

    @Test
    public void getQueryResult_existingTask_returnsResult() {
        FederatedQueryTask task = createTask(TASK_ID, "DH", "batch", "psi", 2);
        task.setResultSummary("查询完成，共匹配 100 条数据");
        task.setResultRowCount(100);
        when(queryTaskRepository.selectQueryTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedQueryService.getQueryResult(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(TASK_ID, map.get("taskId"));
        assertEquals(Integer.valueOf(2), map.get("taskState"));
        assertEquals("查询完成，共匹配 100 条数据", map.get("resultSummary"));
        assertEquals(100, map.get("resultRowCount"));
    }

    @Test
    public void getQueryResult_nullTask_returnsDataQueryNull() {
        when(queryTaskRepository.selectQueryTaskById(999L)).thenReturn(null);

        BaseResultEntity result = federatedQueryService.getQueryResult(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void getQueryResult_repositoryThrows_returnsFailure() {
        when(queryTaskRepository.selectQueryTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedQueryService.getQueryResult(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getSupportedAlgorithms ====================

    @Test
    public void getSupportedAlgorithms_returnsThreeAlgorithmsWithModes() {
        BaseResultEntity result = federatedQueryService.getSupportedAlgorithms();

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(3, list.size());

        for (Object obj : list) {
            Map<?, ?> algo = (Map<?, ?>) obj;
            assertTrue(algo.containsKey("type"));
            assertTrue(algo.containsKey("name"));
            assertTrue(algo.containsKey("psiTag"));
            assertTrue(algo.containsKey("modes"));
            List<?> modes = (List<?>) algo.get("modes");
            assertEquals(2, modes.size());
        }
    }

    // ==================== getLogs ====================

    @Test
    public void getLogs_returnsPaginatedResults() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);
        req.setLogLevel("INFO");

        FederatedQueryLog log = createLog(LOG_ID, TASK_ID, "INFO", "任务已创建");
        when(queryTaskRepository.selectQueryLogCount(any())).thenReturn(1);
        when(queryTaskRepository.selectQueryLogList(any())).thenReturn(Collections.singletonList(log));

        BaseResultEntity result = federatedQueryService.getLogs(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("pageParam"));
        List<?> list = (List<?>) map.get("list");
        assertEquals(1, list.size());
    }

    @Test
    public void getLogs_defaultsPagination() {
        LogQueryReq req = new LogQueryReq();
        when(queryTaskRepository.selectQueryLogCount(any())).thenReturn(0);
        when(queryTaskRepository.selectQueryLogList(any())).thenReturn(Collections.emptyList());

        federatedQueryService.getLogs(req);

        assertEquals(Integer.valueOf(1), req.getPageNo());
        assertEquals(Integer.valueOf(10), req.getPageSize());
    }

    @Test
    public void getLogs_repositoryThrows_returnsFailure() {
        LogQueryReq req = new LogQueryReq();
        when(queryTaskRepository.selectQueryLogCount(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedQueryService.getLogs(req);

        assertEquals(BaseResultEnum.DATA_LOG_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== exportLogs ====================

    @Test
    public void exportLogs_writesToResponse() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);

        FederatedQueryLog log = createLog(LOG_ID, TASK_ID, "INFO", "查询完成");
        when(queryTaskRepository.selectQueryLogList(any())).thenReturn(Collections.singletonList(log));

        federatedQueryService.exportLogs(req, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("query_log_" + TASK_ID));
    }

    @Test
    public void exportLogs_emptyLogs_writesHeaderOnly() throws Exception {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        when(queryTaskRepository.selectQueryLogList(any())).thenReturn(Collections.emptyList());

        federatedQueryService.exportLogs(req, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        String content = response.getContentAsString();
        assertTrue(content.contains("联邦查询日志"));
    }

    // ==================== saveToolConfig ====================

    @Test
    public void saveToolConfig_withName_returnsSuccess() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "payloadChunk");
        req.put("chunkSize", 2048);

        BaseResultEntity result = federatedQueryService.saveToolConfig(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        assertEquals("payloadChunk配置保存成功", result.getResult());
    }

    @Test
    public void saveToolConfig_emptyName_returnsLackOfParam() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "");

        BaseResultEntity result = federatedQueryService.saveToolConfig(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void saveToolConfig_repositoryThrows_notApplicable() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "dedup");

        BaseResultEntity result = federatedQueryService.saveToolConfig(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
    }

    // ==================== getToolConfig ====================

    @Test
    public void getToolConfig_payloadChunk_returnsChunkConfig() {
        BaseResultEntity result = federatedQueryService.getToolConfig("payloadChunk");

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals("payloadChunk", map.get("toolName"));
        assertTrue(map.containsKey("defaultChunkSize"));
        assertEquals(1024 * 1024, map.get("defaultChunkSize"));
    }

    @Test
    public void getToolConfig_dedup_returnsDedupConfig() {
        BaseResultEntity result = federatedQueryService.getToolConfig("dedup");

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue(map.containsKey("algorithms"));
    }

    @Test
    public void getToolConfig_codec_returnsCodecConfig() {
        BaseResultEntity result = federatedQueryService.getToolConfig("codec");

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        List<?> algos = (List<?>) map.get("algorithms");
        assertTrue(algos.contains("gzip"));
        assertTrue(algos.contains("snappy"));
    }

    @Test
    public void getToolConfig_unknown_returnsDisabled() {
        BaseResultEntity result = federatedQueryService.getToolConfig("unknownTool");

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(false, map.get("enabled"));
    }

    @Test
    public void getToolConfig_repositoryThrows_notApplicable() {
        BaseResultEntity result = federatedQueryService.getToolConfig("payloadChunk");
        assertEquals(0, result.getCode().intValue());
    }

    // ==================== testTool ====================

    @Test
    public void testTool_payloadChunk_returnsChunkResult() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "payloadChunk");
        req.put("testInput", "hello world");
        Map<String, Object> params = new HashMap<>();
        params.put("chunkSize", 4);
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals("payloadChunk", map.get("toolName"));
        assertTrue((Boolean) map.get("success"));
        Map<?, ?> output = (Map<?, ?>) map.get("output");
        assertEquals(Integer.valueOf(3), output.get("totalChunks"));
    }

    @Test
    public void testTool_outputFields_returnsFieldResult() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "outputFields");
        req.put("testInput", "sample");
        Map<String, Object> params = new HashMap<>();
        params.put("fields", "name,age,gender");
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
    }

    @Test
    public void testTool_dedupWithHash_removesDuplicates() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "dedup");
        req.put("testInput", "a\nb\na\nc");
        Map<String, Object> params = new HashMap<>();
        params.put("algorithm", "hash");
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
        Map<?, ?> output = (Map<?, ?>) map.get("output");
        assertEquals(4, output.get("total"));
        assertEquals(3, output.get("unique"));
        assertEquals(1, output.get("duplicates"));
    }

    @Test
    public void testTool_dedupWithBloom_removesDuplicates() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "dedup");
        req.put("testInput", "x\ny\nx");
        Map<String, Object> params = new HashMap<>();
        params.put("algorithm", "bloom");
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
        Map<?, ?> output = (Map<?, ?>) map.get("output");
        assertEquals("bloom", output.get("algorithm"));
    }

    @Test
    public void testTool_bucket_distributesItems() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "bucket");
        req.put("testInput", "apple,banana,cherry,date");
        Map<String, Object> params = new HashMap<>();
        params.put("bucketCount", 2);
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
        Map<?, ?> output = (Map<?, ?>) map.get("output");
        assertEquals(2, output.get("bucketCount"));
        assertEquals(4, output.get("totalItems"));
    }

    @Test
    public void testTool_codecWithDefault_compresses() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "codec");
        req.put("testInput", "hello world this is a test string for compression");
        Map<String, Object> params = new HashMap<>();
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
        Map<?, ?> output = (Map<?, ?>) map.get("output");
        assertTrue((Integer) output.get("compressedSize") > 0);
        assertNotNull(output.get("ratio"));
    }

    @Test
    public void testTool_codecWithDeflate_compresses() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "codec");
        req.put("testInput", "compression test data");
        Map<String, Object> params = new HashMap<>();
        params.put("algorithm", "deflate");
        req.put("params", params);

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
    }

    @Test
    public void testTool_unknown_returnsDefaultMessage() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "unknownTool");
        req.put("testInput", "test");

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("success"));
    }

    @Test
    public void testTool_repositoryThrows_notApplicable() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "payloadChunk");
        req.put("testInput", "data");

        BaseResultEntity result = federatedQueryService.testTool(req);

        assertEquals(0, result.getCode().intValue());
    }
}
