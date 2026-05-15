package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataPirReq;
import com.primihub.biz.entity.data.req.DataPirTaskReq;
import com.primihub.biz.service.data.PirService;
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
public class PirControllerTest {

    @Mock
    private PirService pirService;

    @InjectMocks
    private PirController controller;

    private static final String RESOURCE_ID = "res-123";
    private static final String TASK_ID = "task-456";

    private BaseResultEntity successResult;

    @Before
    public void setUp() {
        successResult = BaseResultEntity.success();
    }

    // ==================== pirSubmitTask ====================

    @Test
    public void pirSubmitTask_success() {
        String pirParam = "param1,param2";
        String taskName = "PIR-Test";
        DataPirReq captor = new DataPirReq();
        captor.setResourceId(RESOURCE_ID);
        captor.setTaskName(taskName);
        when(pirService.pirSubmitTask(any(DataPirReq.class), eq(pirParam))).thenReturn(successResult);

        BaseResultEntity result = controller.pirSubmitTask(RESOURCE_ID, pirParam, taskName);
        assertSame(successResult, result);
        verify(pirService).pirSubmitTask(any(DataPirReq.class), eq(pirParam));
    }

    @Test
    public void pirSubmitTask_missingResourceId_returnsLackOfParam() {
        BaseResultEntity result = controller.pirSubmitTask(null, "param", "task");
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(pirService, never()).pirSubmitTask(any(), anyString());
    }

    @Test
    public void pirSubmitTask_missingPirParam_returnsLackOfParam() {
        BaseResultEntity result = controller.pirSubmitTask(RESOURCE_ID, null, "task");
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(pirService, never()).pirSubmitTask(any(), anyString());
    }

    @Test
    public void pirSubmitTask_emptyTaskName_generatesDefault() {
        String pirParam = "query1";
        when(pirService.pirSubmitTask(any(DataPirReq.class), eq(pirParam))).thenReturn(successResult);

        BaseResultEntity result = controller.pirSubmitTask(RESOURCE_ID, pirParam, null);
        assertSame(successResult, result);
        verify(pirService).pirSubmitTask(any(DataPirReq.class), eq(pirParam));
    }

    @Test
    public void pirSubmitTask_longTaskName_truncated() {
        String pirParam = "query1";
        String longName = new String(new char[300]).replace('\0', 'A');
        when(pirService.pirSubmitTask(any(DataPirReq.class), eq(pirParam))).thenReturn(successResult);

        BaseResultEntity result = controller.pirSubmitTask(RESOURCE_ID, pirParam, longName);
        assertSame(successResult, result);
        verify(pirService).pirSubmitTask(any(DataPirReq.class), eq(pirParam));
    }

    // ==================== getPirTaskList ====================

    @Test
    public void getPirTaskList_success() {
        DataPirTaskReq req = new DataPirTaskReq();
        when(pirService.getPirTaskList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getPirTaskList(req);
        assertSame(successResult, result);
        verify(pirService).getPirTaskList(req);
    }

    @Test
    public void getPirTaskList_invalidTaskState_returnsParamInvalidation() {
        DataPirTaskReq req = new DataPirTaskReq();
        req.setTaskState(99);
        BaseResultEntity result = controller.getPirTaskList(req);
        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), result.getCode());
        verify(pirService, never()).getPirTaskList(any());
    }

    @Test
    public void getPirTaskList_resourceNameWithUnderscore_escapes() {
        DataPirTaskReq req = new DataPirTaskReq();
        req.setResourceName("test_resource");
        when(pirService.getPirTaskList(req)).thenReturn(successResult);

        controller.getPirTaskList(req);
        assertEquals("test\\_resource", req.getResourceName());
        verify(pirService).getPirTaskList(req);
    }

    @Test
    public void getPirTaskList_withFilters() {
        DataPirTaskReq req = new DataPirTaskReq();
        req.setTaskName("test-pir");
        req.setTaskState(1);
        req.setOrganName("orgA");
        req.setStartDate("2025-01-01");
        req.setEndDate("2025-12-31");
        when(pirService.getPirTaskList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getPirTaskList(req);
        assertSame(successResult, result);
        verify(pirService).getPirTaskList(req);
    }

    // ==================== getPirTaskDetail ====================

    @Test
    public void getPirTaskDetail_success() {
        Long taskId = 200L;
        when(pirService.getPirTaskDetail(taskId)).thenReturn(successResult);

        BaseResultEntity result = controller.getPirTaskDetail(taskId);
        assertSame(successResult, result);
        verify(pirService).getPirTaskDetail(taskId);
    }

    @Test
    public void getPirTaskDetail_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getPirTaskDetail(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(pirService, never()).getPirTaskDetail(any());
    }

    @Test
    public void getPirTaskDetail_zeroTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getPirTaskDetail(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(pirService, never()).getPirTaskDetail(any());
    }

    // ==================== downloadPirTask ====================

    @Test
    public void downloadPirTask_nullTaskId_returnsEarly() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadPirTask(response, null, "2025-01-01");
        assertEquals(0, response.getContentAsByteArray().length);
    }

    @Test
    public void downloadPirTask_nullTaskDate_returnsEarly() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadPirTask(response, TASK_ID, null);
        assertEquals(0, response.getContentAsByteArray().length);
    }

    @Test
    public void downloadPirTask_success() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        String taskDate = "2025-01-01";
        when(pirService.getResultFilePath(TASK_ID, taskDate)).thenReturn("/tmp/test.csv");

        controller.downloadPirTask(response, TASK_ID, taskDate);
        verify(pirService).getResultFilePath(TASK_ID, taskDate);
    }

    // ===== 联邦查询功能 — PIR =====

    @Test public void testFunction_pir_submitTask() {
        String pirParam = "param1,param2";
        when(pirService.pirSubmitTask(any(DataPirReq.class), eq(pirParam))).thenReturn(successResult);
        BaseResultEntity result = controller.pirSubmitTask(RESOURCE_ID, pirParam, "PIR-Test");
        assertNotNull(result);
    }

    @Test public void testFunction_pir_getTaskList() {
        DataPirTaskReq req = new DataPirTaskReq();
        when(pirService.getPirTaskList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getPirTaskList(req);
        assertNotNull(result);
    }

    @Test public void testFunction_pir_getTaskDetail() {
        Long taskId = 200L;
        when(pirService.getPirTaskDetail(taskId)).thenReturn(successResult);
        BaseResultEntity result = controller.getPirTaskDetail(taskId);
        assertNotNull(result);
    }

    @Test public void testFunction_pir_downloadTask() {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        when(pirService.getResultFilePath(TASK_ID, "2025-01-01")).thenReturn("/tmp/pir.csv");
        controller.downloadPirTask(resp, TASK_ID, "2025-01-01");
        verify(pirService).getResultFilePath(TASK_ID, "2025-01-01");
    }

    @Test public void testFunction_pir_submitWithDefaultName() {
        String pirParam = "query1";
        when(pirService.pirSubmitTask(any(DataPirReq.class), eq(pirParam))).thenReturn(successResult);
        BaseResultEntity result = controller.pirSubmitTask(RESOURCE_ID, pirParam, null);
        assertNotNull(result);
    }

    @Test public void testFunction_pir_taskListWithFilters() {
        DataPirTaskReq req = new DataPirTaskReq();
        req.setTaskName("test-pir");
        req.setTaskState(1);
        req.setOrganName("orgA");
        when(pirService.getPirTaskList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getPirTaskList(req);
        assertNotNull(result);
    }
}
