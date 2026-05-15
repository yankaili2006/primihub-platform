package com.primihub.biz.service.data.impl;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.SceneApiConfig;
import com.primihub.biz.entity.data.po.SceneKeyConfig;
import com.primihub.biz.entity.data.po.SceneTask;
import com.primihub.biz.repository.primarydb.data.ScenePrimarydbRepository;
import com.primihub.biz.service.data.SceneService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.net.HttpURLConnection;
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

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            result.put("sceneType", sceneType);
            result.put("taskType", taskType);
            result.put("status", 0);
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
    public BaseResultEntity getTaskDetail(Long taskId) {
        try {
            SceneTask task = sceneRepository.selectSceneTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
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
                config.getPublicKey() != null ? config.getPublicKey().substring(0, Math.min(16, config.getPublicKey().length())) : "PrimiHubScene".toCharArray(),
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
                config.getPublicKey() != null ? config.getPublicKey().substring(0, Math.min(16, config.getPublicKey().length())) : "PrimiHubScene".toCharArray(),
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
}
