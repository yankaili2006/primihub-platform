package com.primihub.biz.service.data.impl;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.SceneApiConfig;
import com.primihub.biz.entity.data.po.SceneKeyConfig;
import com.primihub.biz.entity.data.po.SceneTask;
import com.primihub.biz.repository.primarydb.data.ScenePrimarydbRepository;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.*;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class SceneServiceImplTest {

    @Mock
    private ScenePrimarydbRepository sceneRepository;

    @InjectMocks
    private SceneServiceImpl sceneService;

    @Captor
    private ArgumentCaptor<SceneTask> taskCaptor;

    @Captor
    private ArgumentCaptor<SceneApiConfig> apiConfigCaptor;

    @Captor
    private ArgumentCaptor<SceneKeyConfig> keyConfigCaptor;

    private static final Long USER_ID = 1L;
    private static final Long TASK_ID = 100L;
    private static final Long API_CONFIG_ID = 200L;
    private static final Long KEY_ID = 300L;

    @Before
    public void setUp() {
    }

    private SceneTask createTask(Long id, String sceneType, Integer state) {
        SceneTask task = new SceneTask();
        task.setId(id);
        task.setSceneType(sceneType);
        task.setTaskName("test-task");
        task.setTaskType("query");
        task.setParams("{}");
        task.setTaskState(state);
        task.setCreatedBy(USER_ID);
        task.setCreatedAt(new Date());
        return task;
    }

    private SceneApiConfig createApiConfig(Long id, String apiName, String apiUrl) {
        SceneApiConfig config = new SceneApiConfig();
        config.setId(id);
        config.setSceneType("police");
        config.setApiName(apiName);
        config.setApiUrl(apiUrl);
        config.setProtocol("REST");
        config.setStatus(1);
        config.setCreatedBy(USER_ID);
        return config;
    }

    // ==================== createTask ====================

    @Test
    public void createTask_returnsTaskIdAndStatus() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskType", "query");
        req.put("taskName", "police-query");

        doAnswer(invocation -> {
            SceneTask task = invocation.getArgument(0);
            task.setId(TASK_ID);
            task.setCreatedAt(new Date());
            return null;
        }).when(sceneRepository).insertSceneTask(taskCaptor.capture());

        BaseResultEntity result = sceneService.createTask("police", req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(TASK_ID, map.get("taskId"));
        assertEquals("police", map.get("sceneType"));
        assertEquals(0, map.get("status"));

        SceneTask captured = taskCaptor.getValue();
        assertEquals("police", captured.getSceneType());
        assertEquals("query", captured.getTaskType());
        assertEquals("police-query", captured.getTaskName());
        assertEquals(Integer.valueOf(0), captured.getTaskState());
        assertEquals(USER_ID, captured.getCreatedBy());
    }

    @Test
    public void createTask_withoutTaskName_defaultsToTaskType() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskType", "cert_query");

        doAnswer(invocation -> {
            ((SceneTask) invocation.getArgument(0)).setId(TASK_ID);
            return null;
        }).when(sceneRepository).insertSceneTask(taskCaptor.capture());

        sceneService.createTask("electronic_cert", req, USER_ID);

        assertEquals("cert_query", taskCaptor.getValue().getTaskName());
    }

    @Test
    public void createTask_withParamsInRequest_serializesCorrectly() {
        Map<String, Object> inner = new HashMap<>();
        inner.put("certId", "abc123");
        Map<String, Object> req = new HashMap<>();
        req.put("taskType", "verify");
        req.put("params", inner);

        doAnswer(invocation -> {
            ((SceneTask) invocation.getArgument(0)).setId(TASK_ID);
            return null;
        }).when(sceneRepository).insertSceneTask(taskCaptor.capture());

        sceneService.createTask("electronic_cert", req, USER_ID);

        assertTrue(taskCaptor.getValue().getParams().contains("abc123"));
    }

    @Test
    public void createTask_repositoryThrows_returnsFailure() {
        Map<String, Object> req = new HashMap<>();
        req.put("taskType", "query");
        doThrow(new RuntimeException("DB error")).when(sceneRepository).insertSceneTask(any());

        BaseResultEntity result = sceneService.createTask("police", req, USER_ID);

        assertEquals(BaseResultEnum.DATA_SAVE_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== getTaskList ====================

    @Test
    public void getTaskList_returnsPaginatedResults() {
        SceneTask task = createTask(TASK_ID, "police", 0);
        when(sceneRepository.selectSceneTaskCount(any())).thenReturn(1);
        when(sceneRepository.selectSceneTaskList(any())).thenReturn(Collections.singletonList(task));

        BaseResultEntity result = sceneService.getTaskList("police", "query", 1, 10);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("pageParam"));
        List<?> list = (List<?>) map.get("list");
        assertEquals(1, list.size());
    }

    @Test
    public void getTaskList_empty_returnsEmpty() {
        when(sceneRepository.selectSceneTaskCount(any())).thenReturn(0);
        when(sceneRepository.selectSceneTaskList(any())).thenReturn(Collections.emptyList());

        BaseResultEntity result = sceneService.getTaskList("police", null, null, null);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertTrue(((List<?>) map.get("list")).isEmpty());
    }

    @Test
    public void getTaskList_defaultsPagination() {
        when(sceneRepository.selectSceneTaskCount(any())).thenReturn(0);
        when(sceneRepository.selectSceneTaskList(any())).thenReturn(Collections.emptyList());

        sceneService.getTaskList(null, null, null, null);

        verify(sceneRepository).selectSceneTaskCount(argThat(m ->
                m.get("pageNo") == null));
    }

    @Test
    public void getTaskList_repositoryThrows_returnsFailure() {
        when(sceneRepository.selectSceneTaskCount(any())).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = sceneService.getTaskList("police", null, 1, 10);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getTaskDetail ====================

    @Test
    public void getTaskDetail_existingTask_returnsTask() {
        SceneTask task = createTask(TASK_ID, "police", 2);
        when(sceneRepository.selectSceneTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = sceneService.getTaskDetail(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        SceneTask returned = (SceneTask) result.getResult();
        assertEquals(TASK_ID, returned.getId());
        assertEquals(Integer.valueOf(2), returned.getTaskState());
    }

    @Test
    public void getTaskDetail_nullTask_returnsDataQueryNull() {
        when(sceneRepository.selectSceneTaskById(999L)).thenReturn(null);

        BaseResultEntity result = sceneService.getTaskDetail(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void getTaskDetail_repositoryThrows_returnsFailure() {
        when(sceneRepository.selectSceneTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = sceneService.getTaskDetail(TASK_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== executeTask ====================

    @Test
    public void executeTask_existingTask_updatesStateAndReturnsSuccess() {
        SceneTask task = createTask(TASK_ID, "police", 0);
        when(sceneRepository.selectSceneTaskById(TASK_ID)).thenReturn(task);

        BaseResultEntity result = sceneService.executeTask(TASK_ID);

        assertEquals(0, result.getCode().intValue());
        verify(sceneRepository).updateSceneTask(taskCaptor.capture());
        assertEquals(Integer.valueOf(1), taskCaptor.getValue().getTaskState());
        assertNotNull(taskCaptor.getValue().getResultData());
    }

    @Test
    public void executeTask_nullTask_returnsDataQueryNull() {
        when(sceneRepository.selectSceneTaskById(999L)).thenReturn(null);

        BaseResultEntity result = sceneService.executeTask(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(sceneRepository, never()).updateSceneTask(any());
    }

    @Test
    public void executeTask_repositoryThrows_returnsFailure() {
        when(sceneRepository.selectSceneTaskById(TASK_ID)).thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = sceneService.executeTask(TASK_ID);

        assertEquals(BaseResultEnum.DATA_RUN_TASK_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== saveApiConfig ====================

    @Test
    public void saveApiConfig_createNew_savesAndReturnsSuccess() {
        Map<String, Object> req = new HashMap<>();
        req.put("apiName", "DataQuery");
        req.put("apiUrl", "http://api.example.com/query");
        req.put("protocol", "REST");
        req.put("authType", "apikey");
        req.put("apiKey", "sk-xxx");

        BaseResultEntity result = sceneService.saveApiConfig("police", req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(sceneRepository).insertSceneApiConfig(apiConfigCaptor.capture());
        SceneApiConfig captured = apiConfigCaptor.getValue();
        assertEquals("police", captured.getSceneType());
        assertEquals("DataQuery", captured.getApiName());
        assertEquals("http://api.example.com/query", captured.getApiUrl());
        assertEquals("REST", captured.getProtocol());
        assertEquals(Integer.valueOf(1), captured.getStatus());
        assertEquals(USER_ID, captured.getCreatedBy());
    }

    @Test
    public void saveApiConfig_updateExisting_updatesAndReturnsSuccess() {
        SceneApiConfig existing = createApiConfig(API_CONFIG_ID, "OldName", "http://old.url");
        when(sceneRepository.selectSceneApiConfigById(API_CONFIG_ID)).thenReturn(existing);

        Map<String, Object> req = new HashMap<>();
        req.put("id", API_CONFIG_ID);
        req.put("apiName", "UpdatedQuery");
        req.put("apiUrl", "http://new.url/query");
        req.put("protocol", "REST");
        req.put("status", 0);

        BaseResultEntity result = sceneService.saveApiConfig("police", req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        verify(sceneRepository).updateSceneApiConfig(apiConfigCaptor.capture());
        SceneApiConfig captured = apiConfigCaptor.getValue();
        assertEquals(API_CONFIG_ID, captured.getId());
        assertEquals("UpdatedQuery", captured.getApiName());
        assertEquals("http://new.url/query", captured.getApiUrl());
    }

    @Test
    public void saveApiConfig_updateNonExisting_returnsDataQueryNull() {
        when(sceneRepository.selectSceneApiConfigById(999L)).thenReturn(null);

        Map<String, Object> req = new HashMap<>();
        req.put("id", 999L);
        req.put("apiName", "NotFound");
        req.put("apiUrl", "http://url");

        BaseResultEntity result = sceneService.saveApiConfig("police", req, USER_ID);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
        verify(sceneRepository, never()).updateSceneApiConfig(any());
    }

    @Test
    public void saveApiConfig_emptyNameOrUrl_returnsLackOfParam() {
        Map<String, Object> req = new HashMap<>();
        req.put("apiName", "");
        req.put("apiUrl", "http://url");

        BaseResultEntity result = sceneService.saveApiConfig("police", req, USER_ID);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(sceneRepository, never()).insertSceneApiConfig(any());
    }

    @Test
    public void saveApiConfig_repositoryThrows_returnsFailure() {
        Map<String, Object> req = new HashMap<>();
        req.put("apiName", "Test");
        req.put("apiUrl", "http://url");
        doThrow(new RuntimeException("DB error")).when(sceneRepository).insertSceneApiConfig(any());

        BaseResultEntity result = sceneService.saveApiConfig("police", req, USER_ID);

        assertEquals(BaseResultEnum.DATA_SAVE_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== getApiConfigList ====================

    @Test
    public void getApiConfigList_returnsList() {
        SceneApiConfig config = createApiConfig(API_CONFIG_ID, "Query", "http://url");
        when(sceneRepository.selectSceneApiConfigList("police"))
                .thenReturn(Collections.singletonList(config));

        BaseResultEntity result = sceneService.getApiConfigList("police");

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(1, list.size());
    }

    @Test
    public void getApiConfigList_empty_returnsEmpty() {
        when(sceneRepository.selectSceneApiConfigList("police")).thenReturn(Collections.emptyList());

        BaseResultEntity result = sceneService.getApiConfigList("police");

        assertEquals(0, result.getCode().intValue());
        assertTrue(((List<?>) result.getResult()).isEmpty());
    }

    @Test
    public void getApiConfigList_repositoryThrows_returnsFailure() {
        when(sceneRepository.selectSceneApiConfigList("police"))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = sceneService.getApiConfigList("police");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== deleteApiConfig ====================

    @Test
    public void deleteApiConfig_returnsSuccess() {
        BaseResultEntity result = sceneService.deleteApiConfig(API_CONFIG_ID);

        assertEquals(0, result.getCode().intValue());
        verify(sceneRepository).deleteSceneApiConfig(API_CONFIG_ID);
    }

    @Test
    public void deleteApiConfig_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(sceneRepository).deleteSceneApiConfig(API_CONFIG_ID);

        BaseResultEntity result = sceneService.deleteApiConfig(API_CONFIG_ID);

        assertEquals(BaseResultEnum.DATA_DEL_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== testApiConnection ====================

    @Test
    public void testApiConnection_configNotFound_returnsDataQueryNull() {
        when(sceneRepository.selectSceneApiConfigById(999L)).thenReturn(null);

        BaseResultEntity result = sceneService.testApiConnection(999L);

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void testApiConnection_connectionFails_returnsConnectedFalse() {
        SceneApiConfig config = createApiConfig(API_CONFIG_ID, "Test", "http://invalid-url");
        when(sceneRepository.selectSceneApiConfigById(API_CONFIG_ID)).thenReturn(config);

        BaseResultEntity result = sceneService.testApiConnection(API_CONFIG_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertFalse((Boolean) map.get("connected"));
    }

    // ==================== callApi ====================

    @Test
    public void callApi_configNotFound_returnsDataQueryNull() {
        when(sceneRepository.selectSceneApiConfigById(999L)).thenReturn(null);

        BaseResultEntity result = sceneService.callApi(999L, new HashMap<>());

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void callApi_connectionFails_returnsFailure() {
        SceneApiConfig config = createApiConfig(API_CONFIG_ID, "Test", "http://invalid");
        when(sceneRepository.selectSceneApiConfigById(API_CONFIG_ID)).thenReturn(config);

        BaseResultEntity result = sceneService.callApi(API_CONFIG_ID, new HashMap<>());

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== generateKey ====================

    @Test
    public void generateKey_generatesRSAKeyAndSaves() {
        Map<String, Object> req = new HashMap<>();
        req.put("scheme", "RSA");
        req.put("keySize", 2048);
        req.put("keyName", "test-key");

        doAnswer(invocation -> {
            SceneKeyConfig config = invocation.getArgument(0);
            config.setId(KEY_ID);
            return null;
        }).when(sceneRepository).insertSceneKeyConfig(keyConfigCaptor.capture());

        BaseResultEntity result = sceneService.generateKey("police", req, USER_ID);

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertEquals(KEY_ID, map.get("keyId"));
        assertEquals("test-key", map.get("keyName"));
        assertEquals("RSA", map.get("scheme"));
        assertEquals(2048, map.get("keySize"));

        SceneKeyConfig captured = keyConfigCaptor.getValue();
        assertEquals("police", captured.getSceneType());
        assertEquals("test-key", captured.getKeyName());
        assertEquals("RSA", captured.getScheme());
        assertEquals(Integer.valueOf(2048), captured.getKeySize());
        assertEquals(Integer.valueOf(1), captured.getStatus());
        assertNotNull(captured.getPublicKey());
        assertNotNull(captured.getPrivateKey());
    }

    @Test
    public void generateKey_withDefaultValues() {
        Map<String, Object> req = new HashMap<>();

        doAnswer(invocation -> {
            ((SceneKeyConfig) invocation.getArgument(0)).setId(KEY_ID);
            return null;
        }).when(sceneRepository).insertSceneKeyConfig(keyConfigCaptor.capture());

        sceneService.generateKey("police", req, USER_ID);

        SceneKeyConfig captured = keyConfigCaptor.getValue();
        assertEquals("BFV", captured.getScheme());
        assertEquals(Integer.valueOf(2048), captured.getKeySize());
        assertTrue(captured.getKeyName().contains("BFV"));
    }

    @Test
    public void generateKey_repositoryThrows_returnsFailure() {
        Map<String, Object> req = new HashMap<>();
        doThrow(new RuntimeException("DB error")).when(sceneRepository).insertSceneKeyConfig(any());

        BaseResultEntity result = sceneService.generateKey("police", req, USER_ID);

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== getKeyList ====================

    @Test
    public void getKeyList_returnsList() {
        SceneKeyConfig config = new SceneKeyConfig();
        config.setId(KEY_ID);
        config.setKeyName("test-key");
        when(sceneRepository.selectSceneKeyConfigList("police"))
                .thenReturn(Collections.singletonList(config));

        BaseResultEntity result = sceneService.getKeyList("police");

        assertEquals(0, result.getCode().intValue());
        List<?> list = (List<?>) result.getResult();
        assertEquals(1, list.size());
    }

    @Test
    public void getKeyList_repositoryThrows_returnsFailure() {
        when(sceneRepository.selectSceneKeyConfigList("police"))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = sceneService.getKeyList("police");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== deleteKey ====================

    @Test
    public void deleteKey_returnsSuccess() {
        BaseResultEntity result = sceneService.deleteKey(KEY_ID);

        assertEquals(0, result.getCode().intValue());
        verify(sceneRepository).deleteSceneKeyConfig(KEY_ID);
    }

    @Test
    public void deleteKey_repositoryThrows_returnsFailure() {
        doThrow(new RuntimeException("DB error")).when(sceneRepository).deleteSceneKeyConfig(KEY_ID);

        BaseResultEntity result = sceneService.deleteKey(KEY_ID);

        assertEquals(BaseResultEnum.DATA_DEL_FAIL.getReturnCode(), result.getCode());
    }

    // ==================== encryptData ====================

    @Test
    public void encryptData_keyNotFound_returnsDataQueryNull() {
        when(sceneRepository.selectSceneKeyConfigById(999L)).thenReturn(null);

        BaseResultEntity result = sceneService.encryptData(999L, "sensitive data");

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void encryptData_validKey_returnsEncryptedData() {
        SceneKeyConfig config = new SceneKeyConfig();
        config.setId(KEY_ID);
        config.setScheme("RSA");
        config.setPrivateKey(Base64.getEncoder().encodeToString(
                new byte[]{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}));
        when(sceneRepository.selectSceneKeyConfigById(KEY_ID)).thenReturn(config);

        BaseResultEntity result = sceneService.encryptData(KEY_ID, "hello");

        assertEquals(0, result.getCode().intValue());
        Map<?, ?> map = (Map<?, ?>) result.getResult();
        assertNotNull(map.get("encryptedData"));
        assertEquals(KEY_ID, map.get("keyId"));
    }

    @Test
    public void encryptData_shortKey_returnsFailure() {
        SceneKeyConfig config = new SceneKeyConfig();
        config.setId(KEY_ID);
        config.setScheme("RSA");
        config.setPrivateKey(Base64.getEncoder().encodeToString(new byte[]{1, 2, 3}));
        when(sceneRepository.selectSceneKeyConfigById(KEY_ID)).thenReturn(config);

        BaseResultEntity result = sceneService.encryptData(KEY_ID, "hello");

        assertEquals(BaseResultEnum.FAILURE.getReturnCode(), result.getCode());
    }

    // ==================== decryptData ====================

    @Test
    public void decryptData_keyNotFound_returnsDataQueryNull() {
        when(sceneRepository.selectSceneKeyConfigById(999L)).thenReturn(null);

        BaseResultEntity result = sceneService.decryptData(999L, "encrypted");

        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), result.getCode());
    }

    @Test
    public void decryptData_invalidData_returnsFailure() {
        SceneKeyConfig config = new SceneKeyConfig();
        config.setId(KEY_ID);
        config.setPrivateKey(Base64.getEncoder().encodeToString(
                new byte[]{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}));
        when(sceneRepository.selectSceneKeyConfigById(KEY_ID)).thenReturn(config);

        BaseResultEntity result = sceneService.decryptData(KEY_ID, "not-valid-base64!!");

        assertEquals(BaseResultEnum.DECRYPTION_FAILED.getReturnCode(), result.getCode());
    }

    @Test
    public void decryptData_repositoryThrows_returnsFailure() {
        when(sceneRepository.selectSceneKeyConfigById(KEY_ID))
                .thenThrow(new RuntimeException("DB error"));

        BaseResultEntity result = sceneService.decryptData(KEY_ID, "data");

        // 异常被通用 catch 捕获 → DECRYPTION_FAILED(仍是失败, 非成功码0)
        assertEquals(BaseResultEnum.DECRYPTION_FAILED.getReturnCode(), result.getCode());
    }
}
