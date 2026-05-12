import request from '@/utils/request'

// 获取联邦统计任务列表
export function getFederatedStatisticsList(params) {
  return request({
    url: '/data/federatedStatistics/task/list',
    method: 'get',
    params
  })
}

// 创建联邦统计任务
export function createFederatedStatistics(data) {
  return request({
    url: '/data/federatedStatistics/task/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 获取联邦统计任务详情
export function getFederatedStatisticsDetail(params) {
  return request({
    url: '/data/federatedStatistics/task/detail',
    method: 'get',
    params
  })
}

// 执行联邦统计任务
export function startFederatedStatistics(data) {
  return request({
    url: '/data/federatedStatistics/task/run',
    method: 'post',
    data
  })
}

// 存储联邦统计结果
export function saveFederatedStatisticsResult(data) {
  return request({
    url: '/data/federatedStatistics/result/save',
    method: 'post',
    type: 'json',
    data
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
