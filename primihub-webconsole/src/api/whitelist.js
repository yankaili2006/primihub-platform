import request from '@/utils/request'

/**
 * 获取白名单分页列表
 *
 * @param params 查询参数
 * @returns {Promise}
 */
export function getWhitelistPage(params) {
  return request({
    url: '/sys/whitelist/findWhitelistPage',
    method: 'get',
    params
  })
}

/**
 * 新增或更新白名单
 *
 * @param data 白名单数据
 * @returns {Promise}
 */
export function saveOrUpdateWhitelist(data) {
  return request({
    url: '/sys/whitelist/saveOrUpdateWhitelist',
    method: 'post',
    data
  })
}

/**
 * 删除白名单
 *
 * @param whitelistId 白名单ID
 * @returns {Promise}
 */
export function deleteWhitelist(whitelistId) {
  return request({
    url: '/sys/whitelist/deleteWhitelist',
    method: 'post',
    params: { whitelistId }
  })
}
