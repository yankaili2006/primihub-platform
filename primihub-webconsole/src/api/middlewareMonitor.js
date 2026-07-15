import request from '@/utils/request'
export function getMiddlewareMonitorList() { return request({ url: '/middlewareMonitor/getList', method: 'get' }) }
export function saveMiddlewareMonitor(data) { return request({ url: '/middlewareMonitor/save', method: 'post', data }) }
export function deleteMiddlewareMonitor(params) { return request({ url: '/middlewareMonitor/delete', method: 'get', params }) }