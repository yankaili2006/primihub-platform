import request from '@/utils/request'

// ==================== 警务数据融合 ====================

export function createPoliceTask(data) {
  return request({ url: '/policeFusion/task/create', method: 'post', data })
}

// #209 加密模型联合运算
export function encryptedCompute(data) {
  return request({ url: '/policeFusion/model/compute', method: 'post', data })
}

export function getPoliceTaskList(params) {
  return request({ url: '/policeFusion/task/list', method: 'get', params })
}

export function getPoliceTaskDetail(params) {
  return request({ url: '/policeFusion/task/detail', method: 'get', params })
}

export function savePoliceApi(data) {
  return request({ url: '/policeFusion/api/save', method: 'post', data })
}

export function getPoliceApiList(params) {
  return request({ url: '/policeFusion/api/list', method: 'get', params })
}

export function deletePoliceApi(data) {
  return request({ url: '/policeFusion/api/delete', method: 'post', data })
}

export function testPoliceApi(params) {
  return request({ url: '/policeFusion/api/test', method: 'get', params })
}

export function generatePoliceKey(data) {
  return request({ url: '/policeFusion/key/generate', method: 'post', data })
}

export function getPoliceKeyList(params) {
  return request({ url: '/policeFusion/key/list', method: 'get', params })
}

export function deletePoliceKey(data) {
  return request({ url: '/policeFusion/key/delete', method: 'post', data })
}

export function encryptPoliceData(data) {
  return request({ url: '/policeFusion/key/encrypt', method: 'post', data })
}

export function decryptPoliceData(data) {
  return request({ url: '/policeFusion/key/decrypt', method: 'post', data })
}

// ==================== 电子证件 ====================

export function convertFeature(data) {
  return request({ url: '/electronicCert/feature/convert', method: 'post', data })
}

// #216 现场证件特征转换
export function convertFeatureOnSite(data) {
  return request({ url: '/electronicCert/feature/convert/onsite', method: 'post', data })
}

export function compareFeature(data) {
  return request({ url: '/electronicCert/compare', method: 'post', data })
}

export function importSceneData(data) {
  return request({ url: '/electronicCert/import', method: 'post', data })
}

export function exportSceneData(data) {
  return request({ url: '/electronicCert/export', method: 'post', data })
}

export function batchExchange(data) {
  return request({ url: '/electronicCert/exchange/batch', method: 'post', data })
}

export function realtimeExchange(data) {
  return request({ url: '/electronicCert/exchange/realtime', method: 'post', data })
}

// ==================== 警务数据融合-密文交换 ====================
export function policeBatchExchange(data) {
  return request({ url: '/policeFusion/exchange/batch', method: 'post', data })
}

export function policeRealtimeExchange(data) {
  return request({ url: '/policeFusion/exchange/realtime', method: 'post', data })
}

// ==================== 警务数据融合-数据源对接 ====================
export function getPoliceDataSourceList(params) {
  return request({ url: '/policeFusion/datasource/list', method: 'get', params })
}

export function savePoliceDataSource(data) {
  return request({ url: '/policeFusion/datasource/save', method: 'post', data })
}

export function deletePoliceDataSource(data) {
  return request({ url: '/policeFusion/datasource/delete', method: 'post', data })
}

export function syncPoliceDataSource(data) {
  return request({ url: '/policeFusion/datasource/sync', method: 'post', data })
}

export function testPoliceDataSource(params) {
  return request({ url: '/policeFusion/datasource/test', method: 'get', params })
}

// ==================== 场景日志（任务即日志记录） ====================
export function getPoliceLogList(params) {
  return request({ url: '/policeFusion/log/list', method: 'get', params })
}

export function exportPoliceLog(params) {
  return request({ url: '/policeFusion/log/export', method: 'get', params, responseType: 'blob' })
}

export function getCertLogList(params) {
  return request({ url: '/electronicCert/log/list', method: 'get', params })
}

export function exportCertLog(params) {
  return request({ url: '/electronicCert/log/export', method: 'get', params, responseType: 'blob' })
}
