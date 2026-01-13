package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.po.*;
import com.primihub.biz.service.sys.*;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

/**
 * 节点管理增强功能Controller
 * 支持9个功能模块的所有API
 */
@Slf4j
@Api(tags = "节点管理增强功能")
@RestController
@RequestMapping("/node")
public class NodeEnhancedController {

    @Autowired
    private NodeAccessControlService accessControlService;

    @Autowired
    private NodeCooperationService cooperationService;

    @Autowired
    private NodeApprovalWorkflowService approvalWorkflowService;

    @Autowired
    private NodeDataExchangeService dataExchangeService;

    // ========== 接入方管理 APIs ==========

    @ApiOperation(value = "查询接入方分页列表")
    @GetMapping("/access/findAccessPartyPage")
    public BaseResultEntity findAccessPartyPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("申请状态") @RequestParam(required = false) Integer applyStatus,
            @ApiParam("接入级别") @RequestParam(required = false) Integer accessLevel,
            @ApiParam("是否激活") @RequestParam(required = false) Integer isActive,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return accessControlService.findAccessPartyPage(keyword, applyStatus, accessLevel, isActive, pageNum, pageSize);
    }

    @ApiOperation(value = "根据ID查询接入方")
    @GetMapping("/access/getAccessPartyById")
    public BaseResultEntity getAccessPartyById(@ApiParam("接入方ID") @RequestParam Long id) {
        return accessControlService.getAccessPartyById(id);
    }

    @ApiOperation(value = "添加接入方申请")
    @PostMapping("/access/addAccessParty")
    public BaseResultEntity addAccessParty(@RequestBody NodeAccessParty accessParty) {
        return accessControlService.addAccessParty(accessParty);
    }

    @ApiOperation(value = "更新接入方信息")
    @PostMapping("/access/updateAccessParty")
    public BaseResultEntity updateAccessParty(@RequestBody NodeAccessParty accessParty) {
        return accessControlService.updateAccessParty(accessParty);
    }

    @ApiOperation(value = "删除接入方")
    @PostMapping("/access/deleteAccessParty")
    public BaseResultEntity deleteAccessParty(@RequestParam Long id) {
        return accessControlService.deleteAccessParty(id);
    }

    @ApiOperation(value = "批量删除接入方")
    @PostMapping("/access/batchDeleteAccessParty")
    public BaseResultEntity batchDeleteAccessParty(@RequestBody List<Long> ids) {
        return accessControlService.batchDeleteAccessParty(ids);
    }

    @ApiOperation(value = "批准接入申请")
    @PostMapping("/access/approve")
    public BaseResultEntity approveAccessParty(
            @RequestParam Long id,
            @RequestParam Long approveUserId,
            @RequestParam String approveUserName,
            @RequestParam(required = false) String approveComment) {
        return accessControlService.approveAccessParty(id, approveUserId, approveUserName, approveComment);
    }

    @ApiOperation(value = "拒绝接入申请")
    @PostMapping("/access/reject")
    public BaseResultEntity rejectAccessParty(
            @RequestParam Long id,
            @RequestParam Long approveUserId,
            @RequestParam String approveUserName,
            @RequestParam(required = false) String approveComment) {
        return accessControlService.rejectAccessParty(id, approveUserId, approveUserName, approveComment);
    }

    @ApiOperation(value = "批量批准接入申请")
    @PostMapping("/access/batchApprove")
    public BaseResultEntity batchApproveAccessParty(
            @RequestBody List<Long> ids,
            @RequestParam Long approveUserId,
            @RequestParam String approveUserName,
            @RequestParam(required = false) String approveComment) {
        return accessControlService.batchApproveAccessParty(ids, approveUserId, approveUserName, approveComment);
    }

    @ApiOperation(value = "更新接入权限级别")
    @PostMapping("/access/updateAccessLevel")
    public BaseResultEntity updateAccessLevel(@RequestParam Long id, @RequestParam Integer accessLevel) {
        return accessControlService.updateAccessLevel(id, accessLevel);
    }

    @ApiOperation(value = "启用/禁用接入方")
    @PostMapping("/access/updateActiveStatus")
    public BaseResultEntity updateActiveStatus(@RequestParam Long id, @RequestParam Integer isActive) {
        return accessControlService.updateActiveStatus(id, isActive);
    }

    @ApiOperation(value = "查询待审批的接入申请")
    @GetMapping("/access/getPendingAccessParties")
    public BaseResultEntity getPendingAccessParties() {
        return accessControlService.getPendingAccessParties();
    }

    @ApiOperation(value = "查询已批准的接入方")
    @GetMapping("/access/getApprovedAccessParties")
    public BaseResultEntity getApprovedAccessParties() {
        return accessControlService.getApprovedAccessParties();
    }

    // ========== 合作方管理 APIs ==========

    @ApiOperation(value = "查询合作方分页列表")
    @GetMapping("/cooperation/findCooperationPartyPage")
    public BaseResultEntity findCooperationPartyPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("合作类型") @RequestParam(required = false) String cooperationType,
            @ApiParam("合作状态") @RequestParam(required = false) Integer cooperationStatus,
            @ApiParam("是否我方发起") @RequestParam(required = false) Integer initiatedByUs,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return cooperationService.findCooperationPartyPage(keyword, cooperationType, cooperationStatus,
                initiatedByUs, pageNum, pageSize);
    }

    @ApiOperation(value = "根据ID查询合作方")
    @GetMapping("/cooperation/getCooperationPartyById")
    public BaseResultEntity getCooperationPartyById(@ApiParam("合作方ID") @RequestParam Long id) {
        return cooperationService.getCooperationPartyById(id);
    }

    @ApiOperation(value = "建立合作关系")
    @PostMapping("/cooperation/establish")
    public BaseResultEntity establishCooperation(@RequestBody NodeCooperationParty cooperationParty) {
        return cooperationService.establishCooperation(cooperationParty);
    }

    @ApiOperation(value = "更新合作方信息")
    @PostMapping("/cooperation/update")
    public BaseResultEntity updateCooperationParty(@RequestBody NodeCooperationParty cooperationParty) {
        return cooperationService.updateCooperationParty(cooperationParty);
    }

    @ApiOperation(value = "取消合作关系")
    @PostMapping("/cooperation/cancel")
    public BaseResultEntity cancelCooperation(@RequestParam Long id, @RequestParam(required = false) String reason) {
        return cooperationService.cancelCooperation(id, reason);
    }

    @ApiOperation(value = "终止合作")
    @PostMapping("/cooperation/terminate")
    public BaseResultEntity terminateCooperation(@RequestParam Long id, @RequestParam(required = false) String reason) {
        return cooperationService.terminateCooperation(id, reason);
    }

    @ApiOperation(value = "续约合作")
    @PostMapping("/cooperation/renew")
    public BaseResultEntity renewCooperation(@RequestParam Long id, @RequestParam Long newEndDateTimestamp) {
        Date newEndDate = new Date(newEndDateTimestamp);
        return cooperationService.renewCooperation(id, newEndDate);
    }

    @ApiOperation(value = "更新合作状态")
    @PostMapping("/cooperation/updateCooperationStatus")
    public BaseResultEntity updateCooperationStatus(@RequestParam Long id, @RequestParam Integer cooperationStatus) {
        return cooperationService.updateCooperationStatus(id, cooperationStatus);
    }

    @ApiOperation(value = "更新健康评分")
    @PostMapping("/cooperation/updateHealthScore")
    public BaseResultEntity updateHealthScore(@RequestParam Long id, @RequestParam Integer healthScore) {
        return cooperationService.updateHealthScore(id, healthScore);
    }

    @ApiOperation(value = "更新数据交换统计")
    @PostMapping("/cooperation/updateDataExchangeCount")
    public BaseResultEntity updateDataExchangeCount(
            @RequestParam Long id,
            @RequestParam Long dataSentCount,
            @RequestParam Long dataReceivedCount) {
        return cooperationService.updateDataExchangeCount(id, dataSentCount, dataReceivedCount);
    }

    @ApiOperation(value = "查询进行中的合作方")
    @GetMapping("/cooperation/getActiveCooperationParties")
    public BaseResultEntity getActiveCooperationParties() {
        return cooperationService.getActiveCooperationParties();
    }

    @ApiOperation(value = "查询即将过期的合作方")
    @GetMapping("/cooperation/getExpiringCooperationParties")
    public BaseResultEntity getExpiringCooperationParties(@RequestParam(required = false) Integer days) {
        return cooperationService.getExpiringCooperationParties(days);
    }

    @ApiOperation(value = "查询健康评分低的合作方")
    @GetMapping("/cooperation/getUnhealthyCooperationParties")
    public BaseResultEntity getUnhealthyCooperationParties(@RequestParam(required = false) Integer threshold) {
        return cooperationService.getUnhealthyCooperationParties(threshold);
    }

    @ApiOperation(value = "批量删除合作方")
    @PostMapping("/cooperation/batchDelete")
    public BaseResultEntity batchDeleteCooperationParty(@RequestBody List<Long> ids) {
        return cooperationService.batchDeleteCooperationParty(ids);
    }

    // ========== 审批工作流 APIs ==========

    @ApiOperation(value = "查询工作流分页列表")
    @GetMapping("/approval/findWorkflowPage")
    public BaseResultEntity findWorkflowPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("工作流类型") @RequestParam(required = false) String workflowType,
            @ApiParam("状态") @RequestParam(required = false) Integer status,
            @ApiParam("申请人ID") @RequestParam(required = false) Long requesterId,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return approvalWorkflowService.findWorkflowPage(keyword, workflowType, status, requesterId, pageNum, pageSize);
    }

    @ApiOperation(value = "根据ID查询工作流")
    @GetMapping("/approval/getWorkflowById")
    public BaseResultEntity getWorkflowById(@ApiParam("工作流ID") @RequestParam Long id) {
        return approvalWorkflowService.getWorkflowById(id);
    }

    @ApiOperation(value = "创建审批工作流")
    @PostMapping("/approval/createWorkflow")
    public BaseResultEntity createWorkflow(
            @RequestBody NodeApprovalWorkflow workflow,
            @RequestParam(required = false) String stepsJson) {
        List<NodeApprovalStep> steps = null;
        // Parse stepsJson if needed
        return approvalWorkflowService.createWorkflow(workflow, steps);
    }

    @ApiOperation(value = "审批通过")
    @PostMapping("/approval/approve")
    public BaseResultEntity approveWorkflow(
            @RequestParam Long workflowId,
            @RequestParam Long approverId,
            @RequestParam String approverName,
            @RequestParam(required = false) String comment) {
        return approvalWorkflowService.approveWorkflow(workflowId, approverId, approverName, comment);
    }

    @ApiOperation(value = "审批拒绝")
    @PostMapping("/approval/reject")
    public BaseResultEntity rejectWorkflow(
            @RequestParam Long workflowId,
            @RequestParam Long approverId,
            @RequestParam String approverName,
            @RequestParam(required = false) String comment) {
        return approvalWorkflowService.rejectWorkflow(workflowId, approverId, approverName, comment);
    }

    @ApiOperation(value = "取消工作流")
    @PostMapping("/approval/cancel")
    public BaseResultEntity cancelWorkflow(@RequestParam Long workflowId, @RequestParam(required = false) String reason) {
        return approvalWorkflowService.cancelWorkflow(workflowId, reason);
    }

    @ApiOperation(value = "查询待审批的工作流")
    @GetMapping("/approval/getPendingWorkflows")
    public BaseResultEntity getPendingWorkflows() {
        return approvalWorkflowService.getPendingWorkflows();
    }

    @ApiOperation(value = "查询我的待审批工作流")
    @GetMapping("/approval/getMyPendingWorkflows")
    public BaseResultEntity getMyPendingWorkflows(@RequestParam Long userId) {
        return approvalWorkflowService.getMyPendingWorkflows(userId);
    }

    @ApiOperation(value = "查询用户创建的工作流")
    @GetMapping("/approval/getWorkflowsByRequester")
    public BaseResultEntity getWorkflowsByRequester(@RequestParam Long requesterId) {
        return approvalWorkflowService.getWorkflowsByRequester(requesterId);
    }

    @ApiOperation(value = "查询所有审批配置")
    @GetMapping("/approval/getAllConfigs")
    public BaseResultEntity getAllConfigs() {
        return approvalWorkflowService.getAllConfigs();
    }

    @ApiOperation(value = "根据类型查询审批配置")
    @GetMapping("/approval/getConfigByType")
    public BaseResultEntity getConfigByType(@RequestParam String workflowType) {
        return approvalWorkflowService.getConfigByType(workflowType);
    }

    @ApiOperation(value = "更新审批配置")
    @PostMapping("/approval/updateConfig")
    public BaseResultEntity updateConfig(@RequestBody NodeApprovalConfig config) {
        return approvalWorkflowService.updateConfig(config);
    }

    @ApiOperation(value = "启用/禁用审批配置")
    @PostMapping("/approval/updateConfigEnabled")
    public BaseResultEntity updateConfigEnabled(@RequestParam Long id, @RequestParam Integer isEnabled) {
        return approvalWorkflowService.updateConfigEnabled(id, isEnabled);
    }

    // ========== 数据交换 APIs ==========

    @ApiOperation(value = "查询数据交换日志分页列表")
    @GetMapping("/exchange/findDataExchangeLogPage")
    public BaseResultEntity findDataExchangeLogPage(
            @ApiParam("关键字") @RequestParam(required = false) String keyword,
            @ApiParam("源节点ID") @RequestParam(required = false) String sourceOrganId,
            @ApiParam("目标节点ID") @RequestParam(required = false) String targetOrganId,
            @ApiParam("交换类型") @RequestParam(required = false) String exchangeType,
            @ApiParam("数据类型") @RequestParam(required = false) String dataType,
            @ApiParam("状态") @RequestParam(required = false) Integer status,
            @ApiParam("开始日期") @RequestParam(required = false) String startDate,
            @ApiParam("结束日期") @RequestParam(required = false) String endDate,
            @ApiParam("页码") @RequestParam(defaultValue = "1") Integer pageNum,
            @ApiParam("每页数量") @RequestParam(defaultValue = "10") Integer pageSize) {
        return dataExchangeService.findDataExchangeLogPage(keyword, sourceOrganId, targetOrganId, exchangeType,
                dataType, status, startDate, endDate, pageNum, pageSize);
    }

    @ApiOperation(value = "根据ID查询数据交换日志")
    @GetMapping("/exchange/getDataExchangeLogById")
    public BaseResultEntity getDataExchangeLogById(@RequestParam Long id) {
        return dataExchangeService.getDataExchangeLogById(id);
    }

    @ApiOperation(value = "根据交换ID查询日志")
    @GetMapping("/exchange/getDataExchangeLogByExchangeId")
    public BaseResultEntity getDataExchangeLogByExchangeId(@RequestParam String exchangeId) {
        return dataExchangeService.getDataExchangeLogByExchangeId(exchangeId);
    }

    @ApiOperation(value = "添加数据交换日志")
    @PostMapping("/exchange/addDataExchangeLog")
    public BaseResultEntity addDataExchangeLog(@RequestBody NodeDataExchangeLog exchangeLog) {
        return dataExchangeService.addDataExchangeLog(exchangeLog);
    }

    @ApiOperation(value = "更新数据交换日志")
    @PostMapping("/exchange/updateDataExchangeLog")
    public BaseResultEntity updateDataExchangeLog(@RequestBody NodeDataExchangeLog exchangeLog) {
        return dataExchangeService.updateDataExchangeLog(exchangeLog);
    }

    @ApiOperation(value = "删除数据交换日志")
    @PostMapping("/exchange/deleteDataExchangeLog")
    public BaseResultEntity deleteDataExchangeLog(@RequestParam Long id) {
        return dataExchangeService.deleteDataExchangeLog(id);
    }

    @ApiOperation(value = "批量删除数据交换日志")
    @PostMapping("/exchange/batchDeleteDataExchangeLog")
    public BaseResultEntity batchDeleteDataExchangeLog(@RequestBody List<Long> ids) {
        return dataExchangeService.batchDeleteDataExchangeLog(ids);
    }

    @ApiOperation(value = "更新交换状态")
    @PostMapping("/exchange/updateExchangeStatus")
    public BaseResultEntity updateExchangeStatus(
            @RequestParam Long id,
            @RequestParam Integer status,
            @RequestParam(required = false) String errorMsg) {
        return dataExchangeService.updateExchangeStatus(id, status, errorMsg);
    }

    @ApiOperation(value = "完成交换")
    @PostMapping("/exchange/completeExchange")
    public BaseResultEntity completeExchange(
            @RequestParam Long id,
            @RequestParam Integer status,
            @RequestParam Long completedAtTimestamp,
            @RequestParam Long durationMs) {
        Date completedAt = new Date(completedAtTimestamp);
        return dataExchangeService.completeExchange(id, status, completedAt, durationMs);
    }

    @ApiOperation(value = "查询源节点的交换日志")
    @GetMapping("/exchange/getExchangeLogsBySourceOrgan")
    public BaseResultEntity getExchangeLogsBySourceOrgan(@RequestParam String sourceOrganId) {
        return dataExchangeService.getExchangeLogsBySourceOrgan(sourceOrganId);
    }

    @ApiOperation(value = "查询目标节点的交换日志")
    @GetMapping("/exchange/getExchangeLogsByTargetOrgan")
    public BaseResultEntity getExchangeLogsByTargetOrgan(@RequestParam String targetOrganId) {
        return dataExchangeService.getExchangeLogsByTargetOrgan(targetOrganId);
    }

    @ApiOperation(value = "查询失败的交换日志")
    @GetMapping("/exchange/getFailedExchangeLogs")
    public BaseResultEntity getFailedExchangeLogs() {
        return dataExchangeService.getFailedExchangeLogs();
    }

    @ApiOperation(value = "查询待处理的交换日志")
    @GetMapping("/exchange/getPendingExchangeLogs")
    public BaseResultEntity getPendingExchangeLogs() {
        return dataExchangeService.getPendingExchangeLogs();
    }

    @ApiOperation(value = "查询交换统计信息")
    @GetMapping("/exchange/getExchangeStatistics")
    public BaseResultEntity getExchangeStatistics(@RequestParam(required = false) String organId) {
        return dataExchangeService.getExchangeStatistics(organId);
    }

    @ApiOperation(value = "查询节点间的交换记录")
    @GetMapping("/exchange/getExchangeLogsBetweenOrgans")
    public BaseResultEntity getExchangeLogsBetweenOrgans(
            @RequestParam String sourceOrganId,
            @RequestParam String targetOrganId) {
        return dataExchangeService.getExchangeLogsBetweenOrgans(sourceOrganId, targetOrganId);
    }

    @ApiOperation(value = "查询最近N天的交换日志")
    @GetMapping("/exchange/getRecentExchangeLogs")
    public BaseResultEntity getRecentExchangeLogs(@RequestParam(required = false) Integer days) {
        return dataExchangeService.getRecentExchangeLogs(days);
    }

    @ApiOperation(value = "触发数据同步")
    @PostMapping("/exchange/trigger")
    public BaseResultEntity triggerDataSync(
            @RequestParam String sourceOrganId,
            @RequestParam String targetOrganId,
            @RequestParam String exchangeType,
            @RequestParam(required = false) String dataType,
            @RequestParam(required = false) String dataId,
            @RequestParam(required = false) String dataName) {
        return dataExchangeService.triggerDataSync(sourceOrganId, targetOrganId, exchangeType, dataType, dataId, dataName);
    }

    // ========== 节点列表增强 APIs (使用现有OrganController) ==========
    // 节点列表、属性编辑、属性展示功能将复用现有的OrganController APIs

    // ========== 节点建立合作和取消合作 APIs (映射到cooperation模块) ==========
    @ApiOperation(value = "搜索可合作节点")
    @GetMapping("/cooperation/search")
    public BaseResultEntity searchCooperationNodes(@RequestParam(required = false) String keyword) {
        // 这里可以复用现有的OrganController的getOrganList方法
        // 或者实现新的搜索逻辑
        return cooperationService.findCooperationPartyPage(keyword, null, null, null, 1, 100);
    }
}
