<template>
  <div class="container">
    <div class="filter-bar">
      <el-select v-model="searchForm.logType" placeholder="日志类型" style="width: 180px; margin-right: 10px;" clearable>
        <el-option label="操作日志" value="operation" />
        <el-option label="调度日志" value="schedule" />
        <el-option label="计算日志" value="compute" />
      </el-select>
      <el-input v-model="searchForm.userName" placeholder="用户名" style="width: 180px; margin-right: 10px;" clearable />
      <el-date-picker
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="开始日期"
        end-placeholder="结束日期"
        value-format="yyyy-MM-dd HH:mm:ss"
        :default-time="['00:00:00', '23:59:59']"
        style="margin-right: 10px;"
      />
      <el-select v-model="searchForm.format" placeholder="导出格式" style="width: 130px; margin-right: 10px;">
        <el-option label="Excel" value="xlsx" />
        <el-option label="CSV" value="csv" />
      </el-select>
      <el-button type="primary" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
    </div>
    <el-card v-if="exportHistory.length > 0">
      <div slot="header"><span>导出历史</span></div>
      <el-table :data="exportHistory" stripe>
        <el-table-column label="导出时间" prop="exportTime" width="180" />
        <el-table-column label="日志类型" prop="logType" width="120" />
        <el-table-column label="日期范围" prop="dateRange" width="300" />
        <el-table-column label="文件格式" prop="format" width="100" />
        <el-table-column label="文件大小" prop="fileSize" width="120" />
        <el-table-column label="操作" width="120">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="downloadFile(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotal" @pagination="handlePagination" />
    </el-card>
    <el-card v-else>
      <el-alert title="选择日志类型和时间范围后点击「导出」按钮即可导出日志" type="info" :closable="false" show-icon />
    </el-card>
  </div>
</template>

<script>
import Pagination from '@/components/Pagination'
export default {
  name: 'LogExport',
  components: { Pagination },
  data() {
    return {
      searchForm: { logType: 'operation', userName: '', format: 'xlsx' },
      dateRange: [],
      exporting: false,
      exportHistory: [],
      pageNum: 1, pageSize: 10, pageCount: 0, itemTotal: 0
    }
  },
  mounted() { this.fetchHistory() },
  methods: {
    handleExport() {
      if (!this.dateRange || this.dateRange.length !== 2) return this.$message.warning('请选择日期范围')
      this.exporting = true
      setTimeout(() => {
        this.exporting = false
        this.$message.success('导出任务已提交，请稍后在导出历史中下载')
        this.fetchHistory()
      }, 1500)
    },
    handleReset() {
      this.searchForm = { logType: 'operation', userName: '', format: 'xlsx' }
      this.dateRange = []
    },
    fetchHistory() {
      this.exportHistory = [
        { exportTime: new Date().toLocaleString(), logType: '操作日志', dateRange: '2026-05-01 ~ 2026-05-13', format: 'XLSX', fileSize: '1.2 MB' }
      ]
      this.itemTotal = 1
      this.pageCount = 1
    },
    downloadFile(row) {
      this.$message.success(`开始下载: ${row.fileSize}`)
    },
    handlePagination() {}
  }
}
</script>
