import request from '@/utils/request'

// ========== 项目结果保存 APIs ==========

/**
 * 查询项目结果分页列表
 */
export function findProjectResultPage(params) {
  return request({
    url: '/project/result/findPage',
    method: 'get',
    params
  })
}

/**
 * 保存项目结果
 */
export function saveProjectResult(data) {
  return request({
    url: '/project/result/save',
    method: 'post',
    data
  })
}

/**
 * 批量保存项目结果
 */
export function batchSaveProjectResult(ids) {
  return request({
    url: '/project/result/batchSave',
    method: 'post',
    data: ids
  })
}

/**
 * 删除项目结果
 */
export function deleteProjectResult(id) {
  return request({
    url: '/project/result/delete',
    method: 'post',
    params: { id }
  })
}

/**
 * 批量删除项目结果
 */
export function batchDeleteProjectResult(ids) {
  return request({
    url: '/project/result/batchDelete',
    method: 'post',
    data: ids
  })
}

/**
 * 下载项目结果
 */
export function downloadProjectResult(id) {
  return request({
    url: '/project/result/download',
    method: 'get',
    params: { id },
    responseType: 'blob'
  })
}

/**
 * 获取结果保存配置
 */
export function getResultConfig() {
  return request({
    url: '/project/result/getConfig',
    method: 'get'
  })
}

/**
 * 更新结果保存配置
 */
export function updateResultConfig(data) {
  return request({
    url: '/project/result/updateConfig',
    method: 'post',
    data
  })
}
