package com.primihub.biz.service.data.impl;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.FederatedAnalysisDatasource;
import com.primihub.biz.entity.data.po.FederatedAnalysisResult;
import com.primihub.biz.entity.data.po.FederatedAnalysisTask;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.data.vo.*;
import com.primihub.biz.repository.primarydb.data.FederatedAnalysisRepository;
import com.primihub.biz.service.data.analysis.SQLRewriteEngine;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.*;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.*;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class FederatedAnalysisServiceImplTest {

    @Mock
    private FederatedAnalysisRepository analysisRepository;

    @Mock
    private SQLRewriteEngine sqlRewriteEngine;

    @InjectMocks
    private FederatedAnalysisServiceImpl analysisService;

    @Captor
    private ArgumentCaptor<FederatedAnalysisTask> taskCaptor;

    @Captor
    private ArgumentCaptor<FederatedAnalysisDatasource> dsCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;
    private static final Long DS_ID = 50L;
    private static final Long PROJECT_ID = 10L;

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private FederatedAnalysisTask createTaskPo(Long id, String name, String sql, Integer state) {
        FederatedAnalysisTask task = new FederatedAnalysisTask();
        task.setId(id);
        task.setTaskName(name);
        task.setProjectId(PROJECT_ID);
        task.setSourceSql(sql);
        task.setRewrittenSql("-- rewritten\n" + sql);
        task.setTaskState(state);
        task.setCreatedBy(USER_ID);
        return task;
    }

    // ==================== validateSql ====================

    @Test
    public void validateSql_validSql_returnsSuccess() {
        SqlValidateReq req = new SqlValidateReq();
        req.setSql("SELECT * FROM users WHERE age > 18");
        req.setDataResources("ds1,ds2");

        SqlValidateVO vo = new SqlValidateVO();
        vo.setValid(true);
        vo.setMessage("校验通过");
        vo.setTables(Arrays.asList("USERS"));
        vo.setColumns(Arrays.asList("*"));
        when(sqlRewriteEngine.validate(req.getSql(), req.getDataResources())).thenReturn(vo);

        BaseResultEntity result = analysisService.validateSql(req);

        assertEquals(0, result.getCode().intValue());
        SqlValidateVO resultVo = (SqlValidateVO) result.getResult();
        assertTrue(resultVo.getValid());
        assertEquals("校验通过", resultVo.getMessage());
    }

    @Test
    public void validateSql_engineThrows_returnsFailure() {
        SqlValidateReq req = new SqlValidateReq();
        req.setSql("DROP TABLE users");
        when(sqlRewriteEngine.validate(req.getSql(), req.getDataResources()))
            .thenThrow(new RuntimeException("SQL注入风险"));

        BaseResultEntity result = analysisService.validateSql(req);

        assertEquals(BaseResultEnum.DATA_RUN_SQL_CHECK_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== formatSql ====================

    @Test
    public void formatSql_validSql_returnsFormatted() {
        SqlFormatReq req = new SqlFormatReq();
        req.setSql("SELECT a,b FROM t WHERE c=1");
        when(sqlRewriteEngine.format(req.getSql())).thenReturn("formatted sql");

        BaseResultEntity result = analysisService.formatSql(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals("formatted sql", map.get("formattedSql"));
    }

    @Test
    public void formatSql_engineThrows_returnsFailure() {
        SqlFormatReq req = new SqlFormatReq();
        req.setSql("invalid sql");
        when(sqlRewriteEngine.format(req.getSql())).thenThrow(new RuntimeException("format error"));

        BaseResultEntity result = analysisService.formatSql(req);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getFunctions ====================

    @Test
    public void getFunctions_withCategory_returnsFiltered() {
        List<FunctionDefVO> funcs = Arrays.asList(
            createFunction("string", "CONCAT", "字符串拼接", "CONCAT(a, b)")
        );
        when(sqlRewriteEngine.getFunctions("string")).thenReturn(funcs);

        BaseResultEntity result = analysisService.getFunctions("string");

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(1, list.size());
    }

    @Test
    public void getFunctions_withoutCategory_returnsAll() {
        List<FunctionDefVO> funcs = new ArrayList<>();
        when(sqlRewriteEngine.getFunctions(null)).thenReturn(funcs);

        BaseResultEntity result = analysisService.getFunctions(null);

        assertEquals(0, result.getCode().intValue());
    }

    private FunctionDefVO createFunction(String cat, String name, String desc, String example) {
        FunctionDefVO f = new FunctionDefVO();
        f.setCategory(cat);
        f.setName(name);
        f.setDescription(desc);
        f.setExample(example);
        return f;
    }

    // ==================== createTask ====================

    @Test
    public void createTask_withValidReq_returnsTaskIdAndRewrittenSql() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("analysis-task");
        req.setProjectId(PROJECT_ID);
        req.setSourceSql("SELECT * FROM users");
        Map<String, Object> params = new HashMap<>();
        params.put("limit", 100);
        req.setParams(params);

        when(sqlRewriteEngine.rewrite(req.getSourceSql(), null)).thenReturn("-- rewritten\nSELECT * FROM users_local");

        doAnswer(invocation -> {
            FederatedAnalysisTask task = invocation.getArgument(0);
            task.setId(TASK_ID);
            return null;
        }).when(analysisRepository).insertTask(taskCaptor.capture());

        BaseResultEntity result = analysisService.createTask(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(TASK_ID, map.get("taskId"));
        assertEquals("-- rewritten\nSELECT * FROM users_local", map.get("rewrittenSql"));

        FederatedAnalysisTask captured = taskCaptor.getValue();
        assertEquals("analysis-task", captured.getTaskName());
        assertEquals("SELECT * FROM users", captured.getSourceSql());
        assertEquals("-- rewritten\nSELECT * FROM users_local", captured.getRewrittenSql());
        assertEquals(0, captured.getTaskState().intValue());
    }

    @Test
    public void createTask_emptyName_returnsLackOfParam() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("");

        BaseResultEntity result = analysisService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(analysisRepository, never()).insertTask(any());
    }

    @Test
    public void createTask_nullName_returnsLackOfParam() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setSourceSql("SELECT 1");

        BaseResultEntity result = analysisService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(analysisRepository, never()).insertTask(any());
    }

    @Test
    public void createTask_emptySql_returnsLackOfParam() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("task");
        req.setSourceSql("");

        BaseResultEntity result = analysisService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(analysisRepository, never()).insertTask(any());
    }

    @Test
    public void createTask_nullParams_usesNullTaskParam() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("task");
        req.setProjectId(PROJECT_ID);
        req.setSourceSql("SELECT 1");

        when(sqlRewriteEngine.rewrite(req.getSourceSql(), null)).thenReturn("rewritten");
        doAnswer(invocation -> {
            ((FederatedAnalysisTask) invocation.getArgument(0)).setId(TASK_ID);
            return null;
        }).when(analysisRepository).insertTask(taskCaptor.capture());

        analysisService.createTask(req, USER_ID);

        assertNull(taskCaptor.getValue().getTaskParam());
    }

    // ==================== getTaskList ====================

    @Test
    public void getTaskList_returnsPaginatedResults() {
        AnalysisTaskQueryReq req = new AnalysisTaskQueryReq();
        req.setTaskName("test");
        req.setTaskState(2);
        req.setProjectId(PROJECT_ID);
        req.setPageNo(1);
        req.setPageSize(10);

        FederatedAnalysisTask task = createTaskPo(TASK_ID, "test-task", "SELECT 1", 2);
        task.setResultRowCount(500);

        when(analysisRepository.selectTaskCount(any())).thenReturn(1);
        when(analysisRepository.selectTaskList(any())).thenReturn(Collections.singletonList(task));

        BaseResultEntity result = analysisService.getTaskList(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(1, map.get("total"));
        List<?> list = (List<?>) map.get("list");
        assertEquals(1, list.size());
        AnalysisTaskListVO vo = (AnalysisTaskListVO) list.get(0);
        assertEquals("test-task", vo.getTaskName());
        assertEquals(2, vo.getTaskState().intValue());
        assertEquals("已完成", vo.getTaskStateName());
        assertEquals(Integer.valueOf(500), vo.getResultRowCount());
    }

    @Test
    public void getTaskList_empty_returnsEmptyList() {
        AnalysisTaskQueryReq req = new AnalysisTaskQueryReq();
        when(analysisRepository.selectTaskCount(any())).thenReturn(0);
        when(analysisRepository.selectTaskList(any())).thenReturn(Collections.emptyList());

        BaseResultEntity result = analysisService.getTaskList(req);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0, map.get("total"));
    }

    // ==================== getTaskDetail ====================

    @Test
    public void getTaskDetail_existingTask_returnsDetail() {
        FederatedAnalysisTask task = createTaskPo(TASK_ID, "detail-task", "SELECT * FROM t", 2);
        task.setRewrittenSql("-- rewritten\nSELECT * FROM t_local");
        task.setResultRowCount(500);
        FederatedAnalysisResult res = new FederatedAnalysisResult();
        res.setId(1L);
        res.setTaskId(TASK_ID);
        res.setResultType("final");

        when(analysisRepository.selectTaskById(TASK_ID)).thenReturn(task);
        when(analysisRepository.selectResultsByTaskId(TASK_ID)).thenReturn(Collections.singletonList(res));

        BaseResultEntity result = analysisService.getTaskDetail(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        AnalysisTaskDetailVO vo = (AnalysisTaskDetailVO) result.getResult();
        assertEquals(TASK_ID, vo.getId());
        assertEquals("detail-task", vo.getTaskName());
        assertEquals("SELECT * FROM t", vo.getSourceSql());
        assertEquals("-- rewritten\nSELECT * FROM t_local", vo.getRewrittenSql());
        assertEquals(2, vo.getTaskState().intValue());
        assertEquals("已完成", vo.getTaskStateName());
        assertEquals(Integer.valueOf(500), vo.getResultRowCount());
    }

    @Test
    public void getTaskDetail_notFound_returnsDataQueryNull() {
        when(analysisRepository.selectTaskById(999L)).thenReturn(null);

        BaseResultEntity result = analysisService.getTaskDetail(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(analysisRepository, never()).selectResultsByTaskId(any());
    }

    // ==================== runTask ====================

    @Test
    public void runTask_existingTask_updatesStateAndRunsAsync() {
        FederatedAnalysisTask task = createTaskPo(TASK_ID, "task", "SELECT 1", 0);
        when(analysisRepository.selectTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = analysisService.runTask(TASK_ID, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(analysisRepository).updateTaskState(TASK_ID, 1, null, null);
    }

    @Test
    public void runTask_nullTask_returnsDataQueryNull() {
        when(analysisRepository.selectTaskById(TASK_ID)).thenReturn(null);

        BaseResultEntity result = analysisService.runTask(TASK_ID, USER_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(analysisRepository, never()).updateTaskState(any(), any(), any(), any());
    }

    @Test
    public void runTask_asyncExecution_completesSuccessfully() throws Exception {
        FederatedAnalysisTask task = createTaskPo(TASK_ID, "async", "SELECT * FROM users", 0);
        when(analysisRepository.selectTaskById(TASK_ID)).thenReturn(task);

        analysisService.runTask(TASK_ID, USER_ID);
        Thread.sleep(400);

        verify(analysisRepository, atLeastOnce()).updateTaskState(eq(TASK_ID), any(), any(), any());
        verify(analysisRepository, atLeastOnce()).updateTaskRewrittenSql(eq(TASK_ID), anyString());
        verify(analysisRepository, atLeastOnce()).insertResult(any());
    }

    // ==================== stopTask ====================

    @Test
    public void stopTask_returnsSuccess() {
        BaseResultEntity result = analysisService.stopTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
    }

    // ==================== DataSource CRUD ====================

    @Test
    public void getDataSourceList_withType_returnsTransformedList() {
        FederatedAnalysisDatasource ds = new FederatedAnalysisDatasource();
        ds.setId(DS_ID);
        ds.setSourceName("MySQL-DS");
        ds.setSourceType("mysql");
        ds.setIsConnected(1);

        when(analysisRepository.selectDatasourceList(any())).thenReturn(Collections.singletonList(ds));

        BaseResultEntity result = analysisService.getDataSourceList("mysql");

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(1, list.size());
        DataSourceVO vo = (DataSourceVO) list.get(0);
        assertEquals("MySQL-DS", vo.getSourceName());
        assertEquals("mysql", vo.getSourceType());
        assertTrue(vo.getIsConnected());
    }

    @Test
    public void getDataSourceList_withoutType_returnsAll() {
        when(analysisRepository.selectDatasourceList(any())).thenReturn(Collections.emptyList());

        BaseResultEntity result = analysisService.getDataSourceList(null);

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertTrue(list.isEmpty());
    }

    @Test
    public void createDataSource_savesAndReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("New-DS");
        req.setSourceType("postgresql");
        req.setSourceConfig("{\"host\":\"localhost\"}");

        doAnswer(invocation -> {
            FederatedAnalysisDatasource ds = invocation.getArgument(0);
            ds.setId(DS_ID);
            return null;
        }).when(analysisRepository).insertDatasource(dsCaptor.capture());

        BaseResultEntity result = analysisService.createDataSource(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        FederatedAnalysisDatasource captured = dsCaptor.getValue();
        assertEquals("New-DS", captured.getSourceName());
        assertEquals("postgresql", captured.getSourceType());
        assertEquals("{\"host\":\"localhost\"}", captured.getSourceConfig());
        assertEquals(USER_ID, captured.getCreatedBy());
    }

    @Test
    public void updateDataSource_updatesAndReturnsSuccess() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setId(DS_ID);
        req.setSourceName("Updated-DS");
        req.setSourceType("oracle");

        BaseResultEntity result = analysisService.updateDataSource(req);

        assertEquals(0, result.getCode().intValue());
        verify(analysisRepository).updateDatasource(dsCaptor.capture());
        assertEquals(DS_ID, dsCaptor.getValue().getId());
        assertEquals("Updated-DS", dsCaptor.getValue().getSourceName());
    }

    @Test
    public void deleteDataSource_deletesAndReturnsSuccess() {
        BaseResultEntity result = analysisService.deleteDataSource(DS_ID);

        assertEquals(0, result.getCode().intValue());
        verify(analysisRepository).deleteDatasource(DS_ID);
    }

    // ==================== testDataSourceConnection ====================

    // ==================== getDataSourceTables ====================

    @Test
    public void getDataSourceTables_notFound_returnsDataQueryNull() {
        when(analysisRepository.selectDatasourceById(999L)).thenReturn(null);

        BaseResultEntity result = analysisService.getDataSourceTables(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void getDataSourceTables_repositoryThrows_returnsFailure() {
        when(analysisRepository.selectDatasourceById(DS_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = analysisService.getDataSourceTables(DS_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getTableColumns ====================

    @Test
    public void getTableColumns_dsNotFound_returnsDataQueryNull() {
        when(analysisRepository.selectDatasourceById(999L)).thenReturn(null);

        BaseResultEntity result = analysisService.getTableColumns(999L, "users");

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void getTableColumns_repositoryThrows_returnsFailure() {
        when(analysisRepository.selectDatasourceById(DS_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = analysisService.getTableColumns(DS_ID, "users");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getSupportedRdbms ====================

    @Test
    public void getSupportedRdbms_returnsFourTypes() {
        BaseResultEntity result = analysisService.getSupportedRdbms();

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(4, list.size());
        assertTrue(list.contains("MySQL"));
        assertTrue(list.contains("PostgreSQL"));
        assertTrue(list.contains("Oracle"));
        assertTrue(list.contains("SQL Server"));
    }

    // ==================== getSupportedBigDataPlatforms ====================

    @Test
    public void getSupportedBigDataPlatforms_returnsFourPlatforms() {
        BaseResultEntity result = analysisService.getSupportedBigDataPlatforms();

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(4, list.size());
        assertTrue(list.contains("Spark"));
        assertTrue(list.contains("Hive"));
        assertTrue(list.contains("Flink"));
        assertTrue(list.contains("Presto"));
    }

    // ==================== getSupportedCloudPlatforms ====================

    @Test
    public void getSupportedCloudPlatforms_returnsFourPlatforms() {
        BaseResultEntity result = analysisService.getSupportedCloudPlatforms();

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(4, list.size());
        assertTrue(list.contains("阿里云OSS"));
        assertTrue(list.contains("AWS S3"));
        assertTrue(list.contains("腾讯云COS"));
        assertTrue(list.contains("华为云OBS"));
    }

    // ==================== getLogs / exportLogs / batchExportLogs ====================

    @Test
    public void getLogs_returnsEmptyList() {
        LogQueryReq req = new LogQueryReq();
        req.setTaskId(TASK_ID);
        req.setLogLevel("ERROR");

        BaseResultEntity result = analysisService.getLogs(req);

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertTrue(list.isEmpty());
    }

    @Test
    public void exportLogs_writesToResponse() {
        LogExportReq req = new LogExportReq();
        req.setTaskId(TASK_ID);

        analysisService.exportLogs(req, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("analysis_log.txt"));
    }

    @Test
    public void batchExportLogs_writesToResponse() {
        BatchExportReq req = new BatchExportReq();
        req.setTaskIds(Arrays.asList(1L, 2L));

        analysisService.batchExportLogs(req, response);

        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("analysis_logs_batch"));
    }

    // ==================== Edge Cases & Exceptions ====================

    @Test
    public void getDataSourceList_repositoryThrows_returnsFailure() {
        when(analysisRepository.selectDatasourceList(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = analysisService.getDataSourceList("mysql");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void createDataSource_repositoryThrows_returnsFailure() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("fail-ds");
        doThrow(new RuntimeException("DB error")).when(analysisRepository).insertDatasource(any());

        BaseResultEntity result = analysisService.createDataSource(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void updateDataSource_repositoryThrows_returnsFailure() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setId(DS_ID);
        doThrow(new RuntimeException("DB error")).when(analysisRepository).updateDatasource(any());

        BaseResultEntity result = analysisService.updateDataSource(req);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void deleteDataSource_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(analysisRepository).deleteDatasource(DS_ID);

        BaseResultEntity result = analysisService.deleteDataSource(DS_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void createTask_repositoryThrows_returnsFailure() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("fail-task");
        req.setSourceSql("SELECT 1");
        when(sqlRewriteEngine.rewrite(req.getSourceSql(), null)).thenReturn("rewritten");
        doThrow(new RuntimeException("DB error")).when(analysisRepository).insertTask(any());

        BaseResultEntity result = analysisService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskList_repositoryThrows_returnsFailure() {
        AnalysisTaskQueryReq req = new AnalysisTaskQueryReq();
        when(analysisRepository.selectTaskCount(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = analysisService.getTaskList(req);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void runTask_repositoryThrows_returnsFailure() {
        when(analysisRepository.selectTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = analysisService.runTask(TASK_ID, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetail_repositoryThrows_returnsFailure() {
        when(analysisRepository.selectTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = analysisService.getTaskDetail(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void createTask_withParams_serializesToTaskParam() {
        AnalysisTaskReq req = new AnalysisTaskReq();
        req.setTaskName("task-with-params");
        req.setSourceSql("SELECT * FROM t WHERE id = ${id}");
        Map<String, Object> params = new HashMap<>();
        params.put("id", 42);
        req.setParams(params);

        when(sqlRewriteEngine.rewrite(req.getSourceSql(), null)).thenReturn("rewritten");
        doAnswer(inv -> {
            ((FederatedAnalysisTask) inv.getArgument(0)).setId(TASK_ID);
            return null;
        }).when(analysisRepository).insertTask(taskCaptor.capture());

        analysisService.createTask(req, USER_ID);

        assertNotNull(taskCaptor.getValue().getTaskParam());
        assertTrue(taskCaptor.getValue().getTaskParam().contains("42"));
    }

    @Test
    public void createRdbmsConnection_reusesCreateDataSource() {
        AnalysisDataSourceReq req = new AnalysisDataSourceReq();
        req.setSourceName("RDBMS-DS");
        req.setSourceType("mysql");
        req.setSourceConfig("{}");

        doAnswer(inv -> {
            ((FederatedAnalysisDatasource) inv.getArgument(0)).setId(DS_ID);
            return null;
        }).when(analysisRepository).insertDatasource(any());

        BaseResultEntity result = analysisService.createDataSource(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(analysisRepository).insertDatasource(any());
    }
}
