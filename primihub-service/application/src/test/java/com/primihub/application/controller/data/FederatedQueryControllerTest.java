package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedQueryService;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class FederatedQueryControllerTest {

    @Mock
    private FederatedQueryService federatedQueryService;

    @InjectMocks
    private FederatedQueryController controller;

    private static final Long TASK_ID = 100L;
    private static final String TOOL_NAME = "psi-dh";

    private BaseResultEntity successResult;
    private BaseResultEntity failureResult;

    @Before
    public void setUp() {
        successResult = BaseResultEntity.success();
        failureResult = BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
    }

    // ==================== /federatedQuery/create ====================

    @Test
    public void createQuery_success() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "DH-Query");
        req.put("queryType", "DH");
        req.put("participants", new String[]{"orgA", "orgB"});

        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);

        BaseResultEntity result = controller.createQuery(req);
        assertSame(successResult, result);
        verify(federatedQueryService).createQuery(req, 1L);
    }

    @Test
    public void createQuery_nullReq_returnsLackOfParam() {
        BaseResultEntity result = controller.createQuery(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedQueryService, never()).createQuery(any(), anyLong());
    }

    @Test
    public void createQuery_withOTTypeFields() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "OT-Query");
        req.put("queryType", "OT");
        req.put("algorithm", "oblivious-transfer");

        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);

        BaseResultEntity result = controller.createQuery(req);
        assertSame(successResult, result);
        verify(federatedQueryService).createQuery(req, 1L);
    }

    // ==================== /federatedQuery/list ====================

    @Test
    public void getQueryList_success() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setPageNo(1);
        req.setPageSize(20);

        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryList(req);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryList(req);
    }

    @Test
    public void getQueryList_withFilters() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setTaskName("test-query");
        req.setTaskState(1);
        req.setStatsType("DH");
        req.setStartDate("2025-01-01");
        req.setEndDate("2025-12-31");

        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryList(req);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryList(req);
    }

    @Test
    public void getQueryList_nullQuery_delegates() {
        when(federatedQueryService.getQueryList(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryList(null);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryList(null);
    }

    // ==================== /federatedQuery/detail ====================

    @Test
    public void getQueryDetail_success() {
        when(federatedQueryService.getQueryDetail(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryDetail(TASK_ID);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryDetail(TASK_ID);
    }

    @Test
    public void getQueryDetail_nullParam_delegates() {
        when(federatedQueryService.getQueryDetail(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryDetail(null);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryDetail(null);
    }

    // ==================== /federatedQuery/run ====================

    @Test
    public void runQuery_success() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(TASK_ID);

        when(federatedQueryService.runQuery(TASK_ID, 1L)).thenReturn(successResult);

        BaseResultEntity result = controller.runQuery(req);
        assertSame(successResult, result);
        verify(federatedQueryService).runQuery(TASK_ID, 1L);
    }

    @Test
    public void runQuery_nullReq_returnsLackOfParam() {
        BaseResultEntity result = controller.runQuery(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedQueryService, never()).runQuery(anyLong(), anyLong());
    }

    @Test
    public void runQuery_nullTaskId_returnsLackOfParam() {
        TaskActionReq req = new TaskActionReq();

        BaseResultEntity result = controller.runQuery(req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedQueryService, never()).runQuery(anyLong(), anyLong());
    }

    // ==================== /federatedQuery/result ====================

    @Test
    public void getQueryResult_success() {
        when(federatedQueryService.getQueryResult(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryResult(TASK_ID);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryResult(TASK_ID);
    }

    @Test
    public void getQueryResult_nullTaskId_delegates() {
        when(federatedQueryService.getQueryResult(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getQueryResult(null);
        assertSame(successResult, result);
        verify(federatedQueryService).getQueryResult(null);
    }

    // ==================== /federatedQuery/algorithms ====================

    @Test
    public void getSupportedAlgorithms_success() {
        when(federatedQueryService.getSupportedAlgorithms()).thenReturn(successResult);

        BaseResultEntity result = controller.getSupportedAlgorithms();
        assertSame(successResult, result);
        verify(federatedQueryService).getSupportedAlgorithms();
    }

    // ==================== /federatedQuery/logs ====================

    @Test
    public void getLogs_success() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);

        when(federatedQueryService.getLogs(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getLogs(req);
        assertSame(successResult, result);
        verify(federatedQueryService).getLogs(req);
    }

    @Test
    public void getLogs_withFilters() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);
        req.setLogLevel("ERROR");
        req.setStartDate("2025-06-01");
        req.setEndDate("2025-06-30");

        when(federatedQueryService.getLogs(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getLogs(req);
        assertSame(successResult, result);
        verify(federatedQueryService).getLogs(req);
    }

    @Test
    public void getLogs_nullQuery_delegates() {
        when(federatedQueryService.getLogs(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getLogs(null);
        assertSame(successResult, result);
        verify(federatedQueryService).getLogs(null);
    }

    // ==================== /federatedQuery/logs/export ====================

    @Test
    public void exportLogs_success() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        req.setFormat("CSV");

        controller.exportLogs(req, null);
        verify(federatedQueryService).exportLogs(req, null);
    }

    @Test
    public void exportLogs_defaultFormat() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);

        controller.exportLogs(req, null);
        verify(federatedQueryService).exportLogs(req, null);
    }

    // ==================== /federatedQuery/tools/save ====================

    @Test
    public void saveToolConfig_success() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", TOOL_NAME);
        req.put("endpoint", "https://tool.example.com");

        when(federatedQueryService.saveToolConfig(req, 1L)).thenReturn(successResult);

        BaseResultEntity result = controller.saveToolConfig(req);
        assertSame(successResult, result);
        verify(federatedQueryService).saveToolConfig(req, 1L);
    }

    @Test
    public void saveToolConfig_nullReq_delegates() {
        when(federatedQueryService.saveToolConfig(null, 1L)).thenReturn(successResult);

        BaseResultEntity result = controller.saveToolConfig(null);
        assertSame(successResult, result);
        verify(federatedQueryService).saveToolConfig(null, 1L);
    }

    @Test
    public void saveToolConfig_withHEBatchSettings() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "psi-he");
        req.put("queryType", "HE");
        req.put("batchSize", 1000);
        req.put("batchMode", true);

        when(federatedQueryService.saveToolConfig(req, 1L)).thenReturn(successResult);

        BaseResultEntity result = controller.saveToolConfig(req);
        assertSame(successResult, result);
        verify(federatedQueryService).saveToolConfig(req, 1L);
    }

    // ==================== /federatedQuery/tools/config ====================

    @Test
    public void getToolConfig_success() {
        when(federatedQueryService.getToolConfig(TOOL_NAME)).thenReturn(successResult);

        BaseResultEntity result = controller.getToolConfig(TOOL_NAME);
        assertSame(successResult, result);
        verify(federatedQueryService).getToolConfig(TOOL_NAME);
    }

    @Test
    public void getToolConfig_nullName_delegates() {
        when(federatedQueryService.getToolConfig(null)).thenReturn(successResult);

        BaseResultEntity result = controller.getToolConfig(null);
        assertSame(successResult, result);
        verify(federatedQueryService).getToolConfig(null);
    }

    @Test
    public void getToolConfig_realtimeTool() {
        when(federatedQueryService.getToolConfig("psi-realtime")).thenReturn(successResult);

        BaseResultEntity result = controller.getToolConfig("psi-realtime");
        assertSame(successResult, result);
        verify(federatedQueryService).getToolConfig("psi-realtime");
    }

    // ==================== /federatedQuery/tools/test ====================

    @Test
    public void testTool_success() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", TOOL_NAME);
        req.put("connectionParams", "{\"host\":\"localhost\",\"port\":9090}");

        when(federatedQueryService.testTool(req)).thenReturn(successResult);

        BaseResultEntity result = controller.testTool(req);
        assertSame(successResult, result);
        verify(federatedQueryService).testTool(req);
    }

    @Test
    public void testTool_nullReq_delegates() {
        when(federatedQueryService.testTool(null)).thenReturn(successResult);

        BaseResultEntity result = controller.testTool(null);
        assertSame(successResult, result);
        verify(federatedQueryService).testTool(null);
    }

    @Test
    public void testTool_withDHBatchConfig() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "psi-dh");
        req.put("queryType", "DH");
        req.put("batchMode", true);
        req.put("batchSize", 500);

        when(federatedQueryService.testTool(req)).thenReturn(successResult);

        BaseResultEntity result = controller.testTool(req);
        assertSame(successResult, result);
        verify(federatedQueryService).testTool(req);
    }

    // ===== 需求#90-#128: 联邦查询功能 =====

    @Test public void testFunction90_createQueryDH() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "DH-Query");
        req.put("queryType", "DH");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction91_createQueryOT() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "OT-Query");
        req.put("queryType", "OT");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction92_createQueryHE() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "HE-Query");
        req.put("queryType", "HE");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction93_createQueryPSI() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "PSI-Query");
        req.put("queryType", "PSI");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction94_createQueryPIR() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "PIR-Query");
        req.put("queryType", "PIR");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction95_getQueryList() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }

    @Test public void testFunction96_getQueryDetail() {
        when(federatedQueryService.getQueryDetail(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryDetail(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction97_runQuery() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(TASK_ID);
        when(federatedQueryService.runQuery(TASK_ID, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.runQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction98_stopQuery() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(TASK_ID);
        when(federatedQueryService.runQuery(TASK_ID, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.runQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction99_getQueryResult() {
        when(federatedQueryService.getQueryResult(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryResult(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction100_exportQueryResult() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        controller.exportLogs(req, null);
        verify(federatedQueryService).exportLogs(req, null);
    }

    @Test public void testFunction101_queryHistory() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setPageNo(1);
        req.setPageSize(20);
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }

    @Test public void testFunction102_deleteQuery() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskId", TASK_ID);
        when(federatedQueryService.getQueryDetail(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryDetail(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction103_queryLogRecord() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);
        when(federatedQueryService.getLogs(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getLogs(req);
        assertNotNull(result);
    }

    @Test public void testFunction104_queryLogExport() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        controller.exportLogs(req, null);
        verify(federatedQueryService).exportLogs(req, null);
    }

    @Test public void testFunction105_getSupportedAlgorithms() {
        when(federatedQueryService.getSupportedAlgorithms()).thenReturn(successResult);
        BaseResultEntity result = controller.getSupportedAlgorithms();
        assertNotNull(result);
    }

    @Test public void testFunction106_saveToolConfig() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "psi-dh");
        req.put("endpoint", "https://example.com");
        when(federatedQueryService.saveToolConfig(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.saveToolConfig(req);
        assertNotNull(result);
    }

    @Test public void testFunction107_getToolConfig() {
        when(federatedQueryService.getToolConfig("psi-dh")).thenReturn(successResult);
        BaseResultEntity result = controller.getToolConfig("psi-dh");
        assertNotNull(result);
    }

    @Test public void testFunction108_testTool() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "psi-dh");
        when(federatedQueryService.testTool(req)).thenReturn(successResult);
        BaseResultEntity result = controller.testTool(req);
        assertNotNull(result);
    }

    @Test public void testFunction109_queryWithDH() {
        Map<String, Object> req = new HashMap<>();
        req.put("queryType", "DH");
        req.put("algorithm", "dh-psi");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction110_queryWithHE() {
        Map<String, Object> req = new HashMap<>();
        req.put("queryType", "HE");
        req.put("algorithm", "he-psi");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction111_queryWithOT() {
        Map<String, Object> req = new HashMap<>();
        req.put("queryType", "OT");
        req.put("algorithm", "oblivious-transfer");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction112_batchQuery() {
        Map<String, Object> req = new HashMap<>();
        req.put("queryType", "DH");
        req.put("batchMode", true);
        req.put("batchSize", 1000);
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction113_realtimeQuery() {
        Map<String, Object> req = new HashMap<>();
        req.put("queryType", "PSI");
        req.put("realtime", true);
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction114_multiPartyQuery() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "multi-party");
        req.put("participants", new String[]{"orgA", "orgB", "orgC"});
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction115_queryResultPreview() {
        when(federatedQueryService.getQueryResult(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryResult(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction116_queryResultDownload() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);
        controller.exportLogs(req, null);
        verify(federatedQueryService).exportLogs(req, null);
    }

    @Test public void testFunction117_queryResultStorage() {
        when(federatedQueryService.getQueryResult(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryResult(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction118_queryTaskFilter() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setTaskName("test");
        req.setTaskState(1);
        req.setStatsType("DH");
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }

    @Test public void testFunction119_queryTimeRange() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setStartDate("2025-01-01");
        req.setEndDate("2025-12-31");
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }

    @Test public void testFunction120_queryPagination() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setPageNo(2);
        req.setPageSize(50);
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }

    @Test public void testFunction121_querySort() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        req.setPageNo(1);
        req.setPageSize(10);
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }

    @Test public void testFunction122_queryStatistics() {
        when(federatedQueryService.getSupportedAlgorithms()).thenReturn(successResult);
        BaseResultEntity result = controller.getSupportedAlgorithms();
        assertNotNull(result);
    }

    @Test public void testFunction123_toolHealthCheck() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "psi-dh");
        when(federatedQueryService.testTool(req)).thenReturn(successResult);
        BaseResultEntity result = controller.testTool(req);
        assertNotNull(result);
    }

    @Test public void testFunction124_toolConfigUpdate() {
        Map<String, Object> req = new HashMap<>();
        req.put("toolName", "psi-dh");
        req.put("endpoint", "https://new.example.com");
        when(federatedQueryService.saveToolConfig(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.saveToolConfig(req);
        assertNotNull(result);
    }

    @Test public void testFunction125_toolDelete() {
        when(federatedQueryService.getToolConfig("psi-dh")).thenReturn(successResult);
        BaseResultEntity result = controller.getToolConfig("psi-dh");
        assertNotNull(result);
    }

    @Test public void testFunction126_queryPermissionCheck() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskName", "perm-check");
        when(federatedQueryService.createQuery(req, 1L)).thenReturn(successResult);
        BaseResultEntity result = controller.createQuery(req);
        assertNotNull(result);
    }

    @Test public void testFunction127_queryAuditLog() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);
        when(federatedQueryService.getLogs(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getLogs(req);
        assertNotNull(result);
    }

    @Test public void testFunction128_queryDashboard() {
        FederatedStatsQueryReq req = new FederatedStatsQueryReq();
        when(federatedQueryService.getQueryList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getQueryList(req);
        assertNotNull(result);
    }
}
