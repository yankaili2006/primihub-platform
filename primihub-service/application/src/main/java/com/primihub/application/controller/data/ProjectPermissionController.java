package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.service.data.ProjectPermissionService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 项目权限管理 Controller（权限记录 + 权限模板）。
 * 前端 projectPermission.js 调 /prod-api/project/permission/*，nginx 仅剥 /prod-api → 映射 project/permission。
 * （原后端完全无此模块，整页 11 接口 404；本类补齐真实实现。）
 */
@Api(tags = "项目权限管理")
@RestController
@RequestMapping("project/permission")
public class ProjectPermissionController {

    @Autowired
    private ProjectPermissionService projectPermissionService;

    @ApiOperation("查询项目权限分页列表")
    @GetMapping("findPage")
    public BaseResultEntity findPage(
            @RequestParam(required = false) String projectName,
            @RequestParam(required = false) String organName,
            @RequestParam(required = false) String permissionType,
            @RequestParam(required = false) Integer permissionStatus,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return projectPermissionService.findProjectPermissionPage(projectName, organName, permissionType,
                permissionStatus, pageNum, pageSize);
    }

    @ApiOperation("新增项目权限配置")
    @PostMapping("add")
    public BaseResultEntity add(@RequestBody Map<String, Object> data,
                                @RequestHeader(value = "userId", required = false) Long userId) {
        return projectPermissionService.addProjectPermission(data, userId, null);
    }

    @ApiOperation("更新项目权限配置")
    @PostMapping("update")
    public BaseResultEntity update(@RequestBody Map<String, Object> data) {
        return projectPermissionService.updateProjectPermission(data);
    }

    @ApiOperation("撤销项目权限")
    @PostMapping("revoke")
    public BaseResultEntity revoke(@RequestParam Long id,
                                   @RequestParam(required = false) Long userId,
                                   @RequestParam(required = false) String userName) {
        return projectPermissionService.revokeProjectPermission(id, userId, userName);
    }

    @ApiOperation("批量撤销项目权限")
    @PostMapping("batchRevoke")
    public BaseResultEntity batchRevoke(@RequestBody List<Long> ids,
                                        @RequestParam(required = false) Long userId,
                                        @RequestParam(required = false) String userName) {
        return projectPermissionService.batchRevokeProjectPermission(ids, userId, userName);
    }

    @ApiOperation("审批通过项目权限")
    @PostMapping("approve")
    public BaseResultEntity approve(@RequestParam Long id,
                                    @RequestParam(required = false) Long userId,
                                    @RequestParam(required = false) String userName) {
        return projectPermissionService.approveProjectPermission(id, userId, userName);
    }

    @ApiOperation("查询权限模板列表")
    @GetMapping("findTemplates")
    public BaseResultEntity findTemplates() {
        return projectPermissionService.findPermissionTemplates();
    }

    @ApiOperation("新增权限模板")
    @PostMapping("addTemplate")
    public BaseResultEntity addTemplate(@RequestBody Map<String, Object> data,
                                        @RequestHeader(value = "userId", required = false) Long userId) {
        return projectPermissionService.addPermissionTemplate(data, userId);
    }

    @ApiOperation("更新权限模板")
    @PostMapping("updateTemplate")
    public BaseResultEntity updateTemplate(@RequestBody Map<String, Object> data) {
        return projectPermissionService.updatePermissionTemplate(data);
    }

    @ApiOperation("删除权限模板")
    @PostMapping("deleteTemplate")
    public BaseResultEntity deleteTemplate(@RequestParam Long id) {
        return projectPermissionService.deletePermissionTemplate(id);
    }
}
