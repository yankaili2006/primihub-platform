import request from '@/utils/request'

export function getOperationLogPage(data) {
  return request({
    url: '/sys/operationLog/getOperationLogPage',
    method: 'post', type: 'json',
    data
  })
}

export function getOperationLogDetail(logId) {
  return request({
    url: '/sys/operationLog/getOperationLogDetail',
    method: 'get',
    params: { logId }
  })
}

export function deleteOperationLog(logId) {
  return request({
    url: '/sys/operationLog/deleteOperationLog',
    method: 'delete',
    params: { logId }
  })
}

export function exportOperationLog(data) {
  return request({
    url: '/sys/operationLog/exportOperationLog',
    method: 'post', type: 'json',
    data,
    responseType: 'blob'
  })
}

export function getOperationLogStatistics(data) {
  return request({
    url: '/sys/operationLog/getOperationLogStatistics',
    method: 'post', type: 'json',
    data
  })
}
