import request from '@/utils/request'

// ========== 取消合作管理 APIs ==========

/**
 * 查询取消合作历史记录分页列表
 */
export function findCancelCooperationHistory(params) {
  return request({
    url: '/node/cooperation/findCancelHistory',
    method: 'get',
    params
  })
}

/**
 * 批量取消合作
 */
export function batchCancelCooperation(ids, reason) {
  return request({
    url: '/node/cooperation/batchCancel',
    method: 'post',
    data: ids,
    params: { reason }
  })
}

/**
 * 根据ID获取取消记录详情
 */
export function getCancelRecordById(id) {
  return request({
    url: '/node/cooperation/getCancelRecordById',
    method: 'get',
    params: { id }
  })
}

/**
 * 导出取消记录
 */
export function exportCancelRecords(params) {
  return request({
    url: '/node/cooperation/exportCancelRecords',
    method: 'get',
    params,
    responseType: 'blob'
  })
}
