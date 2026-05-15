package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.SingleParty;
import com.primihub.biz.entity.data.po.SinglePartyTask;
import com.primihub.biz.entity.data.req.SinglePartyReq;
import com.primihub.biz.repository.primarydb.data.SinglePartyPrRepository;
import com.primihub.biz.repository.secondarydb.data.SinglePartyRepository;
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
public class SinglePartyServiceImplTest {

    @Mock
    private LogManagementService logManagementService;

    @Mock
    private SinglePartyRepository singlePartyRepository;

    @Mock
    private SinglePartyPrRepository singlePartyPrRepository;

    @InjectMocks
    private SinglePartyService singlePartyService;

    @Captor
    private ArgumentCaptor<SingleParty> singlePartyCaptor;

    @Captor
    private ArgumentCaptor<SinglePartyTask> taskCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long PROJECT_ID = 10L;
    private static final String TASK_UUID = "task-uuid-001";

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private SinglePartyReq createReq(Integer algorithmType) {
        SinglePartyReq req = new SinglePartyReq();
        req.setAlgorithmType(algorithmType);
        req.setTaskName("test-task-" + algorithmType);
        req.setProjectId(PROJECT_ID);
        req.setResourceId("res-001");
        req.setSelectedFeatures("f1,f2,f3");
        req.setAlgorithmParams("{\"param1\":\"value1\"}");
        return req;
    }

    private SinglePartyTask createTask(String taskId, Integer state) {
        SinglePartyTask task = new SinglePartyTask();
        task.setId(100L);
        task.setSpId(1L);
        task.setTaskId(taskId);
        task.setTaskState(state);
        task.setResultRows(500);
        task.setResultFilePath("/tmp/result.csv");
        return task;
    }

    private SingleParty createSingleParty(Long id, Integer algorithmType) {
        SingleParty sp = new SingleParty();
        sp.setId(id);
        sp.setAlgorithmType(algorithmType);
        sp.setTaskName("test-task-" + algorithmType);
        sp.setProjectId(PROJECT_ID);
        return sp;
    }

    @Test
    public void createTask_withStatistics_savesAndReturnsTaskId() {
        SinglePartyReq req = createReq(1);
        when(singlePartyPrRepository.saveSingleParty(any())).thenReturn(1);
        when(singlePartyPrRepository.saveSinglePartyTask(any())).thenReturn(1);

        BaseResultEntity result = singlePartyService.createTask(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("taskId"));
        assertEquals("任务已创建，正在执行中...", map.get("message"));

        verify(singlePartyPrRepository).saveSingleParty(singlePartyCaptor.capture());
        SingleParty captured = singlePartyCaptor.getValue();
        assertEquals(Integer.valueOf(1), captured.getAlgorithmType());
        assertEquals(USER_ID, captured.getUserId());
        assertEquals(Integer.valueOf(0), captured.getIsDel());

        verify(singlePartyPrRepository).saveSinglePartyTask(taskCaptor.capture());
        SinglePartyTask capturedTask = taskCaptor.getValue();
        assertEquals(Integer.valueOf(2), capturedTask.getTaskState());
        assertEquals(Integer.valueOf(0), capturedTask.getIsDel());
    }

    @Test
    public void createTask_allAlgorithmTypes_succeed() {
        for (int algorithmType = 1; algorithmType <= 10; algorithmType++) {
            SinglePartyReq req = createReq(algorithmType);
            when(singlePartyPrRepository.saveSingleParty(any())).thenReturn(1);
            when(singlePartyPrRepository.saveSinglePartyTask(any())).thenReturn(1);

            BaseResultEntity result = singlePartyService.createTask(req, USER_ID);
            assertEquals("Algorithm type " + algorithmType + " failed", 0, result.getCode().intValue());
        }
        verify(singlePartyPrRepository, times(10)).saveSingleParty(any());
        verify(singlePartyPrRepository, times(10)).saveSinglePartyTask(any());
    }

    @Test
    public void createTask_repositoryThrows_returnsFailure() {
        SinglePartyReq req = createReq(1);
        when(singlePartyPrRepository.saveSingleParty(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = singlePartyService.createTask(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("创建任务失败"));
    }

    @Test
    public void getTaskList_returnsPaginatedResults() {
        Map<String, Object> row = new HashMap<>();
        row.put("taskId", TASK_UUID);
        row.put("taskName", "my-task");
        row.put("taskState", 2);
        row.put("algorithmType", 1);
        List<Map<String, Object>> data = Collections.singletonList(row);

        when(singlePartyRepository.selectTaskPage(any())).thenReturn(data);
        when(singlePartyRepository.selectTaskPageCount(any())).thenReturn(1L);

        BaseResultEntity result = singlePartyService.getTaskList("my-task", 1, 2,
                PROJECT_ID, null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(1, map.get("total"));
        assertEquals(1, map.get("pageNo"));
        assertEquals(10, map.get("pageSize"));
        assertEquals(Integer.valueOf(1), map.get("totalPage"));
        List<?> list = (List<?>) map.get("data");
        assertEquals(1, list.size());
    }

    @Test
    public void getTaskList_empty_returnsEmpty() {
        when(singlePartyRepository.selectTaskPage(any())).thenReturn(Collections.emptyList());
        when(singlePartyRepository.selectTaskPageCount(any())).thenReturn(0L);

        BaseResultEntity result = singlePartyService.getTaskList(null, null, null,
                null, null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(0L, map.get("total"));
    }

    @Test
    public void getTaskList_repositoryThrows_returnsFailure() {
        when(singlePartyRepository.selectTaskPage(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = singlePartyService.getTaskList(null, null, null,
                null, null, null, 1, 10);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetails_existingTask_returnsDetail() {
        SinglePartyTask task = createTask(TASK_UUID, 1);
        SingleParty sp = createSingleParty(1L, 2);

        when(singlePartyRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(task);
        when(singlePartyRepository.selectById(1L)).thenReturn(sp);

        BaseResultEntity result = singlePartyService.getTaskDetails(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("task"));
        assertNotNull(map.get("singleParty"));
    }

    @Test
    public void getTaskDetails_nullTask_returnsFailure() {
        when(singlePartyRepository.selectTaskByTaskId("not-exist")).thenReturn(null);

        BaseResultEntity result = singlePartyService.getTaskDetails("not-exist");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetails_repositoryThrows_returnsFailure() {
        when(singlePartyRepository.selectTaskByTaskId(TASK_UUID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = singlePartyService.getTaskDetails(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void downloadResult_existingFile_writesResponse() throws Exception {
        SinglePartyTask task = createTask(TASK_UUID, 1);
        task.setResultFilePath("/tmp/test_result.csv");
        when(singlePartyRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(task);

        singlePartyService.downloadResult(response, TASK_UUID);

        assertEquals("application/octet-stream", response.getContentType());
        assertNotNull(response.getHeader("Content-Disposition"));
        assertTrue(response.getHeader("Content-Disposition").contains("result.csv"));
    }

    @Test
    public void downloadResult_nullTask_doesNothing() {
        when(singlePartyRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(null);

        singlePartyService.downloadResult(response, TASK_UUID);

        assertEquals(200, response.getStatus());
    }

    @Test
    public void downloadResult_nullResultPath_doesNothing() {
        SinglePartyTask task = createTask(TASK_UUID, 1);
        task.setResultFilePath(null);
        when(singlePartyRepository.selectTaskByTaskId(TASK_UUID)).thenReturn(task);

        singlePartyService.downloadResult(response, TASK_UUID);

        assertEquals(200, response.getStatus());
    }

    @Test
    public void deleteTask_returnsSuccess() {
        when(singlePartyPrRepository.deleteTask(TASK_UUID)).thenReturn(1);

        BaseResultEntity result = singlePartyService.deleteTask(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        verify(singlePartyPrRepository).deleteTask(TASK_UUID);
    }

    @Test
    public void deleteTask_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(singlePartyPrRepository).deleteTask(TASK_UUID);

        BaseResultEntity result = singlePartyService.deleteTask(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    @Test
    public void cancelTask_returnsSuccess() {
        when(singlePartyPrRepository.cancelTask(TASK_UUID)).thenReturn(1);

        BaseResultEntity result = singlePartyService.cancelTask(TASK_UUID);

        assertEquals(0, result.getCode().intValue());
        verify(singlePartyPrRepository).cancelTask(TASK_UUID);
    }

    @Test
    public void cancelTask_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(singlePartyPrRepository).cancelTask(TASK_UUID);

        BaseResultEntity result = singlePartyService.cancelTask(TASK_UUID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }
}
