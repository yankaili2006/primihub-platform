import request from '@/utils/request'

// ========== 联邦统计相关接口 ==========

// ==================== 联邦统计任务 ====================

/**
 * 获取联邦统计任务列表
 */
export function getStatisticsTaskList(params) {
  return request({
    url: '/federatedStatistics/task/list',
    method: 'get',
    params
  })
}

/**
 * 创建联邦统计任务
 */
export function createStatisticsTask(data) {
  return request({
    url: '/federatedStatistics/task/create',
    method: 'post',
    data
  })
}

/**
 * 获取联邦统计任务详情
 */
export function getStatisticsTaskDetail(params) {
  return request({
    url: '/federatedStatistics/task/detail',
    method: 'get',
    params
  })
}

/**
 * 执行联邦统计任务
 */
export function runStatisticsTask(data) {
  return request({
    url: '/federatedStatistics/task/run',
    method: 'post',
    data
  })
}

/**
 * 停止联邦统计任务
 */
export function stopStatisticsTask(data) {
  return request({
    url: '/federatedStatistics/task/stop',
    method: 'post',
    data
  })
}

/**
 * 删除联邦统计任务
 */
export function deleteStatisticsTask(params) {
  return request({
    url: '/federatedStatistics/task/delete',
    method: 'delete',
    params
  })
}

// ==================== 结果存储 ====================

/**
 * 获取存储配置
 */
export function getStorageConfig(params) {
  return request({
    url: '/federatedStatistics/storage/config',
    method: 'get',
    params
  })
}

/**
 * 保存存储配置
 */
export function saveStorageConfig(data) {
  return request({
    url: '/federatedStatistics/storage/saveConfig',
    method: 'post',
    data
  })
}

/**
 * 测试存储连接
 */
export function testStorageConnection(data) {
  return request({
    url: '/federatedStatistics/storage/testConnection',
    method: 'post',
    data
  })
}

/**
 * 获取存储统计信息
 */
export function getStorageStats(params) {
  return request({
    url: '/federatedStatistics/storage/stats',
    method: 'get',
    params
  })
}

/**
 * 获取存储结果列表
 */
export function getStorageResultList(params) {
  return request({
    url: '/federatedStatistics/storage/results',
    method: 'get',
    params
  })
}

/**
 * 预览存储结果
 */
export function previewStorageResult(params) {
  return request({
    url: '/federatedStatistics/storage/preview',
    method: 'get',
    params
  })
}

/**
 * 下载存储结果
 */
export function downloadStorageResult(params) {
  return request({
    url: '/federatedStatistics/storage/download',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

/**
 * 删除存储结果
 */
export function deleteStorageResult(params) {
  return request({
    url: '/federatedStatistics/storage/delete',
    method: 'delete',
    params
  })
}

// ==================== 结果导出 ====================

/**
 * 导出统计结果
 */
export function exportStatisticsResult(data) {
  return request({
    url: '/federatedStatistics/export/result',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

/**
 * 获取导出历史
 */
export function getResultExportHistory(params) {
  return request({
    url: '/federatedStatistics/export/history',
    method: 'get',
    params
  })
}

/**
 * 下载导出文件
 */
export function downloadResultExportFile(params) {
  return request({
    url: '/federatedStatistics/export/download',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// ==================== 日志管理 ====================

/**
 * 获取联邦统计日志列表
 */
export function getStatisticsLogs(params) {
  return request({
    url: '/federatedStatistics/logs',
    method: 'get',
    params
  })
}

/**
 * 获取日志详情
 */
export function getStatisticsLogDetail(params) {
  return request({
    url: '/federatedStatistics/logs/detail',
    method: 'get',
    params
  })
}

/**
 * 导出联邦统计日志
 */
export function exportStatisticsLogs(data) {
  return request({
    url: '/federatedStatistics/logs/export',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

/**
 * 获取日志导出历史
 */
export function getLogExportHistory(params) {
  return request({
    url: '/federatedStatistics/logs/exportHistory',
    method: 'get',
    params
  })
}

/**
 * 下载日志导出文件
 */
export function downloadLogExportFile(params) {
  return request({
    url: '/federatedStatistics/logs/download',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// ==================== 统计类型 ====================

/**
 * 获取支持的统计类型
 */
export function getStatisticsTypes() {
  return request({
    url: '/federatedStatistics/types',
    method: 'get'
  })
}

/**
 * 执行求和统计
 */
export function executeSumStatistics(data) {
  return request({
    url: '/federatedStatistics/execute/sum',
    method: 'post',
    data
  })
}

/**
 * 执行平均值统计
 */
export function executeAvgStatistics(data) {
  return request({
    url: '/federatedStatistics/execute/avg',
    method: 'post',
    data
  })
}

/**
 * 执行计数统计
 */
export function executeCountStatistics(data) {
  return request({
    url: '/federatedStatistics/execute/count',
    method: 'post',
    data
  })
}

/**
 * 执行最大值统计
 */
export function executeMaxStatistics(data) {
  return request({
    url: '/federatedStatistics/execute/max',
    method: 'post',
    data
  })
}

/**
 * 执行最小值统计
 */
export function executeMinStatistics(data) {
  return request({
    url: '/federatedStatistics/execute/min',
    method: 'post',
    data
  })
}

/**
 * 执行方差统计
 */
export function executeVarianceStatistics(data) {
  return request({
    url: '/federatedStatistics/execute/variance',
    method: 'post',
    data
  })
}
