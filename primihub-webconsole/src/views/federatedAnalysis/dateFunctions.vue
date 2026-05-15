<template>
  <div class="app-container">
    <el-page-header content="日期类型函数" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="日期类型函数用于在联邦分析 SQL 中对日期字段进行格式化、计算和提取，支持 DATE_FORMAT/DATEDIFF/DATE_ADD/DATE_SUB/YEAR/MONTH/DAY/NOW/CURDATE 等函数。"
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    />

    <el-row :gutter="20">
      <el-col :span="10">
        <el-card>
          <div slot="header"><span>日期函数列表</span></div>
          <el-table :data="funcList" border size="small" highlight-current-row @current-change="handleFuncSelect">
            <el-table-column prop="name" label="函数名" width="130" />
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

const ANALYSIS_TYPE = 'DATE_FUNC'

export default {
  name: 'FADateFunctions',
  data() {
    return {
      funcList: [
        { name: 'DATE_FORMAT', syntax: "DATE_FORMAT(date, fmt)", description: '日期格式化', example: "SELECT DATE_FORMAT(create_time, '%Y-%m-%d') AS date FROM orders" },
        { name: 'DATEDIFF', syntax: "DATEDIFF(date1, date2)", description: '日期差（天）', example: "SELECT DATEDIFF(CURDATE(), create_time) AS days_ago FROM orders" },
        { name: 'DATE_ADD', syntax: "DATE_ADD(date, INTERVAL n unit)", description: '日期加法', example: "SELECT DATE_ADD(create_time, INTERVAL 30 DAY) AS expire_time FROM orders" },
        { name: 'DATE_SUB', syntax: "DATE_SUB(date, INTERVAL n unit)", description: '日期减法', example: "SELECT * FROM orders WHERE create_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)" },
        { name: 'YEAR', syntax: "YEAR(date)", description: '提取年份', example: "SELECT YEAR(create_time) AS year, COUNT(*) AS cnt FROM orders GROUP BY YEAR(create_time)" },
        { name: 'MONTH', syntax: "MONTH(date)", description: '提取月份', example: "SELECT MONTH(create_time) AS month, SUM(amount) FROM orders GROUP BY MONTH(create_time)" },
        { name: 'DAY', syntax: "DAY(date)", description: '提取日', example: "SELECT DAY(create_time) AS day_of_month FROM orders WHERE MONTH(create_time) = 1" },
        { name: 'NOW', syntax: "NOW()", description: '当前日期时间', example: "SELECT *, NOW() AS query_time FROM orders WHERE create_time <= NOW()" },
        { name: 'CURDATE', syntax: "CURDATE()", description: '当前日期', example: "SELECT * FROM orders WHERE DATE_FORMAT(create_time, '%Y-%m-%d') = CURDATE()" }
      ],
      sqlInput: "SELECT\n  DATE_FORMAT(create_time, '%Y-%m') AS month,\n  COUNT(*) AS order_count,\n  SUM(amount) AS total_amount,\n  DATEDIFF(CURDATE(), MAX(create_time)) AS days_since_last\nFROM federated_orders\nWHERE create_time >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)\nGROUP BY DATE_FORMAT(create_time, '%Y-%m')\nORDER BY month DESC",
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
