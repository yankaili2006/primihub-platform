package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.DataDifference;
import com.primihub.biz.entity.data.po.DataDifferenceTask;
import com.primihub.biz.entity.data.req.DataDifferenceReq;
import com.primihub.biz.repository.primarydb.data.DataDifferencePrRepository;
import com.primihub.biz.repository.secondarydb.data.DataDifferenceRepository;
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
public class DataDifferenceServiceImplTest {

    @Mock
    private LogManagementService logManagementService;

    @Mock
    private DataDifferenceRepository dataDifferenceRepository;

    @Mock
    private DataDifferencePrRepository dataDifferencePrRepository;

    @InjectMocks
    private DataDifferenceService dataDifferenceService;

    @Captor
    private ArgumentCaptor<DataDifference> differenceCaptor;

    @Captor
    private ArgumentCaptor<DataDifferenceTask> taskCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private DataDifferenceReq validReq() {
        DataDifferenceReq req = new DataDifferenceReq();
        req.setOwnOrganId("orgA");
        req.setOwnResourceId("res-1");
        req.setOwnKeyword("keyword1");
        req.setOtherOrganId("orgB");
        req.setOtherResourceId("res-2");
        req.setOtherKeyword("keyword2");
        req.setResultName("diff-result");
        req.setResultOrganIds("orgA,orgB");
        req.setTag(0);
        req.setDifferenceDirection(0);
        return req;
    }

    private DataDifferenceTask createTask(String taskId, Integer state) {
        DataDifferenceTask task = new DataDifferenceTask();
        task.setId(TASK_ID);
        task.setDifferenceId(1L);
        task.setTaskId(taskId);
        task.setTaskState(state);
        task.setFilePath("/tmp/diff_result.csv");
        return task;
    }

    private DataDifference createDifference(Long id) {
        DataDifference diff = new DataDifference();
        diff.setId(id);
        diff.setOwnOrganId("orgA");
        diff.setOwnResourceId("res-1");
        diff.setResultName("diff-result");
        diff.setUserId(USER_ID);
        return diff;
    }

    // ==================== saveDataDifference ====================

    @Test
    public void saveDataDifference_success() {
        DataDifferenceReq req = validReq();
        doNothing().when(logManagementService).recordComputeLog(any());

        BaseResultEntity result = dataDifferenceService.saveDataDifference(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        assertNotNull(result.getResult());
        verify(logManagementService).recordComputeLog(any());
    }

    @Test
    public void saveDataDifference_repositoryThrows_returnsFailure() {
        DataDifferenceReq req = validReq();
        doThrow(new RuntimeException("DB error")).when(logManagementService).recordComputeLog(any());

        BaseResultEntity result = dataDifferenceService.saveDataDifference(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("创建任务失败"));
    }

    // ==================== getDifferenceTaskList ====================

    @Test
    public void getDifferenceTaskList_returnsSuccess() {
        when(dataDifferenceRepository.selectTaskPage(any())).thenReturn(Collections.emptyList());
        when(dataDifferenceRepository.selectTaskPageCount(any())).thenReturn(0L);

        BaseResultEntity result = dataDifferenceService.getDifferenceTaskList(null, null, null, null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        verify(dataDifferenceRepository).selectTaskPage(any());
        verify(dataDifferenceRepository).selectTaskPageCount(any());
    }

    @Test
    public void getDifferenceTaskList_withAllFilters() {
        Map<String, Object> row = new HashMap<>();
        row.put("taskId", "task-001");
        row.put("resultName", "diff-result");
        row.put("taskState", 2);
        List<Map<String, Object>> data = Collections.singletonList(row);

        when(dataDifferenceRepository.selectTaskPage(any())).thenReturn(data);
        when(dataDifferenceRepository.selectTaskPageCount(any())).thenReturn(1L);

        BaseResultEntity result = dataDifferenceService.getDifferenceTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);

        assertEquals(0, result.getCode().intValue());
        verify(dataDifferenceRepository).selectTaskPage(any());
        verify(dataDifferenceRepository).selectTaskPageCount(any());
    }

    @Test
    public void getDifferenceTaskList_repositoryThrows_returnsFailure() {
        when(dataDifferenceRepository.selectTaskPage(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = dataDifferenceService.getDifferenceTaskList(null, null, null, null, null, 1, 10);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getDifferenceTaskDetails ====================

    @Test
    public void getDifferenceTaskDetails_existingTask_returnsDetail() {
        DataDifferenceTask task = createTask("task-uuid", 1);
        DataDifference diff = createDifference(1L);

        when(dataDifferenceRepository.selectTaskByTaskId(String.valueOf(TASK_ID))).thenReturn(task);
        when(dataDifferenceRepository.selectById(1L)).thenReturn(diff);

        BaseResultEntity result = dataDifferenceService.getDifferenceTaskDetails(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(dataDifferenceRepository).selectTaskByTaskId(String.valueOf(TASK_ID));
    }

    @Test
    public void getDifferenceTaskDetails_repositoryThrows_returnsFailure() {
        when(dataDifferenceRepository.selectTaskByTaskId(String.valueOf(TASK_ID)))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = dataDifferenceService.getDifferenceTaskDetails(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== downloadDifferenceTask ====================

    @Test
    public void downloadDifferenceTask_existingTask() {
        DataDifferenceTask task = createTask("task-uuid", 1);
        task.setFilePath("/tmp/test_result.csv");
        when(dataDifferenceRepository.selectTaskByTaskId(String.valueOf(TASK_ID))).thenReturn(task);

        dataDifferenceService.downloadDifferenceTask(response, TASK_ID);

        verify(dataDifferenceRepository).selectTaskByTaskId(String.valueOf(TASK_ID));
    }

    @Test
    public void downloadDifferenceTask_nullTask_doesNothing() {
        when(dataDifferenceRepository.selectTaskByTaskId(String.valueOf(TASK_ID))).thenReturn(null);

        dataDifferenceService.downloadDifferenceTask(response, TASK_ID);

        assertEquals(200, response.getStatus());
    }

    // ==================== delDifferenceTask ====================

    @Test
    public void delDifferenceTask_returnsSuccess() {
        doNothing().when(dataDifferencePrRepository).delDifferenceTask(TASK_ID);

        BaseResultEntity result = dataDifferenceService.delDifferenceTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(dataDifferencePrRepository).delDifferenceTask(TASK_ID);
    }

    @Test
    public void delDifferenceTask_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(dataDifferencePrRepository).delDifferenceTask(TASK_ID);

        BaseResultEntity result = dataDifferenceService.delDifferenceTask(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== cancelDifferenceTask ====================

    @Test
    public void cancelDifferenceTask_returnsSuccess() {
        BaseResultEntity result = dataDifferenceService.cancelDifferenceTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
    }

    @Test
    public void cancelDifferenceTask_returnsSuccessWhenNoRunningTask() {
        BaseResultEntity result = dataDifferenceService.cancelDifferenceTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
    }
}
