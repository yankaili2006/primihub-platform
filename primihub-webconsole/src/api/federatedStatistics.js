import request from '@/utils/request'

// 获取联邦统计任务列表
export function getFederatedStatisticsList(params) {
  return request({
    url: '/data/federatedStatistics/list',
    method: 'get',
    params
  })
}

// 创建联邦统计任务
export function createFederatedStatistics(data) {
  return request({
    url: '/data/federatedStatistics/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 获取联邦统计任务详情
export function getFederatedStatisticsDetail(params) {
  return request({
    url: '/data/federatedStatistics/detail',
    method: 'get',
    params
  })
}

// 执行联邦统计任务
export function startFederatedStatistics(data) {
  return request({
    url: '/data/federatedStatistics/start',
    method: 'post',
    data
  })
}

// 获取联邦统计结果
export function getFederatedStatisticsResult(params) {
  return request({
    url: '/data/federatedStatistics/result',
    method: 'get',
    params
  })
}

// 存储联邦统计结果
export function saveFederatedStatisticsResult(data) {
  return request({
    url: '/data/federatedStatistics/saveResult',
    method: 'post',
    type: 'json',
    data
  })
}

// 批量存储联邦统计结果
export function batchSaveFederatedStatisticsResult(data) {
  return request({
    url: '/data/federatedStatistics/batchSaveResult',
    method: 'post',
    type: 'json',
    data
  })
}

// 导出联邦统计结果
export function exportFederatedStatisticsResult(params) {
  return request({
    url: '/data/federatedStatistics/exportResult',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// 批量导出联邦统计结果
export function batchExportFederatedStatisticsResult(data) {
  return request({
    url: '/data/federatedStatistics/batchExportResult',
    method: 'post',
    type: 'json',
    data,
    responseType: 'blob'
  })
}

// 获取联邦统计日志列表
export function getFederatedStatisticsLogs(params) {
  return request({
    url: '/data/federatedStatistics/logs',
    method: 'get',
    params
  })
}

// 获取单个任务的日志
export function getFederatedStatisticsTaskLogs(params) {
  return request({
    url: '/data/federatedStatistics/taskLogs',
    method: 'get',
    params
  })
}

// 导出联邦统计日志
export function exportFederatedStatisticsLogs(params) {
  return request({
    url: '/data/federatedStatistics/exportLogs',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// 批量导出联邦统计日志
export function batchExportFederatedStatisticsLogs(data) {
  return request({
    url: '/data/federatedStatistics/batchExportLogs',
    method: 'post',
    type: 'json',
    data,
    responseType: 'blob'
  })
}

// 删除联邦统计任务
export function deleteFederatedStatistics(data) {
  return request({
    url: '/data/federatedStatistics/delete',
    method: 'post',
    data
  })
}

// ==================== 结果存储配置 ====================

export function getStatsStorageConfig() {
  return request({ url: '/federatedStatistics/storage/config', method: 'get' })
}

export function saveStatsStorageConfig(data) {
  return request({ url: '/federatedStatistics/storage/saveConfig', method: 'post', type: 'json', data })
}

export function testStatsStorageConnection(data) {
  return request({ url: '/federatedStatistics/storage/testConnection', method: 'post', type: 'json', data })
}

export function getStoredResults(params) {
  return request({ url: '/federatedStatistics/storage/results', method: 'get', params })
}

export function previewStoredResult(params) {
  return request({ url: '/federatedStatistics/storage/preview', method: 'get', params })
}

export function downloadStoredResult(params) {
  return request({ url: '/federatedStatistics/storage/download', method: 'get', params, responseType: 'blob' })
}

export function deleteStoredResult(data) {
  return request({ url: '/federatedStatistics/storage/delete', method: 'delete', data })
}
