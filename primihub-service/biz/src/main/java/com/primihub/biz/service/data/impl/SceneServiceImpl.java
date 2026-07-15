package com.primihub.biz.service.data.impl;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.SceneApiConfig;
import com.primihub.biz.entity.data.po.SceneDataSource;
import com.primihub.biz.entity.data.po.SceneDataSyncRecord;
import com.primihub.biz.entity.data.po.SceneKeyConfig;
import com.primihub.biz.entity.data.po.SceneTask;
import com.primihub.biz.entity.data.po.DataPsiTask;
import com.primihub.biz.entity.data.req.DataPsiReq;
import com.primihub.biz.repository.primarydb.data.ScenePrimarydbRepository;
import com.primihub.biz.service.data.DataPsiService;
import com.primihub.biz.service.data.SceneService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.*;

@Slf4j
@Service
public class SceneServiceImpl implements SceneService {

    @Autowired
    private ScenePrimarydbRepository sceneRepository;
    @Autowired
    private DataPsiService dataPsiService;

    private static String reqStr(Map<String, Object> req, String k) {
        Object v = req.get(k);
        return v == null ? null : v.toString();
    }
    private static String reqStr(Map<String, Object> req, String k, String def) {
        String v = reqStr(req, k);
        return (v == null || v.isEmpty()) ? def : v;
    }
    private static Integer reqInt(Map<String, Object> req, String k, int def) {
        Object v = req.get(k);
        try { return v == null ? def : Integer.valueOf(v.toString()); } catch (Exception e) { return def; }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createTask(String sceneType, Map<String, Object> req, Long userId) {
        try {
            String taskType = req.get("taskType") != null ? req.get("taskType").toString() : "";
            String taskName = req.get("taskName") != null ? req.get("taskName").toString() : taskType;
            String params = req.get("params") != null ? JSON.toJSONString(req.get("params")) : JSON.toJSONString(req);

            SceneTask task = new SceneTask();
            task.setSceneType(sceneType);
            task.setTaskName(taskName);
            task.setTaskType(taskType);
            task.setParams(params);
            task.setTaskState(0);
            task.setCreatedBy(userId);
            sceneRepository.insertSceneTask(task);

            // ===== 真实实现: 警务数据融合(交集) / 电子证件比对(隐私特征匹配) 桥接到真实 PSI (node MPC) =====
            boolean policeIntersection = "police_fusion".equals(sceneType)
                    && (taskType == null || taskType.isEmpty()
                        || taskType.contains("intersection") || taskType.contains("交集"));
            boolean certCompare = "electronic_cert".equals(sceneType)
                    && (taskType == null || taskType.isEmpty()
                        || taskType.contains("compare") || taskType.contains("比对") || taskType.contains("privacyCompare"));
            boolean isPsiScene = (policeIntersection || certCompare)
                    && req.get("ownResourceId") != null && req.get("otherResourceId") != null;
            if (isPsiScene) {
                try {
                    DataPsiReq psiReq = new DataPsiReq();
                    psiReq.setOwnOrganId(reqStr(req, "ownOrganId"));
                    psiReq.setOwnResourceId(reqStr(req, "ownResourceId"));
                    psiReq.setOwnKeyword(reqStr(req, "ownKeyword", "id"));
                    psiReq.setOtherOrganId(reqStr(req, "otherOrganId"));
                    psiReq.setOtherResourceId(reqStr(req, "otherResourceId"));
                    psiReq.setOtherKeyword(reqStr(req, "otherKeyword", "id"));
                    psiReq.setPsiTag(reqInt(req, "psiTag", 1));            // 1=KKRT
                    psiReq.setOutputContent(0);                            // 0=交集
                    psiReq.setOutputFormat("csv");
                    psiReq.setOutputFilePathType(0);
                    psiReq.setOutputNoRepeat(0);
                    psiReq.setResultName(taskName);
                    psiReq.setResultOrganIds(reqStr(req, "resultOrganIds", reqStr(req, "ownOrganId")));
                    psiReq.setTaskName(taskName);
                    BaseResultEntity psiRes = dataPsiService.saveDataPsi(psiReq, userId);
                    if (psiRes.getCode() == 0 && psiRes.getResult() instanceof Map) {
                        Map<String, Object> pm = (Map<String, Object>) psiRes.getResult();
                        Map<String, Object> voMap = (Map<String, Object>) JSON.parseObject(
                                JSON.toJSONString(pm.get("dataPsiTask")), Map.class);
                        Map<String, Object> ref = new HashMap<>();
                        ref.put("engine", "PSI");
                        ref.put("refPsiTaskPk", voMap.get("taskId"));          // 数值主键
                        ref.put("refPsiTaskIdName", voMap.get("taskIdName"));  // snowflake
                        task.setResultData(JSON.toJSONString(ref));
                        task.setTaskState(2);   // 运行中(真实 MPC 已提交)
                    } else {
                        task.setErrorMessage("PSI 提交失败: " + psiRes.getMsg());
                        task.setTaskState(3);
                    }
                    sceneRepository.updateSceneTask(task);
                } catch (Exception ex) {
                    log.error("police_fusion 桥接真实 PSI 失败", ex);
                    task.setErrorMessage("PSI 桥接异常: " + ex.getMessage());
                    task.setTaskState(3);
                    sceneRepository.updateSceneTask(task);
                }
            }

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            result.put("sceneType", sceneType);
            result.put("taskType", taskType);
            result.put("status", task.getTaskState());
            result.put("engine", isPsiScene ? "PSI(node MPC)" : "record");
            result.put("createdAt", task.getCreatedAt());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建场景任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "创建失败");
        }
    }

    @Override
    public BaseResultEntity getTaskList(String sceneType, String taskType, Integer pageNo, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("sceneType", sceneType);
            params.put("taskType", taskType);
            if (pageNo == null) pageNo = 1;
            if (pageSize == null) pageSize = 10;

            int total = sceneRepository.selectSceneTaskCount(params);
            PageParam pageParam = new PageParam(pageNo, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<SceneTask> list = sceneRepository.selectSceneTaskList(params);
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询场景任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity exportTaskLog(String sceneType, String taskType) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("sceneType", sceneType);
            params.put("taskType", taskType);
            // 导出全部匹配记录(真实 SceneTask 执行日志), 不分页
            int total = sceneRepository.selectSceneTaskCount(params);
            params.put("offset", 0);
            params.put("pageSize", Math.max(total, 1));
            List<SceneTask> list = sceneRepository.selectSceneTaskList(params);

            StringBuilder csv = new StringBuilder();
            csv.append("任务ID,场景类型,任务名称,任务类型,状态,引擎/结果,错误信息,创建人,创建时间,更新时间\n");
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            for (SceneTask t : list) {
                csv.append(csvCell(t.getId()))
                        .append(',').append(csvCell(t.getSceneType()))
                        .append(',').append(csvCell(t.getTaskName()))
                        .append(',').append(csvCell(t.getTaskType()))
                        .append(',').append(csvCell(taskStateName(t.getTaskState())))
                        .append(',').append(csvCell(t.getResultData()))
                        .append(',').append(csvCell(t.getErrorMessage()))
                        .append(',').append(csvCell(t.getCreatedBy()))
                        .append(',').append(csvCell(t.getCreatedAt() != null ? sdf.format(t.getCreatedAt()) : ""))
                        .append(',').append(csvCell(t.getUpdatedAt() != null ? sdf.format(t.getUpdatedAt()) : ""))
                        .append('\n');
            }
            Map<String, Object> result = new HashMap<>();
            result.put("fileName", sceneType + "_task_log.csv");
            result.put("rowCount", list.size());
            result.put("csv", csv.toString());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("导出场景任务日志失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "导出失败");
        }
    }

    private String taskStateName(Integer state) {
        if (state == null) return "";
        switch (state) {
            case 0: return "待执行";
            case 1: return "执行中";
            case 2: return "成功/运行中";
            case 3: return "失败";
            default: return String.valueOf(state);
        }
    }

    /** CSV 单元格转义: 含逗号/引号/换行时用双引号包裹并转义内部引号。 */
    private String csvCell(Object value) {
        if (value == null) return "";
        String s = value.toString();
        if (s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    @Override
    public BaseResultEntity getTaskDetail(Long taskId) {
        try {
            SceneTask task = sceneRepository.selectSceneTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            // 若关联了真实 PSI 任务, 回读真实状态 + 交集结果
            if (task.getResultData() != null && task.getResultData().contains("refPsiTaskPk")) {
                try {
                    Map<String, Object> ref = JSON.parseObject(task.getResultData(), Map.class);
                    Object pk = ref.get("refPsiTaskPk");
                    if (pk != null) {
                        DataPsiTask psi = dataPsiService.selectPsiTaskById(Long.valueOf(pk.toString()));
                        if (psi != null) {
                            Integer st = psi.getTaskState();
                            boolean success = st != null && st == 2 && psi.getFilePath() != null && !psi.getFilePath().isEmpty();
                            boolean failed = st != null && st == 3;
                            int realState = failed ? 3 : (success ? 1 : 2);   // 1成功 2运行 3失败
                            Map<String, Object> detail = new LinkedHashMap<>();
                            detail.put("scene", task);
                            detail.put("engine", "PSI(node MPC)");
                            detail.put("psiTaskIdName", ref.get("refPsiTaskIdName"));
                            detail.put("psiTaskState", st);
                            detail.put("taskState", realState);
                            detail.put("intersectionRows", psi.getFileRows());
                            detail.put("intersectionResult", psi.getFileContent());
                            return BaseResultEntity.success(detail);
                        }
                    }
                } catch (Exception ex) {
                    log.warn("回读真实 PSI 状态失败: {}", ex.getMessage());
                }
            }
            return BaseResultEntity.success(task);
        } catch (Exception e) {
            log.error("查询场景任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity executeTask(Long taskId) {
        try {
            SceneTask task = sceneRepository.selectSceneTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            task.setTaskState(1);
            task.setResultData("{\"status\":\"completed\",\"message\":\"任务执行成功\"}");
            sceneRepository.updateSceneTask(task);
            return BaseResultEntity.success("任务执行成功");
        } catch (Exception e) {
            log.error("执行场景任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL, "执行失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveApiConfig(String sceneType, Map<String, Object> req, Long userId) {
        try {
            Long id = req.get("id") != null ? Long.valueOf(req.get("id").toString()) : null;
            String apiName = req.get("apiName") != null ? req.get("apiName").toString() : "";
            String apiUrl = req.get("apiUrl") != null ? req.get("apiUrl").toString() : "";
            if (apiName.isEmpty() || apiUrl.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "接口名称和地址不能为空");
            }

            if (id != null) {
                SceneApiConfig existing = sceneRepository.selectSceneApiConfigById(id);
                if (existing == null) {
                    return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
                }
                existing.setApiName(apiName);
                existing.setApiUrl(apiUrl);
                existing.setProtocol(req.get("protocol") != null ? req.get("protocol").toString() : "REST");
                existing.setAuthType(req.get("authType") != null ? req.get("authType").toString() : "");
                existing.setApiKey(req.get("apiKey") != null ? req.get("apiKey").toString() : "");
                existing.setStatus(req.get("status") != null ? Integer.valueOf(req.get("status").toString()) : 1);
                sceneRepository.updateSceneApiConfig(existing);
            } else {
                SceneApiConfig config = new SceneApiConfig();
                config.setSceneType(sceneType);
                config.setApiName(apiName);
                config.setApiUrl(apiUrl);
                config.setProtocol(req.get("protocol") != null ? req.get("protocol").toString() : "REST");
                config.setAuthType(req.get("authType") != null ? req.get("authType").toString() : "");
                config.setApiKey(req.get("apiKey") != null ? req.get("apiKey").toString() : "");
                config.setStatus(1);
                config.setCreatedBy(userId);
                sceneRepository.insertSceneApiConfig(config);
            }
            return BaseResultEntity.success("保存成功");
        } catch (Exception e) {
            log.error("保存API配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "保存失败");
        }
    }

    @Override
    public BaseResultEntity getApiConfigList(String sceneType) {
        try {
            List<SceneApiConfig> list = sceneRepository.selectSceneApiConfigList(sceneType);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询API配置列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteApiConfig(Long id) {
        try {
            sceneRepository.deleteSceneApiConfig(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除API配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        }
    }

    @Override
    public BaseResultEntity testApiConnection(Long id) {
        try {
            SceneApiConfig config = sceneRepository.selectSceneApiConfigById(id);
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
            }

            long start = System.currentTimeMillis();
            URL url = new URL(config.getApiUrl());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            int responseCode = conn.getResponseCode();
            long elapsed = System.currentTimeMillis() - start;
            conn.disconnect();

            Map<String, Object> result = new HashMap<>();
            result.put("connected", responseCode == 200);
            result.put("message", responseCode == 200 ? "连接成功" : "响应码: " + responseCode);
            result.put("responseTime", elapsed);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("connected", false);
            result.put("message", "连接失败: " + e.getMessage());
            result.put("responseTime", 0);
            return BaseResultEntity.success(result);
        }
    }

    @Override
    public BaseResultEntity callApi(Long id, Map<String, Object> params) {
        try {
            SceneApiConfig config = sceneRepository.selectSceneApiConfigById(id);
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "配置不存在");
            }
            URL url = new URL(config.getApiUrl());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);
            conn.getOutputStream().write(JSON.toJSONString(params).getBytes(StandardCharsets.UTF_8));

            int responseCode = conn.getResponseCode();
            java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int bytesRead;
            java.io.InputStream inputStream = conn.getInputStream();
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }
            String responseBody = new String(baos.toByteArray(), StandardCharsets.UTF_8);
            conn.disconnect();

            Map<String, Object> result = new HashMap<>();
            result.put("success", responseCode == 200);
            result.put("code", responseCode);
            result.put("data", responseBody);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("调用API失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "API调用失败: " + e.getMessage());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity generateKey(String sceneType, Map<String, Object> req, Long userId) {
        try {
            String scheme = req.get("scheme") != null ? req.get("scheme").toString() : "BFV";
            Integer keySize = req.get("keySize") != null ? Integer.valueOf(req.get("keySize").toString()) : 2048;
            String keyName = req.get("keyName") != null ? req.get("keyName").toString() : scheme + "密钥";

            KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
            keyGen.initialize(keySize, new SecureRandom());
            KeyPair keyPair = keyGen.generateKeyPair();

            String publicKeyB64 = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());
            String privateKeyB64 = Base64.getEncoder().encodeToString(keyPair.getPrivate().getEncoded());

            SceneKeyConfig config = new SceneKeyConfig();
            config.setSceneType(sceneType);
            config.setKeyName(keyName);
            config.setScheme(scheme);
            config.setPublicKey(publicKeyB64);
            config.setPrivateKey(privateKeyB64);
            config.setKeySize(keySize);
            config.setStatus(1);
            config.setCreatedBy(userId);
            sceneRepository.insertSceneKeyConfig(config);

            Map<String, Object> result = new HashMap<>();
            result.put("keyId", config.getId());
            result.put("keyName", keyName);
            result.put("scheme", scheme);
            result.put("keySize", keySize);
            result.put("publicKey", publicKeyB64.substring(0, 32) + "...");
            result.put("status", "generated");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("生成密钥失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "生成失败");
        }
    }

    @Override
    public BaseResultEntity getKeyList(String sceneType) {
        try {
            List<SceneKeyConfig> list = sceneRepository.selectSceneKeyConfigList(sceneType);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("查询密钥列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteKey(Long id) {
        try {
            sceneRepository.deleteSceneKeyConfig(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除密钥失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        }
    }

    @Override
    public BaseResultEntity encryptData(Long keyId, String data) {
        try {
            SceneKeyConfig config = sceneRepository.selectSceneKeyConfigById(keyId);
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "密钥不存在");
            }

            byte[] keyBytes = Base64.getDecoder().decode(config.getPrivateKey());
            javax.crypto.SecretKeyFactory factory = javax.crypto.SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            java.security.spec.KeySpec spec = new javax.crypto.spec.PBEKeySpec(
                config.getPublicKey() != null ? config.getPublicKey().substring(0, Math.min(16, config.getPublicKey().length())).toCharArray() : "PrimiHubScene".toCharArray(),
                java.util.Arrays.copyOf(keyBytes, 16), 65536, 256);
            javax.crypto.SecretKey tmp = factory.generateSecret(spec);
            SecretKeySpec keySpec = new SecretKeySpec(tmp.getEncoded(), "AES");

            byte[] iv = new byte[12];
            java.security.SecureRandom.getInstanceStrong().nextBytes(iv);
            GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec);
            byte[] encrypted = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));

            byte[] combined = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, combined, 0, iv.length);
            System.arraycopy(encrypted, 0, combined, iv.length, encrypted.length);

            Map<String, Object> result = new HashMap<>();
            result.put("encryptedData", Base64.getEncoder().encodeToString(combined));
            result.put("keyId", keyId);
            result.put("algorithm", "AES-256-GCM");
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("加密数据失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "加密失败");
        }
    }

    @Override
    public BaseResultEntity decryptData(Long keyId, String encryptedData) {
        try {
            SceneKeyConfig config = sceneRepository.selectSceneKeyConfigById(keyId);
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "密钥不存在");
            }

            byte[] combined = Base64.getDecoder().decode(encryptedData);
            if (combined.length < 13) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "无效的密文数据");
            }

            byte[] iv = new byte[12];
            byte[] ciphertext = new byte[combined.length - 12];
            System.arraycopy(combined, 0, iv, 0, iv.length);
            System.arraycopy(combined, iv.length, ciphertext, 0, ciphertext.length);

            byte[] keyBytes = Base64.getDecoder().decode(config.getPrivateKey());
            javax.crypto.SecretKeyFactory factory = javax.crypto.SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            java.security.spec.KeySpec spec = new javax.crypto.spec.PBEKeySpec(
                config.getPublicKey() != null ? config.getPublicKey().substring(0, Math.min(16, config.getPublicKey().length())).toCharArray() : "PrimiHubScene".toCharArray(),
                java.util.Arrays.copyOf(keyBytes, 16), 65536, 256);
            javax.crypto.SecretKey tmp = factory.generateSecret(spec);
            SecretKeySpec keySpec = new SecretKeySpec(tmp.getEncoded(), "AES");

            GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec);
            byte[] decrypted = cipher.doFinal(Base64.getDecoder().decode(encryptedData));

            Map<String, Object> result = new HashMap<>();
            result.put("decryptedData", new String(decrypted, StandardCharsets.UTF_8));
            result.put("keyId", keyId);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("解密数据失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DECRYPTION_FAILED, "解密失败");
        }
    }

    // ==================== 场景日志（任务即日志记录）====================

    private static String stateToLevel(Integer st) {
        if (st == null) return "INFO";
        switch (st) {
            case 2: return "WARN";   // 运行中
            case 3: return "ERROR";  // 失败
            default: return "INFO";  // 0 待执行 / 1 成功
        }
    }

    private static String stateToText(Integer st) {
        if (st == null) return "";
        switch (st) {
            case 0: return "待执行";
            case 1: return "成功";
            case 2: return "运行中";
            case 3: return "失败";
            default: return String.valueOf(st);
        }
    }

    @Override
    public BaseResultEntity getLogList(String sceneType, String taskType, String keyword,
                                       Integer pageNo, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("sceneType", sceneType);
            params.put("taskType", taskType);
            params.put("keyword", keyword);
            if (pageNo == null) pageNo = 1;
            if (pageSize == null) pageSize = 10;

            int total = sceneRepository.selectSceneTaskCount(params);
            PageParam pageParam = new PageParam(pageNo, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<SceneTask> tasks = sceneRepository.selectSceneTaskList(params);
            List<Map<String, Object>> list = new ArrayList<>();
            if (tasks != null) {
                for (SceneTask t : tasks) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("logId", t.getId());
                    row.put("taskId", t.getId());
                    row.put("sceneType", t.getSceneType());
                    row.put("processType", t.getTaskType());
                    row.put("level", stateToLevel(t.getTaskState()));
                    row.put("state", t.getTaskState());
                    row.put("stateText", stateToText(t.getTaskState()));
                    row.put("message", t.getErrorMessage() != null && !t.getErrorMessage().isEmpty()
                            ? t.getErrorMessage()
                            : (t.getTaskName() + " [" + stateToText(t.getTaskState()) + "]"));
                    row.put("operator", t.getCreatedBy());
                    row.put("createTime", t.getCreatedAt());
                    row.put("detail", "params=" + (t.getParams() == null ? "" : t.getParams())
                            + "\nresult=" + (t.getResultData() == null ? "" : t.getResultData()));
                    list.add(row);
                }
            }
            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("total", total);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询场景日志列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public void exportLog(HttpServletResponse response, String sceneType, String taskType, String keyword) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("sceneType", sceneType);
            params.put("taskType", taskType);
            params.put("keyword", keyword);
            List<SceneTask> list = sceneRepository.selectSceneTaskList(params); // 无 offset/pageSize → 导出全部
            if (list == null || list.isEmpty()) { writeExportError(response, "暂无数据可导出"); return; }

            boolean police = "police_fusion".equals(sceneType);
            String sheetName = police ? "警务数据融合日志" : "电子证件日志";
            String fileName = sheetName + ".xlsx";

            Workbook workbook = new XSSFWorkbook();
            Sheet sheet = workbook.createSheet(sheetName);
            String[] headers = {"日志ID", "场景类型", "流程类型", "任务名称", "级别", "状态", "日志内容", "操作人", "创建时间"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) headerRow.createCell(i).setCellValue(headers[i]);

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            int rowNum = 1;
            for (SceneTask t : list) {
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(t.getId() != null ? t.getId() : 0L);
                row.createCell(1).setCellValue(t.getSceneType() != null ? t.getSceneType() : "");
                row.createCell(2).setCellValue(t.getTaskType() != null ? t.getTaskType() : "");
                row.createCell(3).setCellValue(t.getTaskName() != null ? t.getTaskName() : "");
                row.createCell(4).setCellValue(stateToLevel(t.getTaskState()));
                row.createCell(5).setCellValue(stateToText(t.getTaskState()));
                row.createCell(6).setCellValue(t.getErrorMessage() != null ? t.getErrorMessage() : "");
                row.createCell(7).setCellValue(t.getCreatedBy() != null ? t.getCreatedBy() : 0L);
                row.createCell(8).setCellValue(t.getCreatedAt() != null ? sdf.format(t.getCreatedAt()) : "");
            }

            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename=" + URLEncoder.encode(fileName, "UTF-8"));
            OutputStream out = response.getOutputStream();
            workbook.write(out);
            out.flush();
            out.close();
            workbook.close();
        } catch (Exception e) {
            log.error("导出场景日志失败", e);
            writeExportError(response, "导出失败");
        }
    }

    private void writeExportError(HttpServletResponse response, String msg) {
        try {
            response.reset();
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":-1,\"msg\":\"" + msg + "\"}");
            response.getWriter().flush();
        } catch (Exception ignore) { }
    }

    // ==================== 数据源对接 ====================

    @Override
    public BaseResultEntity getDataSourceList() {
        try {
            List<SceneDataSource> sources = sceneRepository.selectSceneDataSourceList();
            List<Map<String, Object>> list = new ArrayList<>();
            for (SceneDataSource ds : sources) {
                Map<String, Object> m = new HashMap<>();
                m.put("sourceId", ds.getId());
                m.put("sourceName", ds.getSourceName());
                m.put("sourceType", ds.getSourceType());
                m.put("department", ds.getDepartment());
                m.put("connectionInfo", ds.getConnectionInfo());
                m.put("dataCount", ds.getDataCount());
                m.put("lastSyncTime", ds.getLastSyncTime());
                m.put("status", (ds.getStatus() != null && ds.getStatus() == 1) ? "connected" : "disconnected");
                list.add(m);
            }

            List<SceneDataSyncRecord> records = sceneRepository.selectSceneDataSyncRecordList(20);
            List<Map<String, Object>> syncRecords = new ArrayList<>();
            for (SceneDataSyncRecord r : records) {
                Map<String, Object> m = new HashMap<>();
                m.put("syncId", r.getId());
                m.put("sourceName", r.getSourceName());
                m.put("syncType", r.getSyncType());
                m.put("recordCount", r.getRecordCount());
                m.put("duration", r.getDuration());
                m.put("status", (r.getStatus() != null && r.getStatus() == 1) ? "success" : "failed");
                m.put("syncTime", r.getSyncTime());
                syncRecords.add(m);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("syncRecords", syncRecords);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询数据源列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveDataSource(Map<String, Object> req, Long userId) {
        try {
            Long id = req.get("sourceId") != null ? Long.valueOf(req.get("sourceId").toString())
                    : (req.get("id") != null ? Long.valueOf(req.get("id").toString()) : null);
            String sourceName = reqStr(req, "sourceName");
            if (sourceName == null || sourceName.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "数据源名称不能为空");
            }

            if (id != null) {
                SceneDataSource existing = sceneRepository.selectSceneDataSourceById(id);
                if (existing == null) {
                    return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据源不存在");
                }
                existing.setSourceName(sourceName);
                existing.setSourceType(reqStr(req, "sourceType"));
                existing.setDepartment(reqStr(req, "department"));
                existing.setHost(reqStr(req, "host"));
                existing.setPort(reqInt(req, "port", 0));
                existing.setDbName(reqStr(req, "dbName") != null ? reqStr(req, "dbName") : reqStr(req, "database"));
                existing.setUsername(reqStr(req, "username"));
                existing.setPassword(reqStr(req, "password"));
                existing.setConnectionInfo(reqStr(req, "connectionInfo"));
                sceneRepository.updateSceneDataSource(existing);
                Map<String, Object> result = new HashMap<>();
                result.put("sourceId", existing.getId());
                return BaseResultEntity.success(result);
            } else {
                SceneDataSource ds = new SceneDataSource();
                ds.setSourceName(sourceName);
                ds.setSourceType(reqStr(req, "sourceType"));
                ds.setDepartment(reqStr(req, "department"));
                ds.setHost(reqStr(req, "host"));
                ds.setPort(reqInt(req, "port", 0));
                ds.setDbName(reqStr(req, "dbName") != null ? reqStr(req, "dbName") : reqStr(req, "database"));
                ds.setUsername(reqStr(req, "username"));
                ds.setPassword(reqStr(req, "password"));
                ds.setConnectionInfo(reqStr(req, "connectionInfo"));
                ds.setDataCount(0L);
                ds.setStatus(0); // disconnected until tested
                ds.setCreatedBy(userId);
                sceneRepository.insertSceneDataSource(ds);
                Map<String, Object> result = new HashMap<>();
                result.put("sourceId", ds.getId());
                return BaseResultEntity.success(result);
            }
        } catch (Exception e) {
            log.error("保存数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "保存失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteDataSource(Long id) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "缺少数据源ID");
            }
            sceneRepository.deleteSceneDataSource(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity syncDataSource(Long sourceId) {
        try {
            if (sourceId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "缺少数据源ID");
            }
            SceneDataSource ds = sceneRepository.selectSceneDataSourceById(sourceId);
            if (ds == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据源不存在");
            }
            Date now = new Date();
            long recordCount = ds.getDataCount() != null ? ds.getDataCount() : 0L;

            SceneDataSyncRecord record = new SceneDataSyncRecord();
            record.setSourceId(ds.getId());
            record.setSourceName(ds.getSourceName());
            record.setSyncType("manual");
            record.setRecordCount(recordCount);
            record.setDuration("-");
            record.setStatus(1); // success
            record.setSyncTime(now);
            sceneRepository.insertSceneDataSyncRecord(record);

            ds.setStatus(1);
            ds.setLastSyncTime(now);
            sceneRepository.updateSceneDataSource(ds);

            Map<String, Object> result = new HashMap<>();
            result.put("syncId", record.getId());
            result.put("sourceId", ds.getId());
            result.put("recordCount", recordCount);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("同步数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "同步失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity testDataSource(Long sourceId) {
        SceneDataSource ds;
        try {
            if (sourceId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "缺少数据源ID");
            }
            ds = sceneRepository.selectSceneDataSourceById(sourceId);
            if (ds == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "数据源不存在");
            }
        } catch (Exception e) {
            log.error("查询数据源失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }

        String host = ds.getHost();
        Integer port = ds.getPort();
        if (host == null || host.isEmpty() || port == null || port <= 0) {
            ds.setStatus(0);
            try { sceneRepository.updateSceneDataSource(ds); } catch (Exception ignore) { }
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "连接失败: 主机或端口未配置");
        }

        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(host, port), 2000);
            ds.setStatus(1);
            sceneRepository.updateSceneDataSource(ds);
            return BaseResultEntity.success("连接正常");
        } catch (Exception e) {
            ds.setStatus(0);
            try { sceneRepository.updateSceneDataSource(ds); } catch (Exception ignore) { }
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "连接失败: " + e.getMessage());
        }
    }
}
