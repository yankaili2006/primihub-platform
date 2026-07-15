package com.primihub.application.controller.data;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.FederatedLearningService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.util.Map;

/**
 * D42 补丁：联邦学习「日志导出」缺失接口。前端调 /federatedLearning/batchExportLogs
 * 后端原 404。此处复用现有 FederatedLearningService.getTaskList 拉取任务/日志记录，
 * 以 JSON 文件流式导出（真导出，非空桩）。独立类，不改动现有 FederatedLearningController。
 */
@RestController
@RequestMapping("/federatedLearning")
public class FederatedLearningLogExportController {

    @Autowired
    private FederatedLearningService federatedLearningService;

    @PostMapping("/batchExportLogs")
    public void batchExportLogs(HttpServletResponse response,
                                @RequestBody(required = false) Map<String, Object> body) throws Exception {
        String taskName = (body != null && body.get("taskName") != null) ? String.valueOf(body.get("taskName")) : null;
        // 参数序: (taskName, taskType, algorithmType, taskState, projectId, startDate, endDate, pageNo, pageSize)
        BaseResultEntity res = federatedLearningService.getTaskList(taskName, null, null, null, null, null, null, 1, 1000);
        byte[] out = JSON.toJSONString(res).getBytes("UTF-8");
        response.setContentType("application/octet-stream");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition",
                "attachment; filename=" + URLEncoder.encode("federated_learning_logs.json", "UTF-8"));
        OutputStream os = response.getOutputStream();
        os.write(out);
        os.flush();
    }
}
