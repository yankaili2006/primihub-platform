import request from '@/utils/request'

export function createTask(data) {
  return request({
    url: '/singleParty/createTask',
    method: 'post',
    data
  })
}

export function getTaskList(params) {
  return request({
    url: '/singleParty/getTaskList',
    method: 'get',
    params,
    showLoading: false
  })
}

export function getTaskDetails(params) {
  return request({
    url: '/singleParty/getTaskDetails',
    method: 'get',
    params,
    showLoading: false
  })
}

export function downloadResult(params) {
  return request({
    url: '/singleParty/downloadResult',
    method: 'get',
    params,
    responseType: 'blob'
  })
}

export function deleteTask(params) {
  return request({
    url: '/singleParty/deleteTask',
    method: 'get',
    params
  })
}

export function cancelTask(params) {
  return request({
    url: '/singleParty/cancelTask',
    method: 'get',
    params
  })
}
