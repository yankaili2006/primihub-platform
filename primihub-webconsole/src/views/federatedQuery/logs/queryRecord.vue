<template>
  <div class="log-page">
    <FederatedQueryNav />
    <el-card>
      <div slot="header"><span>联邦查询记录</span></div>
      <el-form :model="query" :inline="true" size="small">
        <el-form-item label="任务名称"><el-input v-model="query.taskName" placeholder="搜索" clearable @clear="search" @keyup.enter.native="search" /></el-form-item>
        <el-form-item><el-button type="primary" @click="search">查询</el-button><el-button @click="reset">重置</el-button></el-form-item>
      </el-form>
      <el-table v-loading="loading" :data="list" border stripe>
        <el-table-column prop="id" label="ID" width="70" />
        <el-table-column prop="taskName" label="任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="algorithm" label="算法" width="70" />
        <el-table-column prop="queryMode" label="模式" width="80" />
        <el-table-column label="状态" width="90">
          <template slot-scope="{ row }">
            <el-tag :type="stateTag(row.taskState)" size="small">{{ stateText(row.taskState) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="结果/错误" min-width="240" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.resultSummary || row.errorMessage || '-' }}</template>
        </el-table-column>
        <el-table-column label="创建时间" width="170">
          <template slot-scope="{ row }">{{ row.createdAt || row.createDate || '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="90" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="row.taskState === 2" type="text" size="small" @click="downloadResult(row)">下载结果</el-button>
            <span v-else>-</span>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination :current-page="pageNo" :page-size="10" :total="total" layout="total, prev, pager, next" style="margin-top:20px" @current-change="onPageChange" />
    </el-card>
  </div>
</template>
<script>
import FederatedQueryNav from '@/components/FederatedQueryNav'
import { getFederatedQueryList } from '@/api/federatedQuery'
import { getToken } from '@/utils/auth'
export default {
  components: { FederatedQueryNav },
  data() {
    return { query: { taskName: '' }, list: [], total: 0, pageNo: 1, loading: false, timer: null }
  },
  mounted() { this.search() },
  beforeDestroy() { this.stopPolling() },
  methods: {
    async search() {
      this.loading = true
      try {
        const { code, result } = await getFederatedQueryList({
          taskName: this.query.taskName || undefined,
          pageNo: this.pageNo,
          pageSize: 10
        })
        if (code === 0 && result) {
          this.list = result.list || []
          this.total = (result.pageParam && result.pageParam.itemTotalCount) || this.list.length
          // 有运行中任务则轮询刷新，全部终态即停
          if (this.list.some(t => t.taskState === 1)) {
            this.startPolling()
          } else {
            this.stopPolling()
          }
        }
      } catch (e) {
        this.$message.error('查询记录加载失败')
      } finally {
        this.loading = false
      }
    },
    startPolling() {
      if (this.timer) return
      this.timer = setInterval(() => { this.search() }, 5000)
    },
    stopPolling() {
      if (this.timer) { clearInterval(this.timer); this.timer = null }
    },
    stateText(s) {
      return { 0: '待执行', 1: '运行中', 2: '完成', 3: '失败' }[s] || s
    },
    stateTag(s) {
      return { 0: 'info', 1: '', 2: 'success', 3: 'danger' }[s] || 'info'
    },
    downloadResult(row) {
      // 与 model/history.vue 的 downloadTaskFile 同款：带信封参数直开附件
      const timestamp = new Date().getTime()
      const nonce = Math.floor(Math.random() * 1000 + 1)
      window.open(`${process.env.VUE_APP_BASE_API}/federatedQuery/result/download?taskId=${row.id}&timestamp=${timestamp}&nonce=${nonce}&token=${getToken()}`, '_self')
    },
    reset() { this.query = { taskName: '' }; this.pageNo = 1; this.search() },
    onPageChange(p) { this.pageNo = p; this.search() }
  }
}
</script>
