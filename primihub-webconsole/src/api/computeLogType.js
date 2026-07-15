import request from '@/utils/request'
export function getComputeLogTypeList() { return request({ url: '/computeLogType/getList', method: 'get' }) }
export function saveComputeLogType(data) { return request({ url: '/computeLogType/save', method: 'post', data }) }
export function deleteComputeLogType(params) { return request({ url: '/computeLogType/delete', method: 'get', params }) }