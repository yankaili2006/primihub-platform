package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedStatsService;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class FederatedStatsControllerTest {

    @Mock
    private FederatedStatsService federatedStatsService;

    @InjectMocks
    private FederatedStatsController controller;

    private MockHttpServletResponse response;

    private static final Long TEST_USER_ID = 1L;
    private static final Long TASK_ID = 100L;
    private static final Long RESULT_ID = 200L;
    private static final Long CONFIG_ID = 300L;
    private static final Long LOG_ID = 400L;

    private BaseResultEntity successResult;
    private BaseResultEntity failureResult;

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
        successResult = BaseResultEntity.success();
        failureResult = BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
    }

    // ==================== createTask ====================

    @Test
    public void createTask_success() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("test-task");
        req.setStatsType("CORRELATION");

        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.createTask(req);
        assertSame(successResult, result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test
    public void createTask_nullReq_returnsLackOfParam() {
        BaseResultEntity result = controller.createTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).createTask(any(), anyLong());
    }

    // ==================== getTaskList ====================

    @Test
    public void getTaskList_success() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setPageNo(1);
        req.setPageSize(20);

        when(federatedStatsService.getTaskList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getTaskList(req);
        assertSame(successResult, result);
        verify(federatedStatsService).getTaskList(req);
    }

    @Test
    public void getTaskList_nullQuery_usesDefaults() {
        when(federatedStatsService.getTaskList(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getTaskList(null);
        assertSame(successResult, result);
        verify(federatedStatsService).getTaskList(null);
    }

    // ==================== getTaskDetail ====================

    @Test
    public void getTaskDetail_success() {
        when(federatedStatsService.getTaskDetail(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getTaskDetail(TASK_ID);
        assertSame(successResult, result);
        verify(federatedStatsService).getTaskDetail(TASK_ID);
    }

    @Test
    public void getTaskDetail_nullParam_stillDelegates() {
        when(federatedStatsService.getTaskDetail(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getTaskDetail(null);
        assertSame(successResult, result);
        verify(federatedStatsService).getTaskDetail(null);
    }

    // ==================== runTask ====================

    @Test
    public void runTask_success() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(TASK_ID);

        when(federatedStatsService.runTask(TASK_ID, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.runTask(req);
        assertSame(successResult, result);
        verify(federatedStatsService).runTask(TASK_ID, TEST_USER_ID);
    }

    @Test
    public void runTask_nullReq_returnsLackOfParam() {
        BaseResultEntity result = controller.runTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).runTask(anyLong(), anyLong());
    }

    @Test
    public void runTask_nullTaskId_returnsLackOfParam() {
        TaskActionReq req = new TaskActionReq();

        BaseResultEntity result = controller.runTask(req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).runTask(anyLong(), anyLong());
    }

    // ==================== stopTask ====================

    @Test
    public void stopTask_success() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(TASK_ID);

        when(federatedStatsService.stopTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.stopTask(req);
        assertSame(successResult, result);
        verify(federatedStatsService).stopTask(TASK_ID);
    }

    @Test
    public void stopTask_nullReq_returnsLackOfParam() {
        BaseResultEntity result = controller.stopTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).stopTask(anyLong());
    }

    // ==================== deleteTask ====================

    @Test
    public void deleteTask_withRequestParam() {
        when(federatedStatsService.deleteTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.deleteTask(TASK_ID, null);
        assertSame(successResult, result);
        verify(federatedStatsService).deleteTask(TASK_ID);
    }

    @Test
    public void deleteTask_withIdReqBody() {
        IdReq req = new IdReq();
        req.setId(TASK_ID);

        when(federatedStatsService.deleteTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.deleteTask(null, req);
        assertSame(successResult, result);
        verify(federatedStatsService).deleteTask(TASK_ID);
    }

    @Test
    public void deleteTask_requestParamTakesPrecedence() {
        IdReq req = new IdReq();
        req.setId(999L);

        when(federatedStatsService.deleteTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.deleteTask(TASK_ID, req);
        assertSame(successResult, result);
        verify(federatedStatsService).deleteTask(TASK_ID);
    }

    @Test
    public void deleteTask_noIdentifiers_returnsLackOfParam() {
        BaseResultEntity result = controller.deleteTask(null, null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).deleteTask(anyLong());
    }

    @Test
    public void deleteTask_emptyIdReq_returnsLackOfParam() {
        BaseResultEntity result = controller.deleteTask(null, new IdReq());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).deleteTask(anyLong());
    }

    // ==================== getResult ====================

    @Test
    public void getResult_success() {
        when(federatedStatsService.getResult(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getResult(TASK_ID);
        assertSame(successResult, result);
        verify(federatedStatsService).getResult(TASK_ID);
    }

    @Test
    public void getResult_nullTaskId_delegates() {
        when(federatedStatsService.getResult(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getResult(null);
        assertSame(successResult, result);
        verify(federatedStatsService).getResult(null);
    }

    // ==================== saveResult ====================

    @Test
    public void saveResult_success() {
        SaveResultReq req = new SaveResultReq();
        req.setTaskId(TASK_ID);
        req.setStorageConfigId(CONFIG_ID);

        when(federatedStatsService.saveResult(req, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.saveResult(req);
        assertSame(successResult, result);
        verify(federatedStatsService).saveResult(req, TEST_USER_ID);
    }

    @Test
    public void saveResult_nullReq_returnsLackOfParam() {
        BaseResultEntity result = controller.saveResult(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).saveResult(any(), anyLong());
    }

    // ==================== exportResult ====================

    @Test
    public void exportResult_defaultFormat() {
        controller.exportResult(TASK_ID, "TXT", response);
        verify(federatedStatsService).exportResult(TASK_ID, "TXT", response);
    }

    @Test
    public void exportResult_customFormat() {
        controller.exportResult(TASK_ID, "CSV", response);
        verify(federatedStatsService).exportResult(TASK_ID, "CSV", response);
    }

    // ==================== batchExportResult ====================

    @Test
    public void batchExportResult_success() {
        BatchExportReq req = new BatchExportReq();
        req.setFormat("CSV");

        controller.batchExportResult(req, response);
        verify(federatedStatsService).batchExportResult(req, response);
    }

    // ==================== getStorageConfig ====================

    @Test
    public void getStorageConfig_success() {
        when(federatedStatsService.getStorageConfig(TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getStorageConfig();
        assertSame(successResult, result);
        verify(federatedStatsService).getStorageConfig(TEST_USER_ID);
    }

    // ==================== saveStorageConfig ====================

    @Test
    public void saveStorageConfig_success() {
        StorageConfigReq req = new StorageConfigReq();
        req.setConfigName("OSS-Config");

        when(federatedStatsService.saveStorageConfig(req, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.saveStorageConfig(req);
        assertSame(successResult, result);
        verify(federatedStatsService).saveStorageConfig(req, TEST_USER_ID);
    }

    // ==================== testStorageConnection ====================

    @Test
    public void testStorageConnection_success() {
        StorageConfigReq req = new StorageConfigReq();
        req.setConnectionJson("{\"endpoint\":\"http://oss.example.com\"}");

        when(federatedStatsService.testStorageConnection(req)).thenReturn(successResult);

        BaseResultEntity result = controller.testStorageConnection(req);
        assertSame(successResult, result);
        verify(federatedStatsService).testStorageConnection(req);
    }

    @Test
    public void testStorageConnection_nullReq_delegates() {
        when(federatedStatsService.testStorageConnection(null)).thenReturn(successResult);

        BaseResultEntity result = controller.testStorageConnection(null);
        assertSame(successResult, result);
        verify(federatedStatsService).testStorageConnection(null);
    }

    // ==================== getStoredResults ====================

    @Test
    public void getStoredResults_defaultPagination() {
        when(federatedStatsService.getStoredResults(1, 10, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getStoredResults(null, null);
        assertSame(successResult, result);
        verify(federatedStatsService).getStoredResults(1, 10, TEST_USER_ID);
    }

    @Test
    public void getStoredResults_customPagination() {
        when(federatedStatsService.getStoredResults(3, 25, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getStoredResults(3, 25);
        assertSame(successResult, result);
        verify(federatedStatsService).getStoredResults(3, 25, TEST_USER_ID);
    }

    // ==================== previewStoredResult ====================

    @Test
    public void previewStoredResult_success() {
        when(federatedStatsService.previewStoredResult(RESULT_ID, 10)).thenReturn(successResult);

        BaseResultEntity result = controller.previewStoredResult(RESULT_ID, 10);
        assertSame(successResult, result);
        verify(federatedStatsService).previewStoredResult(RESULT_ID, 10);
    }

    @Test
    public void previewStoredResult_defaultRows() {
        when(federatedStatsService.previewStoredResult(RESULT_ID, 10)).thenReturn(successResult);

        BaseResultEntity result = controller.previewStoredResult(RESULT_ID, null);
        assertSame(successResult, result);
        verify(federatedStatsService).previewStoredResult(RESULT_ID, 10);
    }

    // ==================== downloadStoredResult ====================

    @Test
    public void downloadStoredResult_success() {
        controller.downloadStoredResult(RESULT_ID, response);
        verify(federatedStatsService).downloadStoredResult(RESULT_ID, response);
    }

    // ==================== deleteStoredResult ====================

    @Test
    public void deleteStoredResult_success() {
        when(federatedStatsService.deleteStoredResult(RESULT_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.deleteStoredResult(RESULT_ID);
        assertSame(successResult, result);
        verify(federatedStatsService).deleteStoredResult(RESULT_ID);
    }

    @Test
    public void deleteStoredResult_nullParam_delegates() {
        when(federatedStatsService.deleteStoredResult(null)).thenReturn(successResult);

        BaseResultEntity result = controller.deleteStoredResult(null);
        assertSame(successResult, result);
        verify(federatedStatsService).deleteStoredResult(null);
    }

    // ==================== getLogs ====================

    @Test
    public void getLogs_success() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);

        when(federatedStatsService.getLogs(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getLogs(req);
        assertSame(successResult, result);
        verify(federatedStatsService).getLogs(req);
    }

    @Test
    public void getLogs_nullQuery_delegates() {
        when(federatedStatsService.getLogs(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getLogs(null);
        assertSame(successResult, result);
        verify(federatedStatsService).getLogs(null);
    }

    // ==================== getLogDetail ====================

    @Test
    public void getLogDetail_success() {
        when(federatedStatsService.getLogDetail(LOG_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getLogDetail(LOG_ID);
        assertSame(successResult, result);
        verify(federatedStatsService).getLogDetail(LOG_ID);
    }

    // ==================== exportLogs ====================

    @Test
    public void exportLogs_success() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        req.setFormat("CSV");

        controller.exportLogs(req, response);
        verify(federatedStatsService).exportLogs(req, response);
    }

    // ==================== getStatisticsTypes ====================

    @Test
    public void getStatisticsTypes_success() {
        when(federatedStatsService.getStatisticsTypes()).thenReturn(successResult);

        BaseResultEntity result = controller.getStatisticsTypes();
        assertSame(successResult, result);
        verify(federatedStatsService).getStatisticsTypes();
    }

    // ==================== Compat endpoints (delegation verification) ====================

    @Test
    public void createTaskCompat_delegatesToCreateTask() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("compat-task");

        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.createTaskCompat(req);
        assertSame(successResult, result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test
    public void getTaskListCompat_delegatesToGetTaskList() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(federatedStatsService.getTaskList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getTaskListCompat(req);
        assertSame(successResult, result);
        verify(federatedStatsService).getTaskList(req);
    }

    @Test
    public void runTaskCompat_delegatesToRunTask() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(TASK_ID);

        when(federatedStatsService.runTask(TASK_ID, TEST_USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.runTaskCompat(req);
        assertSame(successResult, result);
        verify(federatedStatsService).runTask(TASK_ID, TEST_USER_ID);
    }

    @Test
    public void getResultCompat_delegatesToGetResult() {
        when(federatedStatsService.getResult(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getResultCompat(TASK_ID);
        assertSame(successResult, result);
        verify(federatedStatsService).getResult(TASK_ID);
    }

    @Test
    public void deleteTaskCompat_delegatesToDeleteTask() {
        IdReq req = new IdReq();
        req.setId(TASK_ID);

        when(federatedStatsService.deleteTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.deleteTaskCompat(req);
        assertSame(successResult, result);
        verify(federatedStatsService).deleteTask(TASK_ID);
    }

    @Test
    public void deleteTaskCompat_nullIdReq_returnsLackOfParam() {
        BaseResultEntity result = controller.deleteTaskCompat(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedStatsService, never()).deleteTask(anyLong());
    }

    @Test
    public void compatibility_endpointsAreWired() {
        assertNotNull(controller.getClass().getDeclaredMethod("createTaskCompat", FederatedStatsReq.class));
        assertNotNull(controller.getClass().getDeclaredMethod("getTaskListCompat", FederatedStatsQueryReq.class));
        assertNotNull(controller.getClass().getDeclaredMethod("runTaskCompat", TaskActionReq.class));
        assertNotNull(controller.getClass().getDeclaredMethod("getResultCompat", Long.class));
        assertNotNull(controller.getClass().getDeclaredMethod("deleteTaskCompat", IdReq.class));
    }

    // ===== 需求#129-#141: 联邦统计功能 =====

    @Test public void testFunction129_descriptiveStats() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("描述性统计测试");
        req.setStatsType("descriptive");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction130_groupStats() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("分组统计测试");
        req.setStatsType("group");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction131_conditionStats() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("条件统计测试");
        req.setStatsType("condition");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction132_ratioStats() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("占比统计测试");
        req.setStatsType("ratio");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction133_tTest() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("T检验测试");
        req.setStatsType("ttest");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction134_fTest() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("F检验测试");
        req.setStatsType("ftest");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction135_chiSquareTest() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("卡方检验测试");
        req.setStatsType("chisquare");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction136_regressionAnalysis() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("回归分析测试");
        req.setStatsType("regression");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction137_correlationAnalysis() {
        FederatedStatsReq req = new FederatedStatsReq();
        req.setTaskName("相关性分析测试");
        req.setStatsType("correlation");
        when(federatedStatsService.createTask(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.createTask(req);
        assertNotNull(result);
        verify(federatedStatsService).createTask(req, TEST_USER_ID);
    }

    @Test public void testFunction138_resultStorage() {
        SaveResultReq req = new SaveResultReq();
        req.setTaskId(TASK_ID);
        req.setStorageConfigId(CONFIG_ID);
        when(federatedStatsService.saveResult(req, TEST_USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.saveResult(req);
        assertNotNull(result);
        verify(federatedStatsService).saveResult(req, TEST_USER_ID);
    }

    @Test public void testFunction139_resultExport() {
        controller.exportResult(TASK_ID, "CSV", response);
        verify(federatedStatsService).exportResult(TASK_ID, "CSV", response);
    }

    @Test public void testFunction140_logRecord() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);
        when(federatedStatsService.getLogs(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getLogs(req);
        assertNotNull(result);
        verify(federatedStatsService).getLogs(req);
    }

    @Test public void testFunction141_logExport() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        req.setFormat("CSV");
        controller.exportLogs(req, response);
        verify(federatedStatsService).exportLogs(req, response);
    }
}
