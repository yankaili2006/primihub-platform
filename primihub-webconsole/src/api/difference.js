import request from '@/utils/request'

// ========== 联邦求差相关接口 ==========

/**
 * 创建并运行联邦求差任务
 */
export function saveDataDifference(data) {
  return request({
    url: '/data/difference/saveDataDifference',
    method: 'post', type: 'json',
    data
  })
}

/**
 * 查询联邦求差任务列表
 */
export function getDifferenceTaskList(params) {
  return request({
    url: '/data/difference/getDifferenceTaskList',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 查询联邦求差任务详情
 */
export function getDifferenceTaskDetails(params) {
  return request({
    url: '/data/difference/getDifferenceTaskDetails',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 下载联邦求差结果文件
 */
export function downloadDifferenceTask(params) {
  return request({
    url: '/data/difference/downloadDifferenceTask',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

/**
 * 删除联邦求差任务
 */
export function delDifferenceTask(params) {
  return request({
    url: '/data/difference/delDifferenceTask',
    method: 'get',
    params
  })
}

/**
 * 取消联邦求差任务
 */
export function cancelDifferenceTask(params) {
  return request({
    url: '/data/difference/cancelDifferenceTask',
    method: 'get',
    params
  })
}

/**
 * 导出联邦求差日志
 */
export function exportDifferenceLog(params) {
  return request({
    url: '/log/exportComputeLog',
    method: 'get',
    params: {
      ...params,
      computeType: '联邦求差'
    },
    responseType: 'blob'
  })
}
