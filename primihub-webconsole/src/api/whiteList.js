import request from '@/utils/request'

export function getWhiteListPage(params) {
  return request({
    url: '/whiteList/findWhiteListPage',
    method: 'get',
    params
  })
}

export function saveWhiteList(data) {
  return request({
    url: '/whiteList/saveWhiteList',
    method: 'post',
    data
  })
}

export function updateWhiteList(data) {
  return request({
    url: '/whiteList/updateWhiteList',
    method: 'post',
    data
  })
}

export function deleteWhiteList(params) {
  return request({
    url: '/whiteList/deleteWhiteList',
    method: 'get',
    params
  })
}

export function batchDeleteWhiteList(data) {
  return request({
    url: '/whiteList/batchDeleteWhiteList',
    method: 'post',
    data
  })
}

export function getWhiteListDetail(params) {
  return request({
    url: '/whiteList/getWhiteListDetail',
    method: 'get',
    params
  })
}