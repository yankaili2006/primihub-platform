<template>
  <div class="log-page">
    <FederatedQueryNav />
    <el-card>
      <div slot="header"><span>联邦求交日志记录</span></div>
      <el-form :model="query" :inline="true" size="small">
        <el-form-item label="任务名称"><el-input v-model="query.taskName" placeholder="搜索" clearable /></el-form-item>
        <el-form-item label="时间范围"><el-date-picker v-model="query.dateRange" type="daterange" range-separator="至" /></el-form-item>
        <el-form-item><el-button type="primary" @click="search">查询</el-button><el-button @click="reset">重置</el-button></el-form-item>
      </el-form>
      <el-table :data="list" border stripe v-loading="loading">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="taskName" label="任务名称" />
        <el-table-column prop="logLevel" label="级别" width="80" />
        <el-table-column prop="logContent" label="日志内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="时间" width="180" />
      </el-table>
      <el-pagination @current-change="onPageChange" :current-page="pageNo" :page-size="10" :total="total" layout="total, prev, pager, next" style="margin-top:20px" />
    </el-card>
  </div>
</template>
<script>
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default {
  components: { FederatedQueryNav },
  data() { return { query: { taskName: '', dateRange: null }, list: [], total: 0, pageNo: 1, loading: false } },
  mounted() { this.search() },
  methods: {
    async search() { this.loading = true; this.list = []; this.total = 0; this.loading = false },
    reset() { this.query = { taskName: '', dateRange: null }; this.search() },
    onPageChange(p) { this.pageNo = p; this.search() }
  }
}
</script>
