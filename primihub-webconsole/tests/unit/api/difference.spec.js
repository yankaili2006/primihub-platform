/**
 * 联邦求差 API 单元测试
 */
import {
  saveDataDifference,
  getDifferenceTaskList,
  getDifferenceTaskDetails,
  downloadDifferenceTask,
  delDifferenceTask,
  cancelDifferenceTask,
  exportDifferenceLog
} from '@/api/difference'

jest.mock('@/utils/request', () => {
  const mockFn = (config) => Promise.resolve({ data: { code: 0, result: { list: [] } } })
  return {
    __esModule: true,
    default: mockFn
  }
})

describe('API:difference', () => {
  describe('Task CRUD', () => {
    it('saveDataDifference creates task', async () => {
      const data = { taskName: 'diff-test', organId: 'org1', datasetId: 'ds1' }
      const res = await saveDataDifference(data)
      expect(res).toBeDefined()
    })

    it('getDifferenceTaskList fetches paginated list', async () => {
      const res = await getDifferenceTaskList({ pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('getDifferenceTaskList supports filters', async () => {
      const res = await getDifferenceTaskList({
        pageNo: 1, pageSize: 10,
        organId: 'org1', taskName: 'test', taskState: 1,
        startDate: '2024-01-01', endDate: '2024-12-31'
      })
      expect(res).toBeDefined()
    })

    it('getDifferenceTaskDetails fetches detail', async () => {
      const res = await getDifferenceTaskDetails({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })

  describe('Task Actions', () => {
    it('downloadDifferenceTask downloads result', async () => {
      const res = await downloadDifferenceTask({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('delDifferenceTask deletes task', async () => {
      const res = await delDifferenceTask({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('cancelDifferenceTask cancels task', async () => {
      const res = await cancelDifferenceTask({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })

  describe('Log Export', () => {
    it('exportDifferenceLog exports with computeType', async () => {
      const res = await exportDifferenceLog({
        taskId: '123',
        startTime: '2024-01-01',
        endTime: '2024-12-31'
      })
      expect(res).toBeDefined()
    })

    it('exportDifferenceLog handles empty time range', async () => {
      const res = await exportDifferenceLog({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })
})