import request from '@/utils/request'

// ========== 数据需求 CRUD ==========

/**
 * 查询数据需求分页列表
 */
export function findDataRequirementPage(params) {
  return request({
    url: '/dataRequirement/findDataRequirementPage',
    method: 'get',
    params
  })
}

/**
 * 根据ID查询数据需求
 */
export function getDataRequirementById(id) {
  return request({
    url: '/dataRequirement/getDataRequirementById',
    method: 'get',
    params: { id }
  })
}

/**
 * 添加数据需求
 */
export function addDataRequirement(data) {
  return request({
    url: '/dataRequirement/addDataRequirement',
    method: 'post',
    data
  })
}

/**
 * 更新数据需求
 */
export function updateDataRequirement(data) {
  return request({
    url: '/dataRequirement/updateDataRequirement',
    method: 'post',
    data
  })
}

/**
 * 删除数据需求
 */
export function deleteDataRequirement(id) {
  return request({
    url: '/dataRequirement/deleteDataRequirement',
    method: 'post',
    params: { id }
  })
}

/**
 * 批量删除数据需求
 */
export function batchDeleteDataRequirement(ids) {
  return request({
    url: '/dataRequirement/batchDeleteDataRequirement',
    method: 'post',
    data: ids
  })
}

// ========== 数据需求配置 CRUD ==========

/**
 * 查询配置分页列表
 */
export function findConfigPage(params) {
  return request({
    url: '/dataRequirement/findConfigPage',
    method: 'get',
    params
  })
}

/**
 * 添加配置
 */
export function addConfig(data) {
  return request({
    url: '/dataRequirement/addConfig',
    method: 'post',
    data
  })
}

/**
 * 更新配置
 */
export function updateConfig(data) {
  return request({
    url: '/dataRequirement/updateConfig',
    method: 'post',
    data
  })
}

/**
 * 删除配置
 */
export function deleteConfig(id) {
  return request({
    url: '/dataRequirement/deleteConfig',
    method: 'post',
    params: { id }
  })
}

/**
 * 更新配置启用状态
 */
export function updateConfigStatus(id, isEnabled) {
  return request({
    url: '/dataRequirement/updateConfigStatus',
    method: 'post',
    params: { id, isEnabled }
  })
}

// ========== 数据需求匹配功能 ==========

/**
 * 执行数据需求匹配
 */
export function matchDataRequirements(requirementId) {
  return request({
    url: '/dataRequirement/matchDataRequirements',
    method: 'post',
    params: { requirementId }
  })
}

/**
 * 查询匹配的资源列表
 */
export function findMatchedResources(params) {
  return request({
    url: '/dataRequirement/findMatchedResources',
    method: 'get',
    params
  })
}

/**
 * 确认匹配
 */
export function confirmMatch(matchId, confirmUserId, confirmUserName) {
  return request({
    url: '/dataRequirement/confirmMatch',
    method: 'post',
    params: { matchId, confirmUserId, confirmUserName }
  })
}

/**
 * 拒绝匹配
 */
export function rejectMatch(matchId, confirmUserId, confirmUserName) {
  return request({
    url: '/dataRequirement/rejectMatch',
    method: 'post',
    params: { matchId, confirmUserId, confirmUserName }
  })
}
