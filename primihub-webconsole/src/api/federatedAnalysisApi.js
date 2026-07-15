import request from '@/utils/request'

// ========== 联邦分析相关接口 ==========

// ==================== 关系型数据库对接 ====================

/**
 * 获取数据库连接列表
 */
export function getDatabaseConnections(params) {
  return request({
    url: '/federatedAnalysis/database/connections',
    method: 'get',
    params
  })
}

/**
 * 测试数据库连接
 */
export function testDatabaseConnection(data) {
  return request({
    url: '/federatedAnalysis/database/testConnection',
    method: 'post',
    data
  })
}

/**
 * 保存数据库连接
 */
export function saveDatabaseConnection(data) {
  return request({
    url: '/federatedAnalysis/database/saveConnection',
    method: 'post',
    data
  })
}

/**
 * 删除数据库连接
 */
export function deleteDatabaseConnection(params) {
  return request({
    url: '/federatedAnalysis/database/deleteConnection',
    method: 'delete',
    params
  })
}

/**
 * 获取数据库表列表
 */
export function getDatabaseTables(params) {
  return request({
    url: '/federatedAnalysis/database/tables',
    method: 'get',
    params
  })
}

/**
 * 执行SQL查询
 */
export function executeSqlQuery(data) {
  return request({
    url: '/federatedAnalysis/database/executeQuery',
    method: 'post',
    data
  })
}

// ==================== 大数据平台对接 ====================

/**
 * 获取大数据平台连接列表
 */
export function getBigDataConnections(params) {
  return request({
    url: '/federatedAnalysis/bigdata/connections',
    method: 'get',
    params
  })
}

/**
 * 测试大数据平台连接
 */
export function testBigDataConnection(data) {
  return request({
    url: '/federatedAnalysis/bigdata/testConnection',
    method: 'post',
    data
  })
}

/**
 * 保存大数据平台连接
 */
export function saveBigDataConnection(data) {
  return request({
    url: '/federatedAnalysis/bigdata/saveConnection',
    method: 'post',
    data
  })
}

/**
 * 删除大数据平台连接
 */
export function deleteBigDataConnection(params) {
  return request({
    url: '/federatedAnalysis/bigdata/deleteConnection',
    method: 'delete',
    params
  })
}

/**
 * 提交Spark任务
 */
export function submitSparkJob(data) {
  return request({
    url: '/federatedAnalysis/bigdata/submitSparkJob',
    method: 'post',
    data
  })
}

/**
 * 获取HDFS文件列表
 */
export function getHdfsFiles(params) {
  return request({
    url: '/federatedAnalysis/bigdata/hdfsFiles',
    method: 'get',
    params
  })
}

// ==================== 公有云平台对接 ====================

/**
 * 获取云平台连接列表
 */
export function getCloudConnections(params) {
  return request({
    url: '/federatedAnalysis/cloud/connections',
    method: 'get',
    params
  })
}

/**
 * 测试云平台连接
 */
export function testCloudConnection(data) {
  return request({
    url: '/federatedAnalysis/cloud/testConnection',
    method: 'post',
    data
  })
}

/**
 * 保存云平台连接
 */
export function saveCloudConnection(data) {
  return request({
    url: '/federatedAnalysis/cloud/saveConnection',
    method: 'post',
    data
  })
}

/**
 * 删除云平台连接
 */
export function deleteCloudConnection(params) {
  return request({
    url: '/federatedAnalysis/cloud/deleteConnection',
    method: 'delete',
    params
  })
}

/**
 * 获取云存储桶列表
 */
export function getCloudBuckets(params) {
  return request({
    url: '/federatedAnalysis/cloud/buckets',
    method: 'get',
    params
  })
}

/**
 * 获取云存储对象列表
 */
export function getCloudObjects(params) {
  return request({
    url: '/federatedAnalysis/cloud/objects',
    method: 'get',
    params
  })
}

// ==================== 联邦分析任务 ====================

/**
 * 获取联邦分析任务列表
 */
export function getAnalysisTaskList(params) {
  return request({
    url: '/federatedAnalysis/task/list',
    method: 'get',
    params
  })
}

/**
 * 创建联邦分析任务
 */
export function createAnalysisTask(data) {
  return request({
    url: '/federatedAnalysis/task/create',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 获取联邦分析任务详情
 */
export function getAnalysisTaskDetail(params) {
  return request({
    url: '/federatedAnalysis/task/detail',
    method: 'get',
    params
  })
}

/**
 * 执行联邦分析任务
 */
export function runAnalysisTask(data) {
  return request({
    url: '/federatedAnalysis/task/run',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 停止联邦分析任务
 */
export function stopAnalysisTask(data) {
  return request({
    url: '/federatedAnalysis/task/stop',
    method: 'post', type: 'json',
    data
  })
}

// ==================== 日志管理 ====================

/**
 * 获取联邦分析日志列表
 */
export function getAnalysisLogs(params) {
  return request({
    url: '/federatedAnalysis/logs',
    method: 'get',
    params
  })
}

/**
 * 获取日志详情
 */
export function getAnalysisLogDetail(params) {
  return request({
    url: '/federatedAnalysis/logs/detail',
    method: 'get',
    params
  })
}

/**
 * 导出联邦分析日志
 */
export function exportAnalysisLogs(data) {
  return request({
    url: '/federatedAnalysis/logs/export',
    method: 'post', type: 'json',
    data,
    responseType: 'blob'
  })
}

/**
 * 获取导出历史
 */
export function getExportHistory(params) {
  return request({
    url: '/federatedAnalysis/logs/exportHistory',
    method: 'get',
    params
  })
}

/**
 * 下载导出文件
 */
export function downloadExportFile(params) {
  return request({
    url: '/federatedAnalysis/logs/download',
    method: 'get',
    params,
    responseType: 'blob'
  })
}
