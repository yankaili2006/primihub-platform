<template>
  <div class="app-container">
    <el-page-header content="联邦学习日志导出" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>导出配置</span></div>
      <el-form ref="exportForm" :model="exportFormData" label-width="120px">
        <el-form-item label="选择任务">
          <el-select v-model="exportFormData.taskIds" multiple placeholder="请选择任务（可多选）" style="width: 100%;">
            <el-option v-for="t in taskList" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="exportFormData.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="日志类型">
          <el-checkbox-group v-model="exportFormData.logTypes">
            <el-checkbox label="INFO">INFO</el-checkbox>
            <el-checkbox label="WARN">WARN</el-checkbox>
            <el-checkbox label="ERROR">ERROR</el-checkbox>
            <el-checkbox label="DEBUG">DEBUG</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="exportFormData.exportFormat" style="width: 200px;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="TXT (.txt)" value="TXT" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="包含堆栈信息">
          <el-switch v-model="exportFormData.includeStackTrace" />
        </el-form-item>
        <el-form-item label="文件名前缀">
          <el-input v-model="exportFormData.fileNamePrefix" placeholder="federated_learning_log" style="width: 300px;" />
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
        <el-table-column prop="fileName" label="文件名" width="250" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="recordCount" label="记录数" width="100" />
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
import { getTaskList, exportFederatedLearningLog } from '@/api/federatedLearning'

export default {
  name: 'FederatedLearningLogExport',
  data() {
    return {
      exporting: false,
      exportFormData: {
        taskIds: [],
        dateRange: [],
        logTypes: ['INFO', 'WARN', 'ERROR'],
        exportFormat: 'EXCEL',
        includeStackTrace: true,
        fileNamePrefix: 'federated_learning_log'
      },
      taskList: [],
      // 缺陷整改：后端无“导出历史”接口，导出为即时下载 blob，不留服务端记录；置空不再造假数据
      exportHistory: []
    }
  },
  mounted() {
    this.fetchTaskList()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    // 缺陷整改 T2：任务下拉改真实任务（导出需真实 taskId 才能查到数据）
    fetchTaskList() {
      getTaskList({ pageNo: 1, pageSize: 200 }).then(res => {
        const data = (res && res.result && (res.result.data || res.result.list)) || []
        this.taskList = data.map(t => ({ taskId: t.taskId, taskName: t.taskName }))
      }).catch(() => { this.taskList = [] })
    },
    // 缺陷整改 T2：改为真实导出并触发文件下载（原 setTimeout 假成功、不产文件）
    // 后端 /log/exportComputeLog 按单 taskId 过滤，多选时导出所选第一个任务
    handleExport() {
      if (this.exportFormData.taskIds.length === 0) {
        this.$message.warning('请选择至少一个任务')
        return
      }
      this.exporting = true
      const params = {
        taskId: this.exportFormData.taskIds[0],
        startTime: this.exportFormData.dateRange && this.exportFormData.dateRange[0] ? this.exportFormData.dateRange[0] : '',
        endTime: this.exportFormData.dateRange && this.exportFormData.dateRange[1] ? this.exportFormData.dateRange[1] : ''
      }
      exportFederatedLearningLog(params).then(response => {
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `${this.exportFormData.fileNamePrefix}_${new Date().getTime()}.xlsx`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('日志导出成功')
      }).catch(() => {
        this.$message.error('导出失败')
      }).finally(() => {
        this.exporting = false
      })
    },
    handleReset() {
      this.exportFormData = {
        taskIds: [],
        dateRange: [],
        logTypes: ['INFO', 'WARN', 'ERROR'],
        exportFormat: 'EXCEL',
        includeStackTrace: true,
        fileNamePrefix: 'federated_learning_log'
      }
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.fileName}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
