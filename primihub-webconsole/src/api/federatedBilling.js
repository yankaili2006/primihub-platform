import request from '@/utils/request'

// ==================== 联邦查询计费 - 规则管理 ====================

export function getBillingRuleList(params) {
  return request({ url: '/federatedBilling/rule/list', method: 'get', params })
}

export function createBillingRule(data) {
  return request({ url: '/federatedBilling/rule/create', method: 'post', type: 'json', data })
}

export function updateBillingRule(data) {
  return request({ url: '/federatedBilling/rule/update', method: 'post', type: 'json', data })
}

export function deleteBillingRule(data) {
  return request({ url: '/federatedBilling/rule/delete', method: 'post', type: 'json', data })
}

export function toggleBillingRule(data) {
  return request({ url: '/federatedBilling/rule/toggle', method: 'post', type: 'json', data })
}

export function getBillingRuleDetail(params) {
  return request({ url: '/federatedBilling/rule/detail', method: 'get', params })
}

// ==================== 联邦查询计费 - 记录管理 ====================

export function getBillingRecordList(params) {
  return request({ url: '/federatedBilling/record/list', method: 'get', params })
}

export function getBillingStatistics(params) {
  return request({ url: '/federatedBilling/record/statistics', method: 'get', params })
}

export function exportBillingRecords(data) {
  return request({ url: '/federatedBilling/record/export', method: 'post', type: 'json', data, responseType: 'blob' })
}
