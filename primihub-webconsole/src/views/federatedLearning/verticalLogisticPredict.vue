<template>
  <div class="app-container">
    <el-page-header content="联邦学习逻辑回归预测（纵向）" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建纵向逻辑回归预测任务</span></div>
          <el-form ref="taskForm" :model="formData" :rules="formRules" label-width="130px">
            <el-form-item label="任务名称" prop="taskName">
              <el-input v-model="formData.taskName" placeholder="请输入任务名称" />
            </el-form-item>
            <el-form-item label="参与方" prop="participants">
              <el-select v-model="formData.participants" multiple placeholder="请选择参与方" style="width:100%;">
                <el-option label="机构A" value="ORG_A" />
                <el-option label="机构B" value="ORG_B" />
                <el-option label="机构C" value="ORG_C" />
              </el-select>
            </el-form-item>
            <el-form-item label="数据资源" prop="dataResources">
              <el-select v-model="formData.dataResources" multiple placeholder="请选择数据资源" style="width:100%;">
                <el-option v-for="item in dataResourceList" :key="item.value" :label="item.label" :value="item.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="使用模型" prop="modelId">
              <el-select v-model="formData.modelId" placeholder="请选择已训练的逻辑回归模型" style="width:100%;">
                <el-option v-for="item in modelList" :key="item.modelId" :label="item.modelName" :value="item.modelId" />
              </el-select>
            </el-form-item>
            <el-form-item label="预测数据集" prop="predictDataset">
              <el-select v-model="formData.predictDataset" placeholder="请选择预测数据集" style="width:100%;">
                <el-option v-for="item in dataResourceList" :key="item.value" :label="item.label" :value="item.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="输出概率列名" prop="outputColumn">
              <el-input v-model="formData.outputColumn" placeholder="如: pred_prob" />
            </el-form-item>
            <el-form-item label="分类阈值" prop="classThreshold">
              <el-input-number
                v-model="formData.classThreshold"
                :min="0.0"
                :max="1.0"
                :step="0.01"
                :precision="2"
                style="width:100%;"
              />
              <div class="form-tip">概率超过此阈值则分类为正样本，默认 0.5</div>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="submitting" @click="handleSubmit">提交任务</el-button>
              <el-button @click="resetForm">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header">
            <span>任务列表</span>
            <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="loadList">刷新</el-button>
          </div>
          <el-table :data="taskList" border size="small" v-loading="listLoading">
            <el-table-column prop="taskId" label="任务ID" width="80" />
            <el-table-column prop="taskName" label="任务名称" min-width="100" show-overflow-tooltip />
            <el-table-column prop="participantCount" label="参与方数" width="80" align="center" />
            <el-table-column label="任务状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag :type="statusTagType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createTime" label="创建时间" width="140" />
            <el-table-column label="操作" width="160" fixed="right">
              <template slot-scope="{ row }">
                <el-button type="text" size="mini" @click="handleView(row)">查看</el-button>
                <el-button type="text" size="mini" @click="handleRun(row)">执行</el-button>
                <el-button type="text" size="mini" @click="handleDownload(row)">下载</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C;" @click="handleDelete(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog title="任务详情" :visible.sync="detailVisible" width="600px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="任务ID">{{ currentTask.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ currentTask.taskName }}</el-descriptions-item>
        <el-descriptions-item label="使用模型">{{ currentTask.modelId }}</el-descriptions-item>
        <el-descriptions-item label="输出列名">{{ currentTask.outputColumn }}</el-descriptions-item>
        <el-descriptions-item label="分类阈值">{{ currentTask.classThreshold }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentTask.createTime }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer"><el-button @click="detailVisible = false">关闭</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getFLPreprocessList,
  createFLPreprocess,
  runFLPreprocess,
  deleteFLPreprocess,
  downloadFLPreprocessResult,
  getModelList
} from '@/api/federatedLearning'
import { getResourceList } from '@/api/resource'

const PREPROCESS_TYPE = 'VFL_LOGISTIC_PREDICT'

export default {
  name: 'FLVerticalLogisticPredict',
  data() {
    return {
      formData: {
        taskName: '',
        participants: [],
        dataResources: [],
        modelId: '',
        predictDataset: '',
        outputColumn: 'pred_prob',
        classThreshold: 0.5,
        remark: ''
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        participants: [{ required: true, message: '请选择参与方', trigger: 'change' }],
        dataResources: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        modelId: [{ required: true, message: '请选择使用模型', trigger: 'change' }],
        predictDataset: [{ required: true, message: '请选择预测数据集', trigger: 'change' }],
        outputColumn: [{ required: true, message: '请输入输出概率列名', trigger: 'blur' }]
      },
      // 缺陷整改：数据资源/模型下拉改从真实接口加载（原写死 mock）
      dataResourceList: [],
      modelList: [],
      taskList: [],
      listLoading: false,
      submitting: false,
      detailVisible: false,
      currentTask: {}
    }
  },
  created() {
    this.loadList()
    this.loadDataResources()
    this.loadModels()
  },
  methods: {
    // 缺陷整改：数据资源下拉改真实接口
    loadDataResources() {
      getResourceList({ pageNo: 1, pageSize: 100 }).then(res => {
        const list = (res && res.result && (res.result.list || res.result.data || res.result)) || []
        this.dataResourceList = (Array.isArray(list) ? list : []).map(r => ({
          value: r.resourceId || r.id || r.value,
          label: r.resourceName || r.name || r.label
        }))
      }).catch(() => { this.dataResourceList = [] })
    },
    // 缺陷整改：模型下拉改真实接口
    loadModels() {
      getModelList({ pageNo: 1, pageSize: 100 }).then(res => {
        const r = (res && res.result) || {}
        const list = r.list || r.data || (Array.isArray(r) ? r : [])
        this.modelList = Array.isArray(list) ? list : []
      }).catch(() => { this.modelList = [] })
    },
    async loadList() {
      this.listLoading = true
      try {
        const res = await getFLPreprocessList({ preprocessType: PREPROCESS_TYPE })
        this.taskList = res.data || []
      } catch (e) {
        this.$message.error('加载任务列表失败')
      } finally {
        this.listLoading = false
      }
    },
    async handleSubmit() {
      this.$refs.taskForm.validate(async valid => {
        if (!valid) return
        this.submitting = true
        try {
          await createFLPreprocess({ ...this.formData, preprocessType: PREPROCESS_TYPE })
          this.$message.success('任务创建成功')
          this.resetForm()
          this.loadList()
        } catch (e) {
          this.$message.error('任务创建失败')
        } finally {
          this.submitting = false
        }
      })
    },
    async handleRun(row) {
      try {
        await runFLPreprocess({ taskId: row.taskId, preprocessType: PREPROCESS_TYPE })
        this.$message.success('任务已提交执行')
        this.loadList()
      } catch (e) {
        this.$message.error('执行失败')
      }
    },
    async handleDownload(row) {
      try {
        const res = await downloadFLPreprocessResult({ taskId: row.taskId })
        const url = URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a')
        a.href = url
        a.download = `vfl_logistic_predict_${row.taskId}.csv`
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('下载失败')
      }
    },
    async handleDelete(row) {
      try {
        await this.$confirm('确定删除该任务？', '提示', { type: 'warning' })
        await deleteFLPreprocess({ taskId: row.taskId })
        this.$message.success('删除成功')
        this.loadList()
      } catch (e) {
        if (e !== 'cancel') this.$message.error('删除失败')
      }
    },
    handleView(row) {
      this.currentTask = row
      this.detailVisible = true
    },
    resetForm() {
      this.$refs.taskForm.resetFields()
    },
    statusTagType(status) {
      const map = { 0: 'info', 1: 'success', 2: 'warning', 3: 'danger' }
      return map[status] || 'info'
    },
    statusLabel(status) {
      const map = { 0: '待执行', 1: '已完成', 2: '执行中', 3: '执行失败' }
      return map[status] || '未知'
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.form-tip { font-size: 12px; color: #909399; margin-top: 4px; }
</style>
