<template>
  <div class="app-container">
    <el-page-header content="单方学习日志记录" style="margin-bottom:20px;" @back="$router.go(-1)" />
    <el-card>
      <div slot="header">日志列表</div>
      <el-form :inline="true" :model="query" style="margin-bottom:12px;">
        <el-form-item>
          <el-input v-model="query.taskName" placeholder="任务名称" clearable style="width:160px;" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.logLevel" placeholder="日志类型" clearable style="width:120px;">
            <el-option label="INFO" value="INFO" />
            <el-option label="WARN" value="WARN" />
            <el-option label="ERROR" value="ERROR" />
            <el-option label="DEBUG" value="DEBUG" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.taskType" placeholder="任务类型" clearable style="width:140px;">
            <el-option v-for="t in taskTypeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker
            v-model="query.timeRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd"
            style="width:240px;"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchList">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
      <el-table v-loading="loading" :data="list" border>
        <el-table-column prop="logId" label="日志ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="160" />
        <el-table-column prop="taskType" label="任务类型" width="130">
          <template slot-scope="{row}">{{ taskTypeLabel(row.taskType) }}</template>
        </el-table-column>
        <el-table-column prop="logLevel" label="日志级别" width="100">
          <template slot-scope="{row}">
            <el-tag :type="levelTag(row.logLevel)" size="small">{{ row.logLevel }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="logContent" label="日志内容" min-width="240" show-overflow-tooltip>
          <template slot-scope="{row}">
            <el-popover placement="bottom" width="480" trigger="click">
              <pre style="white-space:pre-wrap;word-break:break-all;font-size:12px;max-height:300px;overflow:auto;">{{ row.logContent }}</pre>
              <span slot="reference" style="cursor:pointer;color:#409EFF;">{{ row.logContent }}</span>
            </el-popover>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="记录时间" width="160" />
      </el-table>
      <el-pagination style="margin-top:16px;" :current-page="query.pageNo" :page-size="query.pageSize"
        :total="total" layout="total,prev,pager,next" @current-change="p=>{query.pageNo=p;fetchList()}" />
    </el-card>
  </div>
</template>

<script>
import { getSinglePartyLogs } from '@/api/singleParty'

const TASK_TYPES = [
  { value: 'DATA_STATS', label: '数据统计' },
  { value: 'DATA_CLEANING', label: '数据清洗' },
  { value: 'DATA_SCALING', label: '数据缩放' },
  { value: 'FEATURE_ENCODE', label: '特征编码' },
  { value: 'FEATURE_BIN', label: '特征分箱' },
  { value: 'FEATURE_SELECT', label: '特征筛选' },
  { value: 'FEATURE_DERIVE', label: '特征衍生' },
  { value: 'PYTHON_SCRIPT', label: 'Python脚本' },
  { value: 'SQL_PROCESS', label: 'SQL处理' },
  { value: 'LR', label: 'LR算法' },
  { value: 'XGB', label: 'XGB算法' }
]

const LEVEL_TAG_MAP = { INFO: 'success', WARN: 'warning', ERROR: 'danger', DEBUG: 'info' }

export default {
  name: 'SinglePartyLogRecord',
  data() {
    return {
      query: { taskName: '', logLevel: '', taskType: '', timeRange: [], pageNo: 1, pageSize: 20 },
      list: [], total: 0, loading: false,
      taskTypeOptions: TASK_TYPES
    }
  },
  created() { this.fetchList() },
  methods: {
    async fetchList() {
      this.loading = true
      try {
        const params = { ...this.query }
        if (this.query.timeRange && this.query.timeRange.length === 2) {
          params.startTime = this.query.timeRange[0]
          params.endTime = this.query.timeRange[1]
        }
        delete params.timeRange
        const res = await getSinglePartyLogs(params)
        if (res.code === 0) { this.list = res.result?.list || []; this.total = res.result?.total || 0 }
        else { this.$message.error(res.message || '查询失败') }
      } catch (e) { this.$message.error('请求异常') } finally { this.loading = false }
    },
    resetQuery() {
      this.query = { taskName: '', logLevel: '', taskType: '', timeRange: [], pageNo: 1, pageSize: 20 }
      this.fetchList()
    },
    taskTypeLabel(v) { return TASK_TYPES.find(t => t.value === v)?.label || v || '-' },
    levelTag(v) { return LEVEL_TAG_MAP[v] || 'info' }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
