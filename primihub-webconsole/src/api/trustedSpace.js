import request from '@/utils/request'

// 可信空间：后端 TrustedSpaceController（/trustedSpace/*），经网关 /data 前缀转发

export function getTrustedSpacePage(params) {
  return request({
    url: '/data/trustedSpace/page',
    method: 'get',
    params
  })
}

export function getTrustedSpaceList() {
  return request({
    url: '/data/trustedSpace/listAll',
    method: 'get'
  })
}

export function getTrustedSpaceDetail(params) {
  return request({
    url: '/data/trustedSpace/detail',
    method: 'get',
    params
  })
}

export function saveTrustedSpace(data) {
  return request({
    url: '/data/trustedSpace/save',
    method: 'post',
    type: 'json',
    data
  })
}

export function updateTrustedSpace(data) {
  return request({
    url: '/data/trustedSpace/update',
    method: 'post',
    type: 'json',
    data
  })
}

export function deleteTrustedSpace(params) {
  return request({
    url: '/data/trustedSpace/delete',
    method: 'post',
    params
  })
}

export function assignTrustedSpaceResources(data) {
  return request({
    url: '/data/trustedSpace/assignResources',
    method: 'post',
    type: 'json',
    data
  })
}

export function removeTrustedSpaceResources(data) {
  return request({
    url: '/data/trustedSpace/removeResources',
    method: 'post',
    type: 'json',
    data
  })
}

export function getTrustedSpaceResources(params) {
  return request({
    url: '/data/trustedSpace/resources',
    method: 'get',
    params
  })
}
