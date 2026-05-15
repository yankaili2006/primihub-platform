package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.SinglePartyReq;
import com.primihub.biz.service.data.SinglePartyService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class SinglePartyControllerTest {

    @Mock
    private SinglePartyService singlePartyService;

    @InjectMocks
    private SinglePartyController controller;

    private static final Long USER_ID = 1L;
    private static final String TASK_ID = "task-001";

    // ==================== createTask ====================

    @Test
    public void createTask_success() {
        SinglePartyReq req = new SinglePartyReq();
        req.setAlgorithmType(1);
        req.setTaskName("test-task");
        req.setResourceId("res-001");

        when(singlePartyService.createTask(req, USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createTask(USER_ID, req);

        assertEquals(0, result.getCode().intValue());
        verify(singlePartyService).createTask(req, USER_ID);
    }

    @Test
    public void createTask_nullAlgorithmType_returnsLackOfParam() {
        SinglePartyReq req = new SinglePartyReq();
        req.setTaskName("test-task");
        req.setResourceId("res-001");

        BaseResultEntity result = controller.createTask(USER_ID, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("algorithmType"));
        verify(singlePartyService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_blankTaskName_returnsLackOfParam() {
        SinglePartyReq req = new SinglePartyReq();
        req.setAlgorithmType(1);
        req.setTaskName("");
        req.setResourceId("res-001");

        BaseResultEntity result = controller.createTask(USER_ID, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskName"));
        verify(singlePartyService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_blankResourceId_returnsLackOfParam() {
        SinglePartyReq req = new SinglePartyReq();
        req.setAlgorithmType(1);
        req.setTaskName("test-task");
        req.setResourceId("");

        BaseResultEntity result = controller.createTask(USER_ID, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("resourceId"));
        verify(singlePartyService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_invalidUserId_returnsLackOfParam() {
        SinglePartyReq req = new SinglePartyReq();
        req.setAlgorithmType(1);
        req.setTaskName("test-task");
        req.setResourceId("res-001");

        BaseResultEntity result = controller.createTask(0L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(singlePartyService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_whenServiceFails_returnsFailure() {
        SinglePartyReq req = new SinglePartyReq();
        req.setAlgorithmType(1);
        req.setTaskName("test-task");
        req.setResourceId("res-001");

        when(singlePartyService.createTask(req, USER_ID))
                .thenReturn(BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL));

        BaseResultEntity result = controller.createTask(USER_ID, req);

        assertEquals(1007, result.getCode().intValue());
        verify(singlePartyService).createTask(req, USER_ID);
    }

    // ==================== getTaskList ====================

    @Test
    public void getTaskList_success() {
        when(singlePartyService.getTaskList(eq("test"), eq(1), eq(0),
                eq(1L), eq("2024-01-01"), eq("2024-12-31"),
                eq(1), eq(10)))
                .thenReturn(BaseResultEntity.success("task list"));

        BaseResultEntity result = controller.getTaskList("test", 1, 0,
                1L, "2024-01-01", "2024-12-31", 1, 10);

        assertEquals(0, result.getCode().intValue());
        assertEquals("task list", result.getResult());
        verify(singlePartyService).getTaskList("test", 1, 0,
                1L, "2024-01-01", "2024-12-31", 1, 10);
    }

    @Test
    public void getTaskList_withDefaultPagination() {
        when(singlePartyService.getTaskList(null, null, null,
                null, null, null, 1, 10))
                .thenReturn(BaseResultEntity.success("task list"));

        BaseResultEntity result = controller.getTaskList(null, null, null,
                null, null, null, null, null);

        assertEquals(0, result.getCode().intValue());
        verify(singlePartyService).getTaskList(null, null, null,
                null, null, null, 1, 10);
    }

    @Test
    public void getTaskList_whenServiceFails_returnsFailure() {
        when(singlePartyService.getTaskList(null, null, null,
                null, null, null, 1, 10))
                .thenReturn(BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL));

        BaseResultEntity result = controller.getTaskList(null, null, null,
                null, null, null, null, null);

        assertEquals(1003, result.getCode().intValue());
        verify(singlePartyService).getTaskList(null, null, null,
                null, null, null, 1, 10);
    }

    // ==================== getTaskDetails ====================

    @Test
    public void getTaskDetails_success() {
        when(singlePartyService.getTaskDetails(TASK_ID)).thenReturn(BaseResultEntity.success("task detail"));

        BaseResultEntity result = controller.getTaskDetails(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        assertEquals("task detail", result.getResult());
        verify(singlePartyService).getTaskDetails(TASK_ID);
    }

    @Test
    public void getTaskDetails_blankTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getTaskDetails("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(singlePartyService, never()).getTaskDetails(anyString());
    }

    @Test
    public void getTaskDetails_whenServiceFails_returnsFailure() {
        when(singlePartyService.getTaskDetails("not-found"))
                .thenReturn(BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL));

        BaseResultEntity result = controller.getTaskDetails("not-found");

        assertEquals(1003, result.getCode().intValue());
        verify(singlePartyService).getTaskDetails("not-found");
    }

    // ==================== downloadResult ====================

    @Test
    public void downloadResult_success() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        doNothing().when(singlePartyService).downloadResult(response, TASK_ID);

        controller.downloadResult(response, TASK_ID);

        verify(singlePartyService).downloadResult(response, TASK_ID);
    }

    @Test
    public void downloadResult_blankTaskId_doesNotCallService() {
        MockHttpServletResponse response = new MockHttpServletResponse();

        controller.downloadResult(response, "");

        verify(singlePartyService, never()).downloadResult(any(), anyString());
    }

    // ==================== deleteTask ====================

    @Test
    public void deleteTask_success() {
        when(singlePartyService.deleteTask(TASK_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deleteTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(singlePartyService).deleteTask(TASK_ID);
    }

    @Test
    public void deleteTask_blankTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.deleteTask("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(singlePartyService, never()).deleteTask(anyString());
    }

    @Test
    public void deleteTask_whenServiceFails_returnsFailure() {
        when(singlePartyService.deleteTask(TASK_ID))
                .thenReturn(BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL));

        BaseResultEntity result = controller.deleteTask(TASK_ID);

        assertEquals(1006, result.getCode().intValue());
        verify(singlePartyService).deleteTask(TASK_ID);
    }

    // ==================== cancelTask ====================

    @Test
    public void cancelTask_success() {
        when(singlePartyService.cancelTask(TASK_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.cancelTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(singlePartyService).cancelTask(TASK_ID);
    }

    @Test
    public void cancelTask_blankTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.cancelTask("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(singlePartyService, never()).cancelTask(anyString());
    }

    @Test
    public void cancelTask_whenServiceFails_returnsFailure() {
        when(singlePartyService.cancelTask(TASK_ID))
                .thenReturn(BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL));

        BaseResultEntity result = controller.cancelTask(TASK_ID);

        assertEquals(1007, result.getCode().intValue());
        verify(singlePartyService).cancelTask(TASK_ID);
    }
}
