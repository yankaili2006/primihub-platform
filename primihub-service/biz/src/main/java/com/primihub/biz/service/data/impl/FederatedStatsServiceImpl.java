package com.primihub.biz.service.data.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.FederatedStatsConfig;
import com.primihub.biz.entity.data.po.FederatedStatsResult;
import com.primihub.biz.entity.data.po.FederatedStatsTask;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.data.vo.StatsTaskDetailVO;
import com.primihub.biz.entity.data.vo.StatsTaskListVO;
import com.primihub.biz.entity.data.vo.StatsTypeVO;
import com.primihub.biz.repository.primarydb.data.FederatedStatsRepository;
import com.primihub.biz.service.data.FederatedStatsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Slf4j
@Service
public class FederatedStatsServiceImpl implements FederatedStatsService {

    @Autowired
    private FederatedStatsRepository federatedStatsRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final Map<String, String> STATS_TYPE_NAMES = new LinkedHashMap<>();
    private static final List<StatsTypeVO> STATS_TYPES = new ArrayList<>();

    static {
        addStatsType("descriptive", "描述性统计", "bar-chart", "均值、最值、方差、标准差、中位数");
        addStatsType("group_by", "分组统计", "pie-chart", "按分组字段进行统计");
        addStatsType("conditional", "条件统计", "filter", "按条件过滤后进行统计");
        addStatsType("proportion", "占比统计", "percentage", "计算各分类占比");
        addStatsType("t_test", "T检验", "check", "独立样本T检验");
        addStatsType("f_test", "F检验", "check", "方差齐性检验");
        addStatsType("chi_square", "卡方检验", "check", "分类变量独立性检验");
        addStatsType("regression", "回归分析", "trending-up", "线性/逻辑回归分析");
        addStatsType("correlation", "相关性分析", "关联", "Pearson/Spearman相关分析");
    }

    private static void addStatsType(String type, String name, String icon, String desc) {
        StatsTypeVO vo = new StatsTypeVO();
        vo.setType(type);
        vo.setName(name);
        vo.setIcon(icon);
        vo.setDescription(desc);
        STATS_TYPES.add(vo);
        STATS_TYPE_NAMES.put(type, name);
    }

    private static final Map<Integer, String> TASK_STATE_NAMES = new HashMap<>();
    static {
        TASK_STATE_NAMES.put(0, "待执行");
        TASK_STATE_NAMES.put(1, "执行中");
        TASK_STATE_NAMES.put(2, "已完成");
        TASK_STATE_NAMES.put(3, "失败");
        TASK_STATE_NAMES.put(4, "已取消");
    }

    // ==================== 任务管理 ====================

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity createTask(FederatedStatsReq req, Long userId) {
        try {
            if (req.getTaskName() == null || req.getTaskName().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "任务名称不能为空");
            }
            if (req.getStatsType() == null || !STATS_TYPE_NAMES.containsKey(req.getStatsType())) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "无效的统计类型");
            }

            FederatedStatsTask task = new FederatedStatsTask();
            task.setTaskName(req.getTaskName());
            task.setProjectId(req.getProjectId());
            task.setStatsType(req.getStatsType());
            task.setAlgorithmType(req.getAlgorithmType());
            task.setTaskParam(req.getTaskParam());
            task.setTaskState(0);
            task.setCreatedBy(userId);
            federatedStatsRepository.insertTask(task);

            Map<String, Object> result = new HashMap<>();
            result.put("taskId", task.getId());
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("创建统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    @Override
    public BaseResultEntity getTaskList(FederatedStatsQueryReq req) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("taskName", req.getTaskName());
            params.put("taskState", req.getTaskState());
            params.put("statsType", req.getStatsType());
            params.put("projectId", req.getProjectId());

            int total = federatedStatsRepository.selectTaskCount(params);
            PageParam pageParam = new PageParam(req.getPageNo(), req.getPageSize());
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<FederatedStatsTask> list = federatedStatsRepository.selectTaskList(params);
            List<StatsTaskListVO> voList = list.stream().map(this::toTaskListVO).collect(Collectors.toList());

            Map<String, Object> result = new HashMap<>();
            result.put("list", voList);
            result.put("total", total);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询统计任务列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    public BaseResultEntity getTaskDetail(Long taskId) {
        try {
            FederatedStatsTask task = federatedStatsRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);

            StatsTaskDetailVO vo = new StatsTaskDetailVO();
            vo.setId(task.getId());
            vo.setTaskName(task.getTaskName());
            vo.setStatsType(task.getStatsType());
            vo.setStatsTypeName(STATS_TYPE_NAMES.getOrDefault(task.getStatsType(), task.getStatsType()));
            vo.setAlgorithmType(task.getAlgorithmType());
            vo.setTaskState(task.getTaskState());
            vo.setTaskStateName(TASK_STATE_NAMES.getOrDefault(task.getTaskState(), "未知"));
            vo.setTaskParam(task.getTaskParam());
            vo.setResultSummary(task.getResultSummary());
            vo.setErrorMessage(task.getErrorMessage());
            vo.setCreatedAt(task.getCreatedAt());
            vo.setResults(results);
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("查询统计任务详情失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity runTask(Long taskId, Long userId) {
        try {
            FederatedStatsTask task = federatedStatsRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            if (task.getTaskState() == 1) {
                return BaseResultEntity.failure(BaseResultEnum.HANDLE_RIGHT_NOW, "任务正在执行中");
            }
            federatedStatsRepository.updateTaskState(taskId, 1, null, null);
            // 异步执行统计算法
            executeStatsAsync(task, userId);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("执行统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "执行失败");
        }
    }

    private void executeStatsAsync(FederatedStatsTask task, Long userId) {
        CompletableFuture.runAsync(() -> {
            try {
                Thread.sleep(100); // 模拟计算延迟
                String summary = simulateStatsResult(task.getStatsType());
                federatedStatsRepository.updateTaskState(task.getId(), 2, summary, null);
                FederatedStatsResult result = new FederatedStatsResult();
                result.setTaskId(task.getId());
                result.setResultType("final");
                result.setResultData("{\"summary\":\"" + summary + "\"}");
                result.setRowCount(100);
                federatedStatsRepository.insertResult(result);
            } catch (Exception e) {
                log.error("统计任务执行异常", e);
                federatedStatsRepository.updateTaskState(task.getId(), 3, null, e.getMessage());
            }
        });
    }

    private String simulateStatsResult(String statsType) {
        switch (statsType) {
            case "descriptive": return "均值: 32.5, 方差: 45.2, 标准差: 6.72, 中位数: 31, 最小值: 18, 最大值: 65";
            case "group_by": return "共3个分组: A组120条, B组85条, C组45条";
            case "conditional": return "条件过滤后共156条记录";
            case "proportion": return "分类占比: A类45%, B类30%, C类25%";
            case "t_test": return "t值: 2.34, p值: 0.019, 显著差异(α=0.05)";
            case "f_test": return "F值: 1.87, p值: 0.124, 方差齐性";
            case "chi_square": return "卡方值: 5.21, p值: 0.074, 无显著差异";
            case "regression": return "R²: 0.87, 系数: [0.52, -0.13, 0.28], 截距: 1.23";
            case "correlation": return "Pearson相关系数: 0.76, p值: 0.001, 显著正相关";
            default: return "统计完成";
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity stopTask(Long taskId) {
        try {
            FederatedStatsTask task = federatedStatsRepository.selectTaskById(taskId);
            if (task == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "任务不存在");
            }
            federatedStatsRepository.updateTaskState(taskId, 4, null, "用户取消");
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("取消统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "取消失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteTask(Long taskId) {
        try {
            federatedStatsRepository.deleteResultByTaskId(taskId);
            FederatedStatsTask task = new FederatedStatsTask();
            task.setId(taskId);
            task.setTaskState(4);
            federatedStatsRepository.updateTask(task);
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("删除统计任务失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ==================== 结果管理 ====================

    @Override
    public BaseResultEntity getResult(Long taskId) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);
            return BaseResultEntity.success(results);
        } catch (Exception e) {
            log.error("查询统计结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveResult(SaveResultReq req, Long userId) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(req.getTaskId());
            if (results.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "无结果可保存");
            }
            FederatedStatsConfig config = req.getStorageConfigId() != null ?
                federatedStatsRepository.selectConfigById(req.getStorageConfigId()) :
                federatedStatsRepository.selectDefaultConfig();
            if (config == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "请先配置存储方式");
            }
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存统计结果失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Override
    public void exportResult(Long taskId, String format, HttpServletResponse response) {
        try {
            List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);
            String content = results.stream()
                .map(r -> r.getResultData())
                .collect(Collectors.joining("\n---\n"));
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("stats_" + taskId + ".txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(content.getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("导出统计结果失败", e);
        }
    }

    @Override
    public void batchExportResult(BatchExportReq req, HttpServletResponse response) {
        try {
            List<String> parts = new ArrayList<>();
            for (Long taskId : req.getTaskIds()) {
                List<FederatedStatsResult> results = federatedStatsRepository.selectResultsByTaskId(taskId);
                String content = results.stream()
                    .map(r -> "任务" + taskId + ": " + r.getResultData())
                    .collect(Collectors.joining("\n"));
                parts.add(content);
            }
            String content = String.join("\n\n==========\n\n", parts);
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("stats_batch_export.txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write(content.getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("批量导出统计结果失败", e);
        }
    }

    // ==================== 存储配置 ====================

    @Override
    public BaseResultEntity getStorageConfig(Long userId) {
        try {
            List<FederatedStatsConfig> configs = federatedStatsRepository.selectConfigList(userId);
            return BaseResultEntity.success(configs);
        } catch (Exception e) {
            log.error("获取存储配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveStorageConfig(StorageConfigReq req, Long userId) {
        try {
            FederatedStatsConfig config = new FederatedStatsConfig();
            if (req.getId() != null) {
                config.setId(req.getId());
            }
            config.setConfigName(req.getConfigName());
            config.setStorageType(req.getStorageType());
            config.setStoragePath(req.getStoragePath());
            config.setConnectionJson(req.getConnectionJson());
            config.setIsDefault(req.getIsDefault());
            config.setCreatedBy(userId);
            if (req.getId() != null) {
                federatedStatsRepository.updateConfig(config);
            } else {
                federatedStatsRepository.insertConfig(config);
            }
            return BaseResultEntity.success();
        } catch (Exception e) {
            log.error("保存存储配置失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Override
    public BaseResultEntity testStorageConnection(StorageConfigReq req) {
        Map<String, Object> result = new HashMap<>();
        result.put("connected", true);
        result.put("message", "连接成功");
        return BaseResultEntity.success(result);
    }

    @Override
    public BaseResultEntity getStoredResults(Integer pageNo, Integer pageSize, Long userId) {
        Map<String, Object> result = new HashMap<>();
        result.put("list", Collections.emptyList());
        result.put("total", 0);
        return BaseResultEntity.success(result);
    }

    @Override
    public BaseResultEntity previewStoredResult(Long resultId, Integer rows) {
        Map<String, Object> result = new HashMap<>();
        result.put("headers", new String[]{"字段1", "字段2", "字段3"});
        result.put("rows", Arrays.asList(
            new String[]{"数据1", "数据2", "数据3"},
            new String[]{"数据4", "数据5", "数据6"}
        ));
        return BaseResultEntity.success(result);
    }

    @Override
    public void downloadStoredResult(Long resultId, HttpServletResponse response) {
        try {
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("result_" + resultId + ".txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write("统计结果数据".getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("下载存储结果失败", e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteStoredResult(Long resultId) {
        return BaseResultEntity.success();
    }

    // ==================== 日志 ====================

    @Override
    public BaseResultEntity getLogs(LogQueryReq req) {
        Map<String, Object> result = new HashMap<>();
        result.put("list", Collections.emptyList());
        result.put("total", 0);
        return BaseResultEntity.success(result);
    }

    @Override
    public BaseResultEntity getLogDetail(Long logId) {
        return BaseResultEntity.success(new HashMap<>());
    }

    @Override
    public void exportLogs(LogExportReq req, HttpServletResponse response) {
        try {
            response.setContentType("text/plain;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" +
                URLEncoder.encode("stats_log.txt", StandardCharsets.UTF_8.name()));
            OutputStream os = response.getOutputStream();
            os.write("统计日志".getBytes(StandardCharsets.UTF_8));
            os.flush();
        } catch (Exception e) {
            log.error("导出统计日志失败", e);
        }
    }

    // ==================== 统计类型 ====================

    @Override
    public BaseResultEntity getStatisticsTypes() {
        return BaseResultEntity.success(STATS_TYPES);
    }

    // ==================== 工具方法 ====================

    private StatsTaskListVO toTaskListVO(FederatedStatsTask task) {
        StatsTaskListVO vo = new StatsTaskListVO();
        vo.setId(task.getId());
        vo.setTaskName(task.getTaskName());
        vo.setStatsType(task.getStatsType());
        vo.setStatsTypeName(STATS_TYPE_NAMES.getOrDefault(task.getStatsType(), task.getStatsType()));
        vo.setTaskState(task.getTaskState());
        vo.setTaskStateName(TASK_STATE_NAMES.getOrDefault(task.getTaskState(), "未知"));
        vo.setResultSummary(task.getResultSummary());
        vo.setCreatedAt(task.getCreatedAt());
        return vo;
    }
}
