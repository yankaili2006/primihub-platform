<template>
  <div class="app-container">
    <el-page-header content="纵向联邦逻辑回归预测" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建逻辑回归预测任务（真实联邦推理）</span></div>
          <el-form ref="taskForm" :model="formData" :rules="formRules" label-width="130px">
            <el-form-item label="任务名称" prop="reasoningName">
              <el-input v-model="formData.reasoningName" placeholder="请输入预测任务名称" />
            </el-form-item>
            <el-form-item label="训练好的模型" prop="taskId">
              <el-select v-model="formData.taskId" filterable placeholder="请选择训练成功的逻辑回归模型" style="width:100%;">
                <el-option v-for="m in modelTaskList" :key="m.taskId" :label="modelLabel(m)" :value="m.taskId" />
              </el-select>
              <div class="form-tip">仅列出训练成功的模型任务；没有可选项时请先完成一次逻辑回归训练</div>
            </el-form-item>
            <el-form-item label="协作方" prop="otherOrganId">
              <el-select v-model="formData.otherOrganId" placeholder="请选择协作方机构" style="width:100%;" @change="onOtherOrganChange">
                <el-option v-for="o in organList" :key="o.globalId" :label="o.globalName" :value="o.globalId" />
              </el-select>
            </el-form-item>
            <el-form-item label="发起方预测数据" prop="createdResourceId">
              <el-select v-model="formData.createdResourceId" filterable placeholder="请选择本方预测数据集" style="width:100%;">
                <el-option v-for="r in ownResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="协作方预测数据" prop="providerResourceId">
              <el-select v-model="formData.providerResourceId" filterable placeholder="请先选择协作方，再选其数据集" style="width:100%;">
                <el-option v-for="r in otherResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="formData.reasoningDesc" type="textarea" :rows="2" placeholder="请输入备注" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="submitting" @click="handleSubmit">提交预测</el-button>
              <el-button @click="resetForm">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header">
            <span>预测任务列表</span>
            <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="loadList">刷新</el-button>
          </div>
          <el-table :data="taskList" border size="small" v-loading="listLoading">
            <el-table-column prop="reasoningName" label="任务名称" min-width="110" show-overflow-tooltip />
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag :type="statusTagType(row.reasoningState)" size="small">{{ statusLabel(row.reasoningState) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="releaseDate" label="创建时间" width="140" show-overflow-tooltip />
            <el-table-column label="操作" width="100" fixed="right">
              <template slot-scope="{ row }">
                <el-button type="text" size="mini" @click="handleView(row)">详情</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog title="预测任务详情" :visible.sync="detailVisible" width="700px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="任务名称">{{ currentTask.reasoningName }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ statusLabel(currentTask.reasoningState) }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentTask.releaseDate }}</el-descriptions-item>
        <el-descriptions-item label="备注">{{ currentTask.reasoningDesc }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer"><el-button @click="detailVisible = false">关闭</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getModelTaskSuccessList } from '@/api/model'
import { saveReasoning, getReasoningList } from '@/api/reasoning'
import { getResourceList } from '@/api/fusionResource'
import { getAvailableOrganList } from '@/api/center'

const MODEL_TYPE = 5

export default {
  name: 'FLVerticalLogisticPredict',
  data() {
    return {
      formData: {
        reasoningName: '',
        taskId: '',
        otherOrganId: '',
        createdResourceId: '',
        providerResourceId: '',
        reasoningDesc: ''
      },
      formRules: {
        reasoningName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        taskId: [{ required: true, message: '请选择训练好的模型', trigger: 'change' }],
        otherOrganId: [{ required: true, message: '请选择协作方', trigger: 'change' }],
        createdResourceId: [{ required: true, message: '请选择发起方预测数据', trigger: 'change' }],
        providerResourceId: [{ required: true, message: '请选择协作方预测数据', trigger: 'change' }]
      },
      modelTaskList: [],
      organList: [],
      ownResourceList: [],
      otherResourceList: [],
      taskList: [],
      listLoading: false,
      submitting: false,
      detailVisible: false,
      currentTask: {}
    }
  },
  created() {
    this.loadList()
    this.loadOptions()
  },
  methods: {
    modelLabel(m) {
      return `${m.modelName || '模型'} (任务#${m.taskId})`
    },
    async loadOptions() {
      try {
        const [orgRes, modelRes, resRes] = await Promise.all([
          getAvailableOrganList(),
          getModelTaskSuccessList({ modelType: MODEL_TYPE }),
          getResourceList({ pageNo: 1, pageSize: 100, organId: this.$store.getters.userOrganId })
        ])
        if (orgRes.code === 0) this.organList = orgRes.result || []
        if (modelRes.code === 0) this.modelTaskList = modelRes.result?.data || modelRes.result?.list || modelRes.result || []
        if (resRes.code === 0) this.ownResourceList = resRes.result?.data || []
      } catch (e) { console.error(e) }
    },
    async onOtherOrganChange(organId) {
      this.formData.providerResourceId = ''
      this.otherResourceList = []
      if (!organId) return
      try {
        const res = await getResourceList({ pageNo: 1, pageSize: 100, organId })
        if (res.code === 0) this.otherResourceList = res.result?.data || []
      } catch (e) { console.error(e) }
    },
    async loadList() {
      this.listLoading = true
      try {
        const res = await getReasoningList({ pageNo: 1, pageSize: 50 })
        this.taskList = res.result?.data || res.result?.list || []
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
          const res = await saveReasoning({
            taskId: this.formData.taskId,
            reasoningName: this.formData.reasoningName,
            reasoningDesc: this.formData.reasoningDesc,
            resourceList: [
              { participationIdentity: 1, resourceId: this.formData.createdResourceId },
              { participationIdentity: 2, resourceId: this.formData.providerResourceId }
            ]
          })
          if (res.code === 0) {
            this.$message.success('联邦预测任务已提交，推理在隐私计算节点真实执行')
            this.loadList()
          } else {
            this.$message.error(res.message || '任务创建失败')
          }
        } catch (e) {
          this.$message.error('任务创建失败')
        } finally {
          this.submitting = false
        }
      })
    },
    handleView(row) {
      this.currentTask = row
      this.detailVisible = true
    },
    resetForm() {
      this.$refs.taskForm.resetFields()
      this.otherResourceList = []
    },
    statusTagType(status) {
      const map = { 0: 'info', 1: 'success', 2: 'warning', 3: 'danger' }
      return map[status] || 'info'
    },
    statusLabel(status) {
      const map = { 0: '待执行', 1: '预测成功', 2: '预测中', 3: '预测失败' }
      return map[status] || '未知'
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.form-tip { font-size: 12px; color: #909399; margin-top: 4px; }
</style>
