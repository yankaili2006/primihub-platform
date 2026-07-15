import request from '@/utils/request'
export function getAccessPartyList() { return request({ url: '/accessParty/getList', method: 'get' }) }
export function saveAccessParty(data) { return request({ url: '/accessParty/save', method: 'post', data }) }
export function deleteAccessParty(params) { return request({ url: '/accessParty/delete', method: 'get', params }) }