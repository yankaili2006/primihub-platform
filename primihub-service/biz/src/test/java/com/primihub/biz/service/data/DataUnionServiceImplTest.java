package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.DataUnion;
import com.primihub.biz.entity.data.po.DataUnionTask;
import com.primihub.biz.entity.data.req.DataUnionReq;
import com.primihub.biz.repository.primarydb.data.DataUnionPrRepository;
import com.primihub.biz.repository.secondarydb.data.DataUnionRepository;
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
public class DataUnionServiceImplTest {

    @Mock
    private LogManagementService logManagementService;

    @Mock
    private DataUnionRepository dataUnionRepository;

    @Mock
    private DataUnionPrRepository dataUnionPrRepository;

    @InjectMocks
    private DataUnionService dataUnionService;

    @Captor
    private ArgumentCaptor<DataUnion> unionCaptor;

    @Captor
    private ArgumentCaptor<DataUnionTask> taskCaptor;

    private MockHttpServletResponse response;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;

    @Before
    public void setUp() {
        response = new MockHttpServletResponse();
    }

    private DataUnionReq validReq() {
        DataUnionReq req = new DataUnionReq();
        req.setOwnOrganId("orgA");
        req.setOwnResourceId("res-1");
        req.setOwnKeyword("keyword1");
        req.setOtherOrganId("orgB");
        req.setOtherResourceId("res-2");
        req.setOtherKeyword("keyword2");
        req.setResultName("union-result");
        req.setResultOrganIds("orgA,orgB");
        req.setTag(0);
        return req;
    }

    private DataUnionTask createTask(String taskId, Integer state) {
        DataUnionTask task = new DataUnionTask();
        task.setId(TASK_ID);
        task.setUnionId(1L);
        task.setTaskId(taskId);
        task.setTaskState(state);
        task.setFilePath("/tmp/union_result.csv");
        return task;
    }

    private DataUnion createUnion(Long id) {
        DataUnion union = new DataUnion();
        union.setId(id);
        union.setOwnOrganId("orgA");
        union.setOwnResourceId("res-1");
        union.setResultName("union-result");
        union.setUserId(USER_ID);
        return union;
    }

    // ==================== saveDataUnion ====================

    @Test
    public void saveDataUnion_success() {
        DataUnionReq req = validReq();
        doNothing().when(logManagementService).recordComputeLog(any());

        BaseResultEntity result = dataUnionService.saveDataUnion(req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        assertNotNull(result.getResult());
        verify(logManagementService).recordComputeLog(any());
    }

    @Test
    public void saveDataUnion_repositoryThrows_returnsFailure() {
        DataUnionReq req = validReq();
        doThrow(new RuntimeException("DB error")).when(logManagementService).recordComputeLog(any());

        BaseResultEntity result = dataUnionService.saveDataUnion(req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
        assertTrue(result.getMsg().contains("创建任务失败"));
    }

    // ==================== getUnionTaskList ====================

    @Test
    public void getUnionTaskList_returnsSuccess() {
        when(dataUnionRepository.selectTaskPage(any())).thenReturn(Collections.emptyList());
        when(dataUnionRepository.selectTaskPageCount(any())).thenReturn(0L);

        BaseResultEntity result = dataUnionService.getUnionTaskList(null, null, null, null, null, 1, 10);

        assertEquals(0, result.getCode().intValue());
        verify(dataUnionRepository).selectTaskPage(any());
        verify(dataUnionRepository).selectTaskPageCount(any());
    }

    @Test
    public void getUnionTaskList_withAllFilters() {
        Map<String, Object> row = new HashMap<>();
        row.put("taskId", "task-001");
        row.put("resultName", "union-result");
        row.put("taskState", 2);
        List<Map<String, Object>> data = Collections.singletonList(row);

        when(dataUnionRepository.selectTaskPage(any())).thenReturn(data);
        when(dataUnionRepository.selectTaskPageCount(any())).thenReturn(1L);

        BaseResultEntity result = dataUnionService.getUnionTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);

        assertEquals(0, result.getCode().intValue());
        verify(dataUnionRepository).selectTaskPage(any());
        verify(dataUnionRepository).selectTaskPageCount(any());
    }

    @Test
    public void getUnionTaskList_repositoryThrows_returnsFailure() {
        when(dataUnionRepository.selectTaskPage(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = dataUnionService.getUnionTaskList(null, null, null, null, null, 1, 10);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getUnionTaskDetails ====================

    @Test
    public void getUnionTaskDetails_existingTask_returnsDetail() {
        DataUnionTask task = createTask("task-uuid", 1);
        DataUnion union = createUnion(1L);

        when(dataUnionRepository.selectTaskByTaskId(String.valueOf(TASK_ID))).thenReturn(task);
        when(dataUnionRepository.selectById(1L)).thenReturn(union);

        BaseResultEntity result = dataUnionService.getUnionTaskDetails(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(dataUnionRepository).selectTaskByTaskId(String.valueOf(TASK_ID));
    }

    @Test
    public void getUnionTaskDetails_repositoryThrows_returnsFailure() {
        when(dataUnionRepository.selectTaskByTaskId(String.valueOf(TASK_ID)))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = dataUnionService.getUnionTaskDetails(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== downloadUnionTask ====================

    @Test
    public void downloadUnionTask_existingTask() {
        DataUnionTask task = createTask("task-uuid", 1);
        task.setFilePath("/tmp/test_result.csv");
        when(dataUnionRepository.selectTaskByTaskId(String.valueOf(TASK_ID))).thenReturn(task);

        dataUnionService.downloadUnionTask(response, TASK_ID);

        verify(dataUnionRepository).selectTaskByTaskId(String.valueOf(TASK_ID));
    }

    @Test
    public void downloadUnionTask_nullTask_doesNothing() {
        when(dataUnionRepository.selectTaskByTaskId(String.valueOf(TASK_ID))).thenReturn(null);

        dataUnionService.downloadUnionTask(response, TASK_ID);

        assertEquals(200, response.getStatus());
    }

    // ==================== delUnionTask ====================

    @Test
    public void delUnionTask_returnsSuccess() {
        doNothing().when(dataUnionPrRepository).delUnionTask(TASK_ID);

        BaseResultEntity result = dataUnionService.delUnionTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(dataUnionPrRepository).delUnionTask(TASK_ID);
    }

    @Test
    public void delUnionTask_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(dataUnionPrRepository).delUnionTask(TASK_ID);

        BaseResultEntity result = dataUnionService.delUnionTask(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== cancelUnionTask ====================

    @Test
    public void cancelUnionTask_returnsSuccess() {
        BaseResultEntity result = dataUnionService.cancelUnionTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
    }

    @Test
    public void cancelUnionTask_returnsSuccessWhenNoRunningTask() {
        BaseResultEntity result = dataUnionService.cancelUnionTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
    }
}
