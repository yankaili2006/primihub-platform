package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.service.data.SceneService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Api(value = "场景定制化接口", tags = "场景定制化接口")
@RestController
public class SceneController {

    @Autowired
    private SceneService sceneService;

    // ==================== 警务数据融合 ====================

    @ApiOperation("创建警务数据融合任务")
    @PostMapping("/policeFusion/task/create")
    public BaseResultEntity createPoliceTask(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("police_fusion", req, getCurrentUserId());
    }

    @ApiOperation("警务数据融合任务列表")
    @GetMapping("/policeFusion/task/list")
    public BaseResultEntity getPoliceTaskList(@RequestParam(required = false) String taskType,
                                               @RequestParam(defaultValue = "1") Integer pageNo,
                                               @RequestParam(defaultValue = "10") Integer pageSize) {
        return sceneService.getTaskList("police_fusion", taskType, pageNo, pageSize);
    }

    @ApiOperation("警务数据融合任务详情")
    @GetMapping("/policeFusion/task/detail")
    public BaseResultEntity getPoliceTaskDetail(@RequestParam Long taskId) {
        return sceneService.getTaskDetail(taskId);
    }

    @ApiOperation("警务数据融合-保存API配置")
    @PostMapping("/policeFusion/api/save")
    public BaseResultEntity savePoliceApi(@RequestBody Map<String, Object> req) {
        return sceneService.saveApiConfig("police_fusion", req, getCurrentUserId());
    }

    @ApiOperation("警务数据融合-获取API配置列表")
    @GetMapping("/policeFusion/api/list")
    public BaseResultEntity getPoliceApiList() {
        return sceneService.getApiConfigList("police_fusion");
    }

    @ApiOperation("警务数据融合-删除API配置")
    @PostMapping("/policeFusion/api/delete")
    public BaseResultEntity deletePoliceApi(@RequestBody Map<String, Object> req) {
        Long id = req.get("id") != null ? Long.valueOf(req.get("id").toString()) : null;
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return sceneService.deleteApiConfig(id);
    }

    @ApiOperation("警务数据融合-测试API连接")
    @GetMapping("/policeFusion/api/test")
    public BaseResultEntity testPoliceApi(@RequestParam Long id) {
        return sceneService.testApiConnection(id);
    }

    @ApiOperation("警务数据融合-生成同态密钥")
    @PostMapping("/policeFusion/key/generate")
    public BaseResultEntity generatePoliceKey(@RequestBody Map<String, Object> req) {
        return sceneService.generateKey("police_fusion", req, getCurrentUserId());
    }

    @ApiOperation("警务数据融合-获取密钥列表")
    @GetMapping("/policeFusion/key/list")
    public BaseResultEntity getPoliceKeyList() {
        return sceneService.getKeyList("police_fusion");
    }

    @ApiOperation("警务数据融合-删除密钥")
    @PostMapping("/policeFusion/key/delete")
    public BaseResultEntity deletePoliceKey(@RequestBody Map<String, Object> req) {
        Long id = req.get("id") != null ? Long.valueOf(req.get("id").toString()) : null;
        return sceneService.deleteKey(id);
    }

    @ApiOperation("警务数据融合-加密数据")
    @PostMapping("/policeFusion/key/encrypt")
    public BaseResultEntity encryptPoliceData(@RequestBody Map<String, Object> req) {
        Long keyId = req.get("keyId") != null ? Long.valueOf(req.get("keyId").toString()) : null;
        String data = (String) req.get("data");
        return sceneService.encryptData(keyId, data);
    }

    @ApiOperation("警务数据融合-解密数据")
    @PostMapping("/policeFusion/key/decrypt")
    public BaseResultEntity decryptPoliceData(@RequestBody Map<String, Object> req) {
        Long keyId = req.get("keyId") != null ? Long.valueOf(req.get("keyId").toString()) : null;
        String encryptedData = (String) req.get("encryptedData");
        return sceneService.decryptData(keyId, encryptedData);
    }

    // ==================== 电子证件 ====================

    @ApiOperation("电子证件-创建任务")
    @PostMapping("/electronicCert/task/create")
    public BaseResultEntity createCertTask(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-任务列表")
    @GetMapping("/electronicCert/task/list")
    public BaseResultEntity getCertTaskList(@RequestParam(required = false) String taskType,
                                             @RequestParam(defaultValue = "1") Integer pageNo,
                                             @RequestParam(defaultValue = "10") Integer pageSize) {
        return sceneService.getTaskList("electronic_cert", taskType, pageNo, pageSize);
    }

    @ApiOperation("电子证件-特征转换")
    @PostMapping("/electronicCert/feature/convert")
    public BaseResultEntity convertFeature(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-隐私比对")
    @PostMapping("/electronicCert/compare")
    public BaseResultEntity compareFeature(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-保存API配置")
    @PostMapping("/electronicCert/api/save")
    public BaseResultEntity saveCertApi(@RequestBody Map<String, Object> req) {
        return sceneService.saveApiConfig("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-获取API配置列表")
    @GetMapping("/electronicCert/api/list")
    public BaseResultEntity getCertApiList() {
        return sceneService.getApiConfigList("electronic_cert");
    }

    @ApiOperation("电子证件-删除API配置")
    @PostMapping("/electronicCert/api/delete")
    public BaseResultEntity deleteCertApi(@RequestBody Map<String, Object> req) {
        Long id = req.get("id") != null ? Long.valueOf(req.get("id").toString()) : null;
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        return sceneService.deleteApiConfig(id);
    }

    @ApiOperation("电子证件-生成密钥")
    @PostMapping("/electronicCert/key/generate")
    public BaseResultEntity generateCertKey(@RequestBody Map<String, Object> req) {
        return sceneService.generateKey("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-获取密钥列表")
    @GetMapping("/electronicCert/key/list")
    public BaseResultEntity getCertKeyList() {
        return sceneService.getKeyList("electronic_cert");
    }

    @ApiOperation("电子证件-删除密钥")
    @PostMapping("/electronicCert/key/delete")
    public BaseResultEntity deleteCertKey(@RequestBody Map<String, Object> req) {
        Long id = req.get("id") != null ? Long.valueOf(req.get("id").toString()) : null;
        return sceneService.deleteKey(id);
    }

    @ApiOperation("电子证件-加密数据")
    @PostMapping("/electronicCert/key/encrypt")
    public BaseResultEntity encryptCertData(@RequestBody Map<String, Object> req) {
        Long keyId = req.get("keyId") != null ? Long.valueOf(req.get("keyId").toString()) : null;
        String data = (String) req.get("data");
        return sceneService.encryptData(keyId, data);
    }

    @ApiOperation("电子证件-解密数据")
    @PostMapping("/electronicCert/key/decrypt")
    public BaseResultEntity decryptCertData(@RequestBody Map<String, Object> req) {
        Long keyId = req.get("keyId") != null ? Long.valueOf(req.get("keyId").toString()) : null;
        String encryptedData = (String) req.get("encryptedData");
        return sceneService.decryptData(keyId, encryptedData);
    }

    @ApiOperation("电子证件-数据接入")
    @PostMapping("/electronicCert/import")
    public BaseResultEntity importData(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-数据导出")
    @PostMapping("/electronicCert/export")
    public BaseResultEntity exportData(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-密文交换(批量)")
    @PostMapping("/electronicCert/exchange/batch")
    public BaseResultEntity batchExchange(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    @ApiOperation("电子证件-密文交换(实时)")
    @PostMapping("/electronicCert/exchange/realtime")
    public BaseResultEntity realtimeExchange(@RequestBody Map<String, Object> req) {
        return sceneService.createTask("electronic_cert", req, getCurrentUserId());
    }

    private Long getCurrentUserId() {
        return 1L;
    }
}
