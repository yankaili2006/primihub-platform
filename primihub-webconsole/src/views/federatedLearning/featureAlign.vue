<template>
  <div class="app-container">
    <el-page-header content="联邦学习特征对齐" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="特征对齐由真实 PSI（隐私集合求交）引擎执行：双方在不暴露原始数据的前提下按 ID 字段求交集，任务经 gRPC 派发至隐私计算节点。"
      type="info" show-icon :closable="false" style="margin-bottom:20px;" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建特征对齐（PSI）任务</span></div>
          <el-form ref="taskForm" :model="formData" :rules="formRules" label-width="130px">
            <el-form-item label="任务名称" prop="taskName">
              <el-input v-model="formData.taskName" placeholder="请输入任务名称" @blur="autoFillResultName" />
            </el-form-item>
            <el-form-item label="协作方" prop="otherOrganId">
              <el-select v-model="formData.otherOrganId" placeholder="请选择协作方机构" style="width:100%;" @change="onOtherOrganChange">
                <el-option v-for="o in organList" :key="o.globalId" :label="o.globalName" :value="o.globalId" />
              </el-select>
            </el-form-item>
            <el-form-item label="本方数据集" prop="ownResourceId">
              <el-select v-model="formData.ownResourceId" filterable placeholder="请选择本方数据集" style="width:100%;" @change="onOwnResourceChange">
                <el-option v-for="r in ownResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="本方ID字段" prop="ownKeyword">
              <el-select v-model="formData.ownKeyword" multiple placeholder="请选择本方用于对齐的ID字段" style="width:100%;">
                <el-option v-for="f in ownFieldList" :key="f.fieldName" :label="f.fieldName" :value="f.fieldName" />
              </el-select>
            </el-form-item>
            <el-form-item label="协作方数据集" prop="otherResourceId">
              <el-select v-model="formData.otherResourceId" filterable placeholder="请先选择协作方，再选其数据集" style="width:100%;" @change="onOtherResourceChange">
                <el-option v-for="r in otherResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="协作方ID字段" prop="otherKeyword">
              <el-select v-model="formData.otherKeyword" multiple placeholder="请选择协作方用于对齐的ID字段" style="width:100%;">
                <el-option v-for="f in otherFieldList" :key="f.fieldName" :label="f.fieldName" :value="f.fieldName" />
              </el-select>
            </el-form-item>
            <el-form-item label="结果名称" prop="resultName">
              <el-input v-model="formData.resultName" placeholder="对齐结果资源名称" />
            </el-form-item>
            <el-form-item label="结果获取方">
              <el-checkbox :value="true" disabled>本机构 (发起方)</el-checkbox>
              <el-checkbox v-model="includeOther" :disabled="!formData.otherOrganId">协作方</el-checkbox>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="formData.remarks" type="textarea" :rows="2" placeholder="请输入备注" />
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
            <span>对齐（求交）任务列表</span>
            <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="loadList">刷新</el-button>
          </div>
          <el-table :data="taskList" border size="small" v-loading="listLoading">
            <el-table-column prop="resultName" label="结果名称" min-width="120" show-overflow-tooltip />
            <el-table-column prop="ascription" label="任务类型" width="90" align="center" />
            <el-table-column label="状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag :type="statusTagType(row.taskState)" size="small">{{ statusLabel(row.taskState) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createDate" label="创建时间" width="140" show-overflow-tooltip />
            <el-table-column label="操作" width="110" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.taskState === 1" type="text" size="mini" @click="handleDownload(row)">下载结果</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { saveDataPsi, getPsiTaskList, downloadPsiTask } from '@/api/PSI'
import { getResourceList } from '@/api/fusionResource'
import { getAvailableOrganList } from '@/api/center'

export default {
  name: 'FLFeatureAlign',
  data() {
    return {
      formData: {
        taskName: '',
        otherOrganId: '',
        ownResourceId: '',
        ownKeyword: [],
        otherResourceId: '',
        otherKeyword: [],
        resultName: '',
        remarks: ''
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        otherOrganId: [{ required: true, message: '请选择协作方', trigger: 'change' }],
        ownResourceId: [{ required: true, message: '请选择本方数据集', trigger: 'change' }],
        ownKeyword: [{ required: true, type: 'array', min: 1, message: '请选择本方ID字段', trigger: 'change' }],
        otherResourceId: [{ required: true, message: '请选择协作方数据集', trigger: 'change' }],
        otherKeyword: [{ required: true, type: 'array', min: 1, message: '请选择协作方ID字段', trigger: 'change' }],
        resultName: [{ required: true, message: '请输入结果名称', trigger: 'blur' }]
      },
      includeOther: false,
      organList: [],
      ownResourceList: [],
      otherResourceList: [],
      ownFieldList: [],
      otherFieldList: [],
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
    autoFillResultName() {
      if (!this.formData.resultName && this.formData.taskName) this.formData.resultName = this.formData.taskName + '_对齐结果'
    },
    async loadOptions() {
      try {
        const [orgRes, resRes] = await Promise.all([
          getAvailableOrganList(),
          getResourceList({ pageNo: 1, pageSize: 100, organId: this.$store.getters.userOrganId })
        ])
        if (orgRes.code === 0) this.organList = orgRes.result || []
        if (resRes.code === 0) this.ownResourceList = resRes.result?.data || []
      } catch (e) { console.error(e) }
    },
    async onOtherOrganChange(organId) {
      this.formData.otherResourceId = ''
      this.formData.otherKeyword = []
      this.otherFieldList = []
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
      this.formData.ownKeyword = []
    },
    onOtherResourceChange(id) {
      const r = this.otherResourceList.find(x => x.resourceId === id)
      this.otherFieldList = (r && r.fieldList) || []
      this.formData.otherKeyword = []
    },
    async loadList() {
      this.listLoading = true
      try {
        const res = await getPsiTaskList({ pageNo: 1, pageSize: 50 })
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
          const ownOrganId = this.$store.getters.userOrganId
          const resultOrganIds = this.includeOther && this.formData.otherOrganId
            ? `${ownOrganId},${this.formData.otherOrganId}` : `${ownOrganId}`
          const res = await saveDataPsi({
            taskName: this.formData.taskName,
            ownOrganId,
            ownResourceId: this.formData.ownResourceId,
            ownKeyword: this.formData.ownKeyword.join(','),
            otherOrganId: this.formData.otherOrganId,
            otherResourceId: this.formData.otherResourceId,
            otherKeyword: this.formData.otherKeyword.join(','),
            resultName: this.formData.resultName,
            resultOrganIds,
            remarks: this.formData.remarks,
            outputFormat: 0,
            outputFilePathType: 0,
            outputContent: 0,
            outputNoRepeat: 1,
            psiTag: 0
          })
          if (res.code === 0) {
            this.$message.success('PSI 对齐任务已提交，正在隐私计算节点真实执行')
            this.resetForm()
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
    async handleDownload(row) {
      try {
        const res = await downloadPsiTask({ taskId: row.taskId })
        const url = URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a')
        a.href = url
        a.download = `feature_align_${row.taskId}.csv`
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('下载失败')
      }
    },
    resetForm() {
      this.$refs.taskForm.resetFields()
      this.includeOther = false
      this.ownFieldList = []
      this.otherFieldList = []
      this.otherResourceList = []
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
