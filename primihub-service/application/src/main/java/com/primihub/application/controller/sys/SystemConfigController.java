package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.vo.*;
import com.primihub.biz.service.sys.SysConfigService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@Api(value = "系统配置接口", tags = "系统配置接口")
@RequestMapping("systemConfig")
@RestController
public class SystemConfigController {

    @Autowired
    private SysConfigService sysConfigService;

    // ==================== 网络地址 ====================

    @ApiOperation(value = "获取网络地址配置")
    @GetMapping("getNetworkConfig")
    public BaseResultEntity getNetworkConfig() {
        return sysConfigService.getNetworkConfig();
    }

    @ApiOperation(value = "保存网络地址配置")
    @PostMapping("saveNetworkConfig")
    public BaseResultEntity saveNetworkConfig(@RequestBody NetworkConfigVO vo) {
        if (vo == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return sysConfigService.saveNetworkConfig(vo);
    }

    // ==================== 时间配置 ====================

    @ApiOperation(value = "获取时间配置")
    @GetMapping("getTimeConfig")
    public BaseResultEntity getTimeConfig() {
        return sysConfigService.getTimeConfig();
    }

    @ApiOperation(value = "保存时间配置")
    @PostMapping("saveTimeConfig")
    public BaseResultEntity saveTimeConfig(@RequestBody TimeConfigVO vo) {
        if (vo == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return sysConfigService.saveTimeConfig(vo);
    }

    // ==================== 登录限制 ====================

    @ApiOperation(value = "获取登录限制配置")
    @GetMapping("getLoginRestriction")
    public BaseResultEntity getLoginRestriction() {
        return sysConfigService.getLoginRestriction();
    }

    @ApiOperation(value = "保存登录限制配置")
    @PostMapping("saveLoginRestriction")
    public BaseResultEntity saveLoginRestriction(@RequestBody LoginRestrictionVO vo) {
        if (vo == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return sysConfigService.saveLoginRestriction(vo);
    }

    // ==================== 平台个性化 ====================

    @ApiOperation(value = "获取平台个性化配置")
    @GetMapping("getPersonalizationConfig")
    public BaseResultEntity getPersonalizationConfig() {
        return sysConfigService.getPersonalizationConfig();
    }

    @ApiOperation(value = "保存平台个性化配置")
    @PostMapping("savePersonalizationConfig")
    public BaseResultEntity savePersonalizationConfig(@RequestBody PersonalizationConfigVO vo) {
        if (vo == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return sysConfigService.savePersonalizationConfig(vo);
    }

    // ==================== FTP配置 ====================

    @ApiOperation(value = "获取FTP配置")
    @GetMapping("getFtpConfig")
    public BaseResultEntity getFtpConfig() {
        return sysConfigService.getFtpConfig();
    }

    @ApiOperation(value = "保存FTP配置")
    @PostMapping("saveFtpConfig")
    public BaseResultEntity saveFtpConfig(@RequestBody FtpConfigVO vo) {
        if (vo == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return sysConfigService.saveFtpConfig(vo);
    }

    @ApiOperation(value = "测试FTP连接")
    @PostMapping("testFtpConnection")
    public BaseResultEntity testFtpConnection(@RequestBody FtpConfigVO vo) {
        if (vo == null) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
        }
        return sysConfigService.testFtpConnection(vo);
    }
}
