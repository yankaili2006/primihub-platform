import request from '@/utils/request'

// ==================== 警务数据融合 ====================

export function createPoliceTask(data) {
  return request({ url: '/policeFusion/task/create', method: 'post', data })
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
