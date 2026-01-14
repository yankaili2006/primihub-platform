import request from '@/utils/request'

export function getPirTaskDetail(params) {
  return request({
    url: '/data/pir/getPirTaskDetail',
    method: 'get',
    params,
    showLoading: false
  })
}
export function getPirTaskList(params) {
  return request({
    url: '/data/pir/getPirTaskList',
    method: 'get',
    params,
    showLoading: false
  })
}
export function pirSubmitTask(data) {
  return request({
    url: '/data/pir/pirSubmitTask',
    method: 'post',
    data
  })
}

// 导出PIR日志
export function exportPirLog(params) {
  return request({
    url: '/log/exportComputeLog',
    method: 'get',
    params: {
      ...params,
      computeType: 'pir'
    },
    responseType: 'blob'
  })
}
