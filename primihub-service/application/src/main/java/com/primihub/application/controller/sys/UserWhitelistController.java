package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.param.FindWhitelistPageParam;
import com.primihub.biz.entity.sys.param.SaveOrUpdateWhitelistParam;
import com.primihub.biz.service.sys.SysUserWhitelistService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 用户白名单控制器
 */
@Api(value = "用户白名单接口", tags = "用户白名单管理")
@RequestMapping("whitelist")
@RestController
public class UserWhitelistController {

    @Autowired
    private SysUserWhitelistService whitelistService;

    /**
     * 新增或更新白名单
     *
     * @param param    参数
     * @param userId   用户ID（从请求头获取）
     * @param userName 用户名（从请求头获取）
     * @return 操作结果
     */
    @ApiOperation("新增或更新白名单")
    @PostMapping("saveOrUpdateWhitelist")
    public BaseResultEntity saveOrUpdateWhitelist(
            @RequestBody SaveOrUpdateWhitelistParam param,
            @RequestHeader(value = "userId", required = false) Long userId,
            @RequestHeader(value = "userName", required = false) String userName) {

        return whitelistService.saveOrUpdateWhitelist(param, userId, userName);
    }

    /**
     * 删除白名单
     *
     * @param whitelistId 白名单ID
     * @return 操作结果
     */
    @ApiOperation("删除白名单")
    @PostMapping("deleteWhitelist")
    public BaseResultEntity deleteWhitelist(@RequestParam Long whitelistId) {
        return whitelistService.deleteWhitelist(whitelistId);
    }

    /**
     * 分页查询白名单列表
     *
     * @param findParam 查询参数
     * @param pageNum   页码（默认1）
     * @param pageSize  每页大小（默认10）
     * @return 分页结果
     */
    @ApiOperation("分页查询白名单列表")
    @GetMapping("findWhitelistPage")
    public BaseResultEntity findWhitelistPage(
            FindWhitelistPageParam findParam,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {

        return whitelistService.findWhitelistPage(findParam, pageNum, pageSize);
    }
}
