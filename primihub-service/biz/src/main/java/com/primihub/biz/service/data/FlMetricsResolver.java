package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.data.po.DataModelTask;
import com.primihub.biz.entity.data.po.DataTask;
import com.primihub.biz.entity.data.po.FederatedLearningTask;
import com.primihub.biz.repository.secondarydb.data.DataModelRepository;
import com.primihub.biz.repository.secondarydb.data.DataTaskRepository;
import com.primihub.biz.repository.secondarydb.data.FederatedLearningRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 联邦学习真实指标解析器（FlTuningService/FlReportService 共用，防两份链路发散）。
 * 桥接链路 fl_task.accuracy 从不落值——指标真源是 node 引擎写在共享 /data 卷的
 * indicatorFileName.json（路径在 data_task.task_result_content），application 容器可直读。
 * 任何一环缺失（未派发/未完成/文件不存在）都返回 null，绝不编造。
 */
@Slf4j
@Service
public class FlMetricsResolver {

    @Autowired
    private FederatedLearningRepository federatedLearningRepository;
    @Autowired
    private DataModelRepository dataModelRepository;
    @Autowired
    private DataTaskRepository dataTaskRepository;

    /** fl_task uuid → 桥接背后的真实 data_task */
    public DataTask resolveDataTask(String flTaskId) {
        try {
            return resolveDataTask(federatedLearningRepository.selectTaskByTaskId(flTaskId));
        } catch (Exception e) {
            log.warn("解析真实 data_task 失败 {}: {}", flTaskId, e.getMessage());
            return null;
        }
    }

    public DataTask resolveDataTask(FederatedLearningTask flt) {
        try {
            if (flt == null || flt.getExecutionLog() == null || !flt.getExecutionLog().contains("modelId")) return null;
            // 失败态 syncTaskStateFromModel 会在 JSON 后追加 " | errorMsg"，先剥掉
            String logJson = flt.getExecutionLog();
            int cut = logJson.indexOf(" | ");
            Object modelIdObj = JSON.parseObject(cut > 0 ? logJson.substring(0, cut) : logJson).get("modelId");
            if (modelIdObj == null) return null;
            Map<String, Object> q = new HashMap<>();
            q.put("modelId", Long.valueOf(modelIdObj.toString()));
            q.put("offset", 0);
            q.put("pageSize", 1);
            List<DataModelTask> mts = dataModelRepository.queryModelTaskByModelId(q);
            if (mts == null || mts.isEmpty()) return null;
            return dataTaskRepository.selectDataTaskByTaskId(mts.get(0).getTaskId());
        } catch (Exception e) {
            log.warn("解析真实 data_task 失败 {}: {}", flt == null ? null : flt.getTaskId(), e.getMessage());
            return null;
        }
    }

    /** data_task → 引擎指标文件真值（train_acc/train_auc/train_ks/train_fpr/train_tpr…） */
    public Map<String, Object> readIndicator(DataTask dt) {
        try {
            if (dt == null || dt.getTaskResultContent() == null) return null;
            Object ind = JSON.parseObject(dt.getTaskResultContent()).get("indicatorFileName");
            if (ind == null) return null;
            File f = new File(String.valueOf(ind));
            if (!f.exists()) return null;
            return JSON.parseObject(new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.warn("读取指标文件失败 {}: {}", dt == null ? null : dt.getTaskId(), e.getMessage());
            return null;
        }
    }

    /** 模型产物真实大小(bytes)：task_result_content 列出的实际存在的文件求和；无一存在返回 -1 */
    public long modelBytes(DataTask dt) {
        try {
            if (dt == null || dt.getTaskResultContent() == null) return -1;
            long sum = 0;
            boolean any = false;
            for (Object v : JSON.parseObject(dt.getTaskResultContent()).values()) {
                if (!(v instanceof String)) continue;
                File f = new File((String) v);
                if (f.isFile()) { sum += f.length(); any = true; }
            }
            return any ? sum : -1;
        } catch (Exception e) {
            return -1;
        }
    }
}
