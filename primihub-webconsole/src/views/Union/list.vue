<template>
  <div class="container">
    <div class="search-area">
      <el-form :model="query" :inline="true" @keyup.enter.native="search">
        <el-form-item>
          <el-select v-model="query.organId" placeholder="请选择参与机构" clearable @clear="handleClear('organId')">
            <el-option v-for="item in organList" :key="item.globalId" :label="item.globalName" :value="item.globalId" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="query.taskName" placeholder="请输入任务名称" clearable @clear="handleClear('taskName')" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.taskState" placeholder="请选择任务状态" clearable @clear="handleClear('taskState')">
            <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="query.createDate" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" :default-time="['00:00:00', '23:59:59']" :picker-options="datePickerOptions" @change="handleDateChange" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">查询</el-button>
          <el-button icon="el-icon-refresh-right" @click="reset" />
          <el-button type="success" icon="el-icon-download" :loading="exporting" @click="handleExportLog">导出日志</el-button>
        </el-form-item>
      </el-form>
    </div>
    <div class="organ-container">
      <div class="add-button-wrapper">
        <el-button icon="el-icon-circle-plus-outline" type="primary" @click="toTaskPage">联邦求并</el-button>
        <span class="add-hint">创建联邦求并任务，合并本机构与协作方数据</span>
      </div>
      <el-table v-loading="listLoading" :data="allDataUnionTask" class="table-list" :empty-text="listLoading ? '加载中...' : '暂无数据'">
        <el-table-column type="index" align="center" label="序号" width="50" />
        <el-table-column label="任务名称" min-width="140px">
          <template slot-scope="{row}">
            <el-tooltip :content="row.taskName" placement="top">
              <el-link type="primary" @click="toTaskDetailPage(row.taskId)">{{ row.taskName }}</el-link>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column label="参与机构" align="center">
          <template slot-scope="{row}">
            <el-tooltip :content="row.otherOrganName" placement="top"><span>{{ row.otherOrganName }}</span></el-tooltip>
          </template>
        </el-table-column>
        <el-table-column prop="tag" label="实现方法" align="center">
          <template slot-scope="{row}">
            <el-tag size="small" effect="plain">{{ row.tag | tagFilter }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="发起时间" prop="createDate" min-width="140px">
          <template slot-scope="{row}">
            <span>{{ (row.createDate || '').split(' ')[0] }}</span><br>
            <span class="time-sub">{{ (row.createDate || '').split(' ')[1] }}</span>
          </template>
        </el-table-column>
        <el-table-column label="任务耗时" width="90">
          <template slot-scope="{row}">
            <span>{{ row.consuming | timeFilter }}</span>
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
            <el-button type="text" size="small" @click="toTaskDetailPage(row.taskId)">查看</el-button>
            <el-button v-if="row.taskState === 1" type="text" size="small" @click="handleDownloadResult(row)">下载结果</el-button>
            <el-button v-if="row.taskState === 2" type="text" size="small" style="color:#e6a23c" @click="cancelTask(row)">取消</el-button>
            <el-button type="text" size="small" style="color:#f56c6c" :disabled="row.taskState === 2" @click="delUnionTask(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="totalPage>1" :limit.sync="pageSize" :page-count="totalPage" :page.sync="pageNo" :total="total" @pagination="handlePagination" />
    </div>
  </div>
</template>

<script>
import { getAvailableOrganList } from '@/api/center'
import { getUnionTaskList, delUnionTask, cancelUnionTask, exportUnionLog, downloadUnionTask } from '@/api/union'
import Pagination from '@/components/Pagination'
import { dateRangePickerOptions } from '@/utils/dateShortcuts'

export default {
  name: 'UnionDirectory',
  components: { Pagination },
  filters: {
    tagFilter(state) { return { 0: 'ECDH', 1: 'KKRT', 2: 'TEE' }[state] || '未知' }
  },
  data() {
    return {
      datePickerOptions,
      query: { organId: '', taskName: '', taskState: '', createDate: [] },
      allDataUnionTask: [], organList: [], listLoading: false, exporting: false,
      pageSize: 10, totalPage: 0, total: 0, pageNo: 1, timer: null,
      statusOptions: [
        { label: '待执行', value: 0 }, { label: '成功', value: 1 },
        { label: '运行中', value: 2 }, { label: '失败', value: 3 }, { label: '已取消', value: 4 }
      ]
    }
  },
  created() {
    this.getUnionTaskList()
    this.getAvailableOrganList()
    this.timer = setInterval(() => { this.getUnionTaskList() }, 3000)
  },
  destroyed() { clearInterval(this.timer) },
  methods: {
    statusTagType(s) { return { 0: 'info', 1: 'success', 2: 'warning', 3: 'danger', 4: 'info' }[s] || 'info' },
    handleDateChange(val) { if (!val) { this.query.createDate = []; this.getUnionTaskList() } },
    handleClear(name) { this.query[name] = ''; this.getUnionTaskList() },
    reset() { Object.keys(this.query).forEach(k => { this.query[k] = '' }); this.pageNo = 1; this.getUnionTaskList() },
    toTaskPage() { this.$router.push({ name: 'UnionTask' }) },
    toTaskDetailPage(id) { this.$router.push({ name: 'UnionDetail', params: { id } }) },
    async getAvailableOrganList() {
      try { const { result } = await getAvailableOrganList(); this.organList = result || [] } catch (e) { console.error(e) }
    },
    delUnionTask(row) {
      if (row.taskState === 2) return
      this.$confirm('此操作将永久删除该任务, 是否继续?', '提示', { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' })
        .then(() => {
          delUnionTask({ taskId: row.taskId }).then(res => {
            if (res.code === 0) {
              const idx = this.allDataUnionTask.findIndex(item => item.taskId === row.taskId)
              if (idx !== -1) this.allDataUnionTask.splice(idx, 1)
              this.$message.success('删除成功')
            }
          })
        }).catch(() => {})
    },
    async cancelTask(row) {
      const res = await cancelUnionTask({ taskId: row.taskId })
      if (res.code === 0) { row.taskState = 4; this.$notify({ message: '取消成功', type: 'success', duration: 1500 }) }
    },
    async handleDownloadResult(row) {
      try {
        const res = await downloadUnionTask({ taskId: row.taskId })
        const blob = new Blob([res]); const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url; link.download = `联邦求并结果_${row.taskName}_${Date.now()}.csv`
        link.click(); window.URL.revokeObjectURL(url)
        this.$message.success('下载成功')
      } catch (e) { this.$message.error('下载失败') }
    },
    getUnionTaskList() {
      this.listLoading = true
      const params = { pageNo: this.pageNo, pageSize: this.pageSize }
      if (this.query.createDate && this.query.createDate.length > 0) { params.startDate = this.query.createDate[0]; params.endDate = this.query.createDate[1] }
      if (this.query.organId) params.organId = this.query.organId
      if (this.query.taskState) params.taskState = this.query.taskState
      if (this.query.taskName) params.taskName = this.query.taskName
      getUnionTaskList(params).then(res => {
        const { data, totalPage, total } = res.result || { data: [], totalPage: 0, total: 0 }
        this.totalPage = totalPage; this.total = total; this.allDataUnionTask = data
        const running = data.filter(item => item.taskState === 2)
        if (!running.length) clearInterval(this.timer)
      }).catch(e => { clearInterval(this.timer); console.error('加载列表失败:', e) }).finally(() => { this.listLoading = false })
    },
    handlePagination(data) { this.pageNo = data.page; this.getUnionTaskList() },
    async search() { this.pageNo = 1; await this.getUnionTaskList() },
    async handleExportLog() {
      this.exporting = true
      try {
        const params = {
          taskName: this.query.taskName || '', status: this.query.taskState || null,
          startTime: this.query.createDate && this.query.createDate[0] || '', endTime: this.query.createDate && this.query.createDate[1] || ''
        }
        const response = await exportUnionLog(params)
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob); const link = document.createElement('a')
        link.href = url; link.download = `联邦求并任务日志_${Date.now()}.xlsx`
        link.click(); window.URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败: ' + (e.message || '')) }
      this.exporting = false
    }
  }
}
</script>

<style lang="scss" scoped>
::v-deep .el-input--suffix .el-input__inner { padding-right: 0; }
.el-date-editor--datetimerange.el-input, .el-date-editor--datetimerange.el-input__inner { width: 360px; padding: 3px 5px; }
.search-area { padding: 48px 40px 20px 40px; background-color: #fff; display: flex; flex-wrap: wrap; border-radius: 12px; }
.el-table { margin-top: 24px; }
.organ-container { border-radius: 12px; padding: 25px 40px; background-color: #fff; margin-top: 20px; }
.add-button-wrapper { display: flex; align-items: center; gap: 12px; }
.add-hint { font-size: 13px; color: #909399; }
.pagination-container { padding-left: 0; padding-right: 0; }
.time-sub { font-size: 12px; color: #909399; }
</style>
