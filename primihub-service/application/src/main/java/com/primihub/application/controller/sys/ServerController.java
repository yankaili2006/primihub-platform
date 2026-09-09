package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.param.AgentParam;
import com.primihub.biz.entity.sys.param.ServerParam;
import com.primihub.biz.entity.sys.po.Agent;
import com.primihub.biz.entity.sys.po.Server;
import com.primihub.biz.service.sys.ServerService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 服务器模块 Controller
 * 管理服务器、智能体及其与数据资源、模型、节点的关联关系
 */
@Slf4j
@Api(tags = "服务器管理")
@RestController
@RequestMapping("/server")
public class ServerController {

    @Autowired
    private ServerService serverService;

    // ===== Server =====

    @ApiOperation("查询服务器分页列表")
    @GetMapping("/findServerPage")
    public BaseResultEntity findServerPage(ServerParam param) {
        return serverService.getServerPage(param);
    }

    @ApiOperation("查询服务器详情（含关联资源/模型/节点/智能体）")
    @GetMapping("/getServerDetail")
    public BaseResultEntity getServerDetail(
            @ApiParam("服务器ID") @RequestParam Long serverId) {
        return serverService.getServerDetail(serverId);
    }

    @ApiOperation("新增服务器")
    @PostMapping("/addServer")
    public BaseResultEntity addServer(@RequestBody Server server) {
        return serverService.createServer(server);
    }

    @ApiOperation("更新服务器")
    @PostMapping("/updateServer")
    public BaseResultEntity updateServer(@RequestBody Server server) {
        return serverService.updateServer(server);
    }

    @ApiOperation("删除服务器（软删除）")
    @PostMapping("/deleteServer")
    public BaseResultEntity deleteServer(
            @ApiParam("服务器ID") @RequestParam Long serverId) {
        return serverService.deleteServer(serverId);
    }

    // ===== Agent =====

    @ApiOperation("查询智能体分页列表")
    @GetMapping("/findAgentPage")
    public BaseResultEntity findAgentPage(AgentParam param) {
        return serverService.getAgentPage(param);
    }

    @ApiOperation("新增智能体")
    @PostMapping("/addAgent")
    public BaseResultEntity addAgent(@RequestBody Agent agent) {
        return serverService.createAgent(agent);
    }

    @ApiOperation("更新智能体")
    @PostMapping("/updateAgent")
    public BaseResultEntity updateAgent(@RequestBody Agent agent) {
        return serverService.updateAgent(agent);
    }

    @ApiOperation("删除智能体（软删除）")
    @PostMapping("/deleteAgent")
    public BaseResultEntity deleteAgent(
            @ApiParam("智能体ID") @RequestParam Long agentId) {
        return serverService.deleteAgent(agentId);
    }

    // ===== Associations – Resource =====

    @ApiOperation("绑定数据资源到服务器")
    @PostMapping("/bindResource")
    public BaseResultEntity bindResource(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("数据资源ID") @RequestParam Long resourceId) {
        return serverService.bindResource(serverId, resourceId);
    }

    @ApiOperation("解绑数据资源")
    @PostMapping("/unbindResource")
    public BaseResultEntity unbindResource(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("数据资源ID") @RequestParam Long resourceId) {
        return serverService.unbindResource(serverId, resourceId);
    }

    // ===== Associations – Model =====

    @ApiOperation("绑定模型到服务器")
    @PostMapping("/bindModel")
    public BaseResultEntity bindModel(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("模型ID") @RequestParam Long modelId,
            @ApiParam("模型版本") @RequestParam(required = false) String modelVersion) {
        return serverService.bindModel(serverId, modelId, modelVersion);
    }

    @ApiOperation("解绑模型")
    @PostMapping("/unbindModel")
    public BaseResultEntity unbindModel(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("模型ID") @RequestParam Long modelId) {
        return serverService.unbindModel(serverId, modelId);
    }

    // ===== Associations – Artifact =====

    @ApiOperation("绑定模型产物到服务器")
    @PostMapping("/bindArtifact")
    public BaseResultEntity bindArtifact(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("产物ID") @RequestParam Long artifactId) {
        return serverService.bindArtifact(serverId, artifactId);
    }

    @ApiOperation("解绑模型产物")
    @PostMapping("/unbindArtifact")
    public BaseResultEntity unbindArtifact(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("产物ID") @RequestParam Long artifactId) {
        return serverService.unbindArtifact(serverId, artifactId);
    }

    // ===== Associations – Node =====

    @ApiOperation("绑定节点到服务器")
    @PostMapping("/bindNode")
    public BaseResultEntity bindNode(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("节点ID") @RequestParam Long nodeId,
            @ApiParam("接入类型") @RequestParam(required = false) String accessType,
            @ApiParam("是否主节点: 0否 1是") @RequestParam(required = false) Integer isPrimary) {
        return serverService.bindNode(serverId, nodeId, accessType, isPrimary);
    }

    @ApiOperation("解绑节点")
    @PostMapping("/unbindNode")
    public BaseResultEntity unbindNode(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("节点ID") @RequestParam Long nodeId) {
        return serverService.unbindNode(serverId, nodeId);
    }

    // ===== Associations – Agent =====

    @ApiOperation("绑定智能体到服务器")
    @PostMapping("/bindAgent")
    public BaseResultEntity bindAgent(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("智能体ID") @RequestParam Long agentId) {
        return serverService.bindAgent(serverId, agentId);
    }

    @ApiOperation("解绑智能体")
    @PostMapping("/unbindAgent")
    public BaseResultEntity unbindAgent(
            @ApiParam("服务器ID") @RequestParam Long serverId,
            @ApiParam("智能体ID") @RequestParam Long agentId) {
        return serverService.unbindAgent(serverId, agentId);
    }
}
