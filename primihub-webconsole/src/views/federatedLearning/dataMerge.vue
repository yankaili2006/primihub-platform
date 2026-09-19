<template>
  <div class="app-container">
    <el-page-header content="单方数据合并模块" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>数据合并配置</span></div>
          <el-form ref="mergeForm" :model="mergeFormData" :rules="mergeRules" label-width="100px">
            <el-form-item label="合并名称" prop="mergeName">
              <el-input v-model="mergeFormData.mergeName" placeholder="请输入合并任务名称" />
            </el-form-item>
            <el-form-item label="数据源选择" prop="dataSources">
              <el-select v-model="mergeFormData.dataSources" multiple filterable placeholder="请选择至少 2 个本机构数据资源" style="width: 100%;">
                <el-option v-for="r in resourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="合并方式">
              <el-radio-group v-model="mergeFormData.mergeType">
                <el-radio label="UNION">纵向合并（按同名字段追加行）</el-radio>
                <el-radio label="JOIN">横向合并（按关联字段 Join）</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item v-if="mergeFormData.mergeType === 'JOIN'" label="关联字段" prop="joinKey">
              <el-input v-model="mergeFormData.joinKey" placeholder="请输入各数据源共有的关联字段名" />
            </el-form-item>
            <el-form-item label="去重处理">
              <el-switch v-model="mergeFormData.deduplication" />
            </el-form-item>
            <el-form-item label="输出格式">
              <el-select v-model="mergeFormData.outputFormat" style="width: 100%;">
                <el-option label="CSV" value="CSV" />
                <el-option label="Parquet" value="PARQUET" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="submitting" @click="handleMerge">创建合并任务</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>说明</span></div>
          <div class="merge-tip">
            <p>· 数据合并在本机构内真实执行：读取所选数据资源的本地数据文件，按所选方式合并。</p>
            <p>· 纵向合并：各数据源按共同字段拼接行（无共同字段将报错）。</p>
            <p>· 横向合并：各数据源按关联字段做内连接（关联字段需在每个数据源中存在）。</p>
            <p>· 创建后在下方历史列表点击「执行」运行，完成后可下载真实结果文件。</p>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>合并历史</span>
        <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="loadMergeHistory">刷新</el-button>
      </div>
      <el-table :data="mergeHistory" border>
        <el-table-column prop="taskId" label="任务ID" width="200" show-overflow-tooltip />
        <el-table-column prop="taskName" label="任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="taskState" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.taskState)" size="small">{{ getStatusLabel(scope.row.taskState) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="errorMsg" label="失败原因" min-width="160" show-overflow-tooltip />
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button v-if="scope.row.taskState === 0" size="mini" type="primary" @click="handleRunTask(scope.row)">执行</el-button>
            <el-button size="mini" :disabled="scope.row.taskState !== 1" @click="handleDownloadResult(scope.row)">下载</el-button>
            <el-button size="mini" type="danger" @click="handleDeleteTask(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { createFLPreprocess, getFLPreprocessList, runFLPreprocess, deleteFLPreprocess, downloadFLPreprocessResult } from '@/api/federatedLearning'
import { getResourceList } from '@/api/resource'

const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'SinglePartyDataMerge',
  data() {
    const validateSources = (rule, value, callback) => {
      if (!value || value.length < 2) callback(new Error('请选择至少 2 个数据源'))
      else callback()
    }
    return {
      mergeFormData: {
        mergeName: '',
        dataSources: [],
        mergeType: 'UNION',
        joinKey: '',
        deduplication: true,
        outputFormat: 'CSV'
      },
      mergeRules: {
        mergeName: [{ required: true, message: '请输入合并任务名称', trigger: 'blur' }],
        dataSources: [{ required: true, validator: validateSources, trigger: 'change' }],
        joinKey: [{ required: true, message: '请输入关联字段', trigger: 'blur' }]
      },
      resourceList: [],
      mergeHistory: [],
      submitting: false
    }
  },
  created() {
    this.loadMergeHistory()
    this.loadResources()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    async loadResources() {
      try {
        const res = await getResourceList({ pageNo: 1, pageSize: 100 })
        this.resourceList = res.result?.data || []
      } catch (e) {
        this.resourceList = []
      }
    },
    loadMergeHistory() {
      getFLPreprocessList({ preprocessType: 'DATA_MERGE', pageNo: 1, pageSize: 100 }).then(res => {
        const list = (res && res.result && (res.result.data || res.result.list)) || []
        this.mergeHistory = Array.isArray(list) ? list : []
      }).catch(() => { this.mergeHistory = [] })
    },
    handleMerge() {
      this.$refs.mergeForm.validate((valid) => {
        if (!valid) return
        this.submitting = true
        const names = this.mergeFormData.dataSources
          .map(id => (this.resourceList.find(r => r.resourceId === id) || {}).resourceName)
          .filter(Boolean)
        const payload = {
          taskName: this.mergeFormData.mergeName,
          preprocessType: 'DATA_MERGE',
          mergeType: this.mergeFormData.mergeType,
          dataSources: this.mergeFormData.dataSources,
          resourceId: this.mergeFormData.dataSources.join(','),
          resourceName: names.join(','),
          joinKey: this.mergeFormData.joinKey,
          deduplication: this.mergeFormData.deduplication,
          outputFormat: this.mergeFormData.outputFormat
        }
        createFLPreprocess(payload).then(res => {
          this.submitting = false
          if (!res || res.code !== 0) {
            this.$message.error((res && (res.message || res.msg)) || '创建失败')
            return
          }
          this.$message.success('数据合并任务已创建，请在历史列表点击「执行」运行')
          this.loadMergeHistory()
        }).catch(() => { this.submitting = false; this.$message.error('请求异常') })
      })
    },
    async handleRunTask(row) {
      try {
        const res = await runFLPreprocess({ taskId: row.taskId })
        if (res.code === 0) this.$message.success('任务执行成功')
        else this.$message.error(res.message || '执行失败')
        this.loadMergeHistory()
      } catch (e) {
        this.$message.error('请求异常')
      }
    },
    async handleDownloadResult(row) {
      try {
        const res = await downloadFLPreprocessResult({ taskId: row.taskId })
        const url = URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a')
        a.href = url
        a.download = `data_merge_${row.taskId}.csv`
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('下载失败')
      }
    },
    async handleDeleteTask(row) {
      try {
        await this.$confirm(`确认删除合并任务「${row.taskName}」？`, '提示', { type: 'warning' })
        const res = await deleteFLPreprocess({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success('已删除'); this.loadMergeHistory() } else this.$message.error(res.message)
      } catch (e) {
        if (e !== 'cancel') this.$message.error('操作失败')
      }
    },
    getStatusType(state) {
      return STATUS_MAP[state]?.type || 'info'
    },
    getStatusLabel(state) {
      return STATUS_MAP[state]?.label || '未知'
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.merge-tip { font-size: 13px; color: #606266; line-height: 1.8; }
</style>
