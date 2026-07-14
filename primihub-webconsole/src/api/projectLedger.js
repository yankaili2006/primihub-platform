import request from '@/utils/request'

// ========== 项目台账管理 APIs ==========

/**
 * 查询项目台账分页列表
 */
export function findProjectLedgerPage(params) {
  return request({
    url: '/project/ledger/findPage',
    method: 'get',
    params
  })
}

/**
 * 获取项目台账详情
 */
export function getProjectLedgerDetail(projectId) {
  return request({
    url: '/project/ledger/getDetail',
    method: 'get',
    params: { projectId }
  })
}

/**
 * 导出单个项目台账
 */
export function exportProjectLedger(data) {
  return request({
    url: '/project/ledger/export',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 批量导出项目台账
 */
export function batchExportProjectLedger(data) {
  return request({
    url: '/project/ledger/batchExport',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 导出全部项目台账
 */
export function exportAllProjectLedger(data) {
  return request({
    url: '/project/ledger/exportAll',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 获取导出历史记录
 */
export function getExportHistory() {
  return request({
    url: '/project/ledger/getExportHistory',
    method: 'get'
  })
}

/**
 * 下载导出文件
 */
export function downloadExportFile(exportId) {
  return request({
    url: '/project/ledger/downloadExportFile',
    method: 'get',
    params: { exportId },
    responseType: 'blob'
  })
}

/**
 * 重试导出
 */
export function retryExport(exportId) {
  return request({
    url: '/project/ledger/retryExport',
    method: 'post',
    params: { exportId }
  })
}
