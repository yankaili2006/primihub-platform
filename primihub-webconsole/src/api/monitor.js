import request from '@/utils/request'

// 获取系统监控数据
export function getSystemMonitor(params) {
  return request({
    url: '/monitor/getSystemMonitor',
    method: 'get',
    params
  })
}

// 获取CPU监控数据
export function getCpuMonitor(params) {
  return request({
    url: '/monitor/getCpuMonitor',
    method: 'get',
    params
  })
}

// 获取内存监控数据
export function getMemoryMonitor(params) {
  return request({
    url: '/monitor/getMemoryMonitor',
    method: 'get',
    params
  })
}

// 获取磁盘监控数据
export function getDiskMonitor(params) {
  return request({
    url: '/monitor/getDiskMonitor',
    method: 'get',
    params
  })
}

// 获取数据库监控数据
export function getDatabaseMonitor(params) {
  return request({
    url: '/monitor/getDatabaseMonitor',
    method: 'get',
    params
  })
}

// 获取JVM监控数据
export function getJvmMonitor(params) {
  return request({
    url: '/monitor/getJvmMonitor',
    method: 'get',
    params
  })
}

// 获取Redis监控数据
export function getRedisMonitor(params) {
  return request({
    url: '/monitor/getRedisMonitor',
    method: 'get',
    params
  })
}

// 获取监控历史数据
export function getMonitorHistory(params) {
  return request({
    url: '/monitor/getMonitorHistory',
    method: 'get',
    params
  })
}

// 获取告警配置
export function getAlertConfig(params) {
  return request({
    url: '/monitor/getAlertConfig',
    method: 'get',
    params
  })
}

// 保存告警配置
export function saveAlertConfig(data) {
  return request({
    url: '/monitor/saveAlertConfig',
    method: 'post',
    data
  })
}

// 获取告警历史
export function getAlertHistory(params) {
  return request({
    url: '/monitor/getAlertHistory',
    method: 'get',
    params
  })
}

// 处理告警
export function handleAlert(data) {
  return request({
    url: '/monitor/handleAlert',
    method: 'post',
    data
  })
}

// 获取监控统计数据
export function getMonitorStatistics(params) {
  return request({
    url: '/monitor/getMonitorStatistics',
    method: 'get',
    params
  })
}
