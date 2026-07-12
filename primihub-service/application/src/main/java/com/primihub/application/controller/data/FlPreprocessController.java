package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.SinglePartyExtService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.Map;

/**
 * 联邦学习 数据预处理 Controller（/federatedLearning/preprocess/*，原全 404）。
 * 各算法视图(dataSplit/featureAlign/sampleExpand…)按 preprocessType 区分，复用 sp_ext 存储(category=FLPRE)。
 */
@Api(tags = "联邦学习-数据预处理")
@RestController
@RequestMapping("federatedLearning")
public class FlPreprocessController {

    @Autowired
    private SinglePartyExtService service;

    @ApiOperation("预处理任务列表")
    @GetMapping("preprocess/list")
    public BaseResultEntity list(@RequestParam Map<String, Object> query) { return service.listFlPre(query); }

    @ApiOperation("创建预处理任务")
    @PostMapping("preprocess/create")
    public BaseResultEntity create(@RequestBody Map<String, Object> data,
                                   @RequestHeader(value = "userId", required = false) Long userId) {
        return service.createFlPre(data, userId, null);
    }

    @ApiOperation("运行预处理任务")
    @PostMapping("preprocess/run")
    public BaseResultEntity run(@RequestBody Map<String, Object> data) { return service.runFlPre(data); }

    @ApiOperation("删除预处理任务")
    @PostMapping("preprocess/delete")
    public BaseResultEntity delete(@RequestBody Map<String, Object> data) { return service.deleteFlPre(data); }

    @ApiOperation("下载预处理结果")
    @GetMapping("preprocess/download")
    public void download(@RequestParam String taskId, HttpServletResponse response) { service.downloadFlPre(taskId, response); }
}
