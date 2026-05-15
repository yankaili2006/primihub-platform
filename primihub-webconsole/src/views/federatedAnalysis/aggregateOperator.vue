<template>
  <div class="app-container">
    <el-page-header content="聚合算子（SUM/AVG等）" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="聚合算子用于在联邦场景下对多方数据进行安全聚合计算，支持 SUM/COUNT/AVG/MAX/MIN/STDDEV 等聚合函数，计算过程不泄露各方原始数据。"
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    />

    <el-row :gutter="20">
      <el-col :span="16">
        <el-card>
          <div slot="header">
            <span>SQL 编辑器</span>
            <el-button size="mini" style="float:right; margin-left:8px;" icon="el-icon-delete" @click="sqlInput = ''">清空</el-button>
            <el-button size="mini" style="float:right;" icon="el-icon-document-copy" @click="copySql">复制</el-button>
          </div>
          <el-input
            v-model="sqlInput"
            type="textarea"
            :rows="10"
            placeholder="请输入 SQL 语句"
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

      <el-col :span="8">
        <el-card>
          <div slot="header"><span>功能说明</span></div>
          <div class="syntax-doc">
            <p class="doc-title">支持的聚合函数</p>
            <ul class="doc-list">
              <li><code>SUM(col)</code>：求和</li>
              <li><code>COUNT(*)</code>：计数</li>
              <li><code>AVG(col)</code>：平均值</li>
              <li><code>MAX(col)</code>：最大值</li>
              <li><code>MIN(col)</code>：最小值</li>
              <li><code>STDDEV(col)</code>：标准差</li>
            </ul>
            <p class="doc-title">安全聚合 SQL 示例</p>
            <pre class="doc-pre">SELECT
  COUNT(*) AS total_users,
  SUM(amount) AS total_amount,
  AVG(amount) AS avg_amount,
  MAX(amount) AS max_amount,
  STDDEV(amount) AS std_amount
FROM federated_sales
WHERE status = 'COMPLETED'</pre>
            <p class="doc-title">联邦场景说明</p>
            <ul class="doc-list">
              <li>采用安全多方计算协议保护各方数据隐私</li>
              <li>只返回聚合结果，不暴露明细数据</li>
              <li>支持跨方字段的联合聚合</li>
            </ul>
          </div>
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

const ANALYSIS_TYPE = 'AGGREGATE'

const DEFAULT_SQL = `SELECT
  COUNT(*) AS total_users,
  SUM(amount) AS total_amount,
  AVG(amount) AS avg_amount,
  MAX(amount) AS max_amount,
  MIN(amount) AS min_amount,
  STDDEV(amount) AS std_amount
FROM federated_sales
WHERE status = 'COMPLETED'`

export default {
  name: 'FAAggregateOperator',
  data() {
    return {
      sqlInput: DEFAULT_SQL,
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
.syntax-doc { font-size: 13px; color: #606266; line-height: 1.8; }
.doc-title { font-weight: bold; color: #303133; margin: 12px 0 6px; }
.doc-list { padding-left: 20px; margin: 0; }
.doc-list li { margin-bottom: 4px; }
.doc-pre { background: #f5f7fa; padding: 10px; border-radius: 4px; font-size: 12px; white-space: pre-wrap; margin: 0; }
code { background: #f0f2f5; padding: 1px 4px; border-radius: 3px; font-family: monospace; }
</style>
