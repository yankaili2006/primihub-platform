/**
 * 接口管理 API 单元测试
 */
import {
  getApiPage,
  addApi,
  updateApi,
  deleteApi,
  batchDeleteApi,
  getApiDetail,
  toggleApiStatus,
  getApiStatistics,
  getApiLogPage,
  getApiLogDetail,
  exportApiLog,
  clearApiLog,
  getApiAuthPage,
  addApiAuth,
  updateApiAuth,
  deleteApiAuth,
  validateApiAuth,
  refreshAuthToken
} from '@/api/apiManage'

jest.mock('@/utils/request', () => {
  const mockFn = (config) => Promise.resolve({ data: { code: 0, result: { list: [] } } })
  return {
    __esModule: true,
    default: mockFn
  }
})

describe('API:apiManage', () => {
  describe('API CRUD', () => {
    it('getApiPage fetches paginated list', async () => {
      const res = await getApiPage({ pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('addApi creates new API', async () => {
      const apiData = { apiName: 'test', method: 'GET', apiPath: '/test' }
      const res = await addApi(apiData)
      expect(res).toBeDefined()
    })

    it('updateApi updates existing API', async () => {
      const apiData = { id: 1, apiName: 'updated', apiPath: '/updated' }
      const res = await updateApi(apiData)
      expect(res).toBeDefined()
    })

    it('deleteApi deletes by id', async () => {
      const res = await deleteApi({ id: 1 })
      expect(res).toBeDefined()
    })

    it('batchDeleteApi deletes multiple', async () => {
      const res = await batchDeleteApi({ ids: [1, 2, 3] })
      expect(res).toBeDefined()
    })

    it('getApiDetail fetches detail', async () => {
      const res = await getApiDetail({ id: 1 })
      expect(res).toBeDefined()
    })

    it('toggleApiStatus toggles status', async () => {
      const res = await toggleApiStatus({ id: 1, status: 1 })
      expect(res).toBeDefined()
    })

    it('getApiStatistics returns stats', async () => {
      const res = await getApiStatistics()
      expect(res).toBeDefined()
    })
  })

  describe('API Log', () => {
    it('getApiLogPage fetches logs', async () => {
      const res = await getApiLogPage({ pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('getApiLogDetail fetches log detail', async () => {
      const res = await getApiLogDetail({ logId: 'LOG001' })
      expect(res).toBeDefined()
    })

    it('exportApiLog exports logs', async () => {
      const res = await exportApiLog({ keyword: 'test', startTime: '2024-01-01', endTime: '2024-12-31' })
      expect(res).toBeDefined()
    })

    it('clearApiLog clears all logs', async () => {
      const res = await clearApiLog({})
      expect(res).toBeDefined()
    })
  })

  describe('API Auth', () => {
    it('getApiAuthPage fetches auth list', async () => {
      const res = await getApiAuthPage({ pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('addApiAuth creates auth', async () => {
      const res = await addApiAuth({ apiId: 1, appKey: 'test-key' })
      expect(res).toBeDefined()
    })

    it('updateApiAuth updates auth', async () => {
      const res = await updateApiAuth({ id: 1, appKey: 'new-key' })
      expect(res).toBeDefined()
    })

    it('deleteApiAuth deletes auth', async () => {
      const res = await deleteApiAuth({ id: 1 })
      expect(res).toBeDefined()
    })

    it('validateApiAuth validates auth', async () => {
      const res = await validateApiAuth({ appKey: 'test-key', timestamp: Date.now() })
      expect(res).toBeDefined()
    })

    it('refreshAuthToken refreshes token', async () => {
      const res = await refreshAuthToken({ authId: 1 })
      expect(res).toBeDefined()
    })
  })
})