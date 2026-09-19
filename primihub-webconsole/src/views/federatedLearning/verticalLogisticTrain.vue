<template>
  <div class="app-container">
    <el-page-header content="纵向联邦逻辑回归训练" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建逻辑回归训练任务（真实联邦训练）</span></div>
          <el-form ref="taskForm" :model="formData" :rules="formRules" label-width="130px">
            <el-form-item label="任务名称" prop="taskName">
              <el-input v-model="formData.taskName" placeholder="请输入任务名称" />
            </el-form-item>
            <el-form-item label="所属项目">
              <el-select v-model="formData.projectId" clearable filterable placeholder="不选则使用平台默认项目" style="width:100%;">
                <el-option v-for="p in projectList" :key="p.id || p.projectId" :label="p.projectName" :value="p.id || p.projectId" />
              </el-select>
            </el-form-item>
            <el-form-item label="协作方" prop="participantOrganIds">
              <el-select v-model="formData.participantOrganIds" placeholder="请选择协作方机构" style="width:100%;" @change="onOtherOrganChange">
                <el-option v-for="o in organList" :key="o.globalId" :label="o.globalName" :value="o.globalId" />
              </el-select>
            </el-form-item>
            <el-form-item label="本方数据集" prop="ownResourceId">
              <el-select v-model="formData.ownResourceId" filterable placeholder="请选择本方数据集（含标签方）" style="width:100%;" @change="onOwnResourceChange">
                <el-option v-for="r in ownResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="协作方数据集" prop="participantResourceIds">
              <el-select v-model="formData.participantResourceIds" filterable placeholder="请先选择协作方，再选其数据集" style="width:100%;">
                <el-option v-for="r in otherResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="目标变量（标签）" prop="labelFeature">
              <el-select v-model="formData.labelFeature" filterable placeholder="请选择本方数据中的标签字段" style="width:100%;">
                <el-option v-for="f in ownFieldList" :key="f.fieldName" :label="f.fieldName" :value="f.fieldName" />
              </el-select>
            </el-form-item>
            <el-form-item label="本方特征变量" prop="ownFeatures">
              <el-select v-model="formData.ownFeatures" multiple filterable placeholder="请选择本方参与训练的特征" style="width:100%;">
                <el-option v-for="f in ownFieldList" :key="f.fieldName" :label="f.fieldName" :value="f.fieldName" />
              </el-select>
            </el-form-item>
            <el-form-item label="学习率">
              <el-input-number v-model="formData.learningRate" :min="0.001" :max="1" :step="0.001" :precision="3" style="width:100%;" />
            </el-form-item>
            <el-form-item label="训练轮数（epochs）">
              <el-input-number v-model="formData.epochs" :min="1" :max="1000" :step="1" style="width:100%;" />
            </el-form-item>
            <el-form-item label="批大小（batchSize）">
              <el-input-number v-model="formData.batchSize" :min="1" :max="4096" :step="1" style="width:100%;" />
            </el-form-item>
            <el-form-item label="正则化系数">
              <el-input-number v-model="formData.regularization" :min="0" :max="10" :step="0.001" :precision="4" style="width:100%;" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="submitting" @click="handleSubmit">提交训练</el-button>
              <el-button @click="resetForm">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header">
            <span>训练任务列表</span>
            <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="loadList">刷新</el-button>
          </div>
          <el-table :data="taskList" border size="small" v-loading="listLoading">
            <el-table-column prop="taskName" label="任务名称" min-width="110" show-overflow-tooltip />
            <el-table-column label="进度" width="90" align="center">
              <template slot-scope="{ row }">{{ row.currentRound || 0 }}/{{ row.totalRounds || '-' }}</template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag :type="statusTagType(row.taskState)" size="small">{{ statusLabel(row.taskState) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createDate" label="创建时间" width="140" show-overflow-tooltip />
            <el-table-column label="操作" width="150" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.taskState === 1" type="text" size="mini" @click="handleDownload(row)">结果</el-button>
                <el-button v-if="row.taskState === 2" type="text" size="mini" @click="handleCancel(row)">取消</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C;" @click="handleDelete(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { createTask, getTaskList, downloadResult, deleteTask, cancelTask } from '@/api/federatedLearning'
import { getResourceList } from '@/api/fusionResource'
import { getAvailableOrganList } from '@/api/center'
import { getProjectList } from '@/api/project'

const ALGORITHM_TYPE = 5

export default {
  name: 'FLVerticalLogisticTrain',
  data() {
    return {
      formData: {
        taskName: '',
        projectId: null,
        participantOrganIds: '',
        ownResourceId: '',
        participantResourceIds: '',
        labelFeature: '',
        ownFeatures: [],
        learningRate: 0.01,
        epochs: 10,
        batchSize: 32,
        regularization: 0.01,
        remark: ''
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        participantOrganIds: [{ required: true, message: '请选择协作方', trigger: 'change' }],
        ownResourceId: [{ required: true, message: '请选择本方数据集', trigger: 'change' }],
        participantResourceIds: [{ required: true, message: '请选择协作方数据集', trigger: 'change' }],
        labelFeature: [{ required: true, message: '请选择目标变量', trigger: 'change' }],
        ownFeatures: [{ required: true, type: 'array', min: 1, message: '请选择特征变量', trigger: 'change' }]
      },
      projectList: [],
      organList: [],
      ownResourceList: [],
      otherResourceList: [],
      ownFieldList: [],
      taskList: [],
      listLoading: false,
      submitting: false
    }
  },
  created() {
    this.loadList()
    this.loadOptions()
  },
  methods: {
    async loadOptions() {
      try {
        const [orgRes, projRes, resRes] = await Promise.all([
          getAvailableOrganList(),
          getProjectList({ pageNo: 1, pageSize: 100 }),
          getResourceList({ pageNo: 1, pageSize: 100, organId: this.$store.getters.userOrganId })
        ])
        if (orgRes.code === 0) this.organList = orgRes.result || []
        if (projRes.code === 0) this.projectList = projRes.result?.data || projRes.result?.list || []
        if (resRes.code === 0) this.ownResourceList = resRes.result?.data || []
      } catch (e) { console.error(e) }
    },
    async onOtherOrganChange(organId) {
      this.formData.participantResourceIds = ''
      this.otherResourceList = []
      if (!organId) return
      try {
        const res = await getResourceList({ pageNo: 1, pageSize: 100, organId })
        if (res.code === 0) this.otherResourceList = res.result?.data || []
      } catch (e) { console.error(e) }
    },
    onOwnResourceChange(id) {
      const r = this.ownResourceList.find(x => x.resourceId === id)
      this.ownFieldList = (r && r.fieldList) || []
      this.formData.labelFeature = ''
      this.formData.ownFeatures = []
    },
    async loadList() {
      this.listLoading = true
      try {
        const res = await getTaskList({ taskType: 1, algorithmType: ALGORITHM_TYPE, pageNo: 1, pageSize: 50 })
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
          const res = await createTask({
            taskType: 1,
            algorithmType: ALGORITHM_TYPE,
            federatedType: 2,
            taskName: this.formData.taskName,
            projectId: this.formData.projectId || undefined,
            ownOrganId: this.$store.getters.userOrganId,
            ownResourceId: this.formData.ownResourceId,
            ownFeatures: this.formData.ownFeatures.join(','),
            labelFeature: this.formData.labelFeature,
            isLabelOwner: 1,
            participantOrganIds: this.formData.participantOrganIds,
            participantResourceIds: this.formData.participantResourceIds,
            remarks: this.formData.remark,
            trainingParams: {
              learningRate: this.formData.learningRate,
              epochs: this.formData.epochs,
              batchSize: this.formData.batchSize,
              regularization: this.formData.regularization
            }
          })
          if (res.code === 0) {
            this.$message.success('联邦训练任务已提交，训练在隐私计算节点真实执行')
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
    async handleCancel(row) {
      try {
        const res = await cancelTask({ taskId: row.taskId })
        if (res.code === 0) this.$message.success('已取消')
        else this.$message.error(res.message || '取消失败')
        this.loadList()
      } catch (e) { this.$message.error('取消失败') }
    },
    async handleDownload(row) {
      try {
        const res = await downloadResult({ taskId: row.taskId })
        const url = URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a')
        a.href = url
        a.download = `vfl_logistic_train_${row.taskId}.csv`
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('下载失败')
      }
    },
    async handleDelete(row) {
      try {
        await this.$confirm('确定删除该任务？', '提示', { type: 'warning' })
        const res = await deleteTask({ taskId: row.taskId })
        if (res.code === 0) this.$message.success('删除成功')
        else this.$message.error(res.message || '删除失败')
        this.loadList()
      } catch (e) {
        if (e !== 'cancel') this.$message.error('删除失败')
      }
    },
    resetForm() {
      this.$refs.taskForm.resetFields()
      this.ownFieldList = []
      this.otherResourceList = []
    },
    statusTagType(status) {
      const map = { 0: 'info', 1: 'success', 2: 'warning', 3: 'danger', 4: 'info' }
      return map[status] || 'info'
    },
    statusLabel(status) {
      const map = { 0: '待执行', 1: '训练成功', 2: '训练中', 3: '训练失败', 4: '已取消' }
      return map[status] || '未知'
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
