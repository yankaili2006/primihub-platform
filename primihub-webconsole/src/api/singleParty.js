import request from '@/utils/request'

export function createTask(data) {
  return request({
    url: '/singleParty/createTask',
    method: 'post',
    type: 'json',
    data
  })
}

export function getTaskList(params) {
  return request({
    url: '/singleParty/getTaskList',
    method: 'get',
    params,
    showLoading: false
  })
}

export function getTaskDetails(params) {
  return request({
    url: '/singleParty/getTaskDetails',
    method: 'get',
    params,
    showLoading: false
  })
}

export function downloadResult(params) {
  return request({
    url: '/singleParty/downloadResult',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

export function deleteTask(params) {
  return request({
    url: '/singleParty/deleteTask',
    method: 'get',
    params
  })
}

export function cancelTask(params) {
  return request({
    url: '/singleParty/cancelTask',
    method: 'get',
    params
  })
}

// ==================== 单方数据预处理 ====================

export function getPreprocessTaskList(params) {
  return request({ url: '/singleParty/preprocess/list', method: 'get', params })
}

export function createPreprocessTask(data) {
  return request({ url: '/singleParty/preprocess/create', method: 'post', type: 'json', data })
}

export function runPreprocessTask(data) {
  return request({ url: '/singleParty/preprocess/run', method: 'post', type: 'json', data })
}

export function deletePreprocessTask(data) {
  return request({ url: '/singleParty/preprocess/delete', method: 'post', type: 'json', data })
}

export function downloadPreprocessResult(params) {
  return request({ url: '/singleParty/preprocess/download', method: 'get', params, responseType: 'blob' })
}

// ==================== 单方脚本处理 ====================

export function getScriptTaskList(params) {
  return request({ url: '/singleParty/script/list', method: 'get', params })
}

export function createScriptTask(data) {
  return request({ url: '/singleParty/script/create', method: 'post', type: 'json', data })
}

export function runScriptTask(data) {
  return request({ url: '/singleParty/script/run', method: 'post', type: 'json', data })
}

export function deleteScriptTask(data) {
  return request({ url: '/singleParty/script/delete', method: 'post', type: 'json', data })
}

export function downloadScriptResult(params) {
  return request({ url: '/singleParty/script/download', method: 'get', params, responseType: 'blob' })
}

// ==================== 单方学习日志 ====================

export function getSinglePartyLogs(params) {
  return request({ url: '/singleParty/log/list', method: 'get', params })
}

export function exportSinglePartyLogs(params) {
  return request({ url: '/singleParty/log/export', method: 'get', params, responseType: 'blob' })
}
