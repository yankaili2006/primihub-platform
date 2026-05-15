<template>
  <div class="app-container">
    <el-page-header content="联邦学习逻辑回归建模（纵向）" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建纵向逻辑回归训练任务</span></div>
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
            <el-form-item label="目标变量（因变量）" prop="targetVariable">
              <el-select v-model="formData.targetVariable" placeholder="请选择目标变量" style="width:100%;">
                <el-option v-for="item in targetFieldList" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="特征变量" prop="featureVariables">
              <el-select v-model="formData.featureVariables" multiple placeholder="请选择特征变量" style="width:100%;">
                <el-option v-for="item in featureFieldList" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="学习率" prop="learningRate">
              <el-input-number v-model="formData.learningRate" :min="0.001" :max="0.1" :step="0.001" :precision="3" style="width:100%;" />
            </el-form-item>
            <el-form-item label="最大迭代次数" prop="maxIter">
              <el-input-number v-model="formData.maxIter" :min="10" :max="1000" :step="10" style="width:100%;" />
            </el-form-item>
            <el-form-item label="正则化类型" prop="regType">
              <el-select v-model="formData.regType" placeholder="请选择正则化类型" style="width:100%;">
                <el-option label="None（无正则化）" value="NONE" />
                <el-option label="L1（Lasso）" value="L1" />
                <el-option label="L2（Ridge）" value="L2" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="formData.regType !== 'NONE'" label="正则化系数" prop="regLambda">
              <el-input-number v-model="formData.regLambda" :min="0.0001" :max="10" :step="0.001" :precision="4" style="width:100%;" />
            </el-form-item>
            <el-form-item label="分类阈值" prop="threshold">
              <el-input-number v-model="formData.threshold" :min="0.1" :max="0.9" :step="0.05" :precision="2" style="width:100%;" />
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
        <el-descriptions-item label="目标变量">{{ currentTask.targetVariable }}</el-descriptions-item>
        <el-descriptions-item label="学习率">{{ currentTask.learningRate }}</el-descriptions-item>
        <el-descriptions-item label="最大迭代次数">{{ currentTask.maxIter }}</el-descriptions-item>
        <el-descriptions-item label="正则化类型">{{ currentTask.regType }}</el-descriptions-item>
        <el-descriptions-item label="分类阈值">{{ currentTask.threshold }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentTask.createTime }}</el-descriptions-item>
        <el-descriptions-item label="备注">{{ currentTask.remark }}</el-descriptions-item>
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
  downloadFLPreprocessResult
} from '@/api/federatedLearning'

const PREPROCESS_TYPE = 'VFL_LOGISTIC_TRAIN'

export default {
  name: 'FLVerticalLogisticTrain',
  data() {
    return {
      formData: {
        taskName: '',
        participants: [],
        dataResources: [],
        targetVariable: '',
        featureVariables: [],
        learningRate: 0.01,
        maxIter: 100,
        regType: 'NONE',
        regLambda: 0.01,
        threshold: 0.5,
        remark: ''
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        participants: [{ required: true, message: '请选择参与方', trigger: 'change' }],
        dataResources: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        targetVariable: [{ required: true, message: '请选择目标变量', trigger: 'change' }],
        featureVariables: [{ required: true, message: '请选择特征变量', trigger: 'change' }],
        regType: [{ required: true, message: '请选择正则化类型', trigger: 'change' }]
      },
      dataResourceList: [
        { label: '用户行为数据集', value: 'user_behavior_dataset' },
        { label: '风险特征数据集', value: 'risk_feature_dataset' },
        { label: '标签数据集', value: 'label_dataset' }
      ],
      targetFieldList: ['label', 'churn', 'default', 'fraud', 'approved'],
      featureFieldList: ['age', 'income', 'tenure', 'balance', 'region', 'gender', 'category', 'score'],
      taskList: [],
      listLoading: false,
      submitting: false,
      detailVisible: false,
      currentTask: {}
    }
  },
  created() {
    this.loadList()
  },
  methods: {
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
        a.download = `vfl_logistic_train_${row.taskId}.zip`
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
</style>
