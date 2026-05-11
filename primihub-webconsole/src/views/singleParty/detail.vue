<template>
  <div class="app-container">
    <el-page-header content="任务详情" style="margin-bottom: 20px;" @back="goBack" />

    <el-card v-if="taskInfo" class="detail-card">
      <div slot="header">
        <span>{{ taskInfo.taskName }}</span>
        <el-tag :type="statusTagType(taskInfo.taskState)" size="small" style="margin-left: 12px;">
          {{ taskInfo.taskState | taskStatusFilter }}
        </el-tag>
      </div>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="任务名称">{{ taskInfo.taskName }}</el-descriptions-item>
        <el-descriptions-item label="任务状态">
          <el-tag :type="statusTagType(taskInfo.taskState)" size="small">
            {{ taskInfo.taskState | taskStatusFilter }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="算法类型">{{ taskInfo.algorithmType | algorithmFilter }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ taskInfo.createDate }}</el-descriptions-item>
        <el-descriptions-item v-if="taskInfo.resultRows !== undefined" label="结果行数">{{ taskInfo.resultRows }}</el-descriptions-item>
        <el-descriptions-item v-if="taskInfo.remarks" label="备注">{{ taskInfo.remarks }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card v-if="taskInfo && taskInfo.taskState === 1" class="result-card" style="margin-top: 20px;">
      <div slot="header"><span>执行结果</span></div>
      <el-button type="primary" icon="el-icon-download" @click="handleDownload">下载结果文件</el-button>
    </el-card>
  </div>
</template>

<script>
import { getTaskDetails, downloadResult } from '@/api/singleParty'

const STATUS_OPTIONS = [
  { value: 0, label: '待执行' },
  { value: 1, label: '执行成功' },
  { value: 2, label: '执行中' },
  { value: 3, label: '执行失败' },
  { value: 4, label: '已取消' }
]

const ALGORITHM_OPTIONS = [
  { value: 1, label: '逻辑回归' },
  { value: 2, label: '决策树' },
  { value: 3, label: '随机森林' },
  { value: 4, label: 'XGBoost' },
  { value: 5, label: '线性回归' },
  { value: 6, label: 'K-Means' }
]

export default {
  name: 'SinglePartyDetail',
  filters: {
    taskStatusFilter(val) {
      const opt = STATUS_OPTIONS.find(o => o.value === val)
      return opt ? opt.label : '未知'
    },
    algorithmFilter(val) {
      const opt = ALGORITHM_OPTIONS.find(o => o.value === val)
      return opt ? opt.label : '未知'
    }
  },
  data() {
    return {
      taskInfo: null,
      loading: false
    }
  },
  created() {
    const taskId = this.$route.params.id
    if (taskId) this.fetchDetail(taskId)
  },
  methods: {
    async fetchDetail(taskId) {
      this.loading = true
      try {
        const { result } = await getTaskDetails({ taskId })
        this.taskInfo = result
      } catch (e) {
        this.$message.error('获取任务详情失败')
      } finally {
        this.loading = false
      }
    },
    async handleDownload() {
      if (!this.taskInfo) return
      try {
        const res = await downloadResult({ taskId: this.taskInfo.taskId })
        const blob = new Blob([res])
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = `${this.taskInfo.taskName || 'result'}.csv`
        link.click()
        URL.revokeObjectURL(link.href)
      } catch (e) {
        this.$message.error('下载失败')
      }
    },
    goBack() {
      this.$router.push('/singleParty/list')
    },
    statusTagType(state) {
      const map = { 0: 'info', 1: 'success', 2: 'warning', 3: 'danger', 4: 'info' }
      return map[state] || 'info'
    }
  }
}
</script>

<style scoped>
.detail-card, .result-card {
  margin-bottom: 20px;
}
</style>
