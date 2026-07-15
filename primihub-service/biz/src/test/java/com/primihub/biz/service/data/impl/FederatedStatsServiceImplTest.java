package com.primihub.biz.service.data.impl;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.FederatedStatsConfig;
import com.primihub.biz.entity.data.po.FederatedStatsResult;
import com.primihub.biz.entity.data.po.FederatedStatsTask;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.data.vo.StatsTaskDetailVO;
import com.primihub.biz.entity.data.vo.StatsTypeVO;
import com.primihub.biz.repository.primarydb.data.FederatedStatsRepository;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.*;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class FederatedStatsServiceImplTest {

    @Mock
    private FederatedStatsRepository federatedStatsRepository;

    @InjectMocks
    private FederatedStatsServiceImpl federatedStatsService;

    @Captor
    private ArgumentCaptor<FederatedStatsTask> taskCaptor;

    @Captor
    private ArgumentCaptor<FederatedStatsResult> resultCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;
    private static final Long PROJECT_ID = 10L;
    private static final Long CONFIG_ID = 50L;
    private static final Long RESULT_ID = 200L;

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private FederatedStatsTask createTaskPo(Long id, String taskName, String statsType, Integer state) {
        FederatedStatsTask task = new FederatedStatsTask();
        task.setId(id);
        task.setTaskName(taskName);
        task.setProjectId(PROJECT_ID);
        task.setStatsType(statsType);
        task.setTaskState(state);
        task.setCreatedBy(USER_ID);
        return task;
    }

    private FederatedStatsResult createResultPo(Long id, Long taskId, String type, String data) {
        FederatedStatsResult r = new FederatedStatsResult();
        r.setId(id);
        r.setTaskId(taskId);
        r.setResultType(type);
        r.setResultData(data);
        r.setRowCount(100);
        return r;
    }

    // ==================== createTask ====================

    @Test
    public void createTask_savesTaskAndReturnsSuccess() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("test-task");
        req.setProjectId(PROJECT_ID);
        req.setStatsType("descriptive");
        req.setAlgorithmType("default");
        req.setTaskParam("{}");

        doAnswer(invocation -> {
            FederatedStatsTask task = invocation.getArgument(0);
            task.setId(TASK_ID);
            return null;
        }).when(federatedStatsRepository).insertTask(taskCaptor.capture());

        BaseResultEntity result = federatedStatsService.createTask(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        assertNotNull(result.getResult());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(TASK_ID, map.get("taskId"));

        FederatedStatsTask captured = taskCaptor.getValue();
        assertEquals("test-task", captured.getTaskName());
        assertEquals(PROJECT_ID, captured.getProjectId());
        assertEquals("descriptive", captured.getStatsType());
        assertEquals(0, captured.getTaskState().intValue());
        assertEquals(USER_ID, captured.getCreatedBy());
        verify(federatedStatsRepository).insertTask(any());
    }

    @Test
    public void createTask_emptyName_returnsLackOfParam() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("");

        BaseResultEntity result = federatedStatsService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).insertTask(any());
    }

    @Test
    public void createTask_nullName_returnsLackOfParam() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setStatsType("descriptive");

        BaseResultEntity result = federatedStatsService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).insertTask(any());
    }

    @Test
    public void createTask_invalidStatsType_returnsParamInvalidation() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("test");
        req.setStatsType("unknown_type");

        BaseResultEntity result = federatedStatsService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).insertTask(any());
    }

    @Test
    public void createTask_nullStatsType_returnsParamInvalidation() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("test");

        BaseResultEntity result = federatedStatsService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).insertTask(any());
    }

    // ==================== getTaskList ====================

    @Test
    public void getTaskList_returnsPaginatedResults() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setTaskName("test");
        req.setTaskState(0);
        req.setStatsType("descriptive");
        req.setProjectId(PROJECT_ID);
        req.setPageNo(1);
        req.setPageSize(10);

        FederatedStatsTask task = createTaskPo(TASK_ID, "test-task", "descriptive", 0);
        task.setResultSummary("均值: 32.5");

        when(federatedStatsRepository.selectTaskCount(any())).thenReturn(1);
        when(federatedStatsRepository.selectTaskList(any())).thenReturn(Collections.singletonList(task));

        BaseResultEntity result = federatedStatsService.getTaskList(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(1, map.get("total"));
        List<?> list = (List<?>) map.get("list");
        assertEquals(1, list.size());
        assertTrue(list.get(0) instanceof com.primihub.biz.entity.data.vo.StatsTaskListVO);
        verify(federatedStatsRepository).selectTaskCount(any());
        verify(federatedStatsRepository).selectTaskList(any());
    }

    @Test
    public void getTaskList_emptyResult_returnsEmptyList() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(federatedStatsRepository.selectTaskCount(any())).thenReturn(0);
        when(federatedStatsRepository.selectTaskList(any())).thenReturn(Collections.emptyList());

        BaseResultEntity result = federatedStatsService.getTaskList(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0, map.get("total"));
        List<?> list = (List<?>) map.get("list");
        assertTrue(list.isEmpty());
    }

    @Test
    public void getTaskList_minimalQuery_defaultsPagination() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(federatedStatsRepository.selectTaskCount(any())).thenReturn(0);
        when(federatedStatsRepository.selectTaskList(any())).thenReturn(Collections.emptyList());

        BaseResultEntity result = federatedStatsService.getTaskList(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedStatsRepository).selectTaskCount(any());
        verify(federatedStatsRepository).selectTaskList(any());
    }

    // ==================== getTaskDetail ====================

    @Test
    public void getTaskDetail_existingTask_returnsDetailWithResults() {
        FederatedStatsTask task = createTaskPo(TASK_ID, "detail-task", "regression", 2);
        task.setAlgorithmType("linear");
        task.setTaskParam("{\"alpha\":0.05}");
        task.setResultSummary("R²: 0.87");

        FederatedStatsResult resultPo = createResultPo(RESULT_ID, TASK_ID, "final", "{\"r2\":0.87}");

        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(resultPo));

        BaseResultEntity result = federatedStatsService.getTaskDetail(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        StatsTaskDetailVO vo = (StatsTaskDetailVO) result.getResult();
        assertEquals(TASK_ID, vo.getId());
        assertEquals("detail-task", vo.getTaskName());
        assertEquals("regression", vo.getStatsType());
        assertEquals("回归分析", vo.getStatsTypeName());
        assertEquals("linear", vo.getAlgorithmType());
        assertEquals(2, vo.getTaskState().intValue());
        assertEquals("已完成", vo.getTaskStateName());
        assertEquals(1, vo.getResults().size());
    }

    @Test
    public void getTaskDetail_nullTask_returnsDataQueryNull() {
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(null);

        BaseResultEntity result = federatedStatsService.getTaskDetail(TASK_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).selectResultsByTaskId(any());
    }

    @Test
    public void getTaskDetail_unknownStatsTypeName_fallsBackToRawType() {
        FederatedStatsTask task = createTaskPo(TASK_ID, "task", "unknown_stats", 2);

        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.emptyList());

        BaseResultEntity result = federatedStatsService.getTaskDetail(TASK_ID);

        StatsTaskDetailVO vo = (StatsTaskDetailVO) result.getResult();
        assertEquals("unknown_stats", vo.getStatsTypeName());
    }

    // ==================== runTask ====================

    @Test
    public void runTask_existingTask_updatesStateAndRunsAsync() {
        FederatedStatsTask task = createTaskPo(TASK_ID, "task", "descriptive", 0);
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedStatsService.runTask(TASK_ID, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedStatsRepository).updateTaskState(TASK_ID, 1, null, null);
    }

    @Test
    public void runTask_nullTask_returnsDataQueryNull() {
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(null);

        BaseResultEntity result = federatedStatsService.runTask(TASK_ID, USER_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).updateTaskState(any(), any(), any(), any());
    }

    @Test
    public void runTask_alreadyRunning_returnsHandleRightNow() {
        FederatedStatsTask task = createTaskPo(TASK_ID, "task", "descriptive", 1);
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedStatsService.runTask(TASK_ID, USER_ID);

        assertEquals(BaseResultEnum.HANDLE_RIGHT_NOW.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).updateTaskState(any(), any(), any(), any());
    }

    // ==================== stopTask ====================

    @Test
    public void stopTask_existingTask_updatesStateToCancelled() {
        FederatedStatsTask task = createTaskPo(TASK_ID, "task", "t_test", 1);
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedStatsService.stopTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedStatsRepository).updateTaskState(TASK_ID, 4, null, "用户取消");
    }

    @Test
    public void stopTask_nullTask_returnsDataQueryNull() {
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(null);

        BaseResultEntity result = federatedStatsService.stopTask(TASK_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(federatedStatsRepository, never()).updateTaskState(any(), any(), any(), any());
    }

    // ==================== deleteTask ====================

    @Test
    public void deleteTask_deletesResultsAndUpdatesTask() {
        doNothing().when(federatedStatsRepository).deleteResultByTaskId(TASK_ID);
        doNothing().when(federatedStatsRepository).updateTask(any());

        BaseResultEntity result = federatedStatsService.deleteTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedStatsRepository).deleteResultByTaskId(TASK_ID);
        verify(federatedStatsRepository).updateTask(taskCaptor.capture());
        assertEquals(TASK_ID, taskCaptor.getValue().getId());
        assertEquals(4, taskCaptor.getValue().getTaskState().intValue());
    }

    // ==================== getResult ====================

    @Test
    public void getResult_existingTask_returnsResults() {
        FederatedStatsResult r1 = createResultPo(RESULT_ID, TASK_ID, "final", "{\"key\":\"value\"}");
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(r1));

        BaseResultEntity result = federatedStatsService.getResult(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(1, list.size());
        assertTrue(list.get(0) instanceof FederatedStatsResult);
    }

    @Test
    public void getResult_noResults_returnsEmptyList() {
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.emptyList());

        BaseResultEntity result = federatedStatsService.getResult(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertTrue(list.isEmpty());
    }

    // ==================== saveResult ====================

    @Test
    public void saveResult_withStorageConfigId_savesSuccessfully() {
        SaveResultReq req = new SaveResultReq();
        req.setTaskId(TASK_ID);
        req.setStorageConfigId(CONFIG_ID);

        FederatedStatsResult r = createResultPo(RESULT_ID, TASK_ID, "final", "data");
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(r));
        FederatedStatsConfig config = new FederatedStatsConfig();
        config.setId(CONFIG_ID);
        config.setConfigName("OSS");
        when(federatedStatsRepository.selectConfigById(CONFIG_ID)).thenReturn(config);

        BaseResultEntity result = federatedStatsService.saveResult(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
    }

    @Test
    public void saveResult_noResults_returnsDataQueryNull() {
        SaveResultReq req = new SaveResultReq();
        req.setTaskId(TASK_ID);
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.emptyList());

        BaseResultEntity result = federatedStatsService.saveResult(req, USER_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void saveResult_noConfig_returnsLackOfParam() {
        SaveResultReq req = new SaveResultReq();
        req.setTaskId(TASK_ID);

        FederatedStatsResult r = createResultPo(RESULT_ID, TASK_ID, "final", "data");
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(r));
        when(federatedStatsRepository.selectDefaultConfig()).thenReturn(null);

        BaseResultEntity result = federatedStatsService.saveResult(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void saveResult_usesDefaultConfigWhenNoStorageConfigId() {
        SaveResultReq req = new SaveResultReq();
        req.setTaskId(TASK_ID);

        FederatedStatsResult r = createResultPo(RESULT_ID, TASK_ID, "final", "data");
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(r));
        FederatedStatsConfig config = new FederatedStatsConfig();
        config.setId(1L);
        config.setConfigName("Default");
        when(federatedStatsRepository.selectDefaultConfig()).thenReturn(config);

        BaseResultEntity result = federatedStatsService.saveResult(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedStatsRepository).selectDefaultConfig();
    }

    // ==================== exportResult ====================

    @Test
    public void exportResult_writesContentToResponse() {
        FederatedStatsResult r = createResultPo(RESULT_ID, TASK_ID, "final", "result-data");
        when(federatedStatsRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(r));

        federatedStatsService.exportResult(TASK_ID, "TXT", response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("stats_" + TASK_ID));
        verify(federatedStatsRepository).selectResultsByTaskId(TASK_ID);
    }

    // ==================== batchExportResult ====================

    @Test
    public void batchExportResult_writesContentForMultipleTasks() {
        BatchExportReq req = new BatchExportReq();
        req.setTaskIds(Arrays.asList(1L, 2L));

        FederatedStatsResult r1 = createResultPo(1L, 1L, "final", "data1");
        FederatedStatsResult r2 = createResultPo(2L, 2L, "final", "data2");
        when(federatedStatsRepository.selectResultsByTaskId(1L)).thenReturn(Collections.singletonList(r1));
        when(federatedStatsRepository.selectResultsByTaskId(2L)).thenReturn(Collections.singletonList(r2));

        federatedStatsService.batchExportResult(req, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("stats_batch_export"));
        verify(federatedStatsRepository, times(2)).selectResultsByTaskId(any());
    }

    // ==================== storageConfig ====================

    @Test
    public void getStorageConfig_returnsConfigList() {
        FederatedStatsConfig config = new FederatedStatsConfig();
        config.setId(CONFIG_ID);
        config.setConfigName("OSS");
        when(federatedStatsRepository.selectConfigList(USER_ID)).thenReturn(Collections.singletonList(config));

        BaseResultEntity result = federatedStatsService.getStorageConfig(USER_ID);

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(1, list.size());
    }

    @Test
    public void saveStorageConfig_updateExisting_insertsNew() {
        StorageConfigReq req = new StorageConfigReq();
        req.setId(CONFIG_ID);
        req.setConfigName("S3");
        req.setStorageType("s3");
        req.setStoragePath("/data");
        req.setIsDefault(1);

        federatedStatsService.saveStorageConfig(req, USER_ID);

        verify(federatedStatsRepository).updateConfig(any());
    }

    @Test
    public void saveStorageConfig_newConfig_inserts() {
        StorageConfigReq req = new StorageConfigReq();
        req.setConfigName("MinIO");
        req.setStorageType("minio");

        federatedStatsService.saveStorageConfig(req, USER_ID);

        verify(federatedStatsRepository).insertConfig(any());
    }

    @Test
    public void testStorageConnection_alwaysReturnsConnected() {
        StorageConfigReq req = new StorageConfigReq();
        req.setConnectionJson("{}");

        BaseResultEntity result = federatedStatsService.testStorageConnection(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue((Boolean) map.get("connected"));
    }

    // ==================== getStoredResults / previewStoredResult / downloadStoredResult / deleteStoredResult ====================

    @Test
    public void getStoredResults_returnsEmptyList() {
        BaseResultEntity result = federatedStatsService.getStoredResults(1, 10, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0, map.get("total"));
        assertTrue(((List<?>) map.get("list")).isEmpty());
    }

    @Test
    public void previewStoredResult_returnsPreviewData() {
        // 补 mock: 无此 stub 时 selectResultById 返 null → DATA_QUERY_NULL, 预览走不到成功分支
        when(federatedStatsRepository.selectResultById(RESULT_ID))
                .thenReturn(createResultPo(RESULT_ID, TASK_ID, "final", "{\"key\":\"value\"}"));

        BaseResultEntity result = federatedStatsService.previewStoredResult(RESULT_ID, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("headers"));
        assertNotNull(map.get("rows"));
    }

    @Test
    public void downloadStoredResult_writesToResponse() {
        federatedStatsService.downloadStoredResult(RESULT_ID, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("result_" + RESULT_ID));
    }

    @Test
    public void deleteStoredResult_returnsSuccess() {
        BaseResultEntity result = federatedStatsService.deleteStoredResult(RESULT_ID);

        assertEquals(0, result.getCode().intValue());
    }

    // ==================== getStatisticsTypes ====================

    @Test
    public void getStatisticsTypes_returnsAllNineTypes() {
        BaseResultEntity result = federatedStatsService.getStatisticsTypes();

        assertEquals(0, result.getCode().intValue());
        List<?> types = (List<?>) result.getResult();
        assertEquals(9, types.size());

        List<String> typeKeys = new ArrayList<>();
        for (Object obj : types) {
            StatsTypeVO vo = (StatsTypeVO) obj;
            typeKeys.add(vo.getType());
        }
        assertTrue(typeKeys.contains("descriptive"));
        assertTrue(typeKeys.contains("group_by"));
        assertTrue(typeKeys.contains("conditional"));
        assertTrue(typeKeys.contains("proportion"));
        assertTrue(typeKeys.contains("t_test"));
        assertTrue(typeKeys.contains("f_test"));
        assertTrue(typeKeys.contains("chi_square"));
        assertTrue(typeKeys.contains("regression"));
        assertTrue(typeKeys.contains("correlation"));
    }

    @Test
    public void getStatisticsTypes_eachTypeHasNameAndDescription() {
        BaseResultEntity result = federatedStatsService.getStatisticsTypes();

        List<?> types = (List<?>) result.getResult();
        for (Object obj : types) {
            StatsTypeVO vo = (StatsTypeVO) obj;
            assertNotNull(vo.getType());
            assertNotNull(vo.getName());
            assertNotNull(vo.getIcon());
            assertNotNull(vo.getDescription());
        }
    }

    // ==================== getLogs / getLogDetail / exportLogs ====================

    @Test
    public void getLogs_returnsEmptyResult() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);

        BaseResultEntity result = federatedStatsService.getLogs(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0, map.get("total"));
    }

    @Test
    public void getLogDetail_returnsEmptyMap() {
        BaseResultEntity result = federatedStatsService.getLogDetail(1L);

        assertEquals(0, result.getCode().intValue());
        assertNotNull(result.getResult());
    }

    @Test
    public void exportLogs_writesToResponse() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        // 补 mock: 无日志时 exportLogs 走 writeExportError(application/json); 需返回非空日志才进 text/plain 分支
        Map<String, Object> logEntry = new HashMap<>();
        logEntry.put("level", "INFO");
        logEntry.put("message", "统计完成");
        when(federatedStatsRepository.selectLogList(any()))
                .thenReturn(Collections.singletonList(logEntry));

        federatedStatsService.exportLogs(req, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("stats_log.txt"));
    }

    // ==================== simulateStatsResult (via async execution) ====================

    @Test
    public void runTask_asyncExecution_completesSuccessfully() throws Exception {
        FederatedStatsTask task = createTaskPo(TASK_ID, "async-task", "descriptive", 0);
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = federatedStatsService.runTask(TASK_ID, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedStatsRepository).updateTaskState(TASK_ID, 1, null, null);

        Thread.sleep(300);

        verify(federatedStatsRepository, atLeastOnce()).updateTaskState(eq(TASK_ID), any(), any(), any());
        verify(federatedStatsRepository, atLeastOnce()).insertResult(any());
    }

    @Test
    public void runTask_asyncExecution_descriptiveReturnsExpectedSummary() throws Exception {
        FederatedStatsTask task = createTaskPo(TASK_ID, "async-desc", "descriptive", 0);
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenReturn(task);

        federatedStatsService.runTask(TASK_ID, USER_ID);
        Thread.sleep(300);

        verify(federatedStatsRepository).updateTaskState(eq(TASK_ID), eq(2), argThat(s ->
            s != null && s.contains("均值") && s.contains("方差") && s.contains("标准差") && s.contains("中位数")
        ), eq(null));
    }

    // ==================== Edge Cases ====================

    @Test
    public void createTask_withAllStatsTypes_succeeds() {
        String[] validTypes = {"descriptive", "group_by", "conditional", "proportion",
            "t_test", "f_test", "chi_square", "regression", "correlation"};
        for (String type : validTypes) {
            FederatedStatsReq req = new FederatedStatsReq();
            req.setTaskName("task-" + type);
            req.setStatsType(type);
            federatedStatsService.createTask(req, USER_ID);
        }
        verify(federatedStatsRepository, times(9)).insertTask(any());
    }

    @Test
    public void deleteTask_repositoryException_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(federatedStatsRepository).deleteResultByTaskId(TASK_ID);

        BaseResultEntity result = federatedStatsService.deleteTask(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void createTask_repositoryException_returnsFailure() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("fail-task");
        req.setStatsType("descriptive");
        doThrow(new RuntimeException("DB error")).when(federatedStatsRepository).insertTask(any());

        BaseResultEntity result = federatedStatsService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskList_repositoryException_returnsFailure() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(federatedStatsRepository.selectTaskCount(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedStatsService.getTaskList(req);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetail_repositoryException_returnsFailure() {
        when(federatedStatsRepository.selectTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedStatsService.getTaskDetail(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }
}
