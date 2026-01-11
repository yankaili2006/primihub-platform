import request from '@/utils/request'

// 获取系统配置
export function getSystemConfig(params) {
  return request({
    url: '/systemConfig/getSystemConfig',
    method: 'get',
    params
  })
}

// 保存系统配置
export function saveSystemConfig(data) {
  return request({
    url: '/systemConfig/saveSystemConfig',
    method: 'post',
    data
  })
}

// 获取网络地址配置
export function getNetworkConfig(params) {
  return request({
    url: '/systemConfig/getNetworkConfig',
    method: 'get',
    params
  })
}

// 保存网络地址配置
export function saveNetworkConfig(data) {
  return request({
    url: '/systemConfig/saveNetworkConfig',
    method: 'post',
    data
  })
}

// 获取时间配置
export function getTimeConfig(params) {
  return request({
    url: '/systemConfig/getTimeConfig',
    method: 'get',
    params
  })
}

// 保存时间配置
export function saveTimeConfig(data) {
  return request({
    url: '/systemConfig/saveTimeConfig',
    method: 'post',
    data
  })
}

// 获取登录限制配置
export function getLoginRestriction(params) {
  return request({
    url: '/systemConfig/getLoginRestriction',
    method: 'get',
    params
  })
}

// 保存登录限制配置
export function saveLoginRestriction(data) {
  return request({
    url: '/systemConfig/saveLoginRestriction',
    method: 'post',
    data
  })
}

// 获取平台个性化配置
export function getPersonalizationConfig(params) {
  return request({
    url: '/systemConfig/getPersonalizationConfig',
    method: 'get',
    params
  })
}

// 保存平台个性化配置
export function savePersonalizationConfig(data) {
  return request({
    url: '/systemConfig/savePersonalizationConfig',
    method: 'post',
    data
  })
}

// 获取FTP配置
export function getFtpConfig(params) {
  return request({
    url: '/systemConfig/getFtpConfig',
    method: 'get',
    params
  })
}

// 保存FTP配置
export function saveFtpConfig(data) {
  return request({
    url: '/systemConfig/saveFtpConfig',
    method: 'post',
    data
  })
}

// 测试FTP连接
export function testFtpConnection(data) {
  return request({
    url: '/systemConfig/testFtpConnection',
    method: 'post',
    data
  })
}
