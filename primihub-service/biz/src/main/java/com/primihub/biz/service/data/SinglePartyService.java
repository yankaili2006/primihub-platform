package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.po.SingleParty;
import com.primihub.biz.entity.data.po.SinglePartyTask;
import com.primihub.biz.entity.data.req.SinglePartyReq;
import com.primihub.biz.entity.sys.po.ComputeLog;
import com.primihub.biz.repository.primarydb.data.SinglePartyPrRepository;
import com.primihub.biz.repository.secondarydb.data.SinglePartyRepository;
import com.primihub.biz.service.sys.LogManagementService;
import com.primihub.biz.util.FileUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.util.*;

@Slf4j
@Service
public class SinglePartyService {

    @Autowired
    private LogManagementService logManagementService;

    @Autowired
    private SinglePartyRepository singlePartyRepository;

    @Autowired
    private SinglePartyPrRepository singlePartyPrRepository;

    public BaseResultEntity createTask(SinglePartyReq req, Long userId) {
        try {
            String taskId = UUID.randomUUID().toString();

            SingleParty sp = new SingleParty();
            BeanUtils.copyProperties(req, sp);
            sp.setUserId(userId);
            sp.setCreateDate(new Date());
            sp.setUpdateDate(new Date());
            sp.setIsDel(0);
            singlePartyPrRepository.saveSingleParty(sp);

            SinglePartyTask task = new SinglePartyTask();
            task.setSpId(sp.getId());
            task.setTaskId(taskId);
            task.setTaskState(2);
            task.setIsDel(0);
            task.setCreateDate(new Date());
            task.setUpdateDate(new Date());
            singlePartyPrRepository.saveSinglePartyTask(task);

            Map<String, Object> algorithmParams = buildAlgorithmParams(req, taskId);
            String algorithmPath = getAlgorithmPath(req);
            executePythonAlgorithm(algorithmPath, algorithmParams, taskId);

            String computeType = getComputeType(req);
            recordComputeLog(taskId, req.getTaskName(), computeType, userId, req.getProjectId(), 0);

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", taskId);
            result.put("message", "任务已创建，正在执行中...");

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建单方算法任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建任务失败: " + e.getMessage());
        }
    }

    public BaseResultEntity getTaskList(String taskName, Integer algorithmType, Integer taskState,
                                        Long projectId, String startDate, String endDate,
                                        Integer pageNo, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskName", taskName);
            params.put("algorithmType", algorithmType);
            params.put("taskState", taskState);
            params.put("projectId", projectId);
            params.put("startDate", startDate);
            params.put("endDate", endDate);
            params.put("offset", (pageNo - 1) * pageSize);
            params.put("pageSize", pageSize);

            List<Map<String, Object>> data = singlePartyRepository.selectTaskPage(params);
            Long total = singlePartyRepository.selectTaskPageCount(params);

            Map<String, Object> result = new HashMap<>();
            result.put("data", data);
            result.put("total", total);
            result.put("pageNo", pageNo);
            result.put("pageSize", pageSize);
            result.put("totalPage", (total + pageSize - 1) / pageSize);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询单方算法任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getTaskDetails(String taskId) {
        try {
            SinglePartyTask task = singlePartyRepository.selectTaskByTaskId(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务不存在");
            }
            SingleParty sp = singlePartyRepository.selectById(task.getSpId());

            Map<String, Object> result = new HashMap<>();
            result.put("task", task);
            result.put("singleParty", sp);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询单方算法任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public void downloadResult(HttpServletResponse response, String taskId) {
        try {
            SinglePartyTask task = singlePartyRepository.selectTaskByTaskId(taskId);
            if (task != null && task.getResultFilePath() != null) {
                File file = new File(task.getResultFilePath());
                if (file.exists()) {
                    FileUtil.downloadFile(response, file, "result.csv");
                }
            }
        } catch (Exception e) {
            log.error("下载结果失败", e);
        }
    }

    public BaseResultEntity deleteTask(String taskId) {
        try {
            singlePartyPrRepository.deleteTask(taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    public BaseResultEntity cancelTask(String taskId) {
        try {
            singlePartyPrRepository.cancelTask(taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("取消任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    private Map<String, Object> buildAlgorithmParams(SinglePartyReq req, String taskId) {
        Map<String, Object> params = new HashMap<>();
        params.put("task_id", taskId);
        params.put("algorithm_type", req.getAlgorithmType());
        params.put("resource_id", req.getResourceId());
        params.put("selected_features", req.getSelectedFeatures());
        params.put("algorithm_params", req.getAlgorithmParams());
        return params;
    }

    private String getAlgorithmPath(SinglePartyReq req) {
        String basePath = "/home/primihub/primihub-platform/python-algorithms/single_party/";
        String[] algorithms = {"", "statistics", "cleaning", "scaling", "encoding", "binning",
                               "selection", "derivation", "lr", "xgboost", "script"};
        return basePath + algorithms[req.getAlgorithmType()] + ".py";
    }

    private void executePythonAlgorithm(String algorithmPath, Map<String, Object> params, String taskId) {
        new Thread(() -> {
            try {
                ProcessBuilder pb = new ProcessBuilder("python3", algorithmPath, JSON.toJSONString(params));
                pb.redirectErrorStream(true);
                Process process = pb.start();

                int exitCode = process.waitFor();

                SinglePartyTask task = new SinglePartyTask();
                task.setTaskId(taskId);
                task.setTaskState(exitCode == 0 ? 1 : 3);
                singlePartyPrRepository.updateSinglePartyTask(task);
            } catch (Exception e) {
                log.error("执行Python算法失败, taskId: " + taskId, e);
                try {
                    SinglePartyTask task = new SinglePartyTask();
                    task.setTaskId(taskId);
                    task.setTaskState(3);
                    singlePartyPrRepository.updateSinglePartyTask(task);
                } catch (Exception ex) {
                    log.error("更新任务状态失败", ex);
                }
            }
        }).start();
    }

    private String getComputeType(SinglePartyReq req) {
        String[] types = {"", "数据统计", "数据清洗", "数据缩放", "特征编码", "特征分箱",
                          "特征筛选", "特征衍生", "LR算法", "XGB算法", "Python脚本"};
        return "单方" + types[req.getAlgorithmType()];
    }

    private void recordComputeLog(String taskId, String taskName, String computeType,
                                   Long userId, Long projectId, Integer status) {
        try {
            ComputeLog computeLog = new ComputeLog();
            computeLog.setLogCode("COMPUTE_SP");
            computeLog.setTaskId(taskId);
            computeLog.setTaskName(taskName);
            computeLog.setComputeType(computeType);
            computeLog.setUserId(userId);
            computeLog.setProjectId(projectId);
            computeLog.setStatus(status);
            computeLog.setStartTime(new Date());
            computeLog.setCreateDate(new Date());

            logManagementService.recordComputeLog(computeLog);
        } catch (Exception e) {
            log.error("记录单方算法计算日志失败", e);
        }
    }
}
