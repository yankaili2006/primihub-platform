package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.po.Whitelist;
import com.primihub.biz.entity.sys.po.WhitelistConfig;
import com.primihub.biz.service.sys.WhitelistService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Api(value = "白名单管理接口", tags = "白名单管理接口")
@RequestMapping("whitelist")
@RestController
public class WhitelistController {

    @Autowired
    private WhitelistService whitelistService;

    // ========== 白名单管理 ==========

    @ApiOperation(value = "查询白名单分页列表")
    @GetMapping("findWhitelistPage")
    public BaseResultEntity findWhitelistPage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return whitelistService.findWhitelistPage(keyword, type, status, pageNum, pageSize);
    }

    @ApiOperation(value = "添加白名单")
    @PostMapping("addWhitelist")
    public BaseResultEntity addWhitelist(@RequestBody Whitelist whitelist) {
        if (whitelist == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.addWhitelist(whitelist);
    }

    @ApiOperation(value = "更新白名单")
    @PostMapping("updateWhitelist")
    public BaseResultEntity updateWhitelist(@RequestBody Whitelist whitelist) {
        if (whitelist == null || whitelist.getId() == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.updateWhitelist(whitelist);
    }

    @ApiOperation(value = "删除白名单")
    @PostMapping("deleteWhitelist")
    public BaseResultEntity deleteWhitelist(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.deleteWhitelist(id);
    }

    @ApiOperation(value = "查询白名单详情")
    @GetMapping("getWhitelistDetail")
    public BaseResultEntity getWhitelistDetail(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.getWhitelistDetail(id);
    }

    // ========== 白名单配置管理 ==========

    @ApiOperation(value = "查询白名单配置列表")
    @GetMapping("findWhitelistConfigList")
    public BaseResultEntity findWhitelistConfigList() {
        return whitelistService.findWhitelistConfigList();
    }

    @ApiOperation(value = "保存白名单配置")
    @PostMapping("saveWhitelistConfig")
    public BaseResultEntity saveWhitelistConfig(@RequestBody List<WhitelistConfig> configList) {
        if (configList == null || configList.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.saveWhitelistConfig(configList);
    }

    @ApiOperation(value = "查询白名单配置详情")
    @GetMapping("getWhitelistConfigDetail")
    public BaseResultEntity getWhitelistConfigDetail(@RequestParam String configKey) {
        if (configKey == null || configKey.trim().isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.getWhitelistConfigDetail(configKey);
    }

    // ========== 白名单访问日志管理 ==========

    @ApiOperation(value = "查询访问日志分页列表")
    @GetMapping("findWhitelistAccessLogPage")
    public BaseResultEntity findWhitelistAccessLogPage(
            @RequestParam(required = false) String accessIp,
            @RequestParam(required = false) String accessUrl,
            @RequestParam(required = false) String accessResult,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return whitelistService.findWhitelistAccessLogPage(accessIp, accessUrl, accessResult, startTime, endTime, pageNum, pageSize);
    }

    @ApiOperation(value = "查询访问日志详情")
    @GetMapping("getWhitelistAccessLogDetail")
    public BaseResultEntity getWhitelistAccessLogDetail(@RequestParam Long id) {
        if (id == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.getWhitelistAccessLogDetail(id);
    }

    @ApiOperation(value = "查询访问统计")
    @GetMapping("getWhitelistAccessStatistics")
    public BaseResultEntity getWhitelistAccessStatistics() {
        return whitelistService.getWhitelistAccessStatistics();
    }

    @ApiOperation(value = "批量删除访问日志")
    @PostMapping("batchDeleteAccessLog")
    public BaseResultEntity batchDeleteAccessLog(@RequestBody List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return whitelistService.batchDeleteAccessLog(ids);
    }

    @ApiOperation(value = "清理过期日志")
    @PostMapping("cleanExpiredLogs")
    public BaseResultEntity cleanExpiredLogs(@RequestParam Integer days) {
        if (days == null || days <= 0) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "天数必须大于0");
        }
        return whitelistService.cleanExpiredLogs(days);
    }

    @ApiOperation(value = "导出访问日志")
    @GetMapping("exportAccessLog")
    public BaseResultEntity exportAccessLog(
            @RequestParam(required = false) String accessIp,
            @RequestParam(required = false) String accessUrl,
            @RequestParam(required = false) String accessResult,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        return whitelistService.exportAccessLog(accessIp, accessUrl, accessResult, startTime, endTime);
    }

    @ApiOperation(value = "获取访问趋势")
    @GetMapping("getAccessTrend")
    public BaseResultEntity getAccessTrend(
            @RequestParam(defaultValue = "7") Integer days) {
        return whitelistService.getAccessTrend(days);
    }

    @ApiOperation(value = "获取IP访问排行")
    @GetMapping("getTopAccessIps")
    public BaseResultEntity getTopAccessIps(
            @RequestParam(defaultValue = "10") Integer limit) {
        return whitelistService.getTopAccessIps(limit);
    }

    @ApiOperation(value = "获取URL访问排行")
    @GetMapping("getTopAccessUrls")
    public BaseResultEntity getTopAccessUrls(
            @RequestParam(defaultValue = "10") Integer limit) {
        return whitelistService.getTopAccessUrls(limit);
    }

    @ApiOperation(value = "获取访问详细统计")
    @GetMapping("getAccessDetailStatistics")
    public BaseResultEntity getAccessDetailStatistics(
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        return whitelistService.getAccessDetailStatistics(startTime, endTime);
    }
}
