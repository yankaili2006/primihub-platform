import request from '@/utils/request'

// 存证查询相关
export function getEvidencePage(params) {
  return request({
    url: '/evidence/findEvidencePage',
    method: 'get',
    params
  })
}

export function getEvidenceDetail(params) {
  return request({
    url: '/evidence/getEvidenceDetail',
    method: 'get',
    params
  })
}

export function verifyEvidence(data) {
  return request({
    url: '/evidence/verifyEvidence',
    method: 'post',
    data
  })
}

export function getEvidenceStatistics() {
  return request({
    url: '/evidence/getEvidenceStatistics',
    method: 'get'
  })
}

// 时间戳管理相关
export function getTimestampPage(params) {
  return request({
    url: '/evidence/findTimestampPage',
    method: 'get',
    params
  })
}

export function applyTimestamp(data) {
  return request({
    url: '/evidence/applyTimestamp',
    method: 'post',
    data
  })
}

export function verifyTimestamp(data) {
  return request({
    url: '/evidence/verifyTimestamp',
    method: 'post',
    data
  })
}

export function getTimestampDetail(params) {
  return request({
    url: '/evidence/getTimestampDetail',
    method: 'get',
    params
  })
}

// 存证配置相关
export function getEvidenceConfig() {
  return request({
    url: '/evidence/getEvidenceConfig',
    method: 'get'
  })
}

export function saveEvidenceConfig(data) {
  return request({
    url: '/evidence/saveEvidenceConfig',
    method: 'post',
    data
  })
}

export function getChainList() {
  return request({
    url: '/evidence/getChainList',
    method: 'get'
  })
}

// 存证导出相关
export function exportEvidence(data) {
  return request({
    url: '/evidence/exportEvidence',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

export function encryptExport(data) {
  return request({
    url: '/evidence/encryptExport',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

export function getExportHistory(params) {
  return request({
    url: '/evidence/getExportHistory',
    method: 'get',
    params
  })
}

// 存证接口对接相关
export function getApiList() {
  return request({
    url: '/evidence/getApiList',
    method: 'get'
  })
}

export function getApiKey(params) {
  return request({
    url: '/evidence/getApiKey',
    method: 'get',
    params
  })
}

export function regenerateApiKey(data) {
  return request({
    url: '/evidence/regenerateApiKey',
    method: 'post',
    data
  })
}

export function getApiCallLog(params) {
  return request({
    url: '/evidence/getApiCallLog',
    method: 'get',
    params
  })
}

export function testApiConnection(data) {
  return request({
    url: '/evidence/testApiConnection',
    method: 'post',
    data
  })
}
