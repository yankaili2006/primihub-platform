package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.service.sys.EvidenceService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Api(value = "存证管理接口", tags = "存证管理接口")
@RequestMapping("evidence")
@RestController
public class EvidenceController {

    @Autowired
    private EvidenceService evidenceService;

    // ========== 存证查询相关 ==========

    @ApiOperation(value = "查询存证分页列表")
    @GetMapping("findEvidencePage")
    public BaseResultEntity findEvidencePage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return evidenceService.findEvidencePage(keyword, status, null, startTime, endTime, pageNum, pageSize);
    }

    @ApiOperation(value = "查询存证详情")
    @GetMapping("getEvidenceDetail")
    public BaseResultEntity getEvidenceDetail(@RequestParam Long id) {
        return evidenceService.getEvidenceDetail(id);
    }

    @ApiOperation(value = "创建存证")
    @PostMapping("createEvidence")
    public BaseResultEntity createEvidence(@RequestBody Map<String, Object> data) {
        return evidenceService.createEvidence(data);
    }

    @ApiOperation(value = "验证存证")
    @PostMapping("verifyEvidence")
    public BaseResultEntity verifyEvidence(@RequestBody Map<String, Object> data) {
        Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
        return evidenceService.verifyEvidence(id);
    }

    @ApiOperation(value = "获取存证统计")
    @GetMapping("getEvidenceStatistics")
    public BaseResultEntity getEvidenceStatistics() {
        return evidenceService.getEvidenceStatistics();
    }

    // ========== 时间戳管理相关 ==========

    @ApiOperation(value = "查询时间戳分页列表")
    @GetMapping("findTimestampPage")
    public BaseResultEntity findTimestampPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return evidenceService.findTimestampPage(keyword, pageNum, pageSize);
    }

    @ApiOperation(value = "申请时间戳")
    @PostMapping("applyTimestamp")
    public BaseResultEntity applyTimestamp(@RequestBody Map<String, Object> data) {
        return evidenceService.applyTimestamp(data);
    }

    @ApiOperation(value = "验证时间戳")
    @PostMapping("verifyTimestamp")
    public BaseResultEntity verifyTimestamp(@RequestBody Map<String, Object> data) {
        Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
        return evidenceService.verifyTimestamp(id);
    }

    @ApiOperation(value = "查询时间戳详情")
    @GetMapping("getTimestampDetail")
    public BaseResultEntity getTimestampDetail(@RequestParam Long id) {
        return evidenceService.verifyTimestamp(id);
    }

    // ========== 存证配置相关 ==========

    @ApiOperation(value = "获取存证配置")
    @GetMapping("getEvidenceConfig")
    public BaseResultEntity getEvidenceConfig() {
        return evidenceService.getEvidenceConfig();
    }

    @ApiOperation(value = "保存存证配置")
    @PostMapping("saveEvidenceConfig")
    public BaseResultEntity saveEvidenceConfig(@RequestBody Map<String, Object> data) {
        return evidenceService.saveEvidenceConfig(data);
    }

    @ApiOperation(value = "获取区块链列表")
    @GetMapping("getChainList")
    public BaseResultEntity getChainList() {
        return evidenceService.getChainList();
    }

    // ========== 存证导出相关 ==========

    @ApiOperation(value = "导出存证")
    @PostMapping("exportEvidence")
    public BaseResultEntity exportEvidence(@RequestBody Map<String, Object> data) {
        return evidenceService.exportEvidence(data);
    }

    @ApiOperation(value = "加密导出")
    @PostMapping("encryptExport")
    public BaseResultEntity encryptExport(@RequestBody Map<String, Object> data) {
        return evidenceService.encryptExport(data);
    }

    @ApiOperation(value = "获取导出历史")
    @GetMapping("getExportHistory")
    public BaseResultEntity getExportHistory(
            @RequestParam(required = false) Long createdBy,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return evidenceService.getExportHistory(createdBy, pageNum, pageSize);
    }

    // ========== 存证接口对接相关 ==========

    @ApiOperation(value = "获取API列表")
    @GetMapping("getApiList")
    public BaseResultEntity getApiList() {
        List<Map<String, Object>> apis = new ArrayList<>();
        Map<String, Object> api1 = new HashMap<>();
        api1.put("id", "1");
        api1.put("method", "POST");
        api1.put("path", "/api/evidence/create");
        api1.put("description", "创建存证");
        api1.put("params", "{\"hash\": \"string\", \"data\": \"string\"}");
        api1.put("response", "{\"code\": 0, \"result\": {\"evidenceId\": \"string\"}}");
        apis.add(api1);
        Map<String, Object> api2 = new HashMap<>();
        api2.put("id", "2");
        api2.put("method", "GET");
        api2.put("path", "/api/evidence/query");
        api2.put("description", "查询存证");
        api2.put("params", "{\"evidenceId\": \"string\"}");
        api2.put("response", "{\"code\": 0, \"result\": {\"hash\": \"string\", \"status\": \"string\"}}");
        apis.add(api2);
        return BaseResultEntity.success(apis);
    }

    @ApiOperation(value = "获取API密钥")
    @GetMapping("getApiKey")
    public BaseResultEntity getApiKey() {
        return evidenceService.getApiKey();
    }

    @ApiOperation(value = "重新生成API密钥")
    @PostMapping("regenerateApiKey")
    public BaseResultEntity regenerateApiKey(@RequestBody Map<String, Object> data) {
        return evidenceService.regenerateApiKey(data);
    }

    @ApiOperation(value = "获取API调用日志")
    @GetMapping("getApiCallLog")
    public BaseResultEntity getApiCallLog(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return evidenceService.getApiCallLog(pageNum, pageSize);
    }

    @ApiOperation(value = "测试API连接")
    @PostMapping("testApiConnection")
    public BaseResultEntity testApiConnection(@RequestBody Map<String, Object> data) {
        Object urlObj = data.get("url") != null ? data.get("url") : data.get("apiUrl");
        String url = urlObj != null ? urlObj.toString().trim() : "";
        Map<String, Object> result = new HashMap<>();
        if (url.isEmpty() || !(url.startsWith("http://") || url.startsWith("https://"))) {
            result.put("success", false);
            result.put("message", "无效的URL(需以 http:// 或 https:// 开头)");
            return BaseResultEntity.success(result);
        }
        // 真实探测目标接口连通性，测量真实响应耗时/状态码，不再恒返回成功
        long start = System.currentTimeMillis();
        java.net.HttpURLConnection conn = null;
        try {
            conn = (java.net.HttpURLConnection) new java.net.URL(url).openConnection();
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            conn.setRequestMethod("GET");
            conn.setInstanceFollowRedirects(true);
            int code = conn.getResponseCode();
            long cost = System.currentTimeMillis() - start;
            result.put("success", code >= 200 && code < 400);
            result.put("statusCode", code);
            result.put("message", code >= 200 && code < 400 ? "连接成功" : "目标返回状态码 " + code);
            result.put("responseTime", cost + "ms");
        } catch (Exception e) {
            long cost = System.currentTimeMillis() - start;
            result.put("success", false);
            result.put("message", "连接失败: " + e.getMessage());
            result.put("responseTime", cost + "ms");
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
        return BaseResultEntity.success(result);
    }
}
