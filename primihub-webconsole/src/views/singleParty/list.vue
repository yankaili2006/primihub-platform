<template>
  <div class="container">
    <div class="search-area">
      <el-form :model="query" :inline="true" @keyup.enter.native="search">
        <el-form-item>
          <el-input v-model="query.taskName" placeholder="请输入任务名称" clearable @clear="handleClear('taskName')" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.algorithmType" placeholder="算法类型" clearable @clear="handleClear('algorithmType')">
            <el-option v-for="item in algorithmOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.taskState" placeholder="任务状态" clearable @clear="handleClear('taskState')">
            <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">查询</el-button>
          <el-button icon="el-icon-refresh-right" @click="reset" />
        </el-form-item>
      </el-form>
    </div>
    <div class="organ-container">
      <div class="add-button-wrapper">
        <el-button icon="el-icon-circle-plus-outline" type="primary" @click="toTaskPage">单方算法</el-button>
        <span class="add-hint">创建单方算法任务，使用本机构数据运行算法</span>
      </div>
      <el-table v-loading="listLoading" :data="taskList" class="table-list" :empty-text="listLoading ? '加载中...' : '暂无数据'">
        <el-table-column type="index" align="center" label="序号" width="50" />
        <el-table-column label="任务名称" min-width="140px">
          <template slot-scope="{row}">
            <el-tooltip :content="row.taskName" placement="top">
              <el-link type="primary" @click="toDetailPage(row.taskId)">{{ row.taskName }}</el-link>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column label="算法类型" prop="algorithmType" align="center" width="120">
          <template slot-scope="{row}">
            <el-tag size="small">{{ row.algorithmType | algorithmFilter }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="发起时间" prop="createDate" min-width="140px">
          <template slot-scope="{row}">
            <span>{{ (row.createDate || '').split(' ')[0] }}</span><br>
            <span class="time-sub">{{ (row.createDate || '').split(' ')[1] }}</span>
          </template>
        </el-table-column>
        <el-table-column label="任务状态" prop="taskState" width="100">
          <template slot-scope="{row}">
            <el-tag :type="statusTagType(row.taskState)" size="small" :effect="row.taskState === 2 ? 'dark' : 'light'">
              <i v-if="row.taskState === 2" class="el-icon-loading" />
              {{ row.taskState | taskStatusFilter }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" fixed="right" width="200" align="center">
          <template slot-scope="{row}">
            <el-button type="text" size="small" @click="toDetailPage(row.taskId)">查看</el-button>
            <el-button v-if="row.taskState === 1" type="text" size="small" @click="handleDownloadResult(row)">下载结果</el-button>
            <el-button v-if="row.taskState === 2" type="text" size="small" style="color:#e6a23c" @click="cancelTask(row)">取消</el-button>
            <el-button type="text" size="small" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="totalPage > 1" :limit.sync="pageSize" :page-count="totalPage" :page.sync="pageNo" :total="total" @pagination="handlePagination" />
    </div>
  </div>
</template>

<script>
import { getTaskList, downloadResult, deleteTask, cancelTask } from '@/api/singleParty'
import Pagination from '@/components/Pagination'

const STATUS_OPTIONS = [
  { value: 0, label: '待执行' },
  { value: 1, label: '执行中' },
  { value: 2, label: '执行成功' },
  { value: 3, label: '执行失败' },
  { value: 4, label: '已取消' }
]

const ALGORITHM_OPTIONS = [
  { value: 1, label: '逻辑回归' },
  { value: 2, label: '决策树' },
  { value: 3, label: '随机森林' },
  { value: 4, label: 'XGBoost' },
  { value: 5, label: '线性回归' },
  { value: 6, label: 'K-Means' }
]

export default {
  name: 'SinglePartyList',
  components: { Pagination },
  filters: {
    taskStatusFilter(val) {
      const opt = STATUS_OPTIONS.find(o => o.value === val)
      return opt ? opt.label : '未知'
    },
    algorithmFilter(val) {
      const opt = ALGORITHM_OPTIONS.find(o => o.value === val)
      return opt ? opt.label : '未知'
    }
  },
  data() {
    return {
      query: {
        taskName: '',
        algorithmType: null,
        taskState: null,
        pageNo: 1,
        pageSize: 10
      },
      pageNo: 1,
      pageSize: 10,
      total: 0,
      totalPage: 0,
      taskList: [],
      listLoading: false,
      statusOptions: STATUS_OPTIONS,
      algorithmOptions: ALGORITHM_OPTIONS
    }
  },
  created() {
    this.fetchList()
  },
  methods: {
    async fetchList() {
      this.listLoading = true
      try {
        const params = { ...this.query, pageNo: this.pageNo, pageSize: this.pageSize }
        const { result } = await getTaskList(params)
        if (result) {
          this.taskList = result.data || []
          this.total = result.total || 0
          this.totalPage = result.totalPage || 0
        }
      } catch (e) {
        console.error('获取任务列表失败', e)
      } finally {
        this.listLoading = false
      }
    },
    search() {
      this.pageNo = 1
      this.fetchList()
    },
    reset() {
      this.query = { taskName: '', algorithmType: null, taskState: null }
      this.pageNo = 1
      this.fetchList()
    },
    handleClear(key) {
      this.query[key] = null
    },
    handlePagination({ page, limit }) {
      this.pageNo = page
      this.pageSize = limit
      this.fetchList()
    },
    toTaskPage() {
      this.$router.push('/singleParty/task')
    },
    toDetailPage(taskId) {
      this.$router.push(`/singleParty/detail/${taskId}`)
    },
    async handleDownloadResult(row) {
      try {
        const res = await downloadResult({ taskId: row.taskId })
        const blob = new Blob([res])
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = `${row.taskName || 'result'}.csv`
        link.click()
        URL.revokeObjectURL(link.href)
      } catch (e) {
        this.$message.error('下载失败')
      }
    },
    async cancelTask(row) {
      try {
        await this.$confirm('确认取消该任务?', '提示')
        await cancelTask({ taskId: row.taskId })
        this.$message.success('已取消')
        this.fetchList()
      } catch (e) {
        if (e !== 'cancel') this.$message.error('操作失败')
      }
    },
    async handleDelete(row) {
      try {
        await this.$confirm('确认删除该任务?', '提示', { type: 'warning' })
        await deleteTask({ taskId: row.taskId })
        this.$message.success('已删除')
        this.fetchList()
      } catch (e) {
        if (e !== 'cancel') this.$message.error('操作失败')
      }
    },
    statusTagType(state) {
      const map = { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger', 4: 'info' }
      return map[state] || 'info'
    }
  }
}
</script>

<style scoped>
.time-sub {
  color: #999;
  font-size: 12px;
}
.add-button-wrapper {
  margin-bottom: 16px;
}
.add-hint {
  color: #999;
  font-size: 13px;
  margin-left: 12px;
}
</style>
