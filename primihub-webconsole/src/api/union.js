import request from '@/utils/request'

// ========== 联邦求并相关接口 ==========

/**
 * 创建并运行联邦求并任务
 */
export function saveDataUnion(data) {
  return request({
    url: '/data/union/saveDataUnion',
    method: 'post',
    data
  })
}

/**
 * 查询联邦求并任务列表
 */
export function getUnionTaskList(params) {
  return request({
    url: '/data/union/getUnionTaskList',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 查询联邦求并任务详情
 */
export function getUnionTaskDetails(params) {
  return request({
    url: '/data/union/getUnionTaskDetails',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 下载联邦求并结果文件
 */
export function downloadUnionTask(params) {
  return request({
    url: '/data/union/downloadUnionTask',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

/**
 * 删除联邦求并任务
 */
export function delUnionTask(params) {
  return request({
    url: '/data/union/delUnionTask',
    method: 'get',
    params
  })
}

/**
 * 取消联邦求并任务
 */
export function cancelUnionTask(params) {
  return request({
    url: '/data/union/cancelUnionTask',
    method: 'get',
    params
  })
}

/**
 * 导出联邦求并日志
 */
export function exportUnionLog(params) {
  return request({
    url: '/log/exportComputeLog',
    method: 'get',
    params: {
      ...params,
      computeType: '联邦求并'
    },
    responseType: 'blob'
  })
}
