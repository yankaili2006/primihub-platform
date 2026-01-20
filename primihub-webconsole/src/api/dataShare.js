import request from '@/utils/request'

// ========== 共享数据集 CRUD ==========

/**
 * 查询共享数据集分页列表
 */
export function findSharedDatasetPage(params) {
  return request({
    url: '/sharedDataset/findSharedDatasetPage',
    method: 'get',
    params
  })
}

/**
 * 根据ID查询共享数据集
 */
export function getSharedDatasetById(id) {
  return request({
    url: '/sharedDataset/getSharedDatasetById',
    method: 'get',
    params: { id }
  })
}

/**
 * 添加共享数据集
 */
export function addSharedDataset(data) {
  return request({
    url: '/sharedDataset/addSharedDataset',
    method: 'post',
    data
  })
}

/**
 * 更新共享数据集
 */
export function updateSharedDataset(data) {
  return request({
    url: '/sharedDataset/updateSharedDataset',
    method: 'post',
    data
  })
}

/**
 * 删除共享数据集
 */
export function deleteSharedDataset(id) {
  return request({
    url: '/sharedDataset/deleteSharedDataset',
    method: 'post',
    params: { id }
  })
}

/**
 * 批量删除共享数据集
 */
export function batchDeleteSharedDataset(ids) {
  return request({
    url: '/sharedDataset/batchDeleteSharedDataset',
    method: 'post',
    data: ids
  })
}

/**
 * 更新共享数据集状态
 */
export function updateSharedDatasetStatus(id, status) {
  return request({
    url: '/sharedDataset/updateSharedDatasetStatus',
    method: 'post',
    params: { id, status }
  })
}

/**
 * 获取可共享的资源列表
 */
export function getShareableResources(params) {
  return request({
    url: '/sharedDataset/getShareableResources',
    method: 'get',
    params
  })
}
