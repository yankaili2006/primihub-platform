// 后端 algorithmType（int）↔ 展示名。纵向：9=线性 5=逻辑 2=XGBoost，3=横向LR
// （FederatedLearningService.mapModelType）。任务状态词汇：0待运行 1成功 2运行中 3失败。
export const ALGORITHM_LABELS = { 9: '线性回归', 5: '逻辑回归', 2: 'XGBoost', 3: '横向LR' }
export const ALGORITHM_TAGS = { 9: 'info', 5: 'success', 2: 'warning', 3: '' }

// 供任务下拉选择器复用：按状态拉一页任务（组件自足，不依赖父级共享数据）
import { getTaskList } from '@/api/federatedLearning'
export async function fetchTaskOptions({ projectId = null, taskState = null, pageSize = 100 } = {}) {
  const params = { pageNo: 1, pageSize }
  if (projectId != null && projectId !== '') params.projectId = projectId
  if (taskState != null) params.taskState = taskState
  const res = await getTaskList(params)
  if (res && res.code === 0 && res.result) return res.result.data || res.result.list || []
  return []
}
