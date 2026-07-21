<template>
  <div class="app-container">
    <el-page-header content="联邦学习数据分割" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建数据分割任务</span></div>
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
            <el-form-item label="分割方式" prop="splitMethod">
              <el-select v-model="formData.splitMethod" placeholder="请选择分割方式" style="width:100%;">
                <el-option label="随机分割" value="RANDOM" />
                <el-option label="按时间分割" value="TIME_BASED" />
                <el-option label="分层分割" value="STRATIFIED" />
              </el-select>
            </el-form-item>
            <el-form-item label="训练集比例" prop="trainRatio">
              <el-slider
                v-model="formData.trainRatio"
                :min="50"
                :max="90"
                :step="5"
                show-input
                :format-tooltip="val => val + '%'"
                style="padding-right: 50px;"
                @change="updateValidRatio"
              />
            </el-form-item>
            <el-form-item label="验证集比例">
              <el-input :value="validRatio + '%'" disabled />
              <div class="form-tip">验证集比例 = 100% - 训练集比例</div>
            </el-form-item>
            <el-form-item label="随机种子" prop="randomSeed">
              <el-input-number v-model="formData.randomSeed" :min="0" :max="999999" style="width:100%;" />
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
        <el-descriptions-item label="分割方式">{{ currentTask.splitMethod }}</el-descriptions-item>
        <el-descriptions-item label="训练集比例">{{ currentTask.trainRatio }}%</el-descriptions-item>
        <el-descriptions-item label="随机种子">{{ currentTask.randomSeed }}</el-descriptions-item>
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
  downloadFLPreprocessResult
} from '@/api/federatedLearning'

const PREPROCESS_TYPE = 'DATA_SPLIT'

export default {
  name: 'FLDataSplit',
  data() {
    return {
      formData: {
        taskName: '',
        participants: [],
        dataResources: [],
        trainRatio: 80,
        splitMethod: 'RANDOM',
        randomSeed: 42,
        remark: ''
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        participants: [{ required: true, message: '请选择参与方', trigger: 'change' }],
        dataResources: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        splitMethod: [{ required: true, message: '请选择分割方式', trigger: 'change' }]
      },
      dataResourceList: [
        { label: '销售数据集', value: 'sales_dataset' },
        { label: '用户特征集', value: 'user_feature_dataset' },
        { label: '风险数据集', value: 'risk_dataset' }
      ],
      taskList: [],
      listLoading: false,
      submitting: false,
      detailVisible: false,
      currentTask: {}
    }
  },
  computed: {
    validRatio() {
      return 100 - this.formData.trainRatio
    }
  },
  created() {
    this.loadList()
  },
  methods: {
    updateValidRatio() {},
    async loadList() {
      this.listLoading = true
      try {
        const res = await getFLPreprocessList({ preprocessType: PREPROCESS_TYPE })
        this.taskList = res.data || []
      } catch (e) {
        this.taskList = []
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
        a.download = `data_split_${row.taskId}.zip`
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
      this.formData.trainRatio = 80
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
