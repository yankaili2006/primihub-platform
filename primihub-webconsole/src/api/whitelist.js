import request from '@/utils/request'

// 白名单列表相关
export function getWhitelistPage(params) {
  return request({
    url: '/whitelist/findWhitelistPage',
    method: 'get',
    params
  })
}

export function addWhitelist(data) {
  return request({
    url: '/whitelist/addWhitelist',
    method: 'post',
    type: 'json',
    data
  })
}

export function updateWhitelist(data) {
  return request({
    url: '/whitelist/updateWhitelist',
    method: 'post',
    type: 'json',
    data
  })
}

export function deleteWhitelist(data) {
  return request({
    url: '/whitelist/deleteWhitelist',
    method: 'post',
    data
  })
}

export function getWhitelistDetail(params) {
  return request({
    url: '/whitelist/getWhitelistDetail',
    method: 'get',
    params
  })
}

// 白名单配置相关
export function getWhitelistConfigList(params) {
  return request({
    url: '/whitelist/findWhitelistConfigList',
    method: 'get',
    params
  })
}

export function saveWhitelistConfig(data) {
  return request({
    url: '/whitelist/saveWhitelistConfig',
    method: 'post',
    data
  })
}

export function getWhitelistConfigDetail(params) {
  return request({
    url: '/whitelist/getWhitelistConfigDetail',
    method: 'get',
    params
  })
}

// 白名单访问日志相关
export function getWhitelistAccessLogPage(params) {
  return request({
    url: '/whitelist/findWhitelistAccessLogPage',
    method: 'get',
    params
  })
}

export function getWhitelistAccessLogDetail(params) {
  return request({
    url: '/whitelist/getWhitelistAccessLogDetail',
    method: 'get',
    params
  })
}

export function getWhitelistAccessStatistics(params) {
  return request({
    url: '/whitelist/getWhitelistAccessStatistics',
    method: 'get',
    params
  })
}

// 批量删除访问日志
export function batchDeleteAccessLog(data) {
  return request({
    url: '/whitelist/batchDeleteAccessLog',
    method: 'post',
    data
  })
}

// 清理过期日志
export function cleanExpiredLogs(data) {
  return request({
    url: '/whitelist/cleanExpiredLogs',
    method: 'post',
    data
  })
}

// 导出访问日志
export function exportAccessLog(params) {
  return request({
    url: '/whitelist/exportAccessLog',
    method: 'get',
    params
  })
}

// 获取访问趋势
export function getAccessTrend(params) {
  return request({
    url: '/whitelist/getAccessTrend',
    method: 'get',
    params
  })
}

// 获取IP访问排行
export function getTopAccessIps(params) {
  return request({
    url: '/whitelist/getTopAccessIps',
    method: 'get',
    params
  })
}

// 获取URL访问排行
export function getTopAccessUrls(params) {
  return request({
    url: '/whitelist/getTopAccessUrls',
    method: 'get',
    params
  })
}

// 获取访问详细统计
export function getAccessDetailStatistics(params) {
  return request({
    url: '/whitelist/getAccessDetailStatistics',
    method: 'get',
    params
  })
}
