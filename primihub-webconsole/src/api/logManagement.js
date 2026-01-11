import request from '@/utils/request'

// ========== 操作日志定义 ==========

export function getOperationLogDefinitionPage(params) {
  return request({
    url: '/log/findOperationLogDefinitionPage',
    method: 'get',
    params
  })
}

export function addOperationLogDefinition(data) {
  return request({
    url: '/log/addOperationLogDefinition',
    method: 'post',
    data
  })
}

export function updateOperationLogDefinition(data) {
  return request({
    url: '/log/updateOperationLogDefinition',
    method: 'post',
    data
  })
}

export function deleteOperationLogDefinition(params) {
  return request({
    url: '/log/deleteOperationLogDefinition',
    method: 'post',
    params
  })
}

export function updateOperationLogDefinitionStatus(params) {
  return request({
    url: '/log/updateOperationLogDefinitionStatus',
    method: 'post',
    params
  })
}

// ========== 调度日志定义 ==========

export function getScheduleLogDefinitionPage(params) {
  return request({
    url: '/log/findScheduleLogDefinitionPage',
    method: 'get',
    params
  })
}

export function addScheduleLogDefinition(data) {
  return request({
    url: '/log/addScheduleLogDefinition',
    method: 'post',
    data
  })
}

export function updateScheduleLogDefinition(data) {
  return request({
    url: '/log/updateScheduleLogDefinition',
    method: 'post',
    data
  })
}

export function deleteScheduleLogDefinition(params) {
  return request({
    url: '/log/deleteScheduleLogDefinition',
    method: 'post',
    params
  })
}

// ========== 计算日志定义 ==========

export function getComputeLogDefinitionPage(params) {
  return request({
    url: '/log/findComputeLogDefinitionPage',
    method: 'get',
    params
  })
}

export function addComputeLogDefinition(data) {
  return request({
    url: '/log/addComputeLogDefinition',
    method: 'post',
    data
  })
}

export function updateComputeLogDefinition(data) {
  return request({
    url: '/log/updateComputeLogDefinition',
    method: 'post',
    data
  })
}

export function deleteComputeLogDefinition(params) {
  return request({
    url: '/log/deleteComputeLogDefinition',
    method: 'post',
    params
  })
}

// ========== 操作日志记录 ==========

export function getOperationLogPage(params) {
  return request({
    url: '/log/findOperationLogPage',
    method: 'get',
    params
  })
}

export function exportOperationLog(params) {
  return request({
    url: '/log/exportOperationLog',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// ========== 调度日志记录 ==========

export function getScheduleLogPage(params) {
  return request({
    url: '/log/findScheduleLogPage',
    method: 'get',
    params
  })
}

export function exportScheduleLog(params) {
  return request({
    url: '/log/exportScheduleLog',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// ========== 计算日志记录 ==========

export function getComputeLogPage(params) {
  return request({
    url: '/log/findComputeLogPage',
    method: 'get',
    params
  })
}

export function exportComputeLog(params) {
  return request({
    url: '/log/exportComputeLog',
    method: 'get',
    params,
    responseType: 'blob'
  })
}
