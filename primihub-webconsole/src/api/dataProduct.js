import request from '@/utils/request'

// ==================== 数据产品需求 ====================

export function getDemandList(params) {
  return request({
    url: '/api/v2/service/demand/list',
    method: 'get',
    params
  })
}

export function getDemandById(id) {
  return request({
    url: `/api/v2/service/demand/${id}`,
    method: 'get'
  })
}

export function createDemand(data) {
  return request({
    url: '/api/v2/service/demand',
    method: 'post',
    type: 'json',
    data
  })
}

export function updateDemand(id, data) {
  return request({
    url: `/api/v2/service/demand/${id}`,
    method: 'put',
    data
  })
}

export function deleteDemand(id) {
  return request({
    url: `/api/v2/service/demand/${id}`,
    method: 'delete'
  })
}

export function getDemandStats(params) {
  return request({
    url: '/api/v2/service/demand/stats',
    method: 'get',
    params
  })
}

// ==================== 数据产品供给 ====================

export function getSupplyList(params) {
  return request({
    url: '/api/v2/service/supply/list',
    method: 'get',
    params
  })
}

export function getSupplyById(id) {
  return request({
    url: `/api/v2/service/supply/${id}`,
    method: 'get'
  })
}

export function createSupply(data) {
  return request({
    url: '/api/v2/service/supply',
    method: 'post',
    type: 'json',
    data
  })
}

export function updateSupply(id, data) {
  return request({
    url: `/api/v2/service/supply/${id}`,
    method: 'put',
    data
  })
}

export function deleteSupply(id) {
  return request({
    url: `/api/v2/service/supply/${id}`,
    method: 'delete'
  })
}

export function getSupplyStats(params) {
  return request({
    url: '/api/v2/service/supply/stats',
    method: 'get',
    params
  })
}
