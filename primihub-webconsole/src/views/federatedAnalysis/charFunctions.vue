<template>
  <div class="app-container">
    <el-page-header content="字符类型函数" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="字符类型函数用于在联邦分析 SQL 中对字符串字段进行处理，支持 CONCAT/SUBSTRING/TRIM/UPPER/LOWER/LENGTH/REPLACE/LIKE 等常用字符函数。"
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    />

    <el-row :gutter="20">
      <el-col :span="10">
        <el-card>
          <div slot="header"><span>字符函数列表</span></div>
          <el-table :data="funcList" border size="small" highlight-current-row @current-change="handleFuncSelect">
            <el-table-column prop="name" label="函数名" width="140" />
            <el-table-column prop="syntax" label="语法" min-width="160" show-overflow-tooltip />
            <el-table-column prop="description" label="说明" min-width="120" show-overflow-tooltip />
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

const ANALYSIS_TYPE = 'CHAR_FUNC'

export default {
  name: 'FACharFunctions',
  data() {
    return {
      funcList: [
        { name: 'CONCAT', syntax: "CONCAT(str1, str2, ...)", description: '字符串拼接', example: "SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM users" },
        { name: 'SUBSTRING', syntax: "SUBSTRING(str, pos, len)", description: '截取子字符串', example: "SELECT SUBSTRING(phone, 1, 3) AS area_code FROM users" },
        { name: 'TRIM', syntax: "TRIM([BOTH|LEADING|TRAILING] FROM str)", description: '去除首尾空格', example: "SELECT TRIM(name) AS clean_name FROM users" },
        { name: 'UPPER', syntax: "UPPER(str)", description: '转换为大写', example: "SELECT UPPER(region) AS region_upper FROM sales" },
        { name: 'LOWER', syntax: "LOWER(str)", description: '转换为小写', example: "SELECT LOWER(email) AS email_lower FROM users" },
        { name: 'LENGTH', syntax: "LENGTH(str)", description: '字符串长度', example: "SELECT user_id, LENGTH(name) AS name_len FROM users WHERE LENGTH(name) > 5" },
        { name: 'REPLACE', syntax: "REPLACE(str, from_str, to_str)", description: '替换字符串', example: "SELECT REPLACE(phone, '-', '') AS clean_phone FROM users" },
        { name: 'LIKE', syntax: "col LIKE pattern", description: '模糊匹配', example: "SELECT user_id, name FROM users WHERE name LIKE '张%'" }
      ],
      sqlInput: "SELECT\n  CONCAT(first_name, ' ', last_name) AS full_name,\n  UPPER(region) AS region,\n  LENGTH(address) AS addr_len,\n  REPLACE(phone, '-', '') AS clean_phone\nFROM users\nWHERE name LIKE '张%'\n  AND TRIM(status) = 'active'",
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
