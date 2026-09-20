package com.primihub.application.controller.data;

import com.primihub.biz.service.data.FlReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletResponse;
import java.util.Map;

/**
 * FlLogs 的批量日志导出。原实现导出的是任务列表 JSON（非日志行）；
 * 现委托 FlReportService.exportLogs 导出真实日志事件行 CSV（创建/派发/终态，
 * 支持 logIds 选中导出）。数据源与 /federatedLearning/logs 完全一致。
 */
@RestController
@RequestMapping("/federatedLearning")
public class FederatedLearningLogExportController {

    @Autowired
    private FlReportService flReportService;

    @PostMapping("/batchExportLogs")
    public void batchExportLogs(HttpServletResponse response,
                                @RequestBody(required = false) Map<String, Object> body) {
        flReportService.exportLogs(body, response);
    }
}
