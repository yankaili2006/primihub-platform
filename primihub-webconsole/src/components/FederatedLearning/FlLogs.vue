<template>
  <div>
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="任务ID">
        <el-input v-model="queryForm.taskId" placeholder="请输入任务ID" clearable style="width: 150px;" />
      </el-form-item>
      <el-form-item label="日志类型">
        <el-select v-model="queryForm.logType" placeholder="请选择" clearable style="width: 120px;">
          <el-option label="INFO" value="INFO" />
          <el-option label="WARN" value="WARN" />
          <el-option label="ERROR" value="ERROR" />
          <el-option label="DEBUG" value="DEBUG" />
        </el-select>
      </el-form-item>
      <el-form-item label="时间范围">
        <el-date-picker v-model="queryForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 340px;" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>
    <el-row style="margin-bottom: 15px;">
      <el-button type="primary" icon="el-icon-download" @click="openExport('ALL')">导出日志</el-button>
      <el-button type="success" icon="el-icon-download" :disabled="selectedLogs.length === 0" @click="openExport('SELECTED')">导出选中</el-button>
    </el-row>
    <el-table :data="logData" border @selection-change="v => { selectedLogs = v }">
      <el-table-column type="selection" width="50" />
      <el-table-column prop="logId" label="日志ID" width="100" />
      <el-table-column prop="taskId" label="任务ID" width="120" show-overflow-tooltip />
      <el-table-column prop="taskName" label="任务名称" width="150" show-overflow-tooltip />
      <el-table-column prop="logType" label="日志类型" width="100">
        <template slot-scope="scope">
          <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType || '-' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="content" label="日志内容" min-width="300" show-overflow-tooltip />
      <el-table-column prop="createTime" label="记录时间" width="160" />
      <el-table-column label="操作" width="100" fixed="right">
        <template slot-scope="scope">
          <el-button size="mini" type="text" @click="viewDetail(scope.row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-pagination style="margin-top: 15px;" :current-page="queryForm.pageNum" :page-sizes="[10, 20, 50]" :page-size="queryForm.pageSize" :total="logTotal" layout="total, sizes, prev, pager, next" @size-change="v => { queryForm.pageSize = v; fetchLogs() }" @current-change="v => { queryForm.pageNum = v; fetchLogs() }" />

    <!-- Log Detail Dialog -->
    <el-dialog title="日志详情" :visible.sync="detailVisible" width="50%" append-to-body>
      <el-descriptions :column="1" border>
        <el-descriptions-item label="日志ID">{{ detailData.logId }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ detailData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ detailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="日志类型">
          <el-tag :type="getLogTypeTag(detailData.logType)" size="small">{{ detailData.logType || '-' }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="记录时间">{{ detailData.createTime }}</el-descriptions-item>
        <el-descriptions-item label="日志内容">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0;">{{ detailData.content }}</pre>
        </el-descriptions-item>
        <el-descriptions-item v-if="detailData.stackTrace" label="堆栈信息">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0; font-size: 12px; color: #f56c6c;">{{ detailData.stackTrace }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Log Export Dialog -->
    <el-dialog title="日志导出配置" :visible.sync="exportVisible" width="50%" append-to-body>
      <el-form :model="exportForm" label-width="120px">
        <el-form-item label="导出范围">
          <el-radio-group v-model="exportForm.exportScope">
            <el-radio label="ALL">全部日志</el-radio>
            <el-radio label="FILTERED">筛选结果</el-radio>
            <el-radio label="SELECTED">选中日志</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="exportForm.exportFormat" style="width: 100%;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="TXT (.txt)" value="TXT" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="日志类型">
          <el-checkbox-group v-model="exportForm.logTypes">
            <el-checkbox label="INFO">INFO</el-checkbox>
            <el-checkbox label="WARN">WARN</el-checkbox>
            <el-checkbox label="ERROR">ERROR</el-checkbox>
            <el-checkbox label="DEBUG">DEBUG</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="包含堆栈信息">
          <el-switch v-model="exportForm.includeStackTrace" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="exportVisible = false">取 消</el-button>
        <el-button type="primary" :loading="exportLoading" @click="submitExport">确认导出</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getFederatedLearningLogs, exportFederatedLearningLog, batchExportFederatedLearningLogs } from '@/api/federatedLearning'

export default {
  name: 'FlLogs',
  props: {
    projectId: { type: [String, Number], default: null }
  },
  data() {
    return {
      logData: [],
      logTotal: 0,
      selectedLogs: [],
      queryForm: { taskId: '', logType: '', dateRange: [], pageNum: 1, pageSize: 10 },
      detailVisible: false,
      detailData: {},
      exportVisible: false,
      exportLoading: false,
      exportForm: { exportScope: 'ALL', exportFormat: 'EXCEL', logTypes: ['INFO', 'WARN', 'ERROR'], includeStackTrace: true }
    }
  },
  mounted() {
    this.fetchLogs()
  },
  methods: {
    async fetchLogs() {
      try {
        const params = {
          ...this.queryForm,
          startTime: this.queryForm.dateRange?.[0] || '',
          endTime: this.queryForm.dateRange?.[1] || ''
        }
        if (this.projectId != null && this.projectId !== '') params.projectId = this.projectId
        const res = await getFederatedLearningLogs(params)
        if (res && res.code === 0 && res.result) {
          const rows = res.result.list || res.result.data || []
          this.logData = rows.map(r => ({
            logId: r.logId || r.id,
            taskId: r.taskId,
            taskName: r.taskName,
            logType: r.logType || r.logLevel,
            content: r.content || r.logContent,
            createTime: r.createTime || r.createDate,
            stackTrace: r.stackTrace
          }))
          this.logTotal = res.result.total || this.logData.length
        } else {
          this.logData = []
          this.logTotal = 0
          this.$message.warning('日志查询失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.logData = []
        this.logTotal = 0
        this.$message.error('日志接口不可用: ' + (e.message || e))
      }
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchLogs()
    },
    handleReset() {
      this.queryForm = { taskId: '', logType: '', dateRange: [], pageNum: 1, pageSize: 10 }
      this.fetchLogs()
    },
    viewDetail(row) {
      this.detailData = { ...row }
      this.detailVisible = true
    },
    openExport(scope) {
      if (scope === 'SELECTED' && this.selectedLogs.length === 0) {
        this.$message.warning('请选择要导出的日志')
        return
      }
      this.exportForm = { exportScope: scope, exportFormat: 'EXCEL', logTypes: ['INFO', 'WARN', 'ERROR'], includeStackTrace: true }
      this.exportVisible = true
    },
    async submitExport() {
      this.exportLoading = true
      try {
        const data = {
          ...this.exportForm,
          logIds: this.exportForm.exportScope === 'SELECTED' ? this.selectedLogs.map(l => l.logId) : []
        }
        if (this.exportForm.exportScope === 'SELECTED') {
          await batchExportFederatedLearningLogs(data)
        } else {
          await exportFederatedLearningLog(data)
        }
        this.$message.success('日志导出成功')
        this.exportVisible = false
      } catch (e) {
        this.$message.error('日志导出失败: ' + (e.message || e))
      }
      this.exportLoading = false
    },
    getLogTypeTag(type) {
      const map = { 'INFO': 'info', 'WARN': 'warning', 'ERROR': 'danger', 'DEBUG': '' }
      return map[type] || 'info'
    }
  }
}
</script>
