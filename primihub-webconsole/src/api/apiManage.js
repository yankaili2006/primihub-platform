import request from '@/utils/request'

// 获取接口列表（分页）
export function getApiPage(params) {
  return request({
    url: '/apiManage/findApiPage',
    method: 'get',
    params
  })
}

// 新增接口
export function addApi(data) {
  return request({
    url: '/apiManage/addApi',
    method: 'post',
    data
  })
}

// 更新接口
export function updateApi(data) {
  return request({
    url: '/apiManage/updateApi',
    method: 'post',
    data
  })
}

// 删除接口
export function deleteApi(data) {
  return request({
    url: '/apiManage/deleteApi',
    method: 'post',
    data
  })
}

// 批量删除接口
export function batchDeleteApi(data) {
  return request({
    url: '/apiManage/batchDeleteApi',
    method: 'post',
    data
  })
}

// 获取接口详情
export function getApiDetail(params) {
  return request({
    url: '/apiManage/getApiDetail',
    method: 'get',
    params
  })
}

// 启用/禁用接口
export function toggleApiStatus(data) {
  return request({
    url: '/apiManage/toggleApiStatus',
    method: 'post',
    data
  })
}

// 获取接口授权列表（分页）
export function getApiAuthPage(params) {
  return request({
    url: '/apiManage/findApiAuthPage',
    method: 'get',
    params
  })
}

// 新增接口授权
export function addApiAuth(data) {
  return request({
    url: '/apiManage/addApiAuth',
    method: 'post',
    data
  })
}

// 更新接口授权
export function updateApiAuth(data) {
  return request({
    url: '/apiManage/updateApiAuth',
    method: 'post',
    data
  })
}

// 删除接口授权
export function deleteApiAuth(data) {
  return request({
    url: '/apiManage/deleteApiAuth',
    method: 'post',
    data
  })
}

// 校验接口授权
export function validateApiAuth(data) {
  return request({
    url: '/apiManage/validateApiAuth',
    method: 'post',
    data
  })
}

// 获取授权令牌
export function getAuthToken(data) {
  return request({
    url: '/apiManage/getAuthToken',
    method: 'post',
    data
  })
}

// 刷新授权令牌
export function refreshAuthToken(data) {
  return request({
    url: '/apiManage/refreshAuthToken',
    method: 'post',
    data
  })
}

// 获取接口日志列表（分页）
export function getApiLogPage(params) {
  return request({
    url: '/apiManage/findApiLogPage',
    method: 'get',
    params
  })
}

// 获取接口日志详情
export function getApiLogDetail(params) {
  return request({
    url: '/apiManage/getApiLogDetail',
    method: 'get',
    params
  })
}

// 获取接口调用统计
export function getApiStatistics(params) {
  return request({
    url: '/apiManage/getApiStatistics',
    method: 'get',
    params
  })
}

// 导出接口日志
export function exportApiLog(params) {
  return request({
    url: '/apiManage/exportApiLog',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

// 清空接口日志
export function clearApiLog(data) {
  return request({
    url: '/apiManage/clearApiLog',
    method: 'post',
    data
  })
}
