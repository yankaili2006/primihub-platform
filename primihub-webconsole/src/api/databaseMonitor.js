import request from '@/utils/request'
export function getDatabaseMonitorList() { return request({ url: '/databaseMonitor/getList', method: 'get' }) }
export function saveDatabaseMonitor(data) { return request({ url: '/databaseMonitor/save', method: 'post', data }) }
export function deleteDatabaseMonitor(params) { return request({ url: '/databaseMonitor/delete', method: 'get', params }) }