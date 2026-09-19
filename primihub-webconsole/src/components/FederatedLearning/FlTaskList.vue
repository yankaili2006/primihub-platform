<template>
  <div>
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="任务名称">
        <el-input v-model="queryForm.taskName" placeholder="请输入任务名称" clearable />
      </el-form-item>
      <el-form-item label="算法类型">
        <el-select v-model="queryForm.algorithmType" placeholder="请选择" clearable>
          <el-option label="线性回归（纵向）" :value="9" />
          <el-option label="逻辑回归（纵向）" :value="5" />
          <el-option label="XGBoost（纵向）" :value="2" />
        </el-select>
      </el-form-item>
      <el-form-item label="任务状态">
        <el-select v-model="queryForm.taskState" placeholder="请选择" clearable>
          <el-option label="待运行" :value="0" />
          <el-option label="成功" :value="1" />
          <el-option label="运行中" :value="2" />
          <el-option label="失败" :value="3" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="createDialogVisible = true">创建联邦学习任务</el-button>
    </el-row>

    <!-- Table -->
    <el-table v-loading="loading" :data="tableData" border>
      <el-table-column prop="taskId" label="任务ID" min-width="280" show-overflow-tooltip />
      <el-table-column prop="taskName" label="任务名称" min-width="160" show-overflow-tooltip />
      <el-table-column prop="algorithmType" label="算法类型" width="130">
        <template slot-scope="scope">
          <el-tag :type="getAlgorithmTag(scope.row.algorithmType)">
            {{ getAlgorithmLabel(scope.row.algorithmType) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="federatedType" label="学习类型" width="90">
        <template slot-scope="scope">
          <span>{{ scope.row.federatedType === 1 ? '横向' : '纵向' }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="taskState" label="任务状态" width="90">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.taskState === 0" type="info">待运行</el-tag>
          <el-tag v-else-if="scope.row.taskState === 1" type="success">成功</el-tag>
          <el-tag v-else-if="scope.row.taskState === 2" type="warning">运行中</el-tag>
          <el-tag v-else-if="scope.row.taskState === 3" type="danger">失败</el-tag>
          <el-tag v-else type="info">{{ scope.row.taskState }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="进度" width="140">
        <template slot-scope="scope">
          <el-progress :percentage="getProgress(scope.row)" :status="getProgressStatus(scope.row)" />
        </template>
      </el-table-column>
      <el-table-column prop="createDate" label="创建时间" width="160" />
      <el-table-column label="操作" fixed="right" width="380">
        <template slot-scope="scope">
          <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
          <el-button v-if="scope.row.taskState !== 2" size="mini" type="primary" @click="openRetrain(scope.row)">再次训练</el-button>
          <el-button v-if="scope.row.taskState === 2" size="mini" type="warning" @click="handleCancel(scope.row)">取消</el-button>
          <el-button v-if="scope.row.taskState === 1" size="mini" type="success" @click="handleDownload(scope.row, 'model')">下载模型</el-button>
          <el-button v-if="scope.row.taskState === 1" size="mini" @click="handleDownload(scope.row, 'result')">下载结果</el-button>
          <el-button size="mini" type="danger" @click="handleDelete(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- Pagination -->
    <el-pagination
      style="margin-top: 20px;"
      :current-page="queryForm.pageNo"
      :page-sizes="[10, 20, 50, 100]"
      :page-size="queryForm.pageSize"
      :total="total"
      layout="total, sizes, prev, pager, next, jumper"
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
    />

    <!-- View Dialog（getTaskDetails → task + federatedLearning 全真实字段） -->
    <el-dialog title="联邦学习任务详情" :visible.sync="viewDialogVisible" width="70%" append-to-body>
      <el-tabs v-model="detailTab">
        <el-tab-pane label="基本信息" name="basic">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="任务ID">{{ viewTask.taskId || '-' }}</el-descriptions-item>
            <el-descriptions-item label="任务名称">{{ viewFl.taskName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="算法类型">{{ getAlgorithmLabel(viewFl.algorithmType) }}</el-descriptions-item>
            <el-descriptions-item label="学习类型">{{ viewFl.federatedType === 1 ? '横向联邦' : '纵向联邦' }}</el-descriptions-item>
            <el-descriptions-item label="任务状态">
              <el-tag v-if="viewTask.taskState === 1" type="success">成功</el-tag>
              <el-tag v-else-if="viewTask.taskState === 2" type="warning">运行中</el-tag>
              <el-tag v-else-if="viewTask.taskState === 3" type="danger">失败</el-tag>
              <el-tag v-else type="info">待运行</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ viewTask.createDate || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="资源与参与方" name="resources">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="发起方机构">{{ viewFl.ownOrganId || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发起方资源">{{ viewFl.ownResourceId || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发起方特征">{{ viewFl.ownFeatures || '-' }}</el-descriptions-item>
            <el-descriptions-item label="标签字段">{{ viewFl.labelFeature || '-' }}</el-descriptions-item>
            <el-descriptions-item label="参与方机构">{{ viewFl.participantOrganIds || '-' }}</el-descriptions-item>
            <el-descriptions-item label="参与方资源">{{ viewFl.participantResourceIds || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="进度与结果" name="result">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="当前轮次">{{ viewTask.currentRound != null ? viewTask.currentRound : '-' }}</el-descriptions-item>
            <el-descriptions-item label="总轮次">{{ viewTask.totalRounds != null ? viewTask.totalRounds : '-' }}</el-descriptions-item>
            <el-descriptions-item label="精度">{{ viewTask.accuracy != null ? viewTask.accuracy : '-' }}</el-descriptions-item>
            <el-descriptions-item label="损失">{{ viewTask.loss != null ? viewTask.loss : '-' }}</el-descriptions-item>
          </el-descriptions>
          <div v-if="viewTask.executionLog" style="margin-top: 15px;">
            <div style="font-weight: bold; margin-bottom: 5px;">执行记录</div>
            <pre style="white-space: pre-wrap; word-wrap: break-word; background: #f5f7fa; padding: 10px; margin: 0; font-size: 12px;">{{ viewTask.executionLog }}</pre>
          </div>
        </el-tab-pane>
      </el-tabs>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Retrain Dialog：沿用原任务资源/特征配置，改参数后作为【新任务】重新训练 -->
    <el-dialog title="再次训练（新任务）" :visible.sync="retrainVisible" width="560px" append-to-body>
      <el-descriptions :column="1" border size="small" style="margin-bottom: 15px;">
        <el-descriptions-item label="发起方资源">{{ retrainBase.ownResourceId || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起方特征/标签">{{ retrainBase.ownFeatures || '-' }} / {{ retrainBase.labelFeature || '-' }}</el-descriptions-item>
        <el-descriptions-item label="参与方资源">{{ retrainBase.participantResourceIds || '-' }}</el-descriptions-item>
        <el-descriptions-item label="算法">{{ getAlgorithmLabel(retrainBase.algorithmType) }}（{{ retrainBase.federatedType === 1 ? '横向' : '纵向' }}）</el-descriptions-item>
      </el-descriptions>
      <el-form :model="retrainForm" label-width="100px">
        <el-form-item label="新任务名称">
          <el-input v-model="retrainForm.taskName" />
        </el-form-item>
        <el-form-item label="学习率">
          <el-input-number v-model="retrainForm.learningRate" :min="0.0001" :max="1" :step="0.001" :precision="4" />
        </el-form-item>
        <el-form-item label="迭代轮数">
          <el-input-number v-model="retrainForm.epochs" :min="1" :max="10000" />
        </el-form-item>
        <el-form-item label="批次大小">
          <el-input-number v-model="retrainForm.batchSize" :min="1" :max="4096" />
        </el-form-item>
      </el-form>
      <p style="color: #909399; font-size: 12px; margin: 0;">
        每次训练都会创建一个新任务并重新校验项目/资源授权；原任务及其模型不受影响。
      </p>
      <span slot="footer" class="dialog-footer">
        <el-button @click="retrainVisible = false">取 消</el-button>
        <el-button type="primary" :loading="retrainLoading" @click="submitRetrain">开始训练</el-button>
      </span>
    </el-dialog>

    <!-- Create Dialog：真实建任务需要选资源/特征，指路对应算法训练页 -->
    <el-dialog title="创建联邦学习任务" :visible.sync="createDialogVisible" width="480px" append-to-body>
      <p style="color: #606266; margin-top: 0;">
        创建真实联邦学习任务需要选择本方/参与方资源与特征，请前往对应算法的训练页面：
      </p>
      <el-radio-group v-model="createAlgorithm" style="display: block; margin-bottom: 10px;">
        <el-radio label="verticalLinearTrain" style="display: block; margin: 8px 0;">线性回归建模（纵向）</el-radio>
        <el-radio label="verticalLogisticTrain" style="display: block; margin: 8px 0;">逻辑回归建模（纵向）</el-radio>
        <el-radio label="verticalXGBoostTrain" style="display: block; margin: 8px 0;">XGBoost建模（纵向）</el-radio>
      </el-radio-group>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="goCreatePage">前往创建</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getTaskList, getTaskDetails, cancelTask, deleteTask, downloadModel, downloadResult, createTask } from '@/api/federatedLearning'
import { ALGORITHM_LABELS, ALGORITHM_TAGS } from './constants'

export default {
  name: 'FlTaskList',
  props: {
    // 项目上下文：传入则列表/创建都限定该项目（getTaskList/createTask 后端原生支持）
    projectId: { type: [String, Number], default: null }
  },
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      queryForm: { taskName: '', algorithmType: null, taskState: null, pageNo: 1, pageSize: 10 },
      viewDialogVisible: false,
      viewTask: {},
      viewFl: {},
      detailTab: 'basic',
      createDialogVisible: false,
      createAlgorithm: 'verticalLogisticTrain',
      retrainVisible: false,
      retrainLoading: false,
      retrainBase: {},
      retrainForm: { taskName: '', learningRate: 0.01, epochs: 10, batchSize: 32 }
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    async fetchData() {
      this.loading = true
      try {
        const params = { pageNo: this.queryForm.pageNo, pageSize: this.queryForm.pageSize }
        if (this.projectId != null && this.projectId !== '') params.projectId = this.projectId
        if (this.queryForm.taskName) params.taskName = this.queryForm.taskName
        if (this.queryForm.algorithmType != null) params.algorithmType = this.queryForm.algorithmType
        if (this.queryForm.taskState != null) params.taskState = this.queryForm.taskState
        const res = await getTaskList(params)
        if (res && res.code === 0 && res.result) {
          this.tableData = res.result.data || res.result.list || []
          this.total = res.result.total || 0
        } else {
          this.tableData = []
          this.total = 0
          this.$message.warning('任务列表查询失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.tableData = []
        this.total = 0
        this.$message.error('任务列表接口不可用: ' + (e.message || e))
      }
      this.loading = false
    },
    handleQuery() {
      this.queryForm.pageNo = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = { taskName: '', algorithmType: null, taskState: null, pageNo: 1, pageSize: 10 }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNo = val
      this.fetchData()
    },
    async handleView(row) {
      try {
        const res = await getTaskDetails({ taskId: row.taskId })
        if (res && res.code === 0 && res.result) {
          this.viewTask = res.result.task || {}
          this.viewFl = res.result.federatedLearning || {}
          this.detailTab = 'basic'
          this.viewDialogVisible = true
          // 详情读取触发后端 data_task 终态懒同步；状态变了就刷新列表
          if (this.viewTask.taskState !== row.taskState) this.fetchData()
        } else {
          this.$message.warning('查询详情失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.$message.error('详情接口不可用: ' + (e.message || e))
      }
    },
    // 再次训练：沿用原任务的资源/特征配置，仅改超参；每次提交=一个全新任务
    // （createTask 每次新建并重走项目/资源授权校验）。
    async openRetrain(row) {
      try {
        const res = await getTaskDetails({ taskId: row.taskId })
        const fl = (res && res.code === 0 && res.result && res.result.federatedLearning) || null
        if (!fl || !fl.ownResourceId || !fl.participantResourceIds) {
          this.$message.warning('该任务缺少完整资源配置（旧数据），无法一键复跑，请从训练页重新创建')
          return
        }
        this.retrainBase = fl
        let p = {}
        try { p = JSON.parse(fl.trainingParams) || {} } catch (e) { p = {} }
        this.retrainForm = {
          taskName: (fl.taskName || row.taskId) + '_re' + new Date().getTime().toString().slice(-4),
          learningRate: p.learningRate != null ? p.learningRate : 0.01,
          epochs: p.epochs != null ? p.epochs : 10,
          batchSize: p.batchSize != null ? p.batchSize : 32
        }
        this.retrainVisible = true
      } catch (e) {
        this.$message.error('读取任务配置失败: ' + (e.message || e))
      }
    },
    async submitRetrain() {
      const fl = this.retrainBase
      this.retrainLoading = true
      try {
        const body = {
          taskType: 1,
          algorithmType: fl.algorithmType,
          federatedType: fl.federatedType || 2,
          taskName: this.retrainForm.taskName,
          ownOrganId: fl.ownOrganId,
          ownResourceId: fl.ownResourceId,
          ownFeatures: fl.ownFeatures,
          labelFeature: fl.labelFeature,
          isLabelOwner: fl.isLabelOwner != null ? fl.isLabelOwner : 1,
          participantOrganIds: fl.participantOrganIds,
          participantResourceIds: fl.participantResourceIds,
          trainingParams: {
            learningRate: this.retrainForm.learningRate,
            epochs: this.retrainForm.epochs,
            batchSize: this.retrainForm.batchSize
          }
        }
        if (fl.projectId != null) body.projectId = fl.projectId
        const res = await createTask(body)
        if (res && res.code === 0) {
          this.$message.success('已作为新任务提交训练')
          this.retrainVisible = false
          this.fetchData()
        } else {
          this.$message.warning('提交失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.$message.error('创建任务接口不可用: ' + (e.message || e))
      }
      this.retrainLoading = false
    },
    goCreatePage() {
      this.createDialogVisible = false
      const query = {}
      if (this.projectId != null && this.projectId !== '') query.projectId = this.projectId
      this.$router.push({ path: '/federatedLearning/' + this.createAlgorithm, query })
    },
    handleCancel(row) {
      this.$confirm('确认取消该运行中的联邦学习任务吗?', '提示', { type: 'warning' }).then(async() => {
        try {
          const res = await cancelTask({ taskId: row.taskId })
          if (res && res.code === 0) {
            this.$message.success('任务已取消')
            this.fetchData()
          } else {
            this.$message.warning('取消失败: ' + ((res && res.msg) || '未知错误'))
          }
        } catch (e) {
          this.$message.error('取消接口不可用: ' + (e.message || e))
        }
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm('确认删除该联邦学习任务吗？删除不可恢复。', '提示', { type: 'warning' }).then(async() => {
        try {
          const res = await deleteTask({ taskId: row.taskId })
          if (res && res.code === 0) {
            this.$message.success('任务已删除')
            this.fetchData()
          } else {
            this.$message.warning('删除失败: ' + ((res && res.msg) || '未知错误'))
          }
        } catch (e) {
          this.$message.error('删除接口不可用: ' + (e.message || e))
        }
      }).catch(() => {})
    },
    async handleDownload(row, kind) {
      try {
        const fn = kind === 'model' ? downloadModel : downloadResult
        const blob = await fn({ taskId: row.taskId })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = (row.taskName || row.taskId) + (kind === 'model' ? '_model' : '_result.csv')
        link.click()
        window.URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error((kind === 'model' ? '模型' : '结果') + '下载失败: ' + (e.message || e))
      }
    },
    getAlgorithmLabel(type) {
      return ALGORITHM_LABELS[type] || (type != null ? String(type) : '-')
    },
    getAlgorithmTag(type) {
      return ALGORITHM_TAGS[type] || ''
    },
    getProgress(row) {
      if (row.taskState === 1) return 100
      if (row.totalRounds) {
        const pct = Math.round(((row.currentRound || 0) * 100) / row.totalRounds)
        return Math.min(99, Math.max(0, pct))
      }
      return 0
    },
    getProgressStatus(row) {
      if (row.taskState === 1) return 'success'
      if (row.taskState === 3) return 'exception'
      return null
    }
  }
}
</script>
