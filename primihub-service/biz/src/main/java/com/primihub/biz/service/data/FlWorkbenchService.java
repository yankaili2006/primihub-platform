package com.primihub.biz.service.data;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.repository.primarydb.data.FlWorkbenchRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 联邦学习建模工作台 Service：工作流真持久化(建/存/列/取/删) + 真实运行。
 * 运行 = 桥接 FederatedLearningService.createTask（model-DAG → node gRPC 真实联邦训练），
 * 状态 1运行中 起步，读接口懒同步真实终态（指标经 FlMetricsResolver 读引擎 indicator 文件）。
 * 选项(参与方/数据集)取真实 sys_organ / data_resource。
 * （历史：原 workbench/* 后端全缺 → 曾以"写成功日志+直接置成功"打通壳子；该假执行已根除。）
 */
@Slf4j
@Service
public class FlWorkbenchService {

    @Autowired
    private FlWorkbenchRepository repository;
    @Autowired
    private FederatedLearningService federatedLearningService;
    @Autowired
    private FlMetricsResolver metricsResolver;
    @Autowired
    private com.primihub.biz.config.base.OrganConfiguration organConfiguration;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public BaseResultEntity overview() {
        try {
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("totalWorkflows", repository.countByStatus(null));
            r.put("running", repository.countByStatus(1));
            r.put("success", repository.countByStatus(2));
            r.put("failed", repository.countByStatus(3));
            r.put("draft", repository.countByStatus(0));
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("查询工作台概览失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity options(String organId) {
        try {
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("participants", repository.selectOrgans());
            r.put("datasets", repository.selectDatasets(organId));
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("查询工作台选项失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity listWorkflows(Map<String, Object> query) {
        try {
            Map<String, Object> params = new HashMap<>(query == null ? Collections.emptyMap() : query);
            int total = repository.selectWorkflowCount(params);
            PageParam pp = pageParam(query);
            pp.initItemTotalCount((long) total);
            params.put("offset", pp.getPageIndex());
            params.put("pageSize", pp.getPageSize());
            List<Map<String, Object>> list = repository.selectWorkflowPage(params);
            for (Map<String, Object> wf : list) syncWorkflowState(wf);
            list = repository.selectWorkflowPage(params);   // 同步后重读，让本页返回新状态
            Map<String, Object> r = new HashMap<>();
            r.put("list", list); r.put("data", list);
            r.put("total", total); r.put("totalPage", pp.getPageCount());
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("查询工作流列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getWorkflow(String workflowId) {
        try {
            Map<String, Object> wf = repository.selectWorkflowById(workflowId);
            if (wf == null) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "工作流不存在");
            syncWorkflowState(wf);
            wf = repository.selectWorkflowById(workflowId);
            return BaseResultEntity.success(wf);
        } catch (Exception e) {
            log.error("查询工作流失败, workflowId={}", workflowId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveWorkflow(Map<String, Object> data, Long userId, String userName) {
        try {
            String workflowId = saveOrUpdate(data, userId, userName);
            Map<String, Object> r = new HashMap<>();
            r.put("workflowId", workflowId);
            return BaseResultEntity.success(r);
        } catch (Exception e) {
            log.error("保存工作流失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "保存失败");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity runWorkflow(Map<String, Object> data, Long userId, String userName) {
        try {
            String workflowId = saveOrUpdate(data, userId, userName);
            repository.deleteLogs(workflowId);
            writeLog(workflowId, "info", "开始执行联邦建模任务...");

            // 桥接真实联邦训练（同 FL 训练页/参数调优的链路）
            com.primihub.biz.entity.data.req.FederatedLearningReq req =
                    new com.primihub.biz.entity.data.req.FederatedLearningReq();
            req.setTaskType(1);
            req.setAlgorithmType(5);
            req.setFederatedType(2);
            String wfName = str(firstNonNull(data.get("workflowName"), data.get("name"), workflowId));
            req.setTaskName(wfName);
            String localOrgan = organConfiguration.getSysLocalOrganId();
            req.setOwnOrganId(localOrgan == null || localOrgan.isEmpty() ? null : localOrgan);
            List<String> participants = readStrList(data.get("participants"));
            if (!participants.isEmpty()) req.setParticipantOrganIds(String.join(",", participants));
            String datasetId = str(data.get("datasetId"));
            if (datasetId != null && !datasetId.isEmpty()) req.setOwnResourceId(datasetId);
            com.primihub.biz.entity.data.req.FederatedLearningReq.TrainingParams tp =
                    new com.primihub.biz.entity.data.req.FederatedLearningReq.TrainingParams();
            Integer rounds = toInt(data.get("rounds"));
            if (rounds != null && rounds > 0) tp.setEpochs(rounds);
            Double lr = toDouble(data.get("learningRate"));
            if (lr != null && lr > 0) tp.setLearningRate(lr);
            req.setTrainingParams(tp);

            BaseResultEntity cr = federatedLearningService.createTask(req, userId == null || userId <= 0 ? 1L : userId);
            Map<String, Object> upd = new HashMap<>();
            upd.put("workflowId", workflowId);
            if (cr.getCode() == 0 && cr.getResult() instanceof Map) {
                Map<?, ?> res = (Map<?, ?>) cr.getResult();
                String flTaskId = str(res.get("taskId"));
                Object modelId = res.get("modelId");
                boolean transmitted = Boolean.TRUE.equals(res.get("resourceTransmitted"));
                writeLog(workflowId, "info", "已派发真实联邦训练（model-DAG → node gRPC），taskId=" + flTaskId + "，modelId=" + modelId);
                writeLog(workflowId, "info", transmitted ? "训练数据：使用所选联邦资源" : "训练数据：未配置联邦资源，使用模板演示数据集");
                upd.put("status", 1);
                upd.put("startTime", new Date());
                upd.put("flTaskId", flTaskId);
                upd.put("modelId", modelId == null ? null : Long.valueOf(modelId.toString()));
                upd.put("resultSummary", "真实联邦训练运行中（" + tp.getEpochs() + " 轮，lr=" + tp.getLearningRate() + "）");
                repository.updateWorkflow(upd);
                Map<String, Object> r = new LinkedHashMap<>();
                r.put("workflowId", workflowId);
                r.put("status", 1);
                r.put("taskId", flTaskId);
                r.put("logs", repository.selectLogs(workflowId));
                return BaseResultEntity.success(r);
            }
            // 诚实失败：不粉饰成成功
            writeLog(workflowId, "error", "联邦训练派发失败: " + cr.getMsg());
            upd.put("status", 3);
            upd.put("startTime", new Date());
            upd.put("endTime", new Date());
            upd.put("resultSummary", "派发失败: " + cr.getMsg());
            repository.updateWorkflow(upd);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "联邦训练派发失败: " + cr.getMsg());
        } catch (Exception e) {
            log.error("运行工作流失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "运行失败: " + e.getMessage());
        }
    }

    public BaseResultEntity getLogs(String workflowId) {
        try {
            syncWorkflowState(repository.selectWorkflowById(workflowId));
            return BaseResultEntity.success(repository.selectLogs(workflowId));
        } catch (Exception e) {
            log.error("查询工作流日志失败, workflowId={}", workflowId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 懒同步真实终态：运行中(1)的工作流按 fl_task_id 查真实训练进度，
     * 终态回写 status/endTime/resultSummary（真实指标经 indicator 文件）并补真实事件日志。
     * best-effort：失败不影响读接口。
     */
    private void syncWorkflowState(Map<String, Object> wf) {
        try {
            if (wf == null) return;
            Object st = wf.get("status");
            String flTaskId = str(wf.get("flTaskId"));
            if (st == null || toInt(st) == null || toInt(st) != 1 || flTaskId == null || flTaskId.isEmpty()) return;
            BaseResultEntity p = federatedLearningService.getTrainingProgress(flTaskId);
            if (p.getCode() != 0 || !(p.getResult() instanceof Map)) return;
            Integer taskState = toInt(((Map<?, ?>) p.getResult()).get("taskState"));
            if (taskState == null || taskState == 2 || taskState == 0) return;   // 仍在运行
            String workflowId = str(wf.get("workflowId"));
            Map<String, Object> upd = new HashMap<>();
            upd.put("workflowId", workflowId);
            upd.put("endTime", new Date());
            if (taskState == 1) {
                com.primihub.biz.entity.data.po.DataTask dt = metricsResolver.resolveDataTask(flTaskId);
                Map<String, Object> ind = metricsResolver.readIndicator(dt);
                String secs = (dt != null && dt.getTaskStartTime() != null && dt.getTaskEndTime() != null
                        && dt.getTaskEndTime() > dt.getTaskStartTime())
                        ? String.valueOf((dt.getTaskEndTime() - dt.getTaskStartTime()) / 1000) : null;
                String metrics = ind == null ? "指标文件缺失"
                        : "accuracy=" + ind.get("train_acc") + ", auc=" + ind.get("train_auc");
                upd.put("status", 2);
                upd.put("resultSummary", "真实联邦训练完成，" + metrics);
                writeLog(workflowId, "success", "训练完成" + (secs != null ? "（真实耗时 " + secs + "s）" : "") + "，" + metrics);
            } else {
                upd.put("status", 3);
                String err = null;
                com.primihub.biz.entity.data.po.DataTask dt = metricsResolver.resolveDataTask(flTaskId);
                if (dt != null && dt.getTaskErrorMsg() != null) err = dt.getTaskErrorMsg();
                upd.put("resultSummary", taskState == 4 ? "训练已取消" : ("训练失败" + (err != null ? ": " + err : "")));
                writeLog(workflowId, "error", taskState == 4 ? "训练已取消" : ("训练失败" + (err != null ? ": " + err : "")));
            }
            repository.updateWorkflow(upd);
        } catch (Exception e) {
            log.warn("同步工作流状态失败(不影响读取): {}", e.getMessage());
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteWorkflow(String workflowId) {
        try {
            if (workflowId == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "workflowId 不能为空");
            int n = repository.deleteWorkflow(workflowId);
            if (n <= 0) return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "工作流不存在");
            repository.deleteLogs(workflowId);
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除工作流失败, workflowId={}", workflowId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ---------- internal ----------

    private String saveOrUpdate(Map<String, Object> data, Long userId, String userName) {
        String workflowId = str(data.get("workflowId"));
        Map<String, Object> wf = new HashMap<>();
        wf.put("workflowName", firstNonNull(data.get("workflowName"), data.get("name"), "未命名工作流"));
        wf.put("participants", toJson(data.get("participants")));
        wf.put("datasetId", str(data.get("datasetId")));
        wf.put("datasetName", str(data.get("datasetName")));
        wf.put("rounds", toInt(data.get("rounds")));
        wf.put("learningRate", toDouble(data.get("learningRate")));
        wf.put("nodes", toJson(data.get("nodes")));
        if (workflowId != null && !workflowId.isEmpty() && repository.selectWorkflowById(workflowId) != null) {
            wf.put("workflowId", workflowId);
            repository.updateWorkflow(wf);
        } else {
            workflowId = "FLWF-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
            wf.put("workflowId", workflowId);
            wf.put("status", 0);
            wf.put("userId", userId);
            wf.put("userName", userName);
            wf.put("organId", str(data.get("organId")));
            repository.insertWorkflow(wf);
        }
        return workflowId;
    }

    /** participants 之类的字符串数组字段：兼容 List 与 JSON 串两种来源 */
    private List<String> readStrList(Object v) {
        try {
            List<?> raw;
            if (v == null) return Collections.emptyList();
            if (v instanceof List) {
                raw = (List<?>) v;
            } else {
                String s = String.valueOf(v);
                if (s.trim().isEmpty()) return Collections.emptyList();
                raw = objectMapper.readValue(s, List.class);
            }
            List<String> out = new ArrayList<>();
            for (Object o : raw) if (o != null && !String.valueOf(o).isEmpty()) out.add(String.valueOf(o));
            return out;
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private void writeLog(String workflowId, String level, String content) {
        try {
            Map<String, Object> l = new HashMap<>();
            l.put("workflowId", workflowId); l.put("logLevel", level); l.put("logContent", content);
            repository.insertLog(l);
        } catch (Exception ignore) {}
    }

    private PageParam pageParam(Map<String, Object> query) {
        int pageNum = 1, pageSize = 10;
        if (query != null) {
            Integer pn = toInt(firstNonNull(query.get("pageNo"), query.get("pageNum")));
            Integer ps = toInt(query.get("pageSize"));
            if (pn != null && pn > 0) pageNum = pn;
            if (ps != null && ps > 0) pageSize = ps;
        }
        return new PageParam(pageNum, pageSize);
    }

    private String toJson(Object o) {
        if (o == null) return null;
        if (o instanceof String) return (String) o;
        try { return objectMapper.writeValueAsString(o); } catch (Exception e) { return null; }
    }

    private Object firstNonNull(Object... vs) { for (Object v : vs) if (v != null && !String.valueOf(v).isEmpty()) return v; return null; }
    private String str(Object o) { return o == null ? null : String.valueOf(o); }
    private Integer toInt(Object o) { try { return o == null ? null : Integer.valueOf(String.valueOf(o).replaceAll("\\..*$", "")); } catch (Exception e) { return null; } }
    private Double toDouble(Object o) { try { return o == null ? null : Double.valueOf(String.valueOf(o)); } catch (Exception e) { return null; } }
}
