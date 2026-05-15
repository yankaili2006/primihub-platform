package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataUnionReq;
import com.primihub.biz.repository.primarydb.data.DataUnionPrRepository;
import com.primihub.biz.repository.secondarydb.data.DataUnionRepository;
import com.primihub.biz.service.data.DataUnionService;
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
public class UnionControllerTest {

    @Mock
    private DataUnionService dataUnionService;

    @Mock
    private DataUnionRepository dataUnionRepository;

    @Mock
    private DataUnionPrRepository dataUnionPrRepository;

    @InjectMocks
    private UnionController controller;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;

    private BaseResultEntity successResult;

    @Before
    public void setUp() {
        successResult = BaseResultEntity.success();
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

    // ==================== saveDataUnion ====================

    @Test
    public void saveDataUnion_success() {
        DataUnionReq req = validReq();
        when(dataUnionService.saveDataUnion(req, USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertSame(successResult, result);
        verify(dataUnionService).saveDataUnion(req, USER_ID);
    }

    @Test
    public void saveDataUnion_invalidUserId_returnsLackOfParam() {
        BaseResultEntity result = controller.saveDataUnion(0L, validReq());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).saveDataUnion(any(), anyLong());
    }

    @Test
    public void saveDataUnion_missingOwnOrganId_returnsLackOfParam() {
        DataUnionReq req = validReq();
        req.setOwnOrganId(null);
        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).saveDataUnion(any(), anyLong());
    }

    @Test
    public void saveDataUnion_missingOwnResourceId_returnsLackOfParam() {
        DataUnionReq req = validReq();
        req.setOwnResourceId(null);
        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).saveDataUnion(any(), anyLong());
    }

    @Test
    public void saveDataUnion_missingResultName_returnsLackOfParam() {
        DataUnionReq req = validReq();
        req.setResultName(null);
        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).saveDataUnion(any(), anyLong());
    }

    @Test
    public void saveDataUnion_missingResultOrganIds_returnsLackOfParam() {
        DataUnionReq req = validReq();
        req.setResultOrganIds(null);
        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).saveDataUnion(any(), anyLong());
    }

    @Test
    public void saveDataUnion_missingTag_returnsLackOfParam() {
        DataUnionReq req = validReq();
        req.setTag(null);
        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).saveDataUnion(any(), anyLong());
    }

    // ==================== getUnionTaskList ====================

    @Test
    public void getUnionTaskList_success() {
        when(dataUnionService.getUnionTaskList("task1", null, null, null, null, 1, 10))
                .thenReturn(successResult);

        BaseResultEntity result = controller.getUnionTaskList("task1", null, null, null, null, 1, 10);
        assertSame(successResult, result);
        verify(dataUnionService).getUnionTaskList("task1", null, null, null, null, 1, 10);
    }

    @Test
    public void getUnionTaskList_withAllFilters() {
        when(dataUnionService.getUnionTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20))
                .thenReturn(successResult);

        BaseResultEntity result = controller.getUnionTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);
        assertSame(successResult, result);
        verify(dataUnionService).getUnionTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);
    }

    @Test
    public void getUnionTaskList_defaultPagination() {
        when(dataUnionService.getUnionTaskList(null, null, null, null, null, 1, 10))
                .thenReturn(successResult);

        BaseResultEntity result = controller.getUnionTaskList(null, null, null, null, null, 1, 10);
        assertSame(successResult, result);
        verify(dataUnionService).getUnionTaskList(null, null, null, null, null, 1, 10);
    }

    // ==================== getUnionTaskDetails ====================

    @Test
    public void getUnionTaskDetails_success() {
        when(dataUnionService.getUnionTaskDetails(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getUnionTaskDetails(TASK_ID);
        assertSame(successResult, result);
        verify(dataUnionService).getUnionTaskDetails(TASK_ID);
    }

    @Test
    public void getUnionTaskDetails_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getUnionTaskDetails(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).getUnionTaskDetails(any());
    }

    @Test
    public void getUnionTaskDetails_zeroTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getUnionTaskDetails(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).getUnionTaskDetails(any());
    }

    // ==================== downloadUnionTask ====================

    @Test
    public void downloadUnionTask_success() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadUnionTask(response, TASK_ID);
        verify(dataUnionService).downloadUnionTask(response, TASK_ID);
    }

    @Test
    public void downloadUnionTask_nullTaskId_returnsEarly() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadUnionTask(response, null);
        assertEquals(0, response.getContentAsByteArray().length);
        verify(dataUnionService, never()).downloadUnionTask(any(), any());
    }

    @Test
    public void downloadUnionTask_zeroTaskId_returnsEarly() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadUnionTask(response, 0L);
        assertEquals(0, response.getContentAsByteArray().length);
        verify(dataUnionService, never()).downloadUnionTask(any(), any());
    }

    // ==================== delUnionTask ====================

    @Test
    public void delUnionTask_success() {
        when(dataUnionService.delUnionTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.delUnionTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataUnionService).delUnionTask(TASK_ID);
    }

    @Test
    public void delUnionTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.delUnionTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).delUnionTask(any());
    }

    // ==================== cancelUnionTask ====================

    @Test
    public void cancelUnionTask_success() {
        when(dataUnionService.cancelUnionTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.cancelUnionTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataUnionService).cancelUnionTask(TASK_ID);
    }

    @Test
    public void cancelUnionTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.cancelUnionTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataUnionService, never()).cancelUnionTask(any());
    }

    // ==================== exportUnionLog ====================

    @Test
    public void exportUnionLog_success() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.exportUnionLog(response, TASK_ID);
        assertEquals("text/plain;charset=UTF-8", response.getContentType());
        assertTrue(response.getHeader("Content-Disposition").contains("union_log.txt"));
    }

    @Test
    public void exportUnionLog_nullTaskId() {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.exportUnionLog(response, null);
        assertEquals("text/plain;charset=UTF-8", response.getContentType());
    }

    // ===== 联邦查询功能 — Union =====

    @Test public void testFunction_union_saveDataUnion() {
        DataUnionReq req = validReq();
        when(dataUnionService.saveDataUnion(req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.saveDataUnion(USER_ID, req);
        assertNotNull(result);
    }

    @Test public void testFunction_union_getTaskList() {
        when(dataUnionService.getUnionTaskList(null, null, null, null, null, 1, 10))
                .thenReturn(successResult);
        BaseResultEntity result = controller.getUnionTaskList(null, null, null, null, null, 1, 10);
        assertNotNull(result);
    }

    @Test public void testFunction_union_getTaskDetails() {
        when(dataUnionService.getUnionTaskDetails(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getUnionTaskDetails(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_union_downloadTask() {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        controller.downloadUnionTask(resp, TASK_ID);
        verify(dataUnionService).downloadUnionTask(resp, TASK_ID);
    }

    @Test public void testFunction_union_deleteTask() {
        when(dataUnionService.delUnionTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.delUnionTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_union_cancelTask() {
        when(dataUnionService.cancelUnionTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.cancelUnionTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_union_exportLog() {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        controller.exportUnionLog(resp, TASK_ID);
        assertEquals("text/plain;charset=UTF-8", resp.getContentType());
    }

    @Test public void testFunction_union_taskListWithFilters() {
        when(dataUnionService.getUnionTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20))
                .thenReturn(successResult);
        BaseResultEntity result = controller.getUnionTaskList("test", 1, "orgA", "2025-01-01", "2025-12-31", 2, 20);
        assertNotNull(result);
    }
}
