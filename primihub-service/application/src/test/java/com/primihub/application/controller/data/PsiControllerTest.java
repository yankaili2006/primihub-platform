package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.DataPsi;
import com.primihub.biz.entity.data.po.DataPsiTask;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.service.data.DataPsiService;
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
public class PsiControllerTest {

    @Mock
    private DataPsiService dataPsiService;

    @InjectMocks
    private PsiController controller;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;

    private BaseResultEntity successResult;
    private BaseResultEntity failureResult;

    @Before
    public void setUp() {
        successResult = BaseResultEntity.success();
        failureResult = BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
    }

    private DataPsiReq validPsiReq() {
        DataPsiReq req = new DataPsiReq();
        req.setOwnOrganId("orgA");
        req.setOwnResourceId("res-1");
        req.setOwnKeyword("keyword1");
        req.setOtherOrganId("orgB");
        req.setOtherResourceId("res-2");
        req.setOtherKeyword("keyword2");
        req.setResultName("psi-result");
        req.setResultOrganIds("orgA,orgB");
        req.setPsiTag(0);
        return req;
    }

    // ==================== saveDataPsi ====================

    @Test
    public void saveDataPsi_success() {
        DataPsiReq req = validPsiReq();
        when(dataPsiService.saveDataPsi(req, USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertSame(successResult, result);
        verify(dataPsiService).saveDataPsi(req, USER_ID);
    }

    @Test
    public void saveDataPsi_invalidUserId_returnsLackOfParam() {
        BaseResultEntity result = controller.saveDataPsi(0L, validPsiReq());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).saveDataPsi(any(), anyLong());
    }

    @Test
    public void saveDataPsi_missingOwnOrganId_returnsLackOfParam() {
        DataPsiReq req = validPsiReq();
        req.setOwnOrganId(null);
        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).saveDataPsi(any(), anyLong());
    }

    @Test
    public void saveDataPsi_missingOwnResourceId_returnsLackOfParam() {
        DataPsiReq req = validPsiReq();
        req.setOwnResourceId(null);
        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void saveDataPsi_missingResultName_returnsLackOfParam() {
        DataPsiReq req = validPsiReq();
        req.setResultName(null);
        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void saveDataPsi_teeTagWithoutTeeOrganId_returnsLackOfParam() {
        DataPsiReq req = validPsiReq();
        req.setPsiTag(2);
        req.setTeeOrganId(null);
        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
    }

    @Test
    public void saveDataPsi_teeTagWithTeeOrganId_success() {
        DataPsiReq req = validPsiReq();
        req.setPsiTag(2);
        req.setTeeOrganId("teeOrg");
        when(dataPsiService.saveDataPsi(req, USER_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertSame(successResult, result);
        verify(dataPsiService).saveDataPsi(req, USER_ID);
    }

    // ==================== updateDataPsiResultName ====================

    @Test
    public void updateDataPsiResultName_success() {
        DataPsiReq req = new DataPsiReq();
        req.setId(TASK_ID);
        req.setResultName("new-name");
        when(dataPsiService.updateDataPsiResultName(req)).thenReturn(successResult);

        BaseResultEntity result = controller.updateDataPsiResultName(req);
        assertSame(successResult, result);
        verify(dataPsiService).updateDataPsiResultName(req);
    }

    @Test
    public void updateDataPsiResultName_missingId_returnsLackOfParam() {
        DataPsiReq req = new DataPsiReq();
        req.setResultName("new-name");
        BaseResultEntity result = controller.updateDataPsiResultName(req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).updateDataPsiResultName(any());
    }

    @Test
    public void updateDataPsiResultName_missingResultName_returnsLackOfParam() {
        DataPsiReq req = new DataPsiReq();
        req.setId(TASK_ID);
        BaseResultEntity result = controller.updateDataPsiResultName(req);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).updateDataPsiResultName(any());
    }

    // ==================== getPsiResourceList ====================

    @Test
    public void getPsiResourceList_success() {
        DataResourceReq req = new DataResourceReq();
        when(dataPsiService.getPsiResourceList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getPsiResourceList(req, 1L);
        assertSame(successResult, result);
        verify(dataPsiService).getPsiResourceList(req);
    }

    // ==================== getPsiResourceAllocationList ====================

    @Test
    public void getPsiResourceAllocationList_success() {
        PageReq req = new PageReq();
        when(dataPsiService.getPsiResourceAllocationList(req, "orgA", "res")).thenReturn(successResult);

        BaseResultEntity result = controller.getPsiResourceDataList(req, "orgA", "res");
        assertSame(successResult, result);
        verify(dataPsiService).getPsiResourceAllocationList(req, "orgA", "res");
    }

    @Test
    public void getPsiResourceAllocationList_withNullParams() {
        PageReq req = new PageReq();
        when(dataPsiService.getPsiResourceAllocationList(req, null, null)).thenReturn(successResult);

        BaseResultEntity result = controller.getPsiResourceDataList(req, null, null);
        assertSame(successResult, result);
        verify(dataPsiService).getPsiResourceAllocationList(req, null, null);
    }

    // ==================== getPsiTaskList ====================

    @Test
    public void getPsiTaskList_success() {
        DataPsiQueryReq req = new DataPsiQueryReq();
        when(dataPsiService.getPsiTaskList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getPsiTaskList(req);
        assertSame(successResult, result);
        verify(dataPsiService).getPsiTaskList(req);
    }

    @Test
    public void getPsiTaskList_withFilters() {
        DataPsiQueryReq req = new DataPsiQueryReq();
        req.setTaskName("test-psi");
        req.setTaskState(1);
        req.setStartDate("2025-01-01");
        req.setEndDate("2025-12-31");
        when(dataPsiService.getPsiTaskList(req)).thenReturn(successResult);

        BaseResultEntity result = controller.getPsiTaskList(req);
        assertSame(successResult, result);
        verify(dataPsiService).getPsiTaskList(req);
    }

    // ==================== getOrganPsiTask ====================

    @Test
    public void getOrganPsiTask_success() {
        PageReq req = new PageReq();
        when(dataPsiService.getOrganPsiTask(USER_ID, "result1", req)).thenReturn(successResult);

        BaseResultEntity result = controller.getOrganPsiTask(USER_ID, "result1", req);
        assertSame(successResult, result);
        verify(dataPsiService).getOrganPsiTask(USER_ID, "result1", req);
    }

    @Test
    public void getOrganPsiTask_invalidUserId_returnsLackOfParam() {
        BaseResultEntity result = controller.getOrganPsiTask(0L, "test", new PageReq());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).getOrganPsiTask(anyLong(), anyString(), any());
    }

    // ==================== getPsiTaskDetails ====================

    @Test
    public void getPsiTaskDetails_success() {
        when(dataPsiService.getPsiTaskDetails(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.getPsiTaskDetails(TASK_ID);
        assertSame(successResult, result);
        verify(dataPsiService).getPsiTaskDetails(TASK_ID);
    }

    @Test
    public void getPsiTaskDetails_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getPsiTaskDetails(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).getPsiTaskDetails(any());
    }

    @Test
    public void getPsiTaskDetails_zeroTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.getPsiTaskDetails(0L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).getPsiTaskDetails(any());
    }

    // ==================== downloadPsiTask ====================

    @Test
    public void downloadPsiTask_nullTaskId_returnsEarly() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadPsiTask(response, null);
        assertEquals(0, response.getContentAsByteArray().length);
    }

    @Test
    public void downloadPsiTask_zeroTaskId_returnsEarly() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        controller.downloadPsiTask(response, 0L);
        assertEquals(0, response.getContentAsByteArray().length);
    }

    // ==================== delPsiTask ====================

    @Test
    public void delPsiTask_success() {
        when(dataPsiService.delPsiTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.delPsiTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataPsiService).delPsiTask(TASK_ID);
    }

    @Test
    public void delPsiTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.delPsiTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).delPsiTask(any());
    }

    // ==================== cancelPsiTask ====================

    @Test
    public void cancelPsiTask_success() {
        when(dataPsiService.cancelPsiTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.cancelPsiTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataPsiService).cancelPsiTask(TASK_ID);
    }

    @Test
    public void cancelPsiTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.cancelPsiTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).cancelPsiTask(any());
    }

    // ==================== retryPsiTask ====================

    @Test
    public void retryPsiTask_success() {
        when(dataPsiService.retryPsiTask(TASK_ID)).thenReturn(successResult);

        BaseResultEntity result = controller.retryPsiTask(TASK_ID);
        assertSame(successResult, result);
        verify(dataPsiService).retryPsiTask(TASK_ID);
    }

    @Test
    public void retryPsiTask_nullTaskId_returnsLackOfParam() {
        BaseResultEntity result = controller.retryPsiTask(null);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(dataPsiService, never()).retryPsiTask(any());
    }

    // ===== 联邦查询功能 — PSI =====

    @Test public void testFunction_psi_saveDataPsi() {
        DataPsiReq req = validPsiReq();
        when(dataPsiService.saveDataPsi(req, USER_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.saveDataPsi(USER_ID, req);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_updateResultName() {
        DataPsiReq req = new DataPsiReq();
        req.setId(TASK_ID);
        req.setResultName("new-name");
        when(dataPsiService.updateDataPsiResultName(req)).thenReturn(successResult);
        BaseResultEntity result = controller.updateDataPsiResultName(req);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_getResourceList() {
        DataResourceReq req = new DataResourceReq();
        when(dataPsiService.getPsiResourceList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getPsiResourceList(req, 1L);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_getTaskList() {
        DataPsiQueryReq req = new DataPsiQueryReq();
        when(dataPsiService.getPsiTaskList(req)).thenReturn(successResult);
        BaseResultEntity result = controller.getPsiTaskList(req);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_getTaskDetails() {
        when(dataPsiService.getPsiTaskDetails(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.getPsiTaskDetails(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_downloadTask() {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        when(dataPsiService.getPsiTaskDetails(TASK_ID)).thenReturn(successResult);
        controller.downloadPsiTask(resp, TASK_ID);
    }

    @Test public void testFunction_psi_deleteTask() {
        when(dataPsiService.delPsiTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.delPsiTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_cancelTask() {
        when(dataPsiService.cancelPsiTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.cancelPsiTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_retryTask() {
        when(dataPsiService.retryPsiTask(TASK_ID)).thenReturn(successResult);
        BaseResultEntity result = controller.retryPsiTask(TASK_ID);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_getOrganPsiTask() {
        PageReq req = new PageReq();
        when(dataPsiService.getOrganPsiTask(USER_ID, "result1", req)).thenReturn(successResult);
        BaseResultEntity result = controller.getOrganPsiTask(USER_ID, "result1", req);
        assertNotNull(result);
    }

    @Test public void testFunction_psi_getResourceAllocation() {
        PageReq req = new PageReq();
        when(dataPsiService.getPsiResourceAllocationList(req, "orgA", "res")).thenReturn(successResult);
        BaseResultEntity result = controller.getPsiResourceDataList(req, "orgA", "res");
        assertNotNull(result);
    }
}
