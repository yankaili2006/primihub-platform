import request from '@/utils/request'

// ========== 项目权限管理 APIs ==========

/**
 * 查询项目权限分页列表
 */
export function findProjectPermissionPage(params) {
  return request({
    url: '/project/permission/findPage',
    method: 'get',
    params
  })
}

/**
 * 新增项目权限配置
 */
export function addProjectPermission(data) {
  return request({
    url: '/project/permission/add',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 更新项目权限配置
 */
export function updateProjectPermission(data) {
  return request({
    url: '/project/permission/update',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 撤销项目权限
 */
export function revokeProjectPermission(id, userId, userName) {
  return request({
    url: '/project/permission/revoke',
    method: 'post',
    params: { id, userId, userName }
  })
}

/**
 * 批量撤销项目权限
 */
export function batchRevokeProjectPermission(ids, userId, userName) {
  return request({
    url: '/project/permission/batchRevoke',
    method: 'post',
    type: 'json',
    data: ids,
    params: { userId, userName }
  })
}

/**
 * 审批通过项目权限
 */
export function approveProjectPermission(id, userId, userName) {
  return request({
    url: '/project/permission/approve',
    method: 'post',
    params: { id, userId, userName }
  })
}

/**
 * 查询权限模板列表
 */
export function findPermissionTemplates() {
  return request({
    url: '/project/permission/findTemplates',
    method: 'get'
  })
}

/**
 * 新增权限模板
 */
export function addPermissionTemplate(data) {
  return request({
    url: '/project/permission/addTemplate',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 更新权限模板
 */
export function updatePermissionTemplate(data) {
  return request({
    url: '/project/permission/updateTemplate',
    method: 'post',
    type: 'json',
    data
  })
}

/**
 * 删除权限模板
 */
export function deletePermissionTemplate(id) {
  return request({
    url: '/project/permission/deleteTemplate',
    method: 'post',
    params: { id }
  })
}
