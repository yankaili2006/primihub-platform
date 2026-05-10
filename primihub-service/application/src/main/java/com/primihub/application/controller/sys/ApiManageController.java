package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.service.sys.ApiManageService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Api(value = "接口管理", tags = "接口管理")
@RequestMapping("apiManage")
@RestController
public class ApiManageController {

    @Autowired
    private ApiManageService apiManageService;

    // ========== 接口管理 ==========

    @ApiOperation(value = "查询接口分页列表")
    @GetMapping("findApiPage")
    public BaseResultEntity findApiPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return apiManageService.findApiPage(keyword, status, pageNum, pageSize);
    }

    @ApiOperation(value = "新增接口")
    @PostMapping("addApi")
    public BaseResultEntity addApi(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.addApi(data);
    }

    @ApiOperation(value = "更新接口")
    @PostMapping("updateApi")
    public BaseResultEntity updateApi(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.updateApi(data);
    }

    @ApiOperation(value = "删除接口")
    @PostMapping("deleteApi")
    public BaseResultEntity deleteApi(@RequestBody Map<String, Object> data) {
        Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
        return apiManageService.deleteApi(id);
    }

    @ApiOperation(value = "批量删除接口")
    @PostMapping("batchDeleteApi")
    public BaseResultEntity batchDeleteApi(@RequestBody Map<String, Object> data) {
        List<Long> ids = new ArrayList<>();
        if (data.get("ids") instanceof List) {
            for (Object o : (List<?>) data.get("ids")) {
                ids.add(Long.valueOf(o.toString()));
            }
        }
        return apiManageService.batchDeleteApi(ids);
    }

    @ApiOperation(value = "获取接口详情")
    @GetMapping("getApiDetail")
    public BaseResultEntity getApiDetail(@RequestParam Long id) {
        return apiManageService.getApiDetail(id);
    }

    @ApiOperation(value = "启用/禁用接口")
    @PostMapping("toggleApiStatus")
    public BaseResultEntity toggleApiStatus(@RequestBody Map<String, Object> data) {
        Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
        Integer status = data.get("status") != null ? Integer.valueOf(data.get("status").toString()) : 1;
        return apiManageService.toggleApiStatus(id, status);
    }

    // ========== 接口授权管理 ==========

    @ApiOperation(value = "查询接口授权分页列表")
    @GetMapping("findApiAuthPage")
    public BaseResultEntity findApiAuthPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return apiManageService.findApiAuthPage(keyword, pageNum, pageSize);
    }

    @ApiOperation(value = "新增接口授权")
    @PostMapping("addApiAuth")
    public BaseResultEntity addApiAuth(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.addApiAuth(data);
    }

    @ApiOperation(value = "更新接口授权")
    @PostMapping("updateApiAuth")
    public BaseResultEntity updateApiAuth(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.updateApiAuth(data);
    }

    @ApiOperation(value = "删除接口授权")
    @PostMapping("deleteApiAuth")
    public BaseResultEntity deleteApiAuth(@RequestBody Map<String, Object> data) {
        Long id = data.get("id") != null ? Long.valueOf(data.get("id").toString()) : null;
        return apiManageService.deleteApiAuth(id);
    }

    @ApiOperation(value = "校验接口授权")
    @PostMapping("validateApiAuth")
    public BaseResultEntity validateApiAuth(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.validateApiAuth(data);
    }

    @ApiOperation(value = "获取授权令牌")
    @PostMapping("getAuthToken")
    public BaseResultEntity getAuthToken(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.getAuthToken(data);
    }

    @ApiOperation(value = "刷新授权令牌")
    @PostMapping("refreshAuthToken")
    public BaseResultEntity refreshAuthToken(@RequestBody Map<String, Object> data) {
        if (data == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return apiManageService.refreshAuthToken(data);
    }

    // ========== 接口日志管理 ==========

    @ApiOperation(value = "查询接口日志分页列表")
    @GetMapping("findApiLogPage")
    public BaseResultEntity findApiLogPage(
            @RequestParam(required = false) String apiPath,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return apiManageService.findApiLogPage(apiPath, startTime, endTime, pageNum, pageSize);
    }

    @ApiOperation(value = "获取接口日志详情")
    @GetMapping("getApiLogDetail")
    public BaseResultEntity getApiLogDetail(@RequestParam Long id) {
        return apiManageService.getApiLogDetail(id);
    }

    @ApiOperation(value = "获取接口调用统计")
    @GetMapping("getApiStatistics")
    public BaseResultEntity getApiStatistics(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        return apiManageService.getApiStatistics(startTime, endTime);
    }

    @ApiOperation(value = "导出接口日志")
    @GetMapping("exportApiLog")
    public BaseResultEntity exportApiLog(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        return apiManageService.exportApiLog(startTime, endTime);
    }

    @ApiOperation(value = "清空接口日志")
    @PostMapping("clearApiLog")
    public BaseResultEntity clearApiLog(@RequestBody Map<String, Object> data) {
        return apiManageService.clearApiLog(data);
    }
}
