import request from '@/utils/request'

// ========== 接入方管理 APIs ==========

/**
 * 查询接入方分页列表
 */
export function findAccessPartyPage(params) {
  return request({
    url: '/node/access/findAccessPartyPage',
    method: 'get',
    params
  })
}

/**
 * 根据ID查询接入方
 */
export function getAccessPartyById(id) {
  return request({
    url: '/node/access/getAccessPartyById',
    method: 'get',
    params: { id }
  })
}

/**
 * 添加接入方申请
 */
export function addAccessParty(data) {
  return request({
    url: '/node/access/addAccessParty',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 更新接入方信息
 */
export function updateAccessParty(data) {
  return request({
    url: '/node/access/updateAccessParty',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 删除接入方
 */
export function deleteAccessParty(id) {
  return request({
    url: '/node/access/deleteAccessParty',
    method: 'post',
    params: { id }
  })
}

/**
 * 批量删除接入方
 */
export function batchDeleteAccessParty(ids) {
  return request({
    url: '/node/access/batchDeleteAccessParty',
    method: 'post', type: 'json',
    data: ids
  })
}

/**
 * 批准接入申请
 */
export function approveAccessParty(id, approveUserId, approveUserName, approveComment) {
  return request({
    url: '/node/access/approve',
    method: 'post',
    params: { id, approveUserId, approveUserName, approveComment }
  })
}

/**
 * 拒绝接入申请
 */
export function rejectAccessParty(id, approveUserId, approveUserName, approveComment) {
  return request({
    url: '/node/access/reject',
    method: 'post',
    params: { id, approveUserId, approveUserName, approveComment }
  })
}

/**
 * 批量批准接入申请
 */
export function batchApproveAccessParty(ids, approveUserId, approveUserName, approveComment) {
  return request({
    url: '/node/access/batchApprove',
    method: 'post', type: 'json',
    data: ids,
    params: { approveUserId, approveUserName, approveComment }
  })
}

/**
 * 更新接入权限级别
 */
export function updateAccessLevel(id, accessLevel) {
  return request({
    url: '/node/access/updateAccessLevel',
    method: 'post',
    params: { id, accessLevel }
  })
}

/**
 * 启用/禁用接入方
 */
export function updateActiveStatus(id, isActive) {
  return request({
    url: '/node/access/updateActiveStatus',
    method: 'post',
    params: { id, isActive }
  })
}

/**
 * 查询待审批的接入申请
 */
export function getPendingAccessParties() {
  return request({
    url: '/node/access/getPendingAccessParties',
    method: 'get'
  })
}

/**
 * 查询已批准的接入方
 */
export function getApprovedAccessParties() {
  return request({
    url: '/node/access/getApprovedAccessParties',
    method: 'get'
  })
}

// ========== 合作方管理 APIs ==========

/**
 * 查询合作方分页列表
 */
export function findCooperationPartyPage(params) {
  return request({
    url: '/node/cooperation/findCooperationPartyPage',
    method: 'get',
    params
  })
}

/**
 * 根据ID查询合作方
 */
export function getCooperationPartyById(id) {
  return request({
    url: '/node/cooperation/getCooperationPartyById',
    method: 'get',
    params: { id }
  })
}

/**
 * 建立合作关系
 */
export function establishCooperation(data) {
  return request({
    url: '/node/cooperation/establish',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 更新合作方信息
 */
export function updateCooperationParty(data) {
  return request({
    url: '/node/cooperation/update',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 取消合作关系
 */
export function cancelCooperation(id, reason) {
  return request({
    url: '/node/cooperation/cancel',
    method: 'post',
    params: { id, reason }
  })
}

/**
 * 终止合作
 */
export function terminateCooperation(id, reason) {
  return request({
    url: '/node/cooperation/terminate',
    method: 'post',
    params: { id, reason }
  })
}

/**
 * 续约合作
 */
export function renewCooperation(id, newEndDateTimestamp) {
  return request({
    url: '/node/cooperation/renew',
    method: 'post',
    params: { id, newEndDateTimestamp }
  })
}

/**
 * 更新合作状态
 */
export function updateCooperationStatus(id, cooperationStatus) {
  return request({
    url: '/node/cooperation/updateCooperationStatus',
    method: 'post',
    params: { id, cooperationStatus }
  })
}

/**
 * 更新健康评分
 */
export function updateHealthScore(id, healthScore) {
  return request({
    url: '/node/cooperation/updateHealthScore',
    method: 'post',
    params: { id, healthScore }
  })
}

/**
 * 查询进行中的合作方
 */
export function getActiveCooperationParties() {
  return request({
    url: '/node/cooperation/getActiveCooperationParties',
    method: 'get'
  })
}

/**
 * 查询即将过期的合作方
 */
export function getExpiringCooperationParties(days) {
  return request({
    url: '/node/cooperation/getExpiringCooperationParties',
    method: 'get',
    params: { days }
  })
}

/**
 * 查询健康评分低的合作方
 */
export function getUnhealthyCooperationParties(threshold) {
  return request({
    url: '/node/cooperation/getUnhealthyCooperationParties',
    method: 'get',
    params: { threshold }
  })
}

/**
 * 批量删除合作方
 */
export function batchDeleteCooperationParty(ids) {
  return request({
    url: '/node/cooperation/batchDelete',
    method: 'post', type: 'json',
    data: ids
  })
}

/**
 * 搜索可合作节点
 */
export function searchCooperationNodes(keyword) {
  return request({
    url: '/node/cooperation/search',
    method: 'get',
    params: { keyword }
  })
}

// ========== 审批工作流 APIs ==========

/**
 * 查询工作流分页列表
 */
export function findWorkflowPage(params) {
  return request({
    url: '/node/approval/findWorkflowPage',
    method: 'get',
    params
  })
}

/**
 * 根据ID查询工作流
 */
export function getWorkflowById(id) {
  return request({
    url: '/node/approval/getWorkflowById',
    method: 'get',
    params: { id }
  })
}

/**
 * 创建审批工作流
 */
export function createWorkflow(data) {
  return request({
    url: '/node/approval/createWorkflow',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 审批通过
 */
export function approveWorkflow(workflowId, approverId, approverName, comment) {
  return request({
    url: '/node/approval/approve',
    method: 'post',
    params: { workflowId, approverId, approverName, comment }
  })
}

/**
 * 审批拒绝
 */
export function rejectWorkflow(workflowId, approverId, approverName, comment) {
  return request({
    url: '/node/approval/reject',
    method: 'post',
    params: { workflowId, approverId, approverName, comment }
  })
}

/**
 * 取消工作流
 */
export function cancelWorkflow(workflowId, reason) {
  return request({
    url: '/node/approval/cancel',
    method: 'post',
    params: { workflowId, reason }
  })
}

/**
 * 查询待审批的工作流
 */
export function getPendingWorkflows() {
  return request({
    url: '/node/approval/getPendingWorkflows',
    method: 'get'
  })
}

/**
 * 查询我的待审批工作流
 */
export function getMyPendingWorkflows(userId) {
  return request({
    url: '/node/approval/getMyPendingWorkflows',
    method: 'get',
    params: { userId }
  })
}

/**
 * 查询用户创建的工作流
 */
export function getWorkflowsByRequester(requesterId) {
  return request({
    url: '/node/approval/getWorkflowsByRequester',
    method: 'get',
    params: { requesterId }
  })
}

/**
 * 查询所有审批配置
 */
export function getAllConfigs() {
  return request({
    url: '/node/approval/getAllConfigs',
    method: 'get'
  })
}

/**
 * 根据类型查询审批配置
 */
export function getConfigByType(workflowType) {
  return request({
    url: '/node/approval/getConfigByType',
    method: 'get',
    params: { workflowType }
  })
}

/**
 * 更新审批配置
 */
export function updateApprovalConfig(data) {
  return request({
    url: '/node/approval/updateConfig',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 启用/禁用审批配置
 */
export function updateConfigEnabled(id, isEnabled) {
  return request({
    url: '/node/approval/updateConfigEnabled',
    method: 'post',
    params: { id, isEnabled }
  })
}

// ========== 数据交换 APIs ==========

/**
 * 查询数据交换日志分页列表
 */
export function findDataExchangeLogPage(params) {
  return request({
    url: '/node/exchange/findDataExchangeLogPage',
    method: 'get',
    params
  })
}

/**
 * 根据ID查询数据交换日志
 */
export function getDataExchangeLogById(id) {
  return request({
    url: '/node/exchange/getDataExchangeLogById',
    method: 'get',
    params: { id }
  })
}

/**
 * 触发数据同步
 */
export function triggerDataSync(sourceOrganId, targetOrganId, exchangeType, dataType, dataId, dataName) {
  return request({
    url: '/node/exchange/trigger',
    method: 'post',
    params: { sourceOrganId, targetOrganId, exchangeType, dataType, dataId, dataName }
  })
}

/**
 * 查询交换统计信息
 */
export function getExchangeStatistics(organId) {
  return request({
    url: '/node/exchange/getExchangeStatistics',
    method: 'get',
    params: { organId }
  })
}

/**
 * 查询节点间的交换记录
 */
export function getExchangeLogsBetweenOrgans(sourceOrganId, targetOrganId) {
  return request({
    url: '/node/exchange/getExchangeLogsBetweenOrgans',
    method: 'get',
    params: { sourceOrganId, targetOrganId }
  })
}

/**
 * 查询最近N天的交换日志
 */
export function getRecentExchangeLogs(days) {
  return request({
    url: '/node/exchange/getRecentExchangeLogs',
    method: 'get',
    params: { days }
  })
}

/**
 * 查询失败的交换日志
 */
export function getFailedExchangeLogs() {
  return request({
    url: '/node/exchange/getFailedExchangeLogs',
    method: 'get'
  })
}

/**
 * 批量删除数据交换日志
 */
export function batchDeleteDataExchangeLog(ids) {
  return request({
    url: '/node/exchange/batchDeleteDataExchangeLog',
    method: 'post', type: 'json',
    data: ids
  })
}
