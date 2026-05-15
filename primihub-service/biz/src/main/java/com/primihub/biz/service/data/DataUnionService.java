package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.data.po.DataUnion;
import com.primihub.biz.entity.data.po.DataUnionTask;
import com.primihub.biz.entity.data.req.DataUnionReq;
import com.primihub.biz.entity.sys.po.ComputeLog;
import com.primihub.biz.repository.primarydb.data.DataUnionPrRepository;
import com.primihub.biz.repository.secondarydb.data.DataUnionRepository;
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
public class DataUnionService {

    @Autowired
    private DataUnionRepository dataUnionRepository;
    @Autowired
    private DataUnionPrRepository dataUnionPrRepository;
    @Autowired
    private LogManagementService logManagementService;

    public BaseResultEntity saveDataUnion(DataUnionReq req, Long userId) {
        try {
            DataUnion dataUnion = new DataUnion();
            dataUnion.setOwnOrganId(req.getOwnOrganId());
            dataUnion.setOwnResourceId(req.getOwnResourceId());
            dataUnion.setOwnKeyword(req.getOwnKeyword());
            dataUnion.setOtherOrganId(req.getOtherOrganId());
            dataUnion.setOtherResourceId(req.getOtherResourceId());
            dataUnion.setOtherKeyword(req.getOtherKeyword());
            dataUnion.setOutputFilePathType(0);
            dataUnion.setOutputNoRepeat(0);
            dataUnion.setTag(req.getTag());
            dataUnion.setResultName(req.getResultName());
            dataUnion.setOutputFormat("csv");
            dataUnion.setResultOrganIds(req.getResultOrganIds());
            dataUnion.setRemarks(req.getRemarks());
            dataUnion.setTeeOrganId(req.getTeeOrganId());
            dataUnion.setUserId(userId);
            dataUnionPrRepository.saveDataUnion(dataUnion);

            DataUnionTask task = new DataUnionTask();
            task.setUnionId(dataUnion.getId());
            task.setTaskId(UUID.randomUUID().toString());
            task.setTaskState(0);
            if (dataUnion.getResultOrganIds() != null && dataUnion.getResultOrganIds().indexOf(",") != -1) {
                task.setAscriptionType(1);
            } else {
                task.setAscriptionType(0);
            }
            task.setAscription("并集");
            task.setCreateDate(new Date());
            dataUnionPrRepository.saveDataUnionTask(task);

            recordComputeLog(task.getTaskId(), req.getResultName(), "联邦求并", userId, null, 0);

            Map<String, Object> map = new HashMap<>();
            map.put("dataUnion", dataUnion);
            map.put("taskId", task.getId());
            map.put("taskIdName", task.getTaskId());
            log.info("联邦求并任务创建成功, taskId: {}", task.getTaskId());
            return BaseResultEntity.success(map);
        } catch (Exception e) {
            log.error("创建联邦求并任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建任务失败");
        }
    }

    public BaseResultEntity getUnionTaskList(String taskName, Integer taskState, String organId,
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

            List<Map<String, Object>> list = dataUnionRepository.selectTaskPage(params);
            if (list == null || list.size() == 0) {
                return BaseResultEntity.success(new PageDataEntity(0, pageSize, pageNo, new ArrayList()));
            }
            Long count = dataUnionRepository.selectTaskPageCount(params);
            return BaseResultEntity.success(new PageDataEntity(count.intValue(), pageSize, pageNo, list));
        } catch (Exception e) {
            log.error("查询联邦求并任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getUnionTaskDetails(Long taskId) {
        try {
            DataUnionTask task = dataUnionRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "未查询到任务信息");
            }
            DataUnion dataUnion = dataUnionRepository.selectById(task.getUnionId());
            if (dataUnion == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "未查询到求并信息");
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("task", task);
            result.put("dataUnion", dataUnion);
            if (StringUtils.isNotEmpty(task.getFilePath())) {
                result.put("dataList", FileUtil.getCsvData(task.getFilePath(), 50));
            }
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询联邦求并任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public void downloadUnionTask(HttpServletResponse response, Long taskId) {
        try {
            DataUnionTask task = dataUnionRepository.selectTaskById(taskId);
            if (task == null) {
                log.warn("下载联邦求并结果文件失败, 任务不存在, taskId: {}", taskId);
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
                log.warn("下载联邦求并结果文件失败, 文件路径为空, taskId: {}", taskId);
                return;
            }
            File file = new File(filePath);
            if (!file.exists()) {
                log.warn("下载联邦求并结果文件失败, 文件不存在, path: {}", filePath);
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
            log.info("下载联邦求并结果文件成功, taskId: {}", taskId);
        } catch (Exception e) {
            log.error("下载联邦求并结果文件失败", e);
        }
    }

    public BaseResultEntity delUnionTask(Long taskId) {
        try {
            DataUnionTask task = dataUnionRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL);
            }
            if (task.getTaskState() == 2) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "运行中无法删除");
            }
            dataUnionPrRepository.delUnionTask(task.getId());
            dataUnionPrRepository.delUnion(task.getUnionId());
            log.info("删除联邦求并任务成功, taskId: {}", taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除联邦求并任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    public BaseResultEntity cancelUnionTask(Long taskId) {
        try {
            DataUnionTask task = dataUnionRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "未查询到任务信息");
            }
            task.setTaskState(4);
            dataUnionPrRepository.updateDataUnionTask(task);
            log.info("取消联邦求并任务成功, taskId: {}", taskId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("取消联邦求并任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    private void recordComputeLog(String taskId, String taskName, String computeType,
                                    Long userId, Long projectId, Integer status) {
        try {
            ComputeLog computeLog = new ComputeLog();
            computeLog.setLogCode("COMPUTE_UNION");
            computeLog.setTaskId(taskId);
            computeLog.setTaskName(taskName);
            computeLog.setComputeType(computeType);
            computeLog.setUserId(userId);
            computeLog.setProjectId(projectId);
            computeLog.setStatus(status);
            computeLog.setStartTime(new Date());
            computeLog.setCreateDate(new Date());

            logManagementService.recordComputeLog(computeLog);
            log.info("记录联邦求并计算日志成功, taskId: {}", taskId);
        } catch (Exception e) {
            log.error("记录联邦求并计算日志失败", e);
        }
    }
}
