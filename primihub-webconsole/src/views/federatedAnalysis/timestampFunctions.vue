<template>
  <div class="app-container">
    <el-page-header content="时间戳类型函数" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="时间戳类型函数用于在联邦分析 SQL 中对时间戳字段进行转换和处理，支持 UNIX_TIMESTAMP/FROM_UNIXTIME/TIMESTAMP/TO_TIMESTAMP/EXTRACT 等函数。"
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    />

    <el-row :gutter="20">
      <el-col :span="10">
        <el-card>
          <div slot="header"><span>时间戳函数列表</span></div>
          <el-table :data="funcList" border size="small" highlight-current-row @current-change="handleFuncSelect">
            <el-table-column prop="name" label="函数名" width="140" />
            <el-table-column prop="syntax" label="语法" min-width="160" show-overflow-tooltip />
            <el-table-column prop="description" label="说明" min-width="100" show-overflow-tooltip />
          </el-table>
        </el-card>
      </el-col>

      <el-col :span="14">
        <el-card>
          <div slot="header">
            <span>SQL 示例编辑器</span>
            <el-button size="mini" style="float:right; margin-left:8px;" icon="el-icon-delete" @click="sqlInput = ''">清空</el-button>
            <el-button size="mini" style="float:right;" icon="el-icon-document-copy" @click="copySql">复制</el-button>
          </div>
          <el-input
            v-model="sqlInput"
            type="textarea"
            :rows="10"
            placeholder="请输入或选择左侧函数自动填充 SQL 示例"
            style="font-family: 'Courier New', monospace; font-size: 13px;"
          />
          <div style="margin-top: 12px;">
            <el-button type="primary" :loading="executing" icon="el-icon-video-play" @click="handleExecute">执行</el-button>
          </div>
        </el-card>

        <el-card style="margin-top: 20px;">
          <div slot="header">
            <span>执行历史</span>
            <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="loadHistory">刷新</el-button>
          </div>
          <el-table :data="historyList" border size="small" v-loading="historyLoading">
            <el-table-column prop="taskId" label="任务ID" width="80" />
            <el-table-column label="SQL摘要" min-width="180" show-overflow-tooltip>
              <template slot-scope="{ row }">{{ row.sqlText ? row.sqlText.substring(0, 100) : '' }}</template>
            </el-table-column>
            <el-table-column label="执行状态" width="90" align="center">
              <template slot-scope="{ row }">
                <el-tag :type="statusTagType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createTime" label="执行时间" width="140" />
            <el-table-column label="操作" width="120" fixed="right">
              <template slot-scope="{ row }">
                <el-button type="text" size="mini" @click="handleViewDetail(row)">查看详情</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C;" @click="handleDeleteHistory(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog title="任务详情" :visible.sync="detailVisible" width="700px">
      <el-descriptions :column="1" border>
        <el-descriptions-item label="任务ID">{{ currentTask.taskId }}</el-descriptions-item>
        <el-descriptions-item label="执行状态">
          <el-tag :type="statusTagType(currentTask.status)" size="small">{{ statusLabel(currentTask.status) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="SQL内容">
          <pre style="margin:0; white-space: pre-wrap; font-size:12px;">{{ currentTask.sqlText }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="执行时间">{{ currentTask.createTime }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer"><el-button @click="detailVisible = false">关闭</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import {
  createFederatedAnalysisTask,
  getFederatedAnalysisTaskList,
  deleteFederatedAnalysisTask
} from '@/api/federatedAnalysis'

const ANALYSIS_TYPE = 'TIMESTAMP_FUNC'

export default {
  name: 'FATimestampFunctions',
  data() {
    return {
      funcList: [
        { name: 'UNIX_TIMESTAMP', syntax: "UNIX_TIMESTAMP([date])", description: '转为Unix时间戳', example: "SELECT user_id, UNIX_TIMESTAMP(create_time) AS ts FROM orders" },
        { name: 'FROM_UNIXTIME', syntax: "FROM_UNIXTIME(ts [, fmt])", description: 'Unix时间戳转日期', example: "SELECT FROM_UNIXTIME(ts_column, '%Y-%m-%d %H:%i:%s') AS dt FROM events" },
        { name: 'TIMESTAMP', syntax: "TIMESTAMP(expr)", description: '转为时间戳类型', example: "SELECT TIMESTAMP(create_date) AS ts FROM records" },
        { name: 'TO_TIMESTAMP', syntax: "TO_TIMESTAMP(str, fmt)", description: '字符串转时间戳', example: "SELECT TO_TIMESTAMP('2024-01-15 10:30:00', 'yyyy-MM-dd HH:mm:ss') AS ts" },
        { name: 'EXTRACT', syntax: "EXTRACT(unit FROM date)", description: '提取日期单元', example: "SELECT EXTRACT(HOUR FROM create_time) AS hour FROM orders GROUP BY EXTRACT(HOUR FROM create_time)" }
      ],
      sqlInput: "SELECT\n  user_id,\n  UNIX_TIMESTAMP(create_time) AS unix_ts,\n  FROM_UNIXTIME(UNIX_TIMESTAMP(create_time), '%Y-%m-%d') AS date_str,\n  EXTRACT(HOUR FROM create_time) AS hour_of_day,\n  EXTRACT(DOW FROM create_time) AS day_of_week\nFROM federated_events\nWHERE create_time >= TIMESTAMP('2024-01-01')\nORDER BY unix_ts DESC\nLIMIT 100",
      executing: false,
      historyList: [],
      historyLoading: false,
      detailVisible: false,
      currentTask: {}
    }
  },
  created() {
    this.loadHistory()
  },
  methods: {
    handleFuncSelect(row) {
      if (row && row.example) {
        this.sqlInput = row.example
      }
    },
    async loadHistory() {
      this.historyLoading = true
      try {
        const res = await getFederatedAnalysisTaskList({ analysisType: ANALYSIS_TYPE })
        this.historyList = res.data || []
      } catch (e) {
        this.$message.error('加载执行历史失败')
      } finally {
        this.historyLoading = false
      }
    },
    async handleExecute() {
      if (!this.sqlInput.trim()) {
        this.$message.warning('请输入 SQL 语句')
        return
      }
      this.executing = true
      try {
        await createFederatedAnalysisTask({ sqlText: this.sqlInput, analysisType: ANALYSIS_TYPE })
        this.$message.success('SQL 已提交执行')
        this.loadHistory()
      } catch (e) {
        this.$message.error('执行失败')
      } finally {
        this.executing = false
      }
    },
    async handleDeleteHistory(row) {
      try {
        await this.$confirm('确定删除该执行记录？', '提示', { type: 'warning' })
        await deleteFederatedAnalysisTask({ taskId: row.taskId })
        this.$message.success('删除成功')
        this.loadHistory()
      } catch (e) {
        if (e !== 'cancel') this.$message.error('删除失败')
      }
    },
    handleViewDetail(row) {
      this.currentTask = row
      this.detailVisible = true
    },
    copySql() {
      navigator.clipboard.writeText(this.sqlInput).then(() => {
        this.$message.success('已复制到剪贴板')
      }).catch(() => {
        this.$message.error('复制失败，请手动复制')
      })
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
