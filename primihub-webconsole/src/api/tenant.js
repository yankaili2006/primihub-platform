import request from '@/utils/request'

// 租户列表相关
export function getTenantPage(params) {
  return request({
    url: '/tenant/findTenantPage',
    method: 'get',
    params
  })
}

export function addTenant(data) {
  return request({
    url: '/tenant/addTenant',
    method: 'post',
    data
  })
}

export function updateTenant(data) {
  return request({
    url: '/tenant/updateTenant',
    method: 'post',
    data
  })
}

export function deleteTenant(data) {
  return request({
    url: '/tenant/deleteTenant',
    method: 'post',
    data
  })
}

export function freezeTenant(data) {
  return request({
    url: '/tenant/freezeTenant',
    method: 'post',
    data
  })
}

export function unfreezeTenant(data) {
  return request({
    url: '/tenant/unfreezeTenant',
    method: 'post',
    data
  })
}

export function getTenantDetail(params) {
  return request({
    url: '/tenant/getTenantDetail',
    method: 'get',
    params
  })
}

// 租户资源分配相关
export function getTenantResourceList(params) {
  return request({
    url: '/tenant/findTenantResourceList',
    method: 'get',
    params
  })
}

export function addTenantResource(data) {
  return request({
    url: '/tenant/addTenantResource',
    method: 'post',
    data
  })
}

export function deleteTenantResource(data) {
  return request({
    url: '/tenant/deleteTenantResource',
    method: 'post',
    data
  })
}

export function getAvailableResources(params) {
  return request({
    url: '/tenant/getAvailableResources',
    method: 'get',
    params
  })
}

// 租户隔离配置相关
export function getTenantIsolationConfig(params) {
  return request({
    url: '/tenant/getTenantIsolationConfig',
    method: 'get',
    params
  })
}

export function saveTenantIsolationConfig(data) {
  return request({
    url: '/tenant/saveTenantIsolationConfig',
    method: 'post',
    data
  })
}

// 租户统计相关
export function getTenantStatistics() {
  return request({
    url: '/tenant/getTenantStatistics',
    method: 'get'
  })
}
