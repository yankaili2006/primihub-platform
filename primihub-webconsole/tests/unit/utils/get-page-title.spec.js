import getPageTitle from '@/utils/get-page-title.js'

jest.mock('@/settings', () => ({
  __esModule: true,
  default: { title: '隐私计算平台' }
}))

describe('Utils:getPageTitle', () => {
  it('returns default title when no page title', () => {
    expect(getPageTitle()).toBe('隐私计算平台')
  })

  it('returns default title when page title is empty', () => {
    expect(getPageTitle('')).toBe('隐私计算平台')
  })

  it('returns combined title when page title is provided', () => {
    expect(getPageTitle('登录')).toBe('登录 - 隐私计算平台')
  })

  it('returns combined title with chinese', () => {
    expect(getPageTitle('联邦学习')).toBe('联邦学习 - 隐私计算平台')
  })

  it('returns combined title with special chars', () => {
    expect(getPageTitle('接口管理 >> 接口日志')).toBe('接口管理 >> 接口日志 - 隐私计算平台')
  })
})