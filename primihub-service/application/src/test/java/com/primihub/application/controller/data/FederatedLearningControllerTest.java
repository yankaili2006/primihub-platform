package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.FederatedLearningReq;
import com.primihub.biz.service.data.FederatedLearningService;
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
public class FederatedLearningControllerTest {

    @Mock
    private FederatedLearningService federatedLearningService;

    @InjectMocks
    private FederatedLearningController controller;

    private FederatedLearningReq buildValidReq() {
        FederatedLearningReq req = new FederatedLearningReq();
        req.setTaskType(1);
        req.setAlgorithmType(1);
        req.setFederatedType(1);
        req.setTaskName("test-task");
        req.setOwnOrganId("org-1");
        req.setOwnResourceId("res-1");
        req.setParticipantOrganIds("org-2,org-3");
        return req;
    }

    // ==================== createTask (需求#162) ====================

    @Test
    public void createTask_WithValidRequest_ReturnsSuccess() {
        FederatedLearningReq req = buildValidReq();
        when(federatedLearningService.createTask(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningService).createTask(req, 1L);
    }

    @Test
    public void createTask_WithInvalidUserId_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();

        BaseResultEntity result = controller.createTask(0L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("userId"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_WithNegativeUserId_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();

        BaseResultEntity result = controller.createTask(-1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingTaskType_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setTaskType(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskType"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingAlgorithmType_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setAlgorithmType(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("algorithmType"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingFederatedType_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setFederatedType(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("federatedType"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingTaskName_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setTaskName(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskName"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingOwnOrganId_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setOwnOrganId(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("ownOrganId"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingOwnResourceId_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setOwnResourceId(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("ownResourceId"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_MissingParticipantOrganIds_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setParticipantOrganIds(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("participantOrganIds"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_PredictTaskWithoutModelId_ReturnsLackOfParam() {
        FederatedLearningReq req = buildValidReq();
        req.setTaskType(2);
        req.setModelId(null);

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("modelId"));
        verify(federatedLearningService, never()).createTask(any(), anyLong());
    }

    @Test
    public void createTask_PredictTaskWithModelId_ReturnsSuccess() {
        FederatedLearningReq req = buildValidReq();
        req.setTaskType(2);
        req.setModelId("model-123");
        when(federatedLearningService.createTask(req, 1L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningService).createTask(req, 1L);
    }

    @Test
    public void createTask_WhenServiceFails_ReturnsFailure() {
        FederatedLearningReq req = buildValidReq();
        when(federatedLearningService.createTask(req, 1L)).thenReturn(
                BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL));

        BaseResultEntity result = controller.createTask(1L, req);

        assertEquals(1007, result.getCode().intValue());
        verify(federatedLearningService).createTask(req, 1L);
    }

    // ==================== getTaskList (需求#163) ====================

    @Test
    public void getTaskList_WithQuery_ReturnsTaskList() {
        when(federatedLearningService.getTaskList("test", 1, 2, 3, 1L,
                "2024-01-01", "2024-12-31", 1, 10))
                .thenReturn(BaseResultEntity.success("task list"));

        BaseResultEntity result = controller.getTaskList("test", 1, 2, 3, 1L,
                "2024-01-01", "2024-12-31", 1, 10);

        assertEquals(0, result.getCode().intValue());
        assertEquals("task list", result.getResult());
        verify(federatedLearningService).getTaskList("test", 1, 2, 3, 1L,
                "2024-01-01", "2024-12-31", 1, 10);
    }

    @Test
    public void getTaskList_WithDefaults_ReturnsTaskList() {
        when(federatedLearningService.getTaskList(null, null, null, null, null,
                null, null, 1, 10))
                .thenReturn(BaseResultEntity.success("default list"));

        BaseResultEntity result = controller.getTaskList(null, null, null, null, null,
                null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningService).getTaskList(null, null, null, null, null,
                null, null, 1, 10);
    }

    @Test
    public void getTaskList_WhenServiceFails_ReturnsFailure() {
        when(federatedLearningService.getTaskList(null, null, null, null, null,
                null, null, 1, 10))
                .thenReturn(BaseResultEntity.failure(BaseResultEnum.FAILURE));

        BaseResultEntity result = controller.getTaskList(null, null, null, null, null,
                null, null, 1, 10);

        assertEquals(-1, result.getCode().intValue());
    }

    // ==================== getTaskDetails (需求#164) ====================

    @Test
    public void getTaskDetails_WithValidTaskId_ReturnsTaskDetails() {
        when(federatedLearningService.getTaskDetails("task-123")).thenReturn(
                BaseResultEntity.success("task details"));

        BaseResultEntity result = controller.getTaskDetails("task-123");

        assertEquals(0, result.getCode().intValue());
        assertEquals("task details", result.getResult());
        verify(federatedLearningService).getTaskDetails("task-123");
    }

    @Test
    public void getTaskDetails_WithBlankTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.getTaskDetails("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskId"));
        verify(federatedLearningService, never()).getTaskDetails(anyString());
    }

    @Test
    public void getTaskDetails_WithNullTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.getTaskDetails(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedLearningService, never()).getTaskDetails(anyString());
    }

    // ==================== getModelList (需求#165) ====================

    @Test
    public void getModelList_WithQuery_ReturnsModelList() {
        when(federatedLearningService.getModelList(1, 1L, 1, 10))
                .thenReturn(BaseResultEntity.success("model list"));

        BaseResultEntity result = controller.getModelList(1, 1L, 1, 10);

        assertEquals(0, result.getCode().intValue());
        assertEquals("model list", result.getResult());
        verify(federatedLearningService).getModelList(1, 1L, 1, 10);
    }

    @Test
    public void getModelList_WithDefaults_ReturnsModelList() {
        when(federatedLearningService.getModelList(null, null, 1, 10))
                .thenReturn(BaseResultEntity.success("default models"));

        BaseResultEntity result = controller.getModelList(null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningService).getModelList(null, null, 1, 10);
    }

    // ==================== downloadModel (需求#166) ====================

    @Test
    public void downloadModel_WithValidModelId_CallsService() {
        HttpServletResponse response = mock(HttpServletResponse.class);
        doNothing().when(federatedLearningService).downloadModel(response, "model-123");

        controller.downloadModel(response, "model-123");

        verify(federatedLearningService).downloadModel(response, "model-123");
    }

    @Test
    public void downloadModel_WithBlankModelId_DoesNothing() {
        HttpServletResponse response = mock(HttpServletResponse.class);

        controller.downloadModel(response, "");

        verify(federatedLearningService, never()).downloadModel(any(), anyString());
    }

    @Test
    public void downloadModel_WithNullModelId_DoesNothing() {
        HttpServletResponse response = mock(HttpServletResponse.class);

        controller.downloadModel(response, null);

        verify(federatedLearningService, never()).downloadModel(any(), anyString());
    }

    // ==================== downloadResult (需求#167) ====================

    @Test
    public void downloadResult_WithValidTaskId_CallsService() {
        HttpServletResponse response = mock(HttpServletResponse.class);
        doNothing().when(federatedLearningService).downloadResult(response, "task-123");

        controller.downloadResult(response, "task-123");

        verify(federatedLearningService).downloadResult(response, "task-123");
    }

    @Test
    public void downloadResult_WithBlankTaskId_DoesNothing() {
        HttpServletResponse response = mock(HttpServletResponse.class);

        controller.downloadResult(response, "");

        verify(federatedLearningService, never()).downloadResult(any(), anyString());
    }

    // ==================== deleteTask (需求#168) ====================

    @Test
    public void deleteTask_WithValidTaskId_ReturnsSuccess() {
        when(federatedLearningService.deleteTask("task-123")).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deleteTask("task-123");

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningService).deleteTask("task-123");
    }

    @Test
    public void deleteTask_WithBlankTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.deleteTask("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskId"));
        verify(federatedLearningService, never()).deleteTask(anyString());
    }

    @Test
    public void deleteTask_WithNullTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.deleteTask(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedLearningService, never()).deleteTask(anyString());
    }

    // ==================== cancelTask (需求#169) ====================

    @Test
    public void cancelTask_WithValidTaskId_ReturnsSuccess() {
        when(federatedLearningService.cancelTask("task-123")).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.cancelTask("task-123");

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningService).cancelTask("task-123");
    }

    @Test
    public void cancelTask_WithBlankTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.cancelTask("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskId"));
        verify(federatedLearningService, never()).cancelTask(anyString());
    }

    @Test
    public void cancelTask_WithNullTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.cancelTask(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedLearningService, never()).cancelTask(anyString());
    }

    // ==================== getTrainingProgress (需求#170) ====================

    @Test
    public void getTrainingProgress_WithValidTaskId_ReturnsProgress() {
        when(federatedLearningService.getTrainingProgress("task-123"))
                .thenReturn(BaseResultEntity.success("training progress"));

        BaseResultEntity result = controller.getTrainingProgress("task-123");

        assertEquals(0, result.getCode().intValue());
        assertEquals("training progress", result.getResult());
        verify(federatedLearningService).getTrainingProgress("task-123");
    }

    @Test
    public void getTrainingProgress_WithBlankTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.getTrainingProgress("");

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("taskId"));
        verify(federatedLearningService, never()).getTrainingProgress(anyString());
    }

    @Test
    public void getTrainingProgress_WithNullTaskId_ReturnsLackOfParam() {
        BaseResultEntity result = controller.getTrainingProgress(null);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(federatedLearningService, never()).getTrainingProgress(anyString());
    }
}
