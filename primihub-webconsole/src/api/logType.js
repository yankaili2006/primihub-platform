import request from '@/utils/request'

export function getLogTypeList() {
  return request({
    url: '/logType/getLogTypeList',
    method: 'get'
  })
}

export function saveLogType(data) {
  return request({
    url: '/logType/saveLogType',
    method: 'post',
    data
  })
}

export function deleteLogType(params) {
  return request({
    url: '/logType/deleteLogType',
    method: 'get',
    params
  })
}