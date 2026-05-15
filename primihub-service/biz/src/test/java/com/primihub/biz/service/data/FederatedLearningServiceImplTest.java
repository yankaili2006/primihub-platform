package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.FederatedLearning;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import com.primihub.biz.entity.data.req.FederatedLearningReq;
import com.primihub.biz.repository.primarydb.data.FederatedLearningPrRepository;
import com.primihub.biz.repository.secondarydb.data.FederatedLearningRepository;
import com.primihub.biz.service.sys.LogManagementService;
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
public class FederatedLearningServiceImplTest {

    @Mock
    private LogManagementService logManagementService;

    @Mock
    private FederatedLearningRepository federatedLearningRepository;

    @Mock
    private FederatedLearningPrRepository federatedLearningPrRepository;

    @InjectMocks
    private FederatedLearningService federatedLearningService;

    @Captor
    private ArgumentCaptor<FederatedLearning> flCaptor;

    @Captor
    private ArgumentCaptor<FederatedLearningTask> taskCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long PROJECT_ID = 10L;
    private static final Long FL_ID = 100L;
    private static final String TASK_UUID = "fl-task-uuid-001";
    private static final String MODEL_ID = "model-001";

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private FederatedLearningReq createReq(Integer taskType, Integer algorithmType, Integer federatedType) {
        FederatedLearningReq req = new FederatedLearningReq();
        req.setTaskType(taskType);
        req.setAlgorithmType(algorithmType);
        req.setFederatedType(federatedType);
        req.setTaskName("fl-task");
        req.setProjectId(PROJECT_ID);
        req.setOwnOrganId("org-001");
        req.setOwnResourceId("res-001");
        req.setOwnFeatures("f1,f2,f3");
        req.setLabelFeature("label");
        req.setIsLabelOwner(1);
        req.setParticipantOrganIds("org-002,org-003");
        req.setParticipantResourceIds("[{\"organ\":\"org-002\"}]");
        if (taskType == 1) {
            FederatedLearningReq.TrainingParams params = new FederatedLearningReq.TrainingParams();
            params.setEpochs(20);
            params.setLearningRate(0.01);
            req.setTrainingParams(params);
        } else {
            req.setModelId(MODEL_ID);
        }
        return req;
    }

    private FederatedLearning createFl(Long id, Integer algorithmType) {
        FederatedLearning fl = new FederatedLearning();
        fl.setId(id);
        fl.setAlgorithmType(algorithmType);
        fl.setTaskName("fl-task");
        fl.setProjectId(PROJECT_ID);
        fl.setUserId(USER_ID);
        fl.setModelPath("/tmp/model.pkl");
        return fl;
    }

    private FederatedLearningTask createTask(Long flId, String taskId, Integer state) {
        FederatedLearningTask task = new FederatedLearningTask();
        task.setId(200L);
        task.setFlId(flId);
        task.setTaskId(taskId);
        task.setTaskState(state);
        task.setCurrentRound(5);
        task.setTotalRounds(20);
        task.setAccuracy(0.95);
        task.setLoss(0.12);
        task.setResultFilePath("/tmp/result.csv");
        return task;
    }

    @Test
    public void createTask_withTrainingParams_savesAndReturnsTaskId() {
        FederatedLearningReq req = createReq(1, 1, 2);
        when(federatedLearningPrRepository.saveFederatedLearning(any())).thenReturn(1);
        when(federatedLearningPrRepository.saveFederatedLearningTask(any())).thenReturn(1);

        BaseResultEntity result = federatedLearningService.createTask(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("taskId"));
        assertEquals("任务已创建，正在执行中...", map.get("message"));

        verify(federatedLearningPrRepository).saveFederatedLearning(flCaptor.capture());
        FederatedLearning captured = flCaptor.getValue();
        assertEquals(Integer.valueOf(1), captured.getAlgorithmType());
        assertEquals(Integer.valueOf(2), captured.getFederatedType());
        assertEquals(USER_ID, captured.getUserId());
        assertEquals(Integer.valueOf(0), captured.getIsDel());

        verify(federatedLearningPrRepository).saveFederatedLearningTask(taskCaptor.capture());
        FederatedLearningTask capturedTask = taskCaptor.getValue();
        assertEquals(Integer.valueOf(2), capturedTask.getTaskState());
        assertEquals(Integer.valueOf(20), capturedTask.getTotalRounds());
        assertEquals(Integer.valueOf(0), capturedTask.getCurrentRound());
    }

    @Test
    public void createTask_predictWithoutTrainingParams_defaultsEpochs10() {
        FederatedLearningReq req = createReq(2, 2, 1);
        req.setTrainingParams(null);
        when(federatedLearningPrRepository.saveFederatedLearning(any())).thenReturn(1);
        when(federatedLearningPrRepository.saveFederatedLearningTask(any())).thenReturn(1);

        federatedLearningService.createTask(req, USER_ID);

        verify(federatedLearningPrRepository).saveFederatedLearningTask(taskCaptor.capture());
        assertEquals(Integer.valueOf(10), taskCaptor.getValue().getTotalRounds());
    }

    @Test
    public void createTask_allAlgorithmTypes_succeed() {
        int[][] combos = {{1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, {2, 3}};
        for (int[] combo : combos) {
            FederatedLearningReq req = createReq(combo[0], combo[1], 1);
            when(federatedLearningPrRepository.saveFederatedLearning(any())).thenReturn(1);
            when(federatedLearningPrRepository.saveFederatedLearningTask(any())).thenReturn(1);

            BaseResultEntity result = federatedLearningService.createTask(req, USER_ID);
            assertEquals("taskType=" + combo[0] + " algo=" + combo[1] + " failed",
                    0, result.getCode().intValue());
        }
        verify(federatedLearningPrRepository, times(6)).saveFederatedLearning(any());
        verify(federatedLearningPrRepository, times(6)).saveFederatedLearningTask(any());
    }

    @Test
    public void createTask_repositoryThrows_returnsFailure() {
        FederatedLearningReq req = createReq(1, 1, 1);
        when(federatedLearningPrRepository.saveFederatedLearning(any()))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedLearningService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("创建任务失败"));
    }

    @Test
    public void getTaskList_returnsPaginatedResults() {
        Map<String, Object> row = new HashMap<>();
        row.put("taskId", TASK_UUID);
        row.put("taskName", "fl-task");
        row.put("taskState", 1);
        row.put("algorithmType", 1);
        List<Map<String, Object>> data = Collections.singletonList(row);

        when(federatedLearningRepository.selectTaskPage(any())).thenReturn(data);
        when(federatedLearningRepository.selectTaskPageCount(any())).thenReturn(1L);

        BaseResultEntity result = federatedLearningService.getTaskList(
                "fl-task", 1, 1, 1, PROJECT_ID,
                null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(1, map.get("total"));
        assertEquals(1, map.get("pageNo"));
        assertEquals(10, map.get("pageSize"));
    }

    @Test
    public void getTaskList_empty_returnsEmpty() {
        when(federatedLearningRepository.selectTaskPage(any())).thenReturn(Collections.emptyList());
        when(federatedLearningRepository.selectTaskPageCount(any())).thenReturn(0L);

        BaseResultEntity result = federatedLearningService.getTaskList(
                null, null, null, null, null, null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0L, map.get("total"));
    }

    @Test
    public void getTaskList_repositoryThrows_returnsFailure() {
        when(federatedLearningRepository.selectTaskPage(any()))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedLearningService.getTaskList(
                null, null, null, null, null, null, null, 1, 10);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetails_existingTask_returnsDetail() {
        FederatedLearningTask task = createTask(FL_ID, TASK_UUID, 1);
        FederatedLearning fl = createFl(FL_ID, 1);

        when(federatedLearningRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(task);
        when(federatedLearningRepository.selectById(FL_ID)).thenReturn(fl);

        BaseResultEntity result = federatedLearningService.getTaskDetails(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("task"));
        assertNotNull(map.get("federatedLearning"));
    }

    @Test
    public void getTaskDetails_nullTask_returnsFailure() {
        when(federatedLearningRepository.selectTaskByTaskId("not-exist")).thenReturn(null);

        BaseResultEntity result = federatedLearningService.getTaskDetails("not-exist");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetails_repositoryThrows_returnsFailure() {
        when(federatedLearningRepository.selectTaskByTaskId(TASK_UUID))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedLearningService.getTaskDetails(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getModelList_returnsPaginatedResults() {
        Map<String, Object> row = new HashMap<>();
        row.put("id", 1L);
        row.put("algorithmType", 1);
        row.put("taskName", "model-task");
        List<Map<String, Object>> data = Collections.singletonList(row);

        when(federatedLearningRepository.selectModelList(any())).thenReturn(data);
        when(federatedLearningRepository.selectModelListCount(any())).thenReturn(1L);

        BaseResultEntity result = federatedLearningService.getModelList(1, PROJECT_ID, 1, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(1, map.get("total"));
        List<?> list = (List<?>) map.get("data");
        assertEquals(1, list.size());
    }

    @Test
    public void getModelList_repositoryThrows_returnsFailure() {
        when(federatedLearningRepository.selectModelList(any()))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedLearningService.getModelList(null, null, 1, 10);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void downloadModel_existingFile_writesResponse() throws Exception {
        FederatedLearningTask task = createTask(FL_ID, TASK_UUID, 1);
        FederatedLearning fl = createFl(FL_ID, 1);

        when(federatedLearningRepository.selectTaskByTaskId(MODEL_ID)).thenReturn(task);
        when(federatedLearningRepository.selectById(FL_ID)).thenReturn(fl);

        federatedLearningService.downloadModel(response, MODEL_ID);

        assertEquals("application/octet-stream", response.getContentType());
        assertNotNull(response.getHeader("Content-Disposition"));
        assertTrue(response.getHeader("Content-Disposition").contains("_model.pkl"));
    }

    @Test
    public void downloadModel_nullTask_doesNothing() {
        when(federatedLearningRepository.selectTaskByTaskId("not-exist")).thenReturn(null);

        federatedLearningService.downloadModel(response, "not-exist");

        assertEquals(200, response.getStatus());
    }

    @Test
    public void downloadModel_nullModelPath_doesNothing() {
        FederatedLearningTask task = createTask(FL_ID, MODEL_ID, 1);
        FederatedLearning fl = createFl(FL_ID, 1);
        fl.setModelPath(null);

        when(federatedLearningRepository.selectTaskByTaskId(MODEL_ID)).thenReturn(task);
        when(federatedLearningRepository.selectById(FL_ID)).thenReturn(fl);

        federatedLearningService.downloadModel(response, MODEL_ID);

        assertEquals(200, response.getStatus());
    }

    @Test
    public void downloadResult_existingFile_writesResponse() throws Exception {
        FederatedLearningTask task = createTask(FL_ID, TASK_UUID, 1);
        task.setResultFilePath("/tmp/prediction.csv");

        when(federatedLearningRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(task);

        federatedLearningService.downloadResult(response, TASK_UUID);

        assertEquals("application/octet-stream", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("prediction_result.csv"));
    }

    @Test
    public void downloadResult_nullTask_doesNothing() {
        when(federatedLearningRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(null);

        federatedLearningService.downloadResult(response, TASK_UUID);

        assertEquals(200, response.getStatus());
    }

    @Test
    public void deleteTask_returnsSuccess() {
        when(federatedLearningPrRepository.deleteTask(TASK_UUID)).thenReturn(1);

        BaseResultEntity result = federatedLearningService.deleteTask(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningPrRepository).deleteTask(TASK_UUID);
    }

    @Test
    public void deleteTask_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(federatedLearningPrRepository).deleteTask(TASK_UUID);

        BaseResultEntity result = federatedLearningService.deleteTask(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void cancelTask_returnsSuccess() {
        when(federatedLearningPrRepository.cancelTask(TASK_UUID)).thenReturn(1);

        BaseResultEntity result = federatedLearningService.cancelTask(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        verify(federatedLearningPrRepository).cancelTask(TASK_UUID);
    }

    @Test
    public void cancelTask_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(federatedLearningPrRepository).cancelTask(TASK_UUID);

        BaseResultEntity result = federatedLearningService.cancelTask(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTrainingProgress_existingTask_returnsProgress() {
        FederatedLearningTask task = createTask(FL_ID, TASK_UUID, 1);
        when(federatedLearningRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(task);

        BaseResultEntity result = federatedLearningService.getTrainingProgress(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(Integer.valueOf(5), map.get("currentRound"));
        assertEquals(Integer.valueOf(20), map.get("totalRounds"));
        assertEquals(Double.valueOf(0.95), map.get("accuracy"));
        assertEquals(Double.valueOf(0.12), map.get("loss"));
        assertEquals(Integer.valueOf(1), map.get("taskState"));
    }

    @Test
    public void getTrainingProgress_nullTask_returnsFailure() {
        when(federatedLearningRepository.selectTaskByTaskId("not-exist")).thenReturn(null);

        BaseResultEntity result = federatedLearningService.getTrainingProgress("not-exist");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTrainingProgress_repositoryThrows_returnsFailure() {
        when(federatedLearningRepository.selectTaskByTaskId(TASK_UUID))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = federatedLearningService.getTrainingProgress(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }
}
