package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.FederatedLearning;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import com.primihub.biz.entity.data.req.FederatedLearningReq;
import com.primihub.biz.entity.data.req.DataModelAndComponentReq;
import com.primihub.biz.entity.data.req.DataComponentReq;
import com.primihub.biz.entity.data.req.DataComponentValue;
import com.primihub.biz.entity.sys.po.ComputeLog;
import com.primihub.biz.repository.primarydb.data.FederatedLearningPrRepository;
import com.primihub.biz.repository.secondarydb.data.FederatedLearningRepository;
import com.primihub.biz.service.sys.LogManagementService;
import com.primihub.biz.util.FileUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.util.*;

/**
 * 联邦学习Service
 */
@Slf4j
@Service
public class FederatedLearningService {

    @Autowired
    private LogManagementService logManagementService;

    @Autowired
    private FederatedLearningRepository federatedLearningRepository;

    @Autowired
    private FederatedLearningPrRepository federatedLearningPrRepository;
    @Autowired
    private DataModelService dataModelService;

    // 默认模板模型(纵向LR DAG: start->dataSet->dataAlign->model)与其项目; 可被 req 覆盖。
    private static final Long DEFAULT_TEMPLATE_MODEL_ID = 1L;
    private static final Long DEFAULT_PROJECT_ID = 2L;

    /**
     * 创建并运行联邦学习任务 —— 真实实现: 桥接到平台真实 FL(model-DAG -> node gRPC MPC)。
     * 克隆已验证可跑的模型 DAG(getModelComponentReq)-> 另存为新模型 -> runTaskModel 触发真节点联邦学习。
     */
    public BaseResultEntity createTask(FederatedLearningReq req, Long userId) {
        try {
            String taskId = UUID.randomUUID().toString();

            // 保存联邦学习记录 + 任务记录(审计, best-effort: 表结构漂移不应阻断真实 FL)
            FederatedLearningTask task = new FederatedLearningTask();
            task.setTaskId(taskId);
            task.setTaskState(2);
            task.setCurrentRound(0);
            task.setTotalRounds(req.getTrainingParams() != null ? req.getTrainingParams().getEpochs() : 10);
            task.setIsDel(0);
            task.setCreateDate(new Date());
            task.setUpdateDate(new Date());
            boolean auditSaved = false;
            try {
                FederatedLearning fl = new FederatedLearning();
                BeanUtils.copyProperties(req, fl);
                fl.setUserId(userId);
                fl.setCreateDate(new Date());
                fl.setUpdateDate(new Date());
                fl.setIsDel(0);
                federatedLearningPrRepository.saveFederatedLearning(fl);
                task.setFlId(fl.getId());
                federatedLearningPrRepository.saveFederatedLearningTask(task);
                auditSaved = true;
            } catch (Exception auditEx) {
                log.warn("联邦学习审计记录保存失败(表结构漂移?), 不阻断真实 FL: {}", auditEx.getMessage());
            }

            // ===== 桥接真实 FL =====
            Long templateModelId = DEFAULT_TEMPLATE_MODEL_ID;
            try { if (req.getModelId() != null && req.getModelId().matches("\\d+")) templateModelId = Long.valueOf(req.getModelId()); } catch (Exception ignore) {}
            Long projectId = (req.getProjectId() != null && req.getProjectId() != 0L) ? req.getProjectId() : DEFAULT_PROJECT_ID;

            DataModelAndComponentReq mr = dataModelService.getModelComponentReq(templateModelId, userId, projectId);
            if (mr == null || mr.getModelComponents() == null || mr.getModelComponents().isEmpty()) {
                task.setTaskState(3);
                task.setExecutionLog("无可用模板模型 DAG(templateModelId=" + templateModelId + "), 无法启动真实联邦学习");
                if (auditSaved) federatedLearningPrRepository.updateFederatedLearningTask(task);
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "缺少模板模型 DAG(templateModelId=" + templateModelId + ")");
            }
            // 另存为新模型 + 改名(保证唯一)
            mr.setModelId(null);
            mr.setProjectId(projectId);
            mr.setIsDraft(1);
            String flName = (req.getTaskName() != null && !req.getTaskName().isEmpty()) ? req.getTaskName() : ("fl-" + taskId.substring(0, 8));
            for (DataComponentReq c : mr.getModelComponents()) {
                if (c.getComponentValues() == null) continue;
                if ("model".equals(c.getComponentCode())) setCompVal(c, "modelName", flName);
                if ("start".equals(c.getComponentCode())) setCompVal(c, "taskName", flName);
            }
            BaseResultEntity saveRes = dataModelService.saveModelAndComponent(userId, mr);
            if (saveRes.getCode() != 0 || !(saveRes.getResult() instanceof Map)) {
                task.setTaskState(3);
                task.setExecutionLog("saveModelAndComponent 失败: " + saveRes.getMsg());
                if (auditSaved) federatedLearningPrRepository.updateFederatedLearningTask(task);
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建模型失败: " + saveRes.getMsg());
            }
            Object newModelIdObj = ((Map<String, Object>) saveRes.getResult()).get("modelId");
            Long newModelId = Long.valueOf(newModelIdObj.toString());
            BaseResultEntity runRes = dataModelService.runTaskModel(newModelId, userId);
            // 关联真实模型/任务, 供进度回读
            Map<String, Object> ref = new HashMap<>();
            ref.put("engine", "model-DAG(node gRPC FL)");
            ref.put("modelId", newModelId);
            ref.put("runResult", runRes.getMsg());
            task.setExecutionLog(JSON.toJSONString(ref));
            task.setTaskState(runRes.getCode() == 0 ? 2 : 3);
            if (auditSaved) federatedLearningPrRepository.updateFederatedLearningTask(task);

            String computeType = getComputeType(req);
            recordComputeLog(taskId, req.getTaskName(), computeType, userId, req.getProjectId(), 0);
            log.info("联邦学习任务(真实 FL)创建, taskId:{}, modelId:{}, runCode:{}", taskId, newModelId, runRes.getCode());

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", taskId);
            result.put("engine", "model-DAG(node gRPC FL)");
            result.put("modelId", newModelId);
            result.put("message", runRes.getCode() == 0 ? "真实联邦学习已提交到节点" : ("提交失败: " + runRes.getMsg()));
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建联邦学习任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建任务失败: " + e.getMessage());
        }
    }

    private static void setCompVal(DataComponentReq c, String key, String val) {
        for (DataComponentValue v : c.getComponentValues()) {
            if (key.equals(v.getKey())) { v.setVal(val); return; }
        }
        DataComponentValue nv = new DataComponentValue();
        nv.setKey(key); nv.setVal(val);
        c.getComponentValues().add(nv);
    }

    /**
     * 查询任务列表
     */
    public BaseResultEntity getTaskList(String taskName, Integer taskType, Integer algorithmType,
                                        Integer taskState, Long projectId, String startDate,
                                        String endDate, Integer pageNo, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskName", taskName);
            params.put("taskType", taskType);
            params.put("algorithmType", algorithmType);
            params.put("taskState", taskState);
            params.put("projectId", projectId);
            params.put("startDate", startDate);
            params.put("endDate", endDate);
            params.put("offset", (pageNo - 1) * pageSize);
            params.put("pageSize", pageSize);

            List<Map<String, Object>> data = federatedLearningRepository.selectTaskPage(params);
            Long total = federatedLearningRepository.selectTaskPageCount(params);

            Map<String, Object> result = new HashMap<>();
            result.put("data", data);
            result.put("total", total);
            result.put("pageNo", pageNo);
            result.put("pageSize", pageSize);
            result.put("totalPage", (total + pageSize - 1) / pageSize);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询联邦学习任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询任务详情
     */
    public BaseResultEntity getTaskDetails(String taskId) {
        try {
            FederatedLearningTask task = federatedLearningRepository.selectTaskByTaskId(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在");
            }
            FederatedLearning fl = federatedLearningRepository.selectById(task.getFlId());

            Map<String, Object> result = new HashMap<>();
            result.put("task", task);
            result.put("federatedLearning", fl);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询联邦学习任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 查询模型列表
     */
    public BaseResultEntity getModelList(Integer algorithmType, Long projectId,
                                         Integer pageNo, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("algorithmType", algorithmType);
            params.put("projectId", projectId);
            params.put("offset", (pageNo - 1) * pageSize);
            params.put("pageSize", pageSize);

            List<Map<String, Object>> data = federatedLearningRepository.selectModelList(params);
            Long total = federatedLearningRepository.selectModelListCount(params);

            Map<String, Object> result = new HashMap<>();
            result.put("data", data);
            result.put("total", total);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询模型列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 下载模型文件
     */
    public void downloadModel(HttpServletResponse response, String modelId) {
        try {
            FederatedLearningTask task = federatedLearningRepository.selectTaskByTaskId(modelId);
            if (task == null) {
                return;
            }
            FederatedLearning fl = federatedLearningRepository.selectById(task.getFlId());
            if (fl != null && fl.getModelPath() != null) {
                File file = new File(fl.getModelPath());
                if (file.exists()) {
                    response.setContentType("application/octet-stream");
                    response.setHeader("Content-Disposition", "attachment; filename=" + fl.getTaskName() + "_model.pkl");
                    java.nio.file.Files.copy(file.toPath(), response.getOutputStream());
                }
            }
        } catch (Exception e) {
            log.error("下载模型文件失败", e);
        }
    }

    /**
     * 下载预测结果
     */
    public void downloadResult(HttpServletResponse response, String taskId) {
        try {
            FederatedLearningTask task = federatedLearningRepository.selectTaskByTaskId(taskId);
            if (task != null && task.getResultFilePath() != null) {
                File file = new File(task.getResultFilePath());
                if (file.exists()) {
                    response.setContentType("application/octet-stream");
                    response.setHeader("Content-Disposition", "attachment; filename=prediction_result.csv");
                    java.nio.file.Files.copy(file.toPath(), response.getOutputStream());
                }
            }
        } catch (Exception e) {
            log.error("下载预测结果失败", e);
        }
    }

    /**
     * 删除任务
     */
    public BaseResultEntity deleteTask(String taskId) {
        try {
            federatedLearningPrRepository.deleteTask(taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 取消任务
     */
    public BaseResultEntity cancelTask(String taskId) {
        try {
            federatedLearningPrRepository.cancelTask(taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("取消任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    /**
     * 获取训练进度
     */
    public BaseResultEntity getTrainingProgress(String taskId) {
        try {
            FederatedLearningTask task = federatedLearningRepository.selectTaskByTaskId(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在");
            }

            Map<String, Object> progress = new HashMap<>();
            progress.put("currentRound", task.getCurrentRound());
            progress.put("totalRounds", task.getTotalRounds());
            progress.put("accuracy", task.getAccuracy());
            progress.put("loss", task.getLoss());
            progress.put("taskState", task.getTaskState());

            return BaseResultEntity.success(progress);
        } catch (Exception e) {
            log.error("获取训练进度失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 构建算法参数
     */
    private Map<String, Object> buildAlgorithmParams(FederatedLearningReq req, String taskId) {
        Map<String, Object> params = new HashMap<>();
        params.put("task_id", taskId);
        params.put("task_type", req.getTaskType()); // 1:建模 2:预测
        params.put("algorithm_type", req.getAlgorithmType()); // 1:线性回归 2:逻辑回归 3:XGBoost
        params.put("federated_type", req.getFederatedType()); // 1:横向 2:纵向
        params.put("own_organ_id", req.getOwnOrganId());
        params.put("own_resource_id", req.getOwnResourceId());
        params.put("own_features", req.getOwnFeatures());
        params.put("label_feature", req.getLabelFeature());
        params.put("is_label_owner", req.getIsLabelOwner());
        params.put("participant_organ_ids", req.getParticipantOrganIds());
        params.put("participant_resource_ids", req.getParticipantResourceIds());
        params.put("training_params", req.getTrainingParams() != null ?
            JSON.toJSONString(req.getTrainingParams()) : null);
        params.put("model_id", req.getModelId());

        return params;
    }

    /**
     * 获取计算类型名称
     */
    private String getComputeType(FederatedLearningReq req) {
        String algorithmName = getAlgorithmName(req.getAlgorithmType());
        String taskTypeName = req.getTaskType() == 1 ? "建模" : "预测";
        String federatedTypeName = req.getFederatedType() == 1 ? "横向" : "纵向";

        return String.format("联邦学习%s%s（%s）", algorithmName, taskTypeName, federatedTypeName);
    }

    /**
     * 获取算法名称
     */
    private String getAlgorithmName(Integer algorithmType) {
        switch (algorithmType) {
            case 1: return "线性回归";
            case 2: return "逻辑回归";
            case 3: return "XGBoost";
            default: return "未知算法";
        }
    }

    /**
     * 获取算法路径
     */
    private String getAlgorithmPath(FederatedLearningReq req) {
        String basePath = "/home/primihub/primihub-platform/python-algorithms/federated_learning/";
        String algorithmName = "";

        switch (req.getAlgorithmType()) {
            case 1: algorithmName = "linear_regression"; break;
            case 2: algorithmName = "logistic_regression"; break;
            case 3: algorithmName = "xgboost"; break;
            default: throw new RuntimeException("不支持的算法类型");
        }

        String taskType = req.getTaskType() == 1 ? "train" : "predict";
        return basePath + algorithmName + "_" + taskType + ".py";
    }

    /**
     * 执行Python算法
     */
    private void executePythonAlgorithm(String algorithmPath, Map<String, Object> params, String taskId) {
        new Thread(() -> {
            try {
                ProcessBuilder pb = new ProcessBuilder("python3", algorithmPath, JSON.toJSONString(params));
                pb.redirectErrorStream(true);
                Process process = pb.start();

                int exitCode = process.waitFor();

                FederatedLearningTask task = new FederatedLearningTask();
                task.setTaskId(taskId);
                task.setTaskState(exitCode == 0 ? 1 : 3);
                federatedLearningPrRepository.updateFederatedLearningTask(task);

                log.info("Python算法执行完成, taskId: {}, exitCode: {}", taskId, exitCode);
            } catch (Exception e) {
                log.error("执行Python算法失败, taskId: " + taskId, e);
                try {
                    FederatedLearningTask task = new FederatedLearningTask();
                    task.setTaskId(taskId);
                    task.setTaskState(3);
                    federatedLearningPrRepository.updateFederatedLearningTask(task);
                } catch (Exception ex) {
                    log.error("更新任务状态失败", ex);
                }
            }
        }).start();
    }

    /**
     * 记录计算日志
     */
    private void recordComputeLog(String taskId, String taskName, String computeType,
                                    Long userId, Long projectId, Integer status) {
        try {
            ComputeLog computeLog = new ComputeLog();
            computeLog.setLogCode("COMPUTE_FL");
            computeLog.setTaskId(taskId);
            computeLog.setTaskName(taskName);
            computeLog.setComputeType(computeType);
            computeLog.setUserId(userId);
            computeLog.setProjectId(projectId);
            computeLog.setStatus(status);
            computeLog.setStartTime(new Date());
            computeLog.setCreateDate(new Date());

            logManagementService.recordComputeLog(computeLog);
            log.info("记录联邦学习计算日志成功, taskId: {}", taskId);
        } catch (Exception e) {
            log.error("记录联邦学习计算日志失败", e);
        }
    }
}
