package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.sys.EvidenceService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.util.Date;
import java.util.Map;

/**
 * 存证证书 / 时间戳文件下载。
 * 前端 evidence/query.vue#downloadCert、evidence/timestamp.vue#downloadTimestamp/batchDownload
 * 需要"可下载的文件"；原后端仅有 detail(JSON) 端点、无文件下载。
 * 本控制器按 evidenceId/timestampId 取详情、生成文本证书流式下载。
 * 独立类，不改现有 EvidenceController。
 */
@Api(value = "存证下载接口", tags = "存证下载接口")
@RequestMapping("evidence")
@RestController
public class EvidenceDownloadController {

    @Autowired
    private EvidenceService evidenceService;

    @ApiOperation(value = "下载存证证书")
    @GetMapping("downloadCert")
    public void downloadCert(@RequestParam Long id, HttpServletResponse response) throws Exception {
        writeCert(response, "存证证书 / Evidence Certificate", "evidence_cert_" + id + ".txt",
                evidenceService.getEvidenceDetail(id));
    }

    @ApiOperation(value = "下载时间戳证书")
    @GetMapping("downloadTimestamp")
    public void downloadTimestamp(@RequestParam Long id, HttpServletResponse response) throws Exception {
        writeCert(response, "时间戳证书 / Timestamp Certificate", "timestamp_cert_" + id + ".txt",
                evidenceService.verifyTimestamp(id));
    }

    private void writeCert(HttpServletResponse response, String title, String fileName,
                           BaseResultEntity res) throws Exception {
        StringBuilder sb = new StringBuilder();
        sb.append("==================================================\n");
        sb.append("  ").append(title).append("\n");
        sb.append("==================================================\n\n");
        if (res != null && res.getCode() != null && res.getCode() != 0) {
            sb.append("[提示] ").append(res.getMsg()).append("\n\n");
        }
        Object result = res == null ? null : res.getResult();
        if (result instanceof Map) {
            for (Object o : ((Map<?, ?>) result).entrySet()) {
                Map.Entry<?, ?> en = (Map.Entry<?, ?>) o;
                sb.append(en.getKey()).append(": ").append(en.getValue()).append("\n");
            }
        } else if (result != null) {
            sb.append(String.valueOf(result)).append("\n");
        } else {
            sb.append("无数据\n");
        }
        sb.append("\n--------------------------------------------------\n");
        sb.append("证书生成时间: ").append(new Date()).append("\n");

        byte[] out = sb.toString().getBytes("UTF-8");
        response.reset();
        response.setContentType("application/octet-stream");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition",
                "attachment; filename=" + URLEncoder.encode(fileName, "UTF-8"));
        response.setContentLength(out.length);
        OutputStream os = response.getOutputStream();
        os.write(out);
        os.flush();
    }
}
