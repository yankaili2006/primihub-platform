<template>
  <div class="app-container">
    <el-page-header content="连接算子（JOIN）" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="连接算子用于在联邦分析中实现多方数据的隐私保护连接，支持 INNER JOIN、LEFT JOIN、FULL JOIN 等标准连接类型。"
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
            <p class="doc-title">支持的连接类型</p>
            <ul class="doc-list">
              <li><code>INNER JOIN</code>：取两方数据的交集</li>
              <li><code>LEFT JOIN</code>：保留左方全部数据</li>
              <li><code>FULL JOIN</code>：取两方数据的并集</li>
              <li><code>CROSS JOIN</code>：笛卡尔积连接</li>
            </ul>
            <p class="doc-title">三方 JOIN 示例</p>
            <pre class="doc-pre">SELECT a.user_id, b.amount, c.region
FROM party_a.users a
INNER JOIN party_b.orders b
  ON a.user_id = b.user_id
LEFT JOIN party_c.regions c
  ON a.region_id = c.id
WHERE b.amount > 500</pre>
            <p class="doc-title">联邦场景说明</p>
            <ul class="doc-list">
              <li>JOIN 操作通过 PSI 等隐私求交协议实现</li>
              <li>各方数据不会直接传输给对方</li>
              <li>ON 子句的关联字段需事先协商</li>
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

const ANALYSIS_TYPE = 'JOIN'

const DEFAULT_SQL = `SELECT a.user_id, a.name, b.amount, c.region
FROM party_a.users a
INNER JOIN party_b.orders b
  ON a.user_id = b.user_id
LEFT JOIN party_c.locations c
  ON a.city_id = c.id
WHERE b.amount > 500
  AND b.status = 'PAID'`

export default {
  name: 'FAJoinOperator',
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
