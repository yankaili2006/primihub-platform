/**
 * 可信空间 API 单元测试：断言每个封装都以正确的 url/method/type 调 request。
 */
import {
  getTrustedSpacePage,
  getTrustedSpaceList,
  getTrustedSpaceDetail,
  saveTrustedSpace,
  updateTrustedSpace,
  deleteTrustedSpace,
  assignTrustedSpaceResources,
  removeTrustedSpaceResources,
  getTrustedSpaceResources
} from '@/api/trustedSpace'

const calls = []
jest.mock('@/utils/request', () => {
  return {
    __esModule: true,
    default: (config) => {
      calls.push(config)
      return Promise.resolve({ code: 0, result: {}})
    }
  }
})

describe('API:trustedSpace', () => {
  beforeEach(() => { calls.length = 0 })

  it('getTrustedSpacePage GET /data/trustedSpace/page with params', async() => {
    await getTrustedSpacePage({ pageNo: 1, pageSize: 10 })
    expect(calls[0]).toMatchObject({ url: '/data/trustedSpace/page', method: 'get', params: { pageNo: 1, pageSize: 10 }})
  })

  it('getTrustedSpaceList GET /data/trustedSpace/listAll', async() => {
    await getTrustedSpaceList()
    expect(calls[0]).toMatchObject({ url: '/data/trustedSpace/listAll', method: 'get' })
  })

  it('getTrustedSpaceDetail passes spaceId', async() => {
    await getTrustedSpaceDetail({ spaceId: 1002 })
    expect(calls[0]).toMatchObject({ url: '/data/trustedSpace/detail', params: { spaceId: 1002 }})
  })

  it('save/update/assign/remove are JSON posts', async() => {
    await saveTrustedSpace({ spaceName: '水利' })
    await updateTrustedSpace({ spaceId: 1002, spaceName: '水利' })
    await assignTrustedSpaceResources({ spaceId: 1002, resourceIds: [1, 2] })
    await removeTrustedSpaceResources({ spaceId: 1002, resourceIds: [1] })
    expect(calls.map(c => c.url)).toEqual([
      '/data/trustedSpace/save',
      '/data/trustedSpace/update',
      '/data/trustedSpace/assignResources',
      '/data/trustedSpace/removeResources'
    ])
    calls.forEach(c => {
      expect(c.method).toBe('post')
      expect(c.type).toBe('json')
      expect(c.data).toBeDefined()
    })
  })

  it('deleteTrustedSpace posts spaceId as query param (not JSON body)', async() => {
    await deleteTrustedSpace({ spaceId: 1002 })
    expect(calls[0]).toMatchObject({ url: '/data/trustedSpace/delete', method: 'post', params: { spaceId: 1002 }})
    expect(calls[0].type).toBeUndefined()
  })

  it('getTrustedSpaceResources GET with paging', async() => {
    await getTrustedSpaceResources({ spaceId: 1002, pageNo: 1, pageSize: 10 })
    expect(calls[0]).toMatchObject({ url: '/data/trustedSpace/resources', method: 'get', params: { spaceId: 1002 }})
  })
})
