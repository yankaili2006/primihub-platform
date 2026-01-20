<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦分析日志导出" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>导出配置</span></div>
      <el-form ref="exportForm" :model="exportFormData" label-width="120px">
        <el-form-item label="选择任务">
          <el-select v-model="exportFormData.taskIds" multiple placeholder="请选择任务（可多选）" style="width: 100%;">
            <el-option v-for="t in taskList" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据源类型">
          <el-checkbox-group v-model="exportFormData.sourceTypes">
            <el-checkbox label="RDBMS">关系型数据库</el-checkbox>
            <el-checkbox label="BIGDATA">大数据平台</el-checkbox>
            <el-checkbox label="CLOUD">公有云平台</el-checkbox>
          </el-checkbox-group>
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
        <el-form-item label="文件名前缀">
          <el-input v-model="exportFormData.fileNamePrefix" placeholder="federated_analysis_log" style="width: 300px;" />
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
        <el-table-column prop="fileName" label="文件名" width="280" />
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
export default {
  name: 'FederatedAnalysisLogExport',
  data() {
    return {
      exporting: false,
      exportFormData: {
        taskIds: [],
        sourceTypes: ['RDBMS', 'BIGDATA', 'CLOUD'],
        dateRange: [],
        logTypes: ['INFO', 'WARN', 'ERROR'],
        exportFormat: 'EXCEL',
        fileNamePrefix: 'federated_analysis_log'
      },
      taskList: [
        { taskId: 'FA-DB001', taskName: '用户行为联邦分析' },
        { taskId: 'FA-DB002', taskName: '交易数据关联分析' },
        { taskId: 'FA-BD001', taskName: '大规模用户画像分析' },
        { taskId: 'FA-CL001', taskName: '跨云数据联邦分析' }
      ],
      exportHistory: [
        { id: 'EXP001', fileName: 'federated_analysis_log_20240115.xlsx', format: 'EXCEL', recordCount: 2350, fileSize: '512 KB', createTime: '2024-01-15 16:00:00', status: 'completed' },
        { id: 'EXP002', fileName: 'fa_error_log_20240114.csv', format: 'CSV', recordCount: 128, fileSize: '64 KB', createTime: '2024-01-14 18:30:00', status: 'completed' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleExport() {
      this.exporting = true
      setTimeout(() => {
        this.exporting = false
        this.$message.success('日志导出成功')
        this.exportHistory.unshift({
          id: `EXP${Date.now()}`,
          fileName: `${this.exportFormData.fileNamePrefix}_${new Date().toISOString().slice(0, 10)}.${this.exportFormData.exportFormat.toLowerCase()}`,
          format: this.exportFormData.exportFormat,
          recordCount: Math.floor(Math.random() * 2000) + 200,
          fileSize: `${Math.floor(Math.random() * 800) + 100} KB`,
          createTime: new Date().toLocaleString(),
          status: 'completed'
        })
      }, 2000)
    },
    handleReset() {
      this.exportFormData = {
        taskIds: [],
        sourceTypes: ['RDBMS', 'BIGDATA', 'CLOUD'],
        dateRange: [],
        logTypes: ['INFO', 'WARN', 'ERROR'],
        exportFormat: 'EXCEL',
        fileNamePrefix: 'federated_analysis_log'
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
