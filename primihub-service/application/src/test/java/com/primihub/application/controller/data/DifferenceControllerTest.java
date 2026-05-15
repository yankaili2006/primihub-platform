package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataDifferenceReq;
import com.primihub.biz.repository.primarydb.data.DataDifferencePrRepository;
import com.primihub.biz.repository.secondarydb.data.DataDifferenceRepository;
import com.primihub.biz.service.data.DataDifferenceService;
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
public class DifferenceControllerTest {

    @Mock
    private DataDifferenceService dataDifferenceService;

    @Mock
    private DataDifferenceRepository dataDifferenceRepository;

    @Mock
    private DataDifferencePrRepository dataDifferencePrRepository;

    @InjectMocks
    private DifferenceController controller;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;

    private BaseResultEntity successResult;

    @Before
    public void setUp() {
        successResult = BaseResultEntity.success();
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

    // ==================== saveDataDifference ====================

    @Test
    public void saveDataDifference_success() {
        DataDifferenceReq req = validReq();
        when(dataDifferenceService.saveDataDifference(req, USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertSame(successResult, result);
        verify(dataDifferenceService).saveDataDifference(req, USER_ID);
    }

    @Test
    public void saveDataDifference_invalidUserId_returnsLackOfParam() {
        BaseResultEntity result = controller.saveDataDifference(0L, validReq());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).saveDataDifference(any(), anyLong());
    }

    @Test
    public void saveDataDifference_missingOwnOrganId_returnsLackOfParam() {
        DataDifferenceReq req = validReq();
        req.setOwnOrganId(null);
        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).saveDataDifference(any(), anyLong());
    }

    @Test
    public void saveDataDifference_missingOwnResourceId_returnsLackOfParam() {
        DataDifferenceReq req = validReq();
        req.setOwnResourceId(null);
        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).saveDataDifference(any(), anyLong());
    }

    @Test
    public void saveDataDifference_missingResultName_returnsLackOfParam() {
        DataDifferenceReq req = validReq();
        req.setResultName(null);
        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).saveDataDifference(any(), anyLong());
    }

    @Test
    public void saveDataDifference_missingTag_returnsLackOfParam() {
        DataDifferenceReq req = validReq();
        req.setTag(null);
        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).saveDataDifference(any(), anyLong());
    }

    @Test
    public void saveDataDifference_missingDifferenceDirection_returnsLackOfParam() {
        DataDifferenceReq req = validReq();
        req.setDifferenceDirection(null);
        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).saveDataDifference(any(), anyLong());
    }

    // ==================== getDifferenceTaskList ====================

    @Test
    public void getDifferenceTaskList_success() {
        when(dataDifferenceService.getDifferenceTaskList("task1", null, null, null, null, 1, 10))
                .thenReturn(successResult);

        BaseResultEntity result = controller.getDifferenceTaskList("task1", null, null, null, null, 1, 10);
        assertSame(successResult, result);
        verify(dataDifferenceService).getDifferenceTaskList("task1", null, null, null, null, 1, 10);
    }

    @Test
    public void getDifferenceTaskList_withAllFilters() {
        when(dataDifferenceService.getDifferenceTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20))
                .thenReturn(successResult);

        BaseResultEntity result = controller.getDifferenceTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);
        assertSame(successResult, result);
        verify(dataDifferenceService).getDifferenceTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);
    }

    @Test
    public void getDifferenceTaskList_useDefaultPagination() {
        when(dataDifferenceService.getDifferenceTaskList(null, null, null, null, null, 1, 10))
                .thenReturn(successResult);

        BaseResultEntity result = controller.getDifferenceTaskList(null, null, null, null, null, 1, 10);
        assertSame(successResult, result);
        verify(dataDifferenceService).getDifferenceTaskList(null, null, null, null, null, 1, 10);
    }

    // ==================== getDifferenceTaskDetails ====================

    @Test
    public void getDifferenceTaskDetails_success() {
        when(dataDifferenceService.getDifferenceTaskDetails(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getDifferenceTaskDetails(TASK_ID);
        assertSame(successResult, result);
        verify(dataDifferenceService).getDifferenceTaskDetails(TASK_ID);
    }

    @Test
    public void getDifferenceTaskDetails_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getDifferenceTaskDetails(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).getDifferenceTaskDetails(any());
    }

    @Test
    public void getDifferenceTaskDetails_zeroTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getDifferenceTaskDetails(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).getDifferenceTaskDetails(any());
    }

    // ==================== downloadDifferenceTask ====================

    @Test
    public void downloadDifferenceTask_success() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadDifferenceTask(response, TASK_ID);
        verify(dataDifferenceService).downloadDifferenceTask(response, TASK_ID);
    }

    @Test
    public void downloadDifferenceTask_nullTaskId_returnsEarly() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadDifferenceTask(response, null);
        assertEquals(0, response.getContentAsByteArray().length);
        verify(dataDifferenceService, never()).downloadDifferenceTask(any(), any());
    }

    // ==================== delDifferenceTask ====================

    @Test
    public void delDifferenceTask_success() {
        when(dataDifferenceService.delDifferenceTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.delDifferenceTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataDifferenceService).delDifferenceTask(TASK_ID);
    }

    @Test
    public void delDifferenceTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.delDifferenceTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).delDifferenceTask(any());
    }

    // ==================== cancelDifferenceTask ====================

    @Test
    public void cancelDifferenceTask_success() {
        when(dataDifferenceService.cancelDifferenceTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.cancelDifferenceTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataDifferenceService).cancelDifferenceTask(TASK_ID);
    }

    @Test
    public void cancelDifferenceTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.cancelDifferenceTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataDifferenceService, never()).cancelDifferenceTask(any());
    }

    // ==================== exportDifferenceLog ====================

    @Test
    public void exportDifferenceLog_success() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.exportDifferenceLog(response, TASK_ID);
        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("difference_log.txt"));
    }

    @Test
    public void exportDifferenceLog_nullTaskId() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.exportDifferenceLog(response, null);
        assertEquals("text/plain;charset=UTF-8", response.getContentType());
    }

    // ===== 联邦查询功能 — Difference =====

    @Test public void testFunction_diff_saveDataDifference() {
        DataDifferenceReq req = validReq();
        when(dataDifferenceService.saveDataDifference(req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.saveDataDifference(USER_ID, req);
        assertNotNull(result);
    }

    @Test public void testFunction_diff_getTaskList() {
        when(dataDifferenceService.getDifferenceTaskList(null, null, null, null, null, 1, 10))
                .thenReturn(successResult);
        BaseResultEntity result = controller.getDifferenceTaskList(null, null, null, null, null, 1, 10);
        assertNotNull(result);
    }

    @Test public void testFunction_diff_getTaskDetails() {
        when(dataDifferenceService.getDifferenceTaskDetails(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getDifferenceTaskDetails(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_diff_downloadTask() {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        controller.downloadDifferenceTask(resp, TASK_ID);
        verify(dataDifferenceService).downloadDifferenceTask(resp, TASK_ID);
    }

    @Test public void testFunction_diff_deleteTask() {
        when(dataDifferenceService.delDifferenceTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.delDifferenceTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_diff_cancelTask() {
        when(dataDifferenceService.cancelDifferenceTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.cancelDifferenceTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_diff_exportLog() {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        controller.exportDifferenceLog(resp, TASK_ID);
        assertEquals("text/plain;charset=UTF-8", resp.getContentType());
    }

    @Test public void testFunction_diff_taskListWithFilters() {
        when(dataDifferenceService.getDifferenceTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20))
                .thenReturn(successResult);
        BaseResultEntity result = controller.getDifferenceTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);
        assertNotNull(result);
    }
}
