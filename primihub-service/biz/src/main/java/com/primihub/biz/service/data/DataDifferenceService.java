package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.data.po.DataDifference;
import com.primihub.biz.entity.data.po.DataDifferenceTask;
import com.primihub.biz.entity.data.req.DataDifferenceReq;
import com.primihub.biz.entity.sys.po.ComputeLog;
import com.primihub.biz.repository.primarydb.data.DataDifferencePrRepository;
import com.primihub.biz.repository.secondarydb.data.DataDifferenceRepository;
import com.primihub.biz.service.sys.LogManagementService;
import com.primihub.biz.util.FileUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.util.*;

@Slf4j
@Service
public class DataDifferenceService {

    @Autowired
    private DataDifferenceRepository dataDifferenceRepository;
    @Autowired
    private DataDifferencePrRepository dataDifferencePrRepository;
    @Autowired
    private LogManagementService logManagementService;

    public BaseResultEntity saveDataDifference(DataDifferenceReq req, Long userId) {
        try {
            DataDifference dataDifference = new DataDifference();
            dataDifference.setOwnOrganId(req.getOwnOrganId());
            dataDifference.setOwnResourceId(req.getOwnResourceId());
            dataDifference.setOwnKeyword(req.getOwnKeyword());
            dataDifference.setOtherOrganId(req.getOtherOrganId());
            dataDifference.setOtherResourceId(req.getOtherResourceId());
            dataDifference.setOtherKeyword(req.getOtherKeyword());
            dataDifference.setOutputFilePathType(0);
            dataDifference.setOutputNoRepeat(0);
            dataDifference.setTag(req.getTag());
            dataDifference.setResultName(req.getResultName());
            dataDifference.setOutputFormat("csv");
            dataDifference.setResultOrganIds(req.getResultOrganIds());
            dataDifference.setDifferenceDirection(req.getDifferenceDirection());
            dataDifference.setRemarks(req.getRemarks());
            dataDifference.setTeeOrganId(req.getTeeOrganId());
            dataDifference.setUserId(userId);
            dataDifferencePrRepository.saveDataDifference(dataDifference);

            DataDifferenceTask task = new DataDifferenceTask();
            task.setDifferenceId(dataDifference.getId());
            task.setTaskId(UUID.randomUUID().toString());
            task.setTaskState(0);
            if (dataDifference.getResultOrganIds() != null && dataDifference.getResultOrganIds().indexOf(",") != -1) {
                task.setAscriptionType(1);
            } else {
                task.setAscriptionType(0);
            }
            task.setAscription("差集");
            task.setCreateDate(new Date());
            dataDifferencePrRepository.saveDataDifferenceTask(task);

            recordComputeLog(task.getTaskId(), req.getResultName(), "联邦求差", userId, null, 0);

            Map<String, Object> map = new HashMap<>();
            map.put("dataDifference", dataDifference);
            map.put("taskId", task.getId());
            map.put("taskIdName", task.getTaskId());
            log.info("联邦求差任务创建成功, taskId: {}", task.getTaskId());
            return BaseResultEntity.success(map);
        } catch (Exception e) {
            log.error("创建联邦求差任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建任务失败");
        }
    }

    public BaseResultEntity getDifferenceTaskList(String taskName, Integer taskState, String organId,
                                                   String startDate, String endDate, Integer pageNo, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("resultName", taskName);
            params.put("taskState", taskState);
            params.put("organId", organId);
            params.put("startDate", startDate);
            params.put("endDate", endDate);
            params.put("offset", (pageNo - 1) * pageSize);
            params.put("pageSize", pageSize);

            List<Map<String, Object>> list = dataDifferenceRepository.selectTaskPage(params);
            if (list == null || list.size() == 0) {
                return BaseResultEntity.success(new PageDataEntity(0, pageSize, pageNo, new ArrayList()));
            }
            Long count = dataDifferenceRepository.selectTaskPageCount(params);
            return BaseResultEntity.success(new PageDataEntity(count.intValue(), pageSize, pageNo, list));
        } catch (Exception e) {
            log.error("查询联邦求差任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getDifferenceTaskDetails(Long taskId) {
        try {
            DataDifferenceTask task = dataDifferenceRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "未查询到任务信息");
            }
            DataDifference dataDifference = dataDifferenceRepository.selectById(task.getDifferenceId());
            if (dataDifference == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "未查询到求差信息");
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("task", task);
            result.put("dataDifference", dataDifference);
            if (StringUtils.isNotEmpty(task.getFilePath())) {
                result.put("dataList", FileUtil.getCsvData(task.getFilePath(), 50));
            }
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询联邦求差任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public void downloadDifferenceTask(HttpServletResponse response, Long taskId) {
        try {
            DataDifferenceTask task = dataDifferenceRepository.selectTaskById(taskId);
            if (task == null) {
                log.warn("下载联邦求差结果文件失败, 任务不存在, taskId: {}", taskId);
                return;
            }
            String filePath = task.getFilePath();
            if (StringUtils.isBlank(filePath)) {
                String fileContent = task.getFileContent();
                if (StringUtils.isNotBlank(fileContent)) {
                    response.setContentType("text/plain;charset=UTF-8");
                    response.setHeader("Content-Disposition", "attachment;filename=" +
                            URLEncoder.encode(task.getTaskId() + ".csv", "UTF-8"));
                    response.getOutputStream().write(fileContent.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    return;
                }
                log.warn("下载联邦求差结果文件失败, 文件路径为空, taskId: {}", taskId);
                return;
            }
            File file = new File(filePath);
            if (!file.exists()) {
                log.warn("下载联邦求差结果文件失败, 文件不存在, path: {}", filePath);
                return;
            }
            response.setContentType("application/octet-stream;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                    URLEncoder.encode(file.getName(), "UTF-8"));
            try (FileInputStream fis = new FileInputStream(file);
                 OutputStream os = response.getOutputStream()) {
                byte[] buffer = new byte[4096];
                int len;
                while ((len = fis.read(buffer)) != -1) {
                    os.write(buffer, 0, len);
                }
                os.flush();
            }
            log.info("下载联邦求差结果文件成功, taskId: {}", taskId);
        } catch (Exception e) {
            log.error("下载联邦求差结果文件失败", e);
        }
    }

    public BaseResultEntity delDifferenceTask(Long taskId) {
        try {
            DataDifferenceTask task = dataDifferenceRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL);
            }
            if (task.getTaskState() == 2) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "运行中无法删除");
            }
            dataDifferencePrRepository.delDifferenceTask(task.getId());
            dataDifferencePrRepository.delDifference(task.getDifferenceId());
            log.info("删除联邦求差任务成功, taskId: {}", taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除联邦求差任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    public BaseResultEntity cancelDifferenceTask(Long taskId) {
        try {
            DataDifferenceTask task = dataDifferenceRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "未查询到任务信息");
            }
            task.setTaskState(4);
            dataDifferencePrRepository.updateDataDifferenceTask(task);
            log.info("取消联邦求差任务成功, taskId: {}", taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("取消联邦求差任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    private void recordComputeLog(String taskId, String taskName, String computeType,
                                    Long userId, Long projectId, Integer status) {
        try {
            ComputeLog computeLog = new ComputeLog();
            computeLog.setLogCode("COMPUTE_DIFFERENCE");
            computeLog.setTaskId(taskId);
            computeLog.setTaskName(taskName);
            computeLog.setComputeType(computeType);
            computeLog.setUserId(userId);
            computeLog.setProjectId(projectId);
            computeLog.setStatus(status);
            computeLog.setStartTime(new Date());
            computeLog.setCreateDate(new Date());

            logManagementService.recordComputeLog(computeLog);
            log.info("记录联邦求差计算日志成功, taskId: {}", taskId);
        } catch (Exception e) {
            log.error("记录联邦求差计算日志失败", e);
        }
    }
}
