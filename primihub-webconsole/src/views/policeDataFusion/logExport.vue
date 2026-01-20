<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="流程执行日志导出" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>导出配置</span></div>
      <el-form ref="exportForm" :model="exportForm" label-width="120px">
        <el-form-item label="流程类型">
          <el-checkbox-group v-model="exportForm.processTypes">
            <el-checkbox label="fusion">数据融合</el-checkbox>
            <el-checkbox label="keygen">密钥生成</el-checkbox>
            <el-checkbox label="encrypt">模型加密</el-checkbox>
            <el-checkbox label="compute">联合运算</el-checkbox>
            <el-checkbox label="decrypt">数据解密</el-checkbox>
            <el-checkbox label="exchange">数据交换</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="日志级别">
          <el-checkbox-group v-model="exportForm.logLevels">
            <el-checkbox label="INFO">INFO</el-checkbox>
            <el-checkbox label="WARN">WARN</el-checkbox>
            <el-checkbox label="ERROR">ERROR</el-checkbox>
            <el-checkbox label="DEBUG">DEBUG</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="exportForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="exportForm.exportFormat" style="width: 200px;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="TXT (.txt)" value="TXT" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="文件名前缀">
          <el-input v-model="exportForm.fileNamePrefix" placeholder="police_data_fusion_log" style="width: 300px;" />
        </el-form-item>
        <el-form-item label="包含详情">
          <el-switch v-model="exportForm.includeDetail" active-text="是" inactive-text="否" />
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
        <el-table-column prop="exportId" label="导出ID" width="120" />
        <el-table-column prop="fileName" label="文件名" width="300" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="recordCount" label="记录数" width="100" />
        <el-table-column prop="fileSize" label="文件大小" width="100" />
        <el-table-column prop="createTime" label="导出时间" width="160" />
        <el-table-column prop="status" label="状态" width="80">
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
  name: 'PoliceDataFusionLogExport',
  data() {
    return {
      exporting: false,
      exportForm: {
        processTypes: ['fusion', 'compute', 'exchange'],
        logLevels: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        exportFormat: 'EXCEL',
        fileNamePrefix: 'police_data_fusion_log',
        includeDetail: true
      },
      exportHistory: [
        { exportId: 'EXP001', fileName: 'police_data_fusion_log_20240115.xlsx', format: 'EXCEL', recordCount: 2580, fileSize: '512 KB', createTime: '2024-01-15 16:00:00', status: 'completed' },
        { exportId: 'EXP002', fileName: 'pdf_error_log_20240114.csv', format: 'CSV', recordCount: 125, fileSize: '68 KB', createTime: '2024-01-14 18:30:00', status: 'completed' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleExport() {
      this.exporting = true
      setTimeout(() => {
        this.exporting = false
        this.$message.success('日志导出成功')
        this.exportHistory.unshift({
          exportId: `EXP${Date.now()}`,
          fileName: `${this.exportForm.fileNamePrefix}_${new Date().toISOString().slice(0, 10)}.${this.exportForm.exportFormat.toLowerCase()}`,
          format: this.exportForm.exportFormat,
          recordCount: Math.floor(Math.random() * 3000) + 500,
          fileSize: `${Math.floor(Math.random() * 800) + 100} KB`,
          createTime: new Date().toLocaleString(),
          status: 'completed'
        })
      }, 2000)
    },
    handleReset() {
      this.exportForm = {
        processTypes: ['fusion', 'compute', 'exchange'],
        logLevels: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        exportFormat: 'EXCEL',
        fileNamePrefix: 'police_data_fusion_log',
        includeDetail: true
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
