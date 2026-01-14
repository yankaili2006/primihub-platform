import request from '@/utils/request'

// ========== 联邦学习相关接口 ==========

/**
 * 创建并运行联邦学习任务
 */
export function createTask(data) {
  return request({
    url: '/federatedLearning/createTask',
    method: 'post',
    data
  })
}

/**
 * 查询联邦学习任务列表
 */
export function getTaskList(params) {
  return request({
    url: '/federatedLearning/getTaskList',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 查询联邦学习任务详情
 */
export function getTaskDetails(params) {
  return request({
    url: '/federatedLearning/getTaskDetails',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 查询模型列表
 */
export function getModelList(params) {
  return request({
    url: '/federatedLearning/getModelList',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 下载模型文件
 */
export function downloadModel(params) {
  return request({
    url: '/federatedLearning/downloadModel',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

/**
 * 下载预测结果
 */
export function downloadResult(params) {
  return request({
    url: '/federatedLearning/downloadResult',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

/**
 * 删除任务
 */
export function deleteTask(params) {
  return request({
    url: '/federatedLearning/deleteTask',
    method: 'get',
    params
  })
}

/**
 * 取消任务
 */
export function cancelTask(params) {
  return request({
    url: '/federatedLearning/cancelTask',
    method: 'get',
    params
  })
}

/**
 * 获取训练进度
 */
export function getTrainingProgress(params) {
  return request({
    url: '/federatedLearning/getTrainingProgress',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 导出联邦学习日志
 */
export function exportFederatedLearningLog(params) {
  return request({
    url: '/log/exportComputeLog',
    method: 'get',
    params: {
      ...params,
      computeType: '联邦学习'
    },
    responseType: 'blob'
  })
}
