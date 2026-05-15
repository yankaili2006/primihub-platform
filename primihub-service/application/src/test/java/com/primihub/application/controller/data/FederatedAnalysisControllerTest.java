package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.FederatedAnalysisService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import javax.servlet.http.HttpServletResponse;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class FederatedAnalysisControllerTest {

    @Mock
    private FederatedAnalysisService federatedAnalysisService;

    @InjectMocks
    private FederatedAnalysisController controller;

    // ==================== SQL 操作 (需求#142-#144) ====================

    @Test
    public void validateSql_WithValidRequest_ReturnsSuccess() {
        SqlValidateReq req = new SqlValidateReq();
        req.setSql("SELECT * FROM table");
        when(federatedAnalysisService.validateSql(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.validateSql(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).validateSql(req);
    }

    @Test
    public void validateSql_WhenServiceFails_ReturnsFailure() {
        SqlValidateReq req = new SqlValidateReq();
        when(federatedAnalysisService.validateSql(req)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_RUN_SQL_CHECK_FAIL));

        BaseResultEntity result = controller.validateSql(req);

        assertEquals(1008, result.getCode().intValue());
        verify(federatedAnalysisService).validateSql(req);
    }

    @Test
    public void formatSql_WithValidRequest_ReturnsSuccess() {
        SqlFormatReq req = new SqlFormatReq();
        req.setSql("SELECT * FROM table");
        when(federatedAnalysisService.formatSql(req)).thenReturn(BaseResultEntity.success("formatted sql"));

        BaseResultEntity result = controller.formatSql(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("formatted sql", result.getResult());
        verify(federatedAnalysisService).formatSql(req);
    }

    @Test
    public void getFunctions_WithCategory_ReturnsFunctions() {
        when(federatedAnalysisService.getFunctions("math")).thenReturn(BaseResultEntity.success("math functions"));

        BaseResultEntity result = controller.getFunctions("math");

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getFunctions("math");
    }

    @Test
    public void getFunctions_WithoutCategory_ReturnsAllFunctions() {
        when(federatedAnalysisService.getFunctions(null)).thenReturn(BaseResultEntity.success("all functions"));

        BaseResultEntity result = controller.getFunctions(null);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getFunctions(null);
    }

    // ==================== 任务管理 (需求#145-#149) ====================

    @Test
    public void createTask_WithValidRequest_ReturnsSuccess() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("test task");
        when(federatedAnalysisService.createTask(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createTask(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).createTask(req, 1L);
    }

    @Test
    public void createTask_WithNullRequest_ReturnsLackOfParam() {
        BaseResultEntity result = controller.createTask(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getMessage(), result.getMsg());
        verify(federatedAnalysisService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_WhenServiceFails_ReturnsFailure() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("fail task");
        when(federatedAnalysisService.createTask(req, 1L)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL));

        BaseResultEntity result = controller.createTask(req);

        assertEquals(1007, result.getCode().intValue());
        verify(federatedAnalysisService).createTask(req, 1L);
    }

    @Test
    public void getTaskList_WithQuery_ReturnsTaskList() {
        AnalysisTaskQueryReq req = new AnalysisTaskQueryReq();
        req.setProjectId(1L);
        when(federatedAnalysisService.getTaskList(req)).thenReturn(BaseResultEntity.success("task list"));

        BaseResultEntity result = controller.getTaskList(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getTaskList(req);
    }

    @Test
    public void getTaskDetail_WithValidId_ReturnsTaskDetail() {
        when(federatedAnalysisService.getTaskDetail(1L)).thenReturn(BaseResultEntity.success("task detail"));

        BaseResultEntity result = controller.getTaskDetail(1L);

        assertEquals(0, result.getCode().intValue());
        assertEquals("task detail", result.getResult());
        verify(federatedAnalysisService).getTaskDetail(1L);
    }

    @Test
    public void getTaskDetail_WhenNotFound_ReturnsFailure() {
        when(federatedAnalysisService.getTaskDetail(999L)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL));

        BaseResultEntity result = controller.getTaskDetail(999L);

        assertEquals(1003, result.getCode().intValue());
        verify(federatedAnalysisService).getTaskDetail(999L);
    }

    @Test
    public void runTask_WithValidRequest_ReturnsSuccess() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(1L);
        when(federatedAnalysisService.runTask(1L, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.runTask(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).runTask(1L, 1L);
    }

    @Test
    public void runTask_WithNullRequest_ReturnsLackOfParam() {
        BaseResultEntity result = controller.runTask(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).runTask(anyLong(), anyLong());
    }

    @Test
    public void runTask_WithNullTaskId_ReturnsLackOfParam() {
        TaskActionReq req = new TaskActionReq();

        BaseResultEntity result = controller.runTask(req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).runTask(anyLong(), anyLong());
    }

    @Test
    public void stopTask_WithValidRequest_ReturnsSuccess() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(1L);
        when(federatedAnalysisService.stopTask(1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.stopTask(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).stopTask(1L);
    }

    @Test
    public void stopTask_WithNullRequest_ReturnsLackOfParam() {
        BaseResultEntity result = controller.stopTask(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).stopTask(anyLong());
    }

    @Test
    public void stopTask_WithNullTaskId_ReturnsLackOfParam() {
        TaskActionReq req = new TaskActionReq();

        BaseResultEntity result = controller.stopTask(req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).stopTask(anyLong());
    }

    // ==================== 数据源管理 (需求#150-#155) ====================

    @Test
    public void getDataSourceList_WithSourceType_ReturnsList() {
        when(federatedAnalysisService.getDataSourceList("mysql")).thenReturn(
                BaseResultEntity.success("datasource list"));

        BaseResultEntity result = controller.getDataSourceList("mysql");

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getDataSourceList("mysql");
    }

    @Test
    public void getDataSourceList_WithoutSourceType_ReturnsAll() {
        when(federatedAnalysisService.getDataSourceList(null)).thenReturn(
                BaseResultEntity.success("all datasources"));

        BaseResultEntity result = controller.getDataSourceList(null);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getDataSourceList(null);
    }

    @Test
    public void createDataSource_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("test-ds");
        when(federatedAnalysisService.createDataSource(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createDataSource(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).createDataSource(req, 1L);
    }

    @Test
    public void createDataSource_WithNullRequest_ReturnsLackOfParam() {
        BaseResultEntity result = controller.createDataSource(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).createDataSource(any(), anyLong());
    }

    @Test
    public void createDataSource_WhenServiceFails_ReturnsFailure() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("fail-ds");
        when(federatedAnalysisService.createDataSource(req, 1L)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL));

        BaseResultEntity result = controller.createDataSource(req);

        assertEquals(1001, result.getCode().intValue());
        verify(federatedAnalysisService).createDataSource(req, 1L);
    }

    @Test
    public void updateDataSource_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setId(1L);
        when(federatedAnalysisService.updateDataSource(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.updateDataSource(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).updateDataSource(req);
    }

    @Test
    public void updateDataSource_WhenServiceFails_ReturnsFailure() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        when(federatedAnalysisService.updateDataSource(req)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL));

        BaseResultEntity result = controller.updateDataSource(req);

        assertEquals(1002, result.getCode().intValue());
        verify(federatedAnalysisService).updateDataSource(req);
    }

    @Test
    public void deleteDataSource_WithValidRequest_ReturnsSuccess() {
        IdReq req = new IdReq();
        req.setId(1L);
        when(federatedAnalysisService.deleteDataSource(1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deleteDataSource(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).deleteDataSource(1L);
    }

    @Test
    public void deleteDataSource_WithNullRequest_ReturnsLackOfParam() {
        BaseResultEntity result = controller.deleteDataSource(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).deleteDataSource(anyLong());
    }

    @Test
    public void deleteDataSource_WithNullId_ReturnsLackOfParam() {
        IdReq req = new IdReq();

        BaseResultEntity result = controller.deleteDataSource(req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedAnalysisService, never()).deleteDataSource(anyLong());
    }

    @Test
    public void deleteDataSource_WhenServiceFails_ReturnsFailure() {
        IdReq req = new IdReq();
        req.setId(2L);
        when(federatedAnalysisService.deleteDataSource(2L)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL));

        BaseResultEntity result = controller.deleteDataSource(req);

        assertEquals(1006, result.getCode().intValue());
        verify(federatedAnalysisService).deleteDataSource(2L);
    }

    @Test
    public void testDataSourceConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceConfig("{}");
        when(federatedAnalysisService.testDataSourceConnection(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.testDataSourceConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).testDataSourceConnection(req);
    }

    @Test
    public void getDataSourceTables_WithValidId_ReturnsTables() {
        when(federatedAnalysisService.getDataSourceTables(1L)).thenReturn(BaseResultEntity.success("tables"));

        BaseResultEntity result = controller.getDataSourceTables(1L);

        assertEquals(0, result.getCode().intValue());
        assertEquals("tables", result.getResult());
        verify(federatedAnalysisService).getDataSourceTables(1L);
    }

    @Test
    public void getDataSourceTables_WhenNotFound_ReturnsFailure() {
        when(federatedAnalysisService.getDataSourceTables(999L)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL));

        BaseResultEntity result = controller.getDataSourceTables(999L);

        assertEquals(1003, result.getCode().intValue());
        verify(federatedAnalysisService).getDataSourceTables(999L);
    }

    @Test
    public void getTableColumns_WithValidParams_ReturnsColumns() {
        when(federatedAnalysisService.getTableColumns(1L, "users")).thenReturn(BaseResultEntity.success("columns"));

        BaseResultEntity result = controller.getTableColumns(1L, "users");

        assertEquals(0, result.getCode().intValue());
        assertEquals("columns", result.getResult());
        verify(federatedAnalysisService).getTableColumns(1L, "users");
    }

    // ==================== RDBMS (需求#156) ====================

    @Test
    public void getSupportedRdbms_ReturnsTypes() {
        when(federatedAnalysisService.getSupportedRdbms()).thenReturn(BaseResultEntity.success("rdbms types"));

        BaseResultEntity result = controller.getSupportedRdbms();

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getSupportedRdbms();
    }

    @Test
    public void createRdbmsConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("rdbms-ds");
        when(federatedAnalysisService.createDataSource(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createRdbmsConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).createDataSource(req, 1L);
    }

    @Test
    public void testRdbmsConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        when(federatedAnalysisService.testDataSourceConnection(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.testRdbmsConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).testDataSourceConnection(req);
    }

    // ==================== BigData (需求#157-#158) ====================

    @Test
    public void getSupportedBigDataPlatforms_ReturnsTypes() {
        when(federatedAnalysisService.getSupportedBigDataPlatforms()).thenReturn(
                BaseResultEntity.success("bigdata types"));

        BaseResultEntity result = controller.getSupportedBigDataPlatforms();

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getSupportedBigDataPlatforms();
    }

    @Test
    public void createBigDataConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("bigdata-ds");
        when(federatedAnalysisService.createDataSource(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createBigDataConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).createDataSource(req, 1L);
    }

    @Test
    public void testBigDataConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        when(federatedAnalysisService.testDataSourceConnection(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.testBigDataConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).testDataSourceConnection(req);
    }

    // ==================== Cloud (需求#159-#161) ====================

    @Test
    public void getSupportedCloudPlatforms_ReturnsTypes() {
        when(federatedAnalysisService.getSupportedCloudPlatforms()).thenReturn(
                BaseResultEntity.success("cloud types"));

        BaseResultEntity result = controller.getSupportedCloudPlatforms();

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getSupportedCloudPlatforms();
    }

    @Test
    public void createCloudConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("cloud-ds");
        when(federatedAnalysisService.createDataSource(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createCloudConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).createDataSource(req, 1L);
    }

    @Test
    public void testCloudConnection_WithValidRequest_ReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        when(federatedAnalysisService.testDataSourceConnection(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.testCloudConnection(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).testDataSourceConnection(req);
    }

    // ==================== 日志 (需求#162-#164) ====================

    @Test
    public void getLogs_WithQuery_ReturnsLogs() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(1L);
        when(federatedAnalysisService.getLogs(req)).thenReturn(BaseResultEntity.success("logs"));

        BaseResultEntity result = controller.getLogs(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("logs", result.getResult());
        verify(federatedAnalysisService).getLogs(req);
    }

    @Test
    public void getLogs_WhenServiceFails_ReturnsFailure() {
        LogQueryReq req = new LogQueryReq();
        when(federatedAnalysisService.getLogs(req)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_LOG_FAIL));

        BaseResultEntity result = controller.getLogs(req);

        assertEquals(1012, result.getCode().intValue());
        verify(federatedAnalysisService).getLogs(req);
    }

    @Test
    public void exportLogs_WithValidRequest_CallsService() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(1L);
        HttpServletResponse response = mock(HttpServletResponse.class);
        doNothing().when(federatedAnalysisService).exportLogs(req, response);

        controller.exportLogs(req, response);

        verify(federatedAnalysisService).exportLogs(req, response);
    }

    @Test
    public void batchExportLogs_WithValidRequest_CallsService() {
        BatchExportReq req = new BatchExportReq();
        HttpServletResponse response = mock(HttpServletResponse.class);
        doNothing().when(federatedAnalysisService).batchExportLogs(req, response);

        controller.batchExportLogs(req, response);

        verify(federatedAnalysisService).batchExportLogs(req, response);
    }

    // ==================== 兼容端点 (需求#165-#173) ====================

    @Test
    public void validateSqlCompat_WithValidRequest_ReturnsSuccess() {
        SqlValidateReq req = new SqlValidateReq();
        req.setSql("SELECT 1");
        when(federatedAnalysisService.validateSql(req)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.validateSqlCompat(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).validateSql(req);
    }

    @Test
    public void createTaskCompat_WithValidRequest_ReturnsSuccess() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("compat task");
        when(federatedAnalysisService.createTask(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createTaskCompat(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).createTask(req, 1L);
    }

    @Test
    public void getTaskListCompat_ReturnsTaskList() {
        AnalysisTaskQueryReq req = new AnalysisTaskQueryReq();
        when(federatedAnalysisService.getTaskList(req)).thenReturn(BaseResultEntity.success("list"));

        BaseResultEntity result = controller.getTaskListCompat(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getTaskList(req);
    }

    @Test
    public void getTaskDetailCompat_WithValidId_ReturnsDetail() {
        when(federatedAnalysisService.getTaskDetail(99L)).thenReturn(BaseResultEntity.success("detail"));

        BaseResultEntity result = controller.getTaskDetailCompat(99L);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getTaskDetail(99L);
    }

    @Test
    public void runTaskCompat_WithValidRequest_ReturnsSuccess() {
        TaskActionReq req = new TaskActionReq();
        req.setTaskId(5L);
        when(federatedAnalysisService.runTask(5L, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.runTaskCompat(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).runTask(5L, 1L);
    }

    @Test
    public void getDataSourceListCompat_WithSourceType_ReturnsList() {
        when(federatedAnalysisService.getDataSourceList("postgres")).thenReturn(
                BaseResultEntity.success("compat list"));

        BaseResultEntity result = controller.getDataSourceListCompat("postgres");

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getDataSourceList("postgres");
    }

    @Test
    public void getLogsCompat_WithQuery_ReturnsLogs() {
        LogQueryReq req = new LogQueryReq();
        when(federatedAnalysisService.getLogs(req)).thenReturn(BaseResultEntity.success("compat logs"));

        BaseResultEntity result = controller.getLogsCompat(req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedAnalysisService).getLogs(req);
    }

    @Test
    public void exportLogsCompat_WithValidRequest_CallsService() {
        LogExportReq req = new LogExportReq();
        HttpServletResponse response = mock(HttpServletResponse.class);
        doNothing().when(federatedAnalysisService).exportLogs(req, response);

        controller.exportLogsCompat(req, response);

        verify(federatedAnalysisService).exportLogs(req, response);
    }
}
