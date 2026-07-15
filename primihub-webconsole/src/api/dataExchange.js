import request from '@/utils/request'
export function getExchangeLogList() { return request({ url: '/dataExchange/getList', method: 'get' }) }
export function triggerSync(data) { return request({ url: '/dataExchange/triggerSync', method: 'post', data }) }
export function deleteExchangeLog(params) { return request({ url: '/dataExchange/delete', method: 'get', params }) }