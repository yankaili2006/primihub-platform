<template>
  <div class="app-container">
    <el-page-header content="联邦统计结果导出" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>导出配置</span></div>
      <el-form ref="exportForm" :model="exportFormData" label-width="120px">
        <el-form-item label="选择统计任务">
          <el-select v-model="exportFormData.taskIds" multiple placeholder="请选择任务（可多选）" style="width: 100%;">
            <el-option v-for="t in taskList" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="exportFormData.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="导出内容">
          <el-checkbox-group v-model="exportFormData.exportContent">
            <el-checkbox label="SUMMARY">统计摘要</el-checkbox>
            <el-checkbox label="DETAIL">详细数据</el-checkbox>
            <el-checkbox label="CHART">图表数据</el-checkbox>
            <el-checkbox label="RAW">原始数据</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="exportFormData.exportFormat" style="width: 200px;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="PDF (.pdf)" value="PDF" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="包含图表">
          <el-switch v-model="exportFormData.includeCharts" />
        </el-form-item>
        <el-form-item label="文件名前缀">
          <el-input v-model="exportFormData.fileNamePrefix" placeholder="federated_statistics_result" style="width: 300px;" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="exporting" @click="handleExport">开始导出</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>导出历史</span></div>
      <el-table :data="exportHistory" border>
        <el-table-column prop="id" label="导出ID" width="100" />
        <el-table-column prop="fileName" label="文件名" width="300" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="taskCount" label="任务数" width="80" />
        <el-table-column prop="fileSize" label="文件大小" width="100" />
        <el-table-column prop="createTime" label="导出时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'completed' ? 'success' : 'warning'" size="small">
              {{ scope.row.status === 'completed' ? '已完成' : '导出中' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template slot-scope="scope">
            <el-button size="mini" type="primary" :disabled="scope.row.status !== 'completed'" @click="handleDownload(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getStatisticsTaskList, batchExportStatisticsResult } from '@/api/federatedStatisticsApi'

export default {
  name: 'FederatedStatisticsResultExport',
  data() {
    return {
      exporting: false,
      exportFormData: {
        taskIds: [],
        dateRange: [],
        exportContent: ['SUMMARY', 'DETAIL'],
        exportFormat: 'EXCEL',
        includeCharts: true,
        fileNamePrefix: 'federated_statistics_result'
      },
      taskList: [],
      exportHistory: [
        { id: 'EXP001', fileName: 'federated_statistics_result_20240115.xlsx', format: 'EXCEL', taskCount: 3, fileSize: '1.2 MB', createTime: '2024-01-15 16:00:00', status: 'completed' },
        { id: 'EXP002', fileName: 'statistics_summary_20240114.pdf', format: 'PDF', taskCount: 2, fileSize: '856 KB', createTime: '2024-01-14 18:30:00', status: 'completed' }
      ]
    }
  },
  mounted() {
    this.fetchTaskList()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    // 缺陷整改 T2：任务下拉改真实任务（批量导出后端按数值 taskId 查询）
    fetchTaskList() {
      getStatisticsTaskList({ pageNo: 1, pageSize: 200 }).then(res => {
        if (res && res.code === 0 && res.result) {
          this.taskList = (res.result.list || []).map(t => ({ taskId: t.id, taskName: t.taskName }))
        }
      }).catch(() => { this.taskList = [] })
    },
    // 缺陷整改 T2：改为真实批量导出并触发下载（原 setTimeout 假成功、不产文件）
    handleExport() {
      if (this.exportFormData.taskIds.length === 0) {
        this.$message.warning('请选择至少一个统计任务')
        return
      }
      this.exporting = true
      const data = {
        taskIds: this.exportFormData.taskIds,
        format: this.exportFormData.exportFormat
      }
      const fileName = `${this.exportFormData.fileNamePrefix}_${new Date().getTime()}.xlsx`
      batchExportStatisticsResult(data).then(response => {
        this.triggerBlobDownload(response, fileName)
        // 记录真实导出历史(带 taskIds, 供"导出历史→下载"再次下载)
        this.exportHistory.unshift({
          id: 'EXP' + Date.now(),
          fileName,
          format: this.exportFormData.exportFormat,
          taskIds: [...this.exportFormData.taskIds],
          taskCount: this.exportFormData.taskIds.length,
          fileSize: '-',
          createTime: new Date().toLocaleString(),
          status: 'completed'
        })
        this.$message.success('结果导出成功')
      }).catch(() => {
        this.$message.error('导出失败')
      }).finally(() => {
        this.exporting = false
      })
    },
    // 把 blob 响应真正触发浏览器下载(通用)
    triggerBlobDownload(response, filename) {
      const blob = response instanceof Blob ? response : new Blob([response], { type: 'application/octet-stream' })
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = filename
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
    },
    handleReset() {
      this.exportFormData = {
        taskIds: [],
        dateRange: [],
        exportContent: ['SUMMARY', 'DETAIL'],
        exportFormat: 'EXCEL',
        includeCharts: true,
        fileNamePrefix: 'federated_statistics_result'
      }
    },
    // 缺陷整改: 原 handleDownload 只弹提示不下载 -> 真实按 taskIds 重新导出并触发下载
    handleDownload(row) {
      if (!row.taskIds || row.taskIds.length === 0) {
        this.$message.warning('该历史记录为演示数据(无关联任务)，请在上方选择任务重新导出')
        return
      }
      batchExportStatisticsResult({ taskIds: row.taskIds, format: row.format }).then(response => {
        this.triggerBlobDownload(response, row.fileName || `export_${row.id}.xlsx`)
        this.$message.success('下载完成')
      }).catch(() => {
        this.$message.error('下载失败')
      })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
