package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.service.data.SceneService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class SceneControllerTest {

    @Mock
    private SceneService sceneService;

    @InjectMocks
    private SceneController controller;

    private static final String POLICE = "police_fusion";
    private static final String CERT = "electronic_cert";
    private static final Long TEST_USER_ID = 1L;

    private Map<String, Object> req(Map.Entry<String, Object>... entries) {
        Map<String, Object> map = new HashMap<>();
        for (Map.Entry<String, Object> e : entries) {
            map.put(e.getKey(), e.getValue());
        }
        return map;
    }

    // ==================== 警务数据融合 - Task ====================

    @Test
    public void createPoliceTask_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(POLICE, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createPoliceTask(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).createTask(POLICE, req, TEST_USER_ID);
    }

    @Test
    public void getPoliceTaskList_success() {
        when(sceneService.getTaskList(POLICE, "fusion", 1, 10)).thenReturn(BaseResultEntity.success("task list"));

        BaseResultEntity result = controller.getPoliceTaskList("fusion", 1, 10);

        assertEquals(0, result.getCode().intValue());
        assertEquals("task list", result.getResult());
        verify(sceneService).getTaskList(POLICE, "fusion", 1, 10);
    }

    @Test
    public void getPoliceTaskList_withDefaultPagination() {
        when(sceneService.getTaskList(POLICE, null, 1, 10)).thenReturn(BaseResultEntity.success("task list"));

        BaseResultEntity result = controller.getPoliceTaskList(null, null, null);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).getTaskList(POLICE, null, 1, 10);
    }

    @Test
    public void getPoliceTaskDetail_success() {
        when(sceneService.getTaskDetail(100L)).thenReturn(BaseResultEntity.success("task detail"));

        BaseResultEntity result = controller.getPoliceTaskDetail(100L);

        assertEquals(0, result.getCode().intValue());
        assertEquals("task detail", result.getResult());
        verify(sceneService).getTaskDetail(100L);
    }

    // ==================== 警务数据融合 - API ====================

    @Test
    public void savePoliceApi_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.saveApiConfig(POLICE, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.savePoliceApi(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).saveApiConfig(POLICE, req, TEST_USER_ID);
    }

    @Test
    public void getPoliceApiList_success() {
        when(sceneService.getApiConfigList(POLICE)).thenReturn(BaseResultEntity.success("api list"));

        BaseResultEntity result = controller.getPoliceApiList();

        assertEquals(0, result.getCode().intValue());
        assertEquals("api list", result.getResult());
        verify(sceneService).getApiConfigList(POLICE);
    }

    @Test
    public void deletePoliceApi_success() {
        Map<String, Object> req = req(Map.entry("id", 42L));
        when(sceneService.deleteApiConfig(42L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deletePoliceApi(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).deleteApiConfig(42L);
    }

    @Test
    public void deletePoliceApi_nullId_returnsLackOfParam() {
        Map<String, Object> req = new HashMap<>();

        BaseResultEntity result = controller.deletePoliceApi(req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(sceneService, never()).deleteApiConfig(anyLong());
    }

    @Test
    public void testPoliceApi_success() {
        when(sceneService.testApiConnection(42L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.testPoliceApi(42L);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).testApiConnection(42L);
    }

    // ==================== 警务数据融合 - Key ====================

    @Test
    public void generatePoliceKey_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.generateKey(POLICE, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success("key"));

        BaseResultEntity result = controller.generatePoliceKey(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("key", result.getResult());
        verify(sceneService).generateKey(POLICE, req, TEST_USER_ID);
    }

    @Test
    public void getPoliceKeyList_success() {
        when(sceneService.getKeyList(POLICE)).thenReturn(BaseResultEntity.success("key list"));

        BaseResultEntity result = controller.getPoliceKeyList();

        assertEquals(0, result.getCode().intValue());
        assertEquals("key list", result.getResult());
        verify(sceneService).getKeyList(POLICE);
    }

    @Test
    public void deletePoliceKey_success() {
        Map<String, Object> req = req(Map.entry("id", 7L));
        when(sceneService.deleteKey(7L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deletePoliceKey(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).deleteKey(7L);
    }

    @Test
    public void deletePoliceKey_nullId_passesNull() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.deleteKey(null)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deletePoliceKey(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).deleteKey(null);
    }

    @Test
    public void encryptPoliceData_success() {
        Map<String, Object> req = req(Map.entry("keyId", 1L), Map.entry("data", "plaintext"));

        when(sceneService.encryptData(1L, "plaintext")).thenReturn(BaseResultEntity.success("cipher"));

        BaseResultEntity result = controller.encryptPoliceData(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("cipher", result.getResult());
        verify(sceneService).encryptData(1L, "plaintext");
    }

    @Test
    public void encryptPoliceData_missingKeyId_passesNull() {
        Map<String, Object> req = req(Map.entry("data", "plaintext"));

        when(sceneService.encryptData(null, "plaintext")).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.encryptPoliceData(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).encryptData(null, "plaintext");
    }

    @Test
    public void decryptPoliceData_success() {
        Map<String, Object> req = req(Map.entry("keyId", 2L), Map.entry("encryptedData", "cipher"));

        when(sceneService.decryptData(2L, "cipher")).thenReturn(BaseResultEntity.success("plaintext"));

        BaseResultEntity result = controller.decryptPoliceData(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("plaintext", result.getResult());
        verify(sceneService).decryptData(2L, "cipher");
    }

    // ==================== 电子证件 - Task ====================

    @Test
    public void createCertTask_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.createCertTask(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }

    @Test
    public void getCertTaskList_success() {
        when(sceneService.getTaskList(CERT, "verify", 2, 20)).thenReturn(BaseResultEntity.success("cert tasks"));

        BaseResultEntity result = controller.getCertTaskList("verify", 2, 20);

        assertEquals(0, result.getCode().intValue());
        assertEquals("cert tasks", result.getResult());
        verify(sceneService).getTaskList(CERT, "verify", 2, 20);
    }

    // ==================== 电子证件 - Feature ====================

    @Test
    public void convertFeature_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.convertFeature(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }

    @Test
    public void compareFeature_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.compareFeature(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }

    // ==================== 电子证件 - API ====================

    @Test
    public void saveCertApi_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.saveApiConfig(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.saveCertApi(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).saveApiConfig(CERT, req, TEST_USER_ID);
    }

    @Test
    public void getCertApiList_success() {
        when(sceneService.getApiConfigList(CERT)).thenReturn(BaseResultEntity.success("cert api list"));

        BaseResultEntity result = controller.getCertApiList();

        assertEquals(0, result.getCode().intValue());
        assertEquals("cert api list", result.getResult());
        verify(sceneService).getApiConfigList(CERT);
    }

    @Test
    public void deleteCertApi_success() {
        Map<String, Object> req = req(Map.entry("id", 99L));
        when(sceneService.deleteApiConfig(99L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deleteCertApi(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).deleteApiConfig(99L);
    }

    @Test
    public void deleteCertApi_nullId_returnsLackOfParam() {
        Map<String, Object> req = new HashMap<>();

        BaseResultEntity result = controller.deleteCertApi(req);

        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), result.getCode());
        verify(sceneService, never()).deleteApiConfig(anyLong());
    }

    // ==================== 电子证件 - Key ====================

    @Test
    public void generateCertKey_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.generateKey(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success("cert key"));

        BaseResultEntity result = controller.generateCertKey(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("cert key", result.getResult());
        verify(sceneService).generateKey(CERT, req, TEST_USER_ID);
    }

    @Test
    public void getCertKeyList_success() {
        when(sceneService.getKeyList(CERT)).thenReturn(BaseResultEntity.success("cert key list"));

        BaseResultEntity result = controller.getCertKeyList();

        assertEquals(0, result.getCode().intValue());
        assertEquals("cert key list", result.getResult());
        verify(sceneService).getKeyList(CERT);
    }

    @Test
    public void deleteCertKey_success() {
        Map<String, Object> req = req(Map.entry("id", 15L));
        when(sceneService.deleteKey(15L)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.deleteCertKey(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).deleteKey(15L);
    }

    @Test
    public void encryptCertData_success() {
        Map<String, Object> req = req(Map.entry("keyId", 3L), Map.entry("data", "secret"));
        when(sceneService.encryptData(3L, "secret")).thenReturn(BaseResultEntity.success("encrypted"));

        BaseResultEntity result = controller.encryptCertData(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("encrypted", result.getResult());
        verify(sceneService).encryptData(3L, "secret");
    }

    @Test
    public void decryptCertData_success() {
        Map<String, Object> req = req(Map.entry("keyId", 4L), Map.entry("encryptedData", "ciphertext"));
        when(sceneService.decryptData(4L, "ciphertext")).thenReturn(BaseResultEntity.success("decrypted"));

        BaseResultEntity result = controller.decryptCertData(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("decrypted", result.getResult());
        verify(sceneService).decryptData(4L, "ciphertext");
    }

    // ==================== 电子证件 - Import/Export/Exchange ====================

    @Test
    public void importData_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success());

        BaseResultEntity result = controller.importData(req);

        assertEquals(0, result.getCode().intValue());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }

    @Test
    public void exportData_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success("export"));

        BaseResultEntity result = controller.exportData(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("export", result.getResult());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }

    @Test
    public void batchExchange_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success("batch"));

        BaseResultEntity result = controller.batchExchange(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("batch", result.getResult());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }

    @Test
    public void realtimeExchange_success() {
        Map<String, Object> req = new HashMap<>();
        when(sceneService.createTask(CERT, req, TEST_USER_ID)).thenReturn(BaseResultEntity.success("realtime"));

        BaseResultEntity result = controller.realtimeExchange(req);

        assertEquals(0, result.getCode().intValue());
        assertEquals("realtime", result.getResult());
        verify(sceneService).createTask(CERT, req, TEST_USER_ID);
    }
}
