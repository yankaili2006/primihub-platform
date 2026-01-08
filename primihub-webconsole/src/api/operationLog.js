import request from '@/utils/request'

/**
 * 获取操作日志分页列表
 *
 * @param data 查询参数
 * @returns {Promise}
 */
export function getOperationLogPage(data) {
  return request({
    url: '/sys/operationLog/getOperationLogPage',
    method: 'post',
    data
  })
}

/**
 * 获取操作日志详情
 *
 * @param logId 日志ID
 * @returns {Promise}
 */
export function getOperationLogDetail(logId) {
  return request({
    url: '/sys/operationLog/getOperationLogDetail',
    method: 'get',
    params: { logId }
  })
}

/**
 * 删除操作日志
 *
 * @param logId 日志ID
 * @returns {Promise}
 */
export function deleteOperationLog(logId) {
  return request({
    url: '/sys/operationLog/deleteOperationLog',
    method: 'delete',
    params: { logId }
  })
}

/**
 * 导出操作日志
 *
 * @param data 查询参数
 * @returns {Promise}
 */
export function exportOperationLog(data) {
  return request({
    url: '/sys/operationLog/exportOperationLog',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

/**
 * 获取操作日志统计
 *
 * @param data 查询参数
 * @returns {Promise}
 */
export function getOperationLogStatistics(data) {
  return request({
    url: '/sys/operationLog/getOperationLogStatistics',
    method: 'post',
    data
  })
}
