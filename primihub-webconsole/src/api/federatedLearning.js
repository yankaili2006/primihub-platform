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

// ==================== 联邦建模工作台 ====================

/**
 * 获取工作台概览数据
 */
export function getWorkbenchOverview(params) {
  return request({
    url: '/federatedLearning/workbench/overview',
    method: 'get',
    params
  })
}

/**
 * 获取数据集列表
 */
export function getWorkbenchDatasets(params) {
  return request({
    url: '/federatedLearning/workbench/datasets',
    method: 'get',
    params
  })
}

/**
 * 获取特征列表
 */
export function getWorkbenchFeatures(params) {
  return request({
    url: '/federatedLearning/workbench/features',
    method: 'get',
    params
  })
}

/**
 * 保存特征配置
 */
export function saveFeatureConfig(data) {
  return request({
    url: '/federatedLearning/workbench/saveFeatures',
    method: 'post',
    data
  })
}

/**
 * 获取模型配置
 */
export function getModelConfig(params) {
  return request({
    url: '/federatedLearning/workbench/modelConfig',
    method: 'get',
    params
  })
}

/**
 * 保存模型配置
 */
export function saveModelConfig(data) {
  return request({
    url: '/federatedLearning/workbench/saveModelConfig',
    method: 'post',
    data
  })
}

// ==================== 参数调优 ====================

/**
 * 获取参数调优任务列表
 */
export function getParamTuningList(params) {
  return request({
    url: '/federatedLearning/paramTuning/list',
    method: 'get',
    params
  })
}

/**
 * 创建参数调优任务
 */
export function createParamTuning(data) {
  return request({
    url: '/federatedLearning/paramTuning/create',
    method: 'post',
    data
  })
}

/**
 * 获取参数调优结果
 */
export function getParamTuningResult(params) {
  return request({
    url: '/federatedLearning/paramTuning/result',
    method: 'get',
    params
  })
}

/**
 * 应用最优参数
 */
export function applyBestParams(data) {
  return request({
    url: '/federatedLearning/paramTuning/apply',
    method: 'post',
    data
  })
}

// ==================== 训练迭代 ====================

/**
 * 获取训练迭代数据
 */
export function getTrainingIterations(params) {
  return request({
    url: '/federatedLearning/training/iterations',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 获取实时训练指标
 */
export function getTrainingMetrics(params) {
  return request({
    url: '/federatedLearning/training/metrics',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 获取损失曲线数据
 */
export function getLossCurve(params) {
  return request({
    url: '/federatedLearning/training/lossCurve',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 获取精度曲线数据
 */
export function getAccuracyCurve(params) {
  return request({
    url: '/federatedLearning/training/accuracyCurve',
    method: 'get',
    params,
    showLoading: false
  })
}

// ==================== 训练报告 ====================

/**
 * 获取训练报告
 */
export function getTrainingReport(params) {
  return request({
    url: '/federatedLearning/report/detail',
    method: 'get',
    params
  })
}

/**
 * 生成训练报告
 */
export function generateTrainingReport(data) {
  return request({
    url: '/federatedLearning/report/generate',
    method: 'post',
    data
  })
}

/**
 * 导出训练报告
 */
export function exportTrainingReport(params) {
  return request({
    url: '/federatedLearning/report/export',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

/**
 * 获取模型评估指标
 */
export function getModelEvaluation(params) {
  return request({
    url: '/federatedLearning/report/evaluation',
    method: 'get',
    params
  })
}

/**
 * 获取特征重要性
 */
export function getFeatureImportance(params) {
  return request({
    url: '/federatedLearning/report/featureImportance',
    method: 'get',
    params
  })
}

// ==================== 日志管理 ====================

/**
 * 获取联邦学习日志列表
 */
export function getFederatedLearningLogs(params) {
  return request({
    url: '/federatedLearning/logs',
    method: 'get',
    params
  })
}

/**
 * 获取单个任务的日志
 */
export function getFederatedLearningTaskLogs(params) {
  return request({
    url: '/federatedLearning/taskLogs',
    method: 'get',
    params
  })
}

/**
 * 批量导出联邦学习日志
 */
export function batchExportFederatedLearningLogs(data) {
  return request({
    url: '/federatedLearning/batchExportLogs',
    method: 'post',
    data,
    responseType: 'blob'
  })
}

/**
 * 获取训练日志（实时）
 */
export function getTrainingLogs(params) {
  return request({
    url: '/federatedLearning/training/logs',
    method: 'get',
    params,
    showLoading: false
  })
}

// ==================== 联邦学习预处理 ====================

/**
 * 获取预处理任务列表
 */
export function getFLPreprocessList(params) {
  return request({
    url: '/federatedLearning/preprocess/list',
    method: 'get',
    params,
    showLoading: false
  })
}

/**
 * 创建预处理任务
 */
export function createFLPreprocess(data) {
  return request({
    url: '/federatedLearning/preprocess/create',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 执行预处理任务
 */
export function runFLPreprocess(data) {
  return request({
    url: '/federatedLearning/preprocess/run',
    method: 'post',
    data
  })
}

/**
 * 删除预处理任务
 */
export function deleteFLPreprocess(data) {
  return request({
    url: '/federatedLearning/preprocess/delete',
    method: 'post',
    data
  })
}

/**
 * 下载预处理结果
 */
export function downloadFLPreprocessResult(params) {
  return request({
    url: '/federatedLearning/preprocess/download',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// ==================== 建模工作台（真实后端，modelingWorkbench.vue 用）====================
export function flWorkbenchOverview() {
  return request({ url: '/federatedLearning/workbench/overview', method: 'get' })
}
export function flWorkbenchOptions(params) {
  return request({ url: '/federatedLearning/workbench/options', method: 'get', params })
}
export function flWorkflowList(params) {
  return request({ url: '/federatedLearning/workflow/list', method: 'get', params })
}
export function flWorkflowGet(workflowId) {
  return request({ url: '/federatedLearning/workflow/get', method: 'get', params: { workflowId } })
}
export function flWorkflowSave(data) {
  return request({ url: '/federatedLearning/workflow/save', method: 'post', type: 'json', data })
}
export function flWorkflowRun(data) {
  return request({ url: '/federatedLearning/workflow/run', method: 'post', type: 'json', data })
}
export function flWorkflowLogs(workflowId) {
  return request({ url: '/federatedLearning/workflow/logs', method: 'get', params: { workflowId } })
}
export function flWorkflowDelete(workflowId) {
  return request({ url: '/federatedLearning/workflow/delete', method: 'post', params: { workflowId } })
}
