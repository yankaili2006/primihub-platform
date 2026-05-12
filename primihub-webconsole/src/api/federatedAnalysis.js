import request from '@/utils/request'

// 获取联邦分析任务列表
export function getFederatedAnalysisList(params) {
  return request({
    url: '/data/federatedAnalysis/task/list',
    method: 'get',
    params
  })
}

// 创建联邦分析任务
export function createFederatedAnalysis(data) {
  return request({
    url: '/data/federatedAnalysis/task/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 获取联邦分析任务详情
export function getFederatedAnalysisDetail(params) {
  return request({
    url: '/data/federatedAnalysis/task/detail',
    method: 'get',
    params
  })
}

// 执行联邦分析任务
export function startFederatedAnalysis(data) {
  return request({
    url: '/data/federatedAnalysis/task/run',
    method: 'post',
    data
  })
}

// 导出分析结果
export function exportFederatedAnalysisResult(params) {
  return request({
    url: '/data/federatedAnalysis/result/export',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// ==================== 数据源连接管理 ====================

// 获取数据源连接列表
export function getDataSourceList(params) {
  return request({
    url: '/data/federatedAnalysis/datasource/list',
    method: 'get',
    params
  })
}

// 创建数据源连接
export function createDataSource(data) {
  return request({
    url: '/data/federatedAnalysis/datasource/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 更新数据源连接
export function updateDataSource(data) {
  return request({
    url: '/data/federatedAnalysis/datasource/update',
    method: 'post',
    type: 'json',
    data
  })
}

// 删除数据源连接
export function deleteDataSource(data) {
  return request({
    url: '/data/federatedAnalysis/datasource/delete',
    method: 'post',
    data
  })
}

// 测试数据源连接
export function testDataSourceConnection(data) {
  return request({
    url: '/data/federatedAnalysis/datasource/test',
    method: 'post',
    type: 'json',
    data
  })
}

// 获取数据源表列表
export function getDataSourceTables(params) {
  return request({
    url: '/data/federatedAnalysis/datasource/tables',
    method: 'get',
    params
  })
}

// 获取表字段列表
export function getTableColumns(params) {
  return request({
    url: '/data/federatedAnalysis/datasource/columns',
    method: 'get',
    params
  })
}

// ==================== 关系型数据库连接 ====================

// 获取支持的关系型数据库类型
export function getSupportedRdbms() {
  return request({
    url: '/data/federatedAnalysis/rdbms/types',
    method: 'get'
  })
}

// 创建关系型数据库连接
export function createRdbmsConnection(data) {
  return request({
    url: '/data/federatedAnalysis/rdbms/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 测试关系型数据库连接
export function testRdbmsConnection(data) {
  return request({
    url: '/data/federatedAnalysis/rdbms/test',
    method: 'post',
    type: 'json',
    data
  })
}

// ==================== 大数据平台连接 ====================

// 获取支持的大数据平台类型
export function getSupportedBigDataPlatforms() {
  return request({
    url: '/data/federatedAnalysis/bigdata/types',
    method: 'get'
  })
}

// 创建大数据平台连接
export function createBigDataConnection(data) {
  return request({
    url: '/data/federatedAnalysis/bigdata/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 测试大数据平台连接
export function testBigDataConnection(data) {
  return request({
    url: '/data/federatedAnalysis/bigdata/test',
    method: 'post',
    type: 'json',
    data
  })
}

// ==================== 公有云平台连接 ====================

// 获取支持的公有云平台类型
export function getSupportedCloudPlatforms() {
  return request({
    url: '/data/federatedAnalysis/cloud/types',
    method: 'get'
  })
}

// 创建公有云平台连接
export function createCloudConnection(data) {
  return request({
    url: '/data/federatedAnalysis/cloud/create',
    method: 'post',
    type: 'json',
    data
  })
}

// 测试公有云平台连接
export function testCloudConnection(data) {
  return request({
    url: '/data/federatedAnalysis/cloud/test',
    method: 'post',
    type: 'json',
    data
  })
}

// 获取云平台存储桶列表
export function getCloudBuckets(params) {
  return request({
    url: '/data/federatedAnalysis/cloud/buckets',
    method: 'get',
    params
  })
}

// ==================== 日志管理 ====================

// 获取联邦分析日志列表
export function getFederatedAnalysisLogs(params) {
  return request({
    url: '/data/federatedAnalysis/logs',
    method: 'get',
    params
  })
}

// 获取单个任务的日志
export function getFederatedAnalysisTaskLogs(params) {
  return request({
    url: '/data/federatedAnalysis/taskLogs',
    method: 'get',
    params
  })
}

// 导出联邦分析日志
export function exportFederatedAnalysisLogs(params) {
  return request({
    url: '/data/federatedAnalysis/exportLogs',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// 批量导出联邦分析日志
export function batchExportFederatedAnalysisLogs(data) {
  return request({
    url: '/data/federatedAnalysis/batchExportLogs',
    method: 'post',
    type: 'json',
    data,
    responseType: 'blob'
  })
}

// ==================== SQL 校验与格式化 ====================

export function validateSql(data) {
  return request({ url: '/federatedAnalysis/sql/validate', method: 'post', type: 'json', data })
}

export function formatSql(data) {
  return request({ url: '/federatedAnalysis/sql/format', method: 'post', type: 'json', data })
}

export function getSqlFunctions(params) {
  return request({ url: '/federatedAnalysis/sql/functions', method: 'get', params })
}

// ==================== 任务停止 ====================

export function stopFederatedAnalysis(data) {
  return request({ url: '/federatedAnalysis/task/stop', method: 'post', type: 'json', data })
}
