import request from '@/utils/request'
export function getMonitorConfigList() { return request({ url: '/monitorConfig/getList', method: 'get' }) }
export function saveMonitorConfig(data) { return request({ url: '/monitorConfig/save', method: 'post', data }) }
export function deleteMonitorConfig(params) { return request({ url: '/monitorConfig/delete', method: 'get', params }) }