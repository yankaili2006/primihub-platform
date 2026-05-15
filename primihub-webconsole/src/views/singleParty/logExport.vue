<template>
  <div class="app-container">
    <el-page-header content="单方学习日志导出" style="margin-bottom:20px;" @back="$router.go(-1)" />

    <el-card style="margin-bottom:20px;">
      <div slot="header">导出配置</div>
      <el-form ref="exportForm" :model="exportForm" :rules="exportRules" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="任务类型" prop="taskTypes">
              <el-select v-model="exportForm.taskTypes" multiple placeholder="请选择任务类型（不选则全部）" style="width:100%;">
                <el-option v-for="t in taskTypeOptions" :key="t.value" :label="t.label" :value="t.value" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="日志级别" prop="logLevels">
              <el-select v-model="exportForm.logLevels" multiple placeholder="请选择日志级别（不选则全部）" style="width:100%;">
                <el-option label="INFO" value="INFO" />
                <el-option label="WARN" value="WARN" />
                <el-option label="ERROR" value="ERROR" />
                <el-option label="DEBUG" value="DEBUG" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="时间范围" prop="timeRange">
              <el-date-picker
                v-model="exportForm.timeRange"
                type="daterange"
                range-separator="至"
                start-placeholder="开始时间"
                end-placeholder="结束时间"
                value-format="yyyy-MM-dd"
                style="width:100%;"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="导出格式" prop="exportFormat">
              <el-radio-group v-model="exportForm.exportFormat">
                <el-radio label="EXCEL">Excel</el-radio>
                <el-radio label="CSV">CSV</el-radio>
                <el-radio label="JSON">JSON</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item>
          <el-button type="primary" :loading="exporting" icon="el-icon-download" @click="handleExport">立即导出</el-button>
          <el-button @click="resetExportForm">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card>
      <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
        <span>导出历史</span>
        <el-button size="small" icon="el-icon-refresh" @click="fetchHistory">刷新</el-button>
      </div>
      <el-table v-loading="loading" :data="historyList" border>
        <el-table-column type="index" width="50" label="序号" />
        <el-table-column prop="exportTime" label="导出时间" width="160" />
        <el-table-column prop="conditionSummary" label="导出条件摘要" min-width="200" show-overflow-tooltip />
        <el-table-column prop="exportFormat" label="导出格式" width="100">
          <template slot-scope="{row}">
            <el-tag size="small" :type="formatTag(row.exportFormat)">{{ row.exportFormat }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="fileSize" label="文件大小" width="120" />
        <el-table-column label="操作" width="100" fixed="right">
          <template slot-scope="{row}">
            <el-button type="text" size="small" @click="handleDownloadHistory(row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:16px;" :current-page="historyQuery.pageNo" :page-size="historyQuery.pageSize"
        :total="historyTotal" layout="total,prev,pager,next" @current-change="p=>{historyQuery.pageNo=p;fetchHistory()}" />
    </el-card>
  </div>
</template>

<script>
import { getSinglePartyLogs, exportSinglePartyLogs } from '@/api/singleParty'

const TASK_TYPES = [
  { value: 'DATA_STATS', label: '数据统计' },
  { value: 'DATA_CLEANING', label: '数据清洗' },
  { value: 'DATA_SCALING', label: '数据缩放' },
  { value: 'FEATURE_ENCODE', label: '特征编码' },
  { value: 'FEATURE_BIN', label: '特征分箱' },
  { value: 'FEATURE_SELECT', label: '特征筛选' },
  { value: 'FEATURE_DERIVE', label: '特征衍生' },
  { value: 'PYTHON_SCRIPT', label: 'Python脚本' },
  { value: 'SQL_PROCESS', label: 'SQL处理' },
  { value: 'LR', label: 'LR算法' },
  { value: 'XGB', label: 'XGB算法' }
]

export default {
  name: 'SinglePartyLogExport',
  data() {
    return {
      exportForm: { taskTypes: [], logLevels: [], timeRange: [], exportFormat: 'EXCEL' },
      exportRules: {
        exportFormat: [{ required: true, message: '请选择导出格式', trigger: 'change' }]
      },
      exporting: false,
      taskTypeOptions: TASK_TYPES,
      historyQuery: { pageNo: 1, pageSize: 10 },
      historyList: [], historyTotal: 0, loading: false
    }
  },
  created() { this.fetchHistory() },
  methods: {
    async fetchHistory() {
      this.loading = true
      try {
        const res = await getSinglePartyLogs({ ...this.historyQuery, queryType: 'EXPORT_HISTORY' })
        if (res.code === 0) { this.historyList = res.result?.list || []; this.historyTotal = res.result?.total || 0 }
      } catch (e) { console.error(e) } finally { this.loading = false }
    },
    resetExportForm() {
      this.$refs.exportForm && this.$refs.exportForm.resetFields()
      this.exportForm = { taskTypes: [], logLevels: [], timeRange: [], exportFormat: 'EXCEL' }
    },
    async handleExport() {
      this.$refs.exportForm.validate(async valid => {
        if (!valid) return
        this.exporting = true
        try {
          const params = {
            taskTypes: this.exportForm.taskTypes.join(','),
            logLevels: this.exportForm.logLevels.join(','),
            exportFormat: this.exportForm.exportFormat
          }
          if (this.exportForm.timeRange && this.exportForm.timeRange.length === 2) {
            params.startTime = this.exportForm.timeRange[0]
            params.endTime = this.exportForm.timeRange[1]
          }
          const res = await exportSinglePartyLogs(params)
          const ext = this.exportForm.exportFormat === 'EXCEL' ? 'xlsx' : this.exportForm.exportFormat.toLowerCase()
          const url = window.URL.createObjectURL(new Blob([res]))
          const a = document.createElement('a'); a.href = url; a.download = `单方学习日志_${new Date().toLocaleDateString()}.${ext}`; a.click()
          window.URL.revokeObjectURL(url)
          this.$message.success('导出成功')
          this.fetchHistory()
        } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
      })
    },
    async handleDownloadHistory(row) {
      try {
        const res = await exportSinglePartyLogs({ exportId: row.exportId })
        const ext = row.exportFormat === 'EXCEL' ? 'xlsx' : (row.exportFormat || 'csv').toLowerCase()
        const url = window.URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a'); a.href = url; a.download = `日志导出_${row.exportTime}.${ext}`; a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('下载失败') }
    },
    formatTag(v) { const map = { EXCEL: 'success', CSV: 'primary', JSON: 'warning' }; return map[v] || 'info' }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
