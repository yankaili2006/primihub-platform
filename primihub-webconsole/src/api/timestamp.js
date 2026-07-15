import request from '@/utils/request'

export function getTimestampPage(params) {
  return request({
    url: '/timestamp/findTimestampPage',
    method: 'get',
    params
  })
}

export function applyTimestamp(data) {
  return request({
    url: '/timestamp/applyTimestamp',
    method: 'post',
    data
  })
}

export function submitTimestamp(params) {
  return request({
    url: '/timestamp/submitTimestamp',
    method: 'get',
    params
  })
}

export function deleteTimestamp(params) {
  return request({
    url: '/timestamp/deleteTimestamp',
    method: 'get',
    params
  })
}

export function getTimestampDetail(params) {
  return request({
    url: '/timestamp/getTimestampDetail',
    method: 'get',
    params
  })
}