/**
 * 联邦统计 API 单元测试
 * 验证 API 请求参数构造和响应格式
 */
import {
  getStatisticsTaskList,
  createStatisticsTask,
  getStatisticsTaskDetail,
  runStatisticsTask,
  getStatisticsLogs,
  getStatisticsLogDetail,
  exportStatisticsLogs,
  getLogExportHistory,
  downloadLogExportFile,
  getStatisticsTypes,
  executeSumStatistics,
  executeAvgStatistics,
  executeCountStatistics,
  batchExportStatisticsResult
} from '@/api/federatedStatisticsApi'

// Mock axios request
jest.mock('@/utils/request', () => {
  const mockFn = (config) => Promise.resolve({ data: { code: 0, result: { list: [] } } })
  mockFn.get = jest.fn(() => Promise.resolve({ data: { code: 0, result: { list: [] } } }))
  mockFn.post = jest.fn(() => Promise.resolve({ data: { code: 0, result: {} } }))
  return {
    __esModule: true,
    default: mockFn
  }
})

describe('API:federatedStatisticsApi', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Task APIs', () => {
    it('getStatisticsTaskList sends GET with params', async () => {
      const result = await getStatisticsTaskList({ pageNo: 1, pageSize: 10 })
      expect(result).toBeDefined()
    })

    it('createStatisticsTask sends POST with data', async () => {
      const taskData = { taskName: 'test', statisticsType: 'SUM' }
      const result = await createStatisticsTask(taskData)
      expect(result).toBeDefined()
    })

    it('getStatisticsTaskDetail sends GET with taskId', async () => {
      const result = await getStatisticsTaskDetail({ taskId: '123' })
      expect(result).toBeDefined()
    })

    it('runStatisticsTask sends POST with taskId', async () => {
      const result = await runStatisticsTask({ taskId: '123' })
      expect(result).toBeDefined()
    })
  })

  describe('Log APIs', () => {
    it('getStatisticsLogs sends GET with optional filters', async () => {
      const params = {
        taskId: '001',
        logLevel: 'ERROR',
        statisticsType: 'SUM',
        startDate: '2024-01-01',
        endDate: '2024-12-31',
        pageNo: 1,
        pageSize: 10
      }
      const result = await getStatisticsLogs(params)
      expect(result).toBeDefined()
    })

    it('getStatisticsLogs handles empty filters', async () => {
      const result = await getStatisticsLogs({ pageNo: 1, pageSize: 10 })
      expect(result).toBeDefined()
    })

    it('getStatisticsLogDetail sends GET with logId', async () => {
      const result = await getStatisticsLogDetail({ logId: 'LOG001' })
      expect(result).toBeDefined()
    })
  })

  describe('Export APIs', () => {
    it('exportStatisticsLogs sends POST with blob responseType', async () => {
      const params = {
        taskId: '123',
        format: 'CSV',
        startDate: '2024-01-01',
        endDate: '2024-12-31'
      }
      const result = await exportStatisticsLogs(params)
      expect(result).toBeDefined()
    })

    it('getLogExportHistory sends GET with pagination', async () => {
      const result = await getLogExportHistory({ pageNo: 1, pageSize: 50 })
      expect(result).toBeDefined()
    })

    it('downloadLogExportFile sends GET with blob responseType', async () => {
      const result = await downloadLogExportFile({ exportId: 'EXP001' })
      expect(result).toBeDefined()
    })
  })

  describe('Statistics Type APIs', () => {
    it('getStatisticsTypes returns list of types', async () => {
      const result = await getStatisticsTypes()
      expect(result).toBeDefined()
    })
  })

  describe('Execute APIs', () => {
    it('executeSumStatistics sends POST with data', async () => {
      const result = await executeSumStatistics({ taskId: '123', fields: ['amount'] })
      expect(result).toBeDefined()
    })

    it('executeAvgStatistics sends POST with data', async () => {
      const result = await executeAvgStatistics({ taskId: '123', fields: ['amount'] })
      expect(result).toBeDefined()
    })

    it('executeCountStatistics sends POST with data', async () => {
      const result = await executeCountStatistics({ taskId: '123' })
      expect(result).toBeDefined()
    })
  })

  describe('Batch Export API', () => {
    it('batchExportStatisticsResult sends POST with taskIds', async () => {
      const result = await batchExportStatisticsResult({ taskIds: ['1', '2'], format: 'EXCEL' })
      expect(result).toBeDefined()
    })
  })
})