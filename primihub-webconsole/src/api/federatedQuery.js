import request from '@/utils/request'

export function createFederatedQuery(data) {
  return request({ url: '/federatedQuery/create', method: 'post', data })
}

export function getFederatedQueryList(params) {
  return request({ url: '/federatedQuery/list', method: 'get', params })
}

export function getFederatedQueryDetail(params) {
  return request({ url: '/federatedQuery/detail', method: 'get', params })
}

export function runFederatedQuery(data) {
  return request({ url: '/federatedQuery/run', method: 'post', data })
}

export function getFederatedQueryResult(params) {
  return request({ url: '/federatedQuery/result', method: 'get', params })
}

export function getSupportedAlgorithms() {
  return request({ url: '/federatedQuery/algorithms', method: 'get' })
}

export function getFederatedQueryLogs(params) {
  return request({ url: '/federatedQuery/logs', method: 'get', params })
}

export function exportFederatedQueryLogs(data) {
  return request({ url: '/federatedQuery/logs/export', method: 'post', data })
}

export function createPsiTask(data) {
  return request({ url: '/data/psi/saveDataPsi', method: 'post', data })
}

export function getPsiTaskList(params) {
  return request({ url: '/data/psi/getPsiTaskList', method: 'get', params })
}

export function getDifferenceTaskList(params) {
  return request({ url: '/data/difference/getDifferenceTaskList', method: 'get', params })
}

export function getUnionTaskList(params) {
  return request({ url: '/data/union/getUnionTaskList', method: 'get', params })
}
