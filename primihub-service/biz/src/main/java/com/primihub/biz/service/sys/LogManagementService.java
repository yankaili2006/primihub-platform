package com.primihub.biz.service.sys;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.po.*;
import com.primihub.biz.repository.primarydb.sys.LogManagementPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 日志管理Service
 */
@Slf4j
@Service
public class LogManagementService {

    @Autowired
    private LogManagementPrimarydbRepository logManagementRepository;

    // ========== 操作日志定义 ==========

    /**
     * 查询操作日志定义分页列表
     */
    public BaseResultEntity findOperationLogDefinitionPage(String keyword, String logType, String moduleName,
                                                           Integer isEnabled, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("logType", logType);
            params.put("moduleName", moduleName);
            params.put("isEnabled", isEnabled);

            int total = logManagementRepository.selectOperationLogDefinitionCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<OperationLogDefinition> list = logManagementRepository.selectOperationLogDefinitionList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询操作日志定义列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加操作日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addOperationLogDefinition(OperationLogDefinition definition) {
        try {
            if (definition.getLogCode() == null || definition.getLogCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志代码不能为空");
            }
            if (definition.getLogName() == null || definition.getLogName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志名称不能为空");
            }

            OperationLogDefinition existing = logManagementRepository.selectOperationLogDefinitionByCode(definition.getLogCode());
            if (existing != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "日志代码已存在");
            }

            if (definition.getIsEnabled() == null) {
                definition.setIsEnabled(1);
            }
            if (definition.getRetentionDays() == null) {
                definition.setRetentionDays(30);
            }

            logManagementRepository.insertOperationLogDefinition(definition);
            return BaseResultEntity.success("添加成功");
        } catch (Exception e) {
            log.error("添加操作日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新操作日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateOperationLogDefinition(OperationLogDefinition definition) {
        try {
            if (definition.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            logManagementRepository.updateOperationLogDefinition(definition);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新操作日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除操作日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteOperationLogDefinition(Long id) {
        try {
            logManagementRepository.deleteOperationLogDefinition(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除操作日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 更新操作日志定义状态
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateOperationLogDefinitionStatus(Long id, Integer isEnabled) {
        try {
            logManagementRepository.updateOperationLogDefinitionStatus(id, isEnabled);
            return BaseResultEntity.success("更新状态成功");
        } catch (Exception e) {
            log.error("更新操作日志定义状态失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新状态失败");
        }
    }

    // ========== 调度日志定义 ==========

    /**
     * 查询调度日志定义分页列表
     */
    public BaseResultEntity findScheduleLogDefinitionPage(String keyword, String scheduleType, String moduleName,
                                                          Integer isEnabled, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("scheduleType", scheduleType);
            params.put("moduleName", moduleName);
            params.put("isEnabled", isEnabled);

            int total = logManagementRepository.selectScheduleLogDefinitionCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ScheduleLogDefinition> list = logManagementRepository.selectScheduleLogDefinitionList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询调度日志定义列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加调度日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addScheduleLogDefinition(ScheduleLogDefinition definition) {
        try {
            if (definition.getLogCode() == null || definition.getLogCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志代码不能为空");
            }
            if (definition.getLogName() == null || definition.getLogName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志名称不能为空");
            }

            ScheduleLogDefinition existing = logManagementRepository.selectScheduleLogDefinitionByCode(definition.getLogCode());
            if (existing != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "日志代码已存在");
            }

            if (definition.getIsEnabled() == null) {
                definition.setIsEnabled(1);
            }
            if (definition.getRetentionDays() == null) {
                definition.setRetentionDays(30);
            }

            logManagementRepository.insertScheduleLogDefinition(definition);
            return BaseResultEntity.success("添加成功");
        } catch (Exception e) {
            log.error("添加调度日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新调度日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateScheduleLogDefinition(ScheduleLogDefinition definition) {
        try {
            if (definition.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            logManagementRepository.updateScheduleLogDefinition(definition);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新调度日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除调度日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteScheduleLogDefinition(Long id) {
        try {
            logManagementRepository.deleteScheduleLogDefinition(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除调度日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ========== 计算日志定义 ==========

    /**
     * 查询计算日志定义分页列表
     */
    public BaseResultEntity findComputeLogDefinitionPage(String keyword, String computeType, String moduleName,
                                                         Integer isEnabled, Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("computeType", computeType);
            params.put("moduleName", moduleName);
            params.put("isEnabled", isEnabled);

            int total = logManagementRepository.selectComputeLogDefinitionCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ComputeLogDefinition> list = logManagementRepository.selectComputeLogDefinitionList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询计算日志定义列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加计算日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addComputeLogDefinition(ComputeLogDefinition definition) {
        try {
            if (definition.getLogCode() == null || definition.getLogCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志代码不能为空");
            }
            if (definition.getLogName() == null || definition.getLogName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "日志名称不能为空");
            }

            ComputeLogDefinition existing = logManagementRepository.selectComputeLogDefinitionByCode(definition.getLogCode());
            if (existing != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "日志代码已存在");
            }

            if (definition.getIsEnabled() == null) {
                definition.setIsEnabled(1);
            }
            if (definition.getRetentionDays() == null) {
                definition.setRetentionDays(30);
            }

            logManagementRepository.insertComputeLogDefinition(definition);
            return BaseResultEntity.success("添加成功");
        } catch (Exception e) {
            log.error("添加计算日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新计算日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateComputeLogDefinition(ComputeLogDefinition definition) {
        try {
            if (definition.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }

            logManagementRepository.updateComputeLogDefinition(definition);
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新计算日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除计算日志定义
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteComputeLogDefinition(Long id) {
        try {
            logManagementRepository.deleteComputeLogDefinition(id);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除计算日志定义失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ========== 操作日志记录 ==========

    /**
     * 查询操作日志记录分页列表
     */
    public BaseResultEntity findOperationLogPage(String logCode, Long userId, String userName,
                                                 String operationType, String operationModule,
                                                 Integer status, String startTime, String endTime,
                                                 Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("logCode", logCode);
            params.put("userId", userId);
            params.put("userName", userName);
            params.put("operationType", operationType);
            params.put("operationModule", operationModule);
            params.put("status", status);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            int total = logManagementRepository.selectOperationLogCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<OperationLog> list = logManagementRepository.selectOperationLogList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询操作日志记录失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 记录操作日志
     */
    @Transactional(rollbackFor = Exception.class)
    public void recordOperationLog(OperationLog operationLog) {
        try {
            logManagementRepository.insertOperationLog(operationLog);
        } catch (Exception e) {
            log.error("记录操作日志失败", e);
        }
    }

    // ========== 调度日志记录 ==========

    /**
     * 查询调度日志记录分页列表
     */
    public BaseResultEntity findScheduleLogPage(String logCode, String scheduleName, String scheduleType,
                                                Integer status, String startTime, String endTime,
                                                Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("logCode", logCode);
            params.put("scheduleName", scheduleName);
            params.put("scheduleType", scheduleType);
            params.put("status", status);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            int total = logManagementRepository.selectScheduleLogCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ScheduleLog> list = logManagementRepository.selectScheduleLogList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询调度日志记录失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 记录调度日志
     */
    @Transactional(rollbackFor = Exception.class)
    public void recordScheduleLog(ScheduleLog scheduleLog) {
        try {
            logManagementRepository.insertScheduleLog(scheduleLog);
        } catch (Exception e) {
            log.error("记录调度日志失败", e);
        }
    }

    /**
     * 更新调度日志
     */
    @Transactional(rollbackFor = Exception.class)
    public void updateScheduleLog(ScheduleLog scheduleLog) {
        try {
            logManagementRepository.updateScheduleLog(scheduleLog);
        } catch (Exception e) {
            log.error("更新调度日志失败", e);
        }
    }

    // ========== 计算日志记录 ==========

    /**
     * 查询计算日志记录分页列表
     */
    public BaseResultEntity findComputeLogPage(String logCode, String taskId, String taskName,
                                               String computeType, Long projectId, Long userId,
                                               Integer status, String startTime, String endTime,
                                               Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("logCode", logCode);
            params.put("taskId", taskId);
            params.put("taskName", taskName);
            params.put("computeType", computeType);
            params.put("projectId", projectId);
            params.put("userId", userId);
            params.put("status", status);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            int total = logManagementRepository.selectComputeLogCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<ComputeLog> list = logManagementRepository.selectComputeLogList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询计算日志记录失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 记录计算日志
     */
    @Transactional(rollbackFor = Exception.class)
    public void recordComputeLog(ComputeLog computeLog) {
        try {
            logManagementRepository.insertComputeLog(computeLog);
        } catch (Exception e) {
            log.error("记录计算日志失败", e);
        }
    }

    /**
     * 更新计算日志
     */
    @Transactional(rollbackFor = Exception.class)
    public void updateComputeLog(ComputeLog computeLog) {
        try {
            logManagementRepository.updateComputeLog(computeLog);
        } catch (Exception e) {
            log.error("更新计算日志失败", e);
        }
    }

    // ========== 日志导出 ==========

    /**
     * 导出操作日志
     */
    public void exportOperationLog(HttpServletResponse response, String logCode, Long userId, String userName,
                                    String operationType, String operationModule, Integer status,
                                    String startTime, String endTime) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("logCode", logCode);
            params.put("userId", userId);
            params.put("userName", userName);
            params.put("operationType", operationType);
            params.put("operationModule", operationModule);
            params.put("status", status);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            List<OperationLog> list = logManagementRepository.selectOperationLogList(params);

            Workbook workbook = new XSSFWorkbook();
            Sheet sheet = workbook.createSheet("操作日志");

            String[] headers = {"ID", "日志代码", "用户ID", "用户名", "机构名称", "操作类型", "操作模块",
                              "操作描述", "请求方法", "请求URL", "IP地址", "状态", "执行时长(ms)", "创建时间"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
            }

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            int rowNum = 1;
            for (OperationLog log : list) {
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(log.getId());
                row.createCell(1).setCellValue(log.getLogCode());
                row.createCell(2).setCellValue(log.getUserId() != null ? log.getUserId() : 0);
                row.createCell(3).setCellValue(log.getUserName());
                row.createCell(4).setCellValue(log.getOrganName());
                row.createCell(5).setCellValue(log.getOperationType());
                row.createCell(6).setCellValue(log.getOperationModule());
                row.createCell(7).setCellValue(log.getOperationDesc());
                row.createCell(8).setCellValue(log.getRequestMethod());
                row.createCell(9).setCellValue(log.getRequestUrl());
                row.createCell(10).setCellValue(log.getIpAddress());
                row.createCell(11).setCellValue(log.getStatus() == 1 ? "成功" : "失败");
                row.createCell(12).setCellValue(log.getExecutionTime() != null ? log.getExecutionTime() : 0);
                row.createCell(13).setCellValue(log.getCreateDate() != null ? sdf.format(log.getCreateDate()) : "");
            }

            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename=" + URLEncoder.encode("操作日志.xlsx", "UTF-8"));

            OutputStream out = response.getOutputStream();
            workbook.write(out);
            out.flush();
            out.close();
            workbook.close();
        } catch (Exception e) {
            log.error("导出操作日志失败", e);
        }
    }

    /**
     * 导出调度日志
     */
    public void exportScheduleLog(HttpServletResponse response, String logCode, String scheduleName,
                                   String scheduleType, Integer status, String startTime, String endTime) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("logCode", logCode);
            params.put("scheduleName", scheduleName);
            params.put("scheduleType", scheduleType);
            params.put("status", status);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            List<ScheduleLog> list = logManagementRepository.selectScheduleLogList(params);

            Workbook workbook = new XSSFWorkbook();
            Sheet sheet = workbook.createSheet("调度日志");

            String[] headers = {"ID", "日志代码", "任务名称", "调度类型", "Cron表达式", "执行服务器",
                              "开始时间", "结束时间", "执行时长(ms)", "状态", "重试次数", "创建时间"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
            }

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            int rowNum = 1;
            for (ScheduleLog log : list) {
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(log.getId());
                row.createCell(1).setCellValue(log.getLogCode());
                row.createCell(2).setCellValue(log.getScheduleName());
                row.createCell(3).setCellValue(log.getScheduleType());
                row.createCell(4).setCellValue(log.getScheduleCron());
                row.createCell(5).setCellValue(log.getExecuteServer());
                row.createCell(6).setCellValue(log.getStartTime() != null ? sdf.format(log.getStartTime()) : "");
                row.createCell(7).setCellValue(log.getEndTime() != null ? sdf.format(log.getEndTime()) : "");
                row.createCell(8).setCellValue(log.getExecutionTime() != null ? log.getExecutionTime() : 0);
                String statusText = log.getStatus() == 0 ? "运行中" : log.getStatus() == 1 ? "成功" : "失败";
                row.createCell(9).setCellValue(statusText);
                row.createCell(10).setCellValue(log.getRetryCount());
                row.createCell(11).setCellValue(log.getCreateDate() != null ? sdf.format(log.getCreateDate()) : "");
            }

            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename=" + URLEncoder.encode("调度日志.xlsx", "UTF-8"));

            OutputStream out = response.getOutputStream();
            workbook.write(out);
            out.flush();
            out.close();
            workbook.close();
        } catch (Exception e) {
            log.error("导出调度日志失败", e);
        }
    }

    /**
     * 导出计算日志
     */
    public void exportComputeLog(HttpServletResponse response, String logCode, String taskId, String taskName,
                                  String computeType, Long projectId, Long userId, Integer status,
                                  String startTime, String endTime) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("logCode", logCode);
            params.put("taskId", taskId);
            params.put("taskName", taskName);
            params.put("computeType", computeType);
            params.put("projectId", projectId);
            params.put("userId", userId);
            params.put("status", status);
            params.put("startTime", startTime);
            params.put("endTime", endTime);

            List<ComputeLog> list = logManagementRepository.selectComputeLogList(params);

            Workbook workbook = new XSSFWorkbook();
            Sheet sheet = workbook.createSheet("计算日志");

            String[] headers = {"ID", "日志代码", "任务ID", "任务名称", "计算类型", "项目名称",
                              "用户名", "机构名称", "开始时间", "结束时间", "执行时长(ms)", "状态", "创建时间"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
            }

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            int rowNum = 1;
            for (ComputeLog log : list) {
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(log.getId());
                row.createCell(1).setCellValue(log.getLogCode());
                row.createCell(2).setCellValue(log.getTaskId());
                row.createCell(3).setCellValue(log.getTaskName());
                row.createCell(4).setCellValue(log.getComputeType());
                row.createCell(5).setCellValue(log.getProjectName());
                row.createCell(6).setCellValue(log.getUserName());
                row.createCell(7).setCellValue(log.getOrganName());
                row.createCell(8).setCellValue(log.getStartTime() != null ? sdf.format(log.getStartTime()) : "");
                row.createCell(9).setCellValue(log.getEndTime() != null ? sdf.format(log.getEndTime()) : "");
                row.createCell(10).setCellValue(log.getExecutionTime() != null ? log.getExecutionTime() : 0);
                String statusText = log.getStatus() == 0 ? "运行中" : log.getStatus() == 1 ? "成功" :
                                   log.getStatus() == 2 ? "失败" : "取消";
                row.createCell(11).setCellValue(statusText);
                row.createCell(12).setCellValue(log.getCreateDate() != null ? sdf.format(log.getCreateDate()) : "");
            }

            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename=" + URLEncoder.encode("计算日志.xlsx", "UTF-8"));

            OutputStream out = response.getOutputStream();
            workbook.write(out);
            out.flush();
            out.close();
            workbook.close();
        } catch (Exception e) {
            log.error("导出计算日志失败", e);
        }
    }
}
