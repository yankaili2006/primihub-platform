/**
 * 联邦学习 API 单元测试
 */
import {
  createTask,
  getTaskList,
  getTaskDetails,
  getModelList,
  importModel,
  downloadModel,
  downloadResult,
  deleteTask,
  cancelTask,
  getTrainingProgress,
  exportFederatedLearningLog,
  getWorkbenchOverview,
  getWorkbenchDatasets,
  getWorkbenchFeatures,
  saveFeatureConfig,
  getModelConfig,
  saveModelConfig,
  getParamTuningList,
  createParamTuning,
  getFLPreprocessList,
  createFLPreprocess,
  runFLPreprocess,
  downloadFLPreprocessResult,
  getFederatedLearningLogs,
  batchExportFederatedLearningLogs,
  applyBestParams,
  getTrainingIterations,
  getTrainingReport,
  generateTrainingReport,
  exportTrainingReport
} from '@/api/federatedLearning'

jest.mock('@/utils/request', () => {
  const mockFn = (config) => Promise.resolve({ data: { code: 0, result: { list: [] } } })
  return {
    __esModule: true,
    default: mockFn
  }
})

describe('API:federatedLearning', () => {
  describe('Task APIs', () => {
    it('createTask', async () => {
      const res = await createTask({ taskName: 'test', algorithmType: 'LINEAR_REGRESSION' })
      expect(res).toBeDefined()
    })

    it('getTaskList with filters', async () => {
      const res = await getTaskList({ pageNo: 1, pageSize: 10, taskName: 'test', taskState: 1 })
      expect(res).toBeDefined()
    })

    it('getTaskDetails', async () => {
      const res = await getTaskDetails({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('deleteTask', async () => {
      const res = await deleteTask({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('cancelTask', async () => {
      const res = await cancelTask({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })

  describe('Model APIs', () => {
    it('getModelList', async () => {
      const res = await getModelList({ pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('importModel with FormData', async () => {
      const fd = new FormData()
      fd.append('file', new Blob(['test']), 'model.pkl')
      const res = await importModel(fd)
      expect(res).toBeDefined()
    })

    it('downloadModel', async () => {
      const res = await downloadModel({ modelId: 'm1' })
      expect(res).toBeDefined()
    })

    it('downloadResult', async () => {
      const res = await downloadResult({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })

  describe('Training APIs', () => {
    it('getTrainingProgress', async () => {
      const res = await getTrainingProgress({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('getTrainingIterations', async () => {
      const res = await getTrainingIterations({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('getTrainingReport', async () => {
      const res = await getTrainingReport({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('generateTrainingReport', async () => {
      const res = await generateTrainingReport({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('exportTrainingReport', async () => {
      const res = await exportTrainingReport({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })

  describe('Log APIs', () => {
    it('getFederatedLearningLogs', async () => {
      const res = await getFederatedLearningLogs({ pageNo: 1, pageSize: 10, taskId: '123' })
      expect(res).toBeDefined()
    })

    it('exportFederatedLearningLog', async () => {
      const res = await exportFederatedLearningLog({ taskId: '123', startTime: '2024-01-01', endTime: '2024-12-31' })
      expect(res).toBeDefined()
    })

    it('batchExportFederatedLearningLogs', async () => {
      const res = await batchExportFederatedLearningLogs({ logIds: ['1', '2'], format: 'EXCEL' })
      expect(res).toBeDefined()
    })
  })

  describe('Workbench APIs', () => {
    it('getWorkbenchOverview', async () => {
      const res = await getWorkbenchOverview()
      expect(res).toBeDefined()
    })

    it('getWorkbenchDatasets', async () => {
      const res = await getWorkbenchDatasets()
      expect(res).toBeDefined()
    })

    it('getWorkbenchFeatures', async () => {
      const res = await getWorkbenchFeatures({ datasetId: 'ds1' })
      expect(res).toBeDefined()
    })

    it('saveFeatureConfig', async () => {
      const res = await saveFeatureConfig({ datasetId: 'ds1', features: ['f1', 'f2'] })
      expect(res).toBeDefined()
    })

    it('getModelConfig', async () => {
      const res = await getModelConfig({ taskId: '123' })
      expect(res).toBeDefined()
    })

    it('saveModelConfig', async () => {
      const res = await saveModelConfig({ taskId: '123', algorithmType: 'XGBOOST' })
      expect(res).toBeDefined()
    })
  })

  describe('Preprocess APIs', () => {
    it('getFLPreprocessList', async () => {
      const res = await getFLPreprocessList({ preprocessType: 'DATA_MERGE', pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('createFLPreprocess', async () => {
      const res = await createFLPreprocess({ taskName: 'preprocess', preprocessType: 'DATA_MERGE' })
      expect(res).toBeDefined()
    })

    it('runFLPreprocess', async () => {
      const res = await runFLPreprocess({ taskId: '123', preprocessType: 'DATA_MERGE' })
      expect(res).toBeDefined()
    })

    it('downloadFLPreprocessResult', async () => {
      const res = await downloadFLPreprocessResult({ taskId: '123' })
      expect(res).toBeDefined()
    })
  })

  describe('Param Tuning APIs', () => {
    it('getParamTuningList', async () => {
      const res = await getParamTuningList({ pageNo: 1, pageSize: 10 })
      expect(res).toBeDefined()
    })

    it('createParamTuning', async () => {
      const res = await createParamTuning({ taskId: '123', searchMethod: 'GRID' })
      expect(res).toBeDefined()
    })

    it('applyBestParams', async () => {
      const res = await applyBestParams({ taskId: '123', params: { learningRate: 0.01 } })
      expect(res).toBeDefined()
    })
  })
})