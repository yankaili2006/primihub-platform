<template>
  <div class="container">
    <div class="filter-bar">
      <el-input v-model="searchForm.taskId" placeholder="请输入任务ID" style="width: 200px; margin-right: 10px;" clearable />
      <el-input v-model="searchForm.taskName" placeholder="请输入任务名称" style="width: 200px; margin-right: 10px;" clearable />
      <el-select v-model="searchForm.computeType" placeholder="计算类型" style="width: 150px; margin-right: 10px;" clearable>
        <el-option label="联合建模" value="联合建模" />
        <el-option label="安全求交" value="安全求交" />
        <el-option label="隐匿查询" value="隐匿查询" />
        <el-option label="联合预测" value="联合预测" />
      </el-select>
      <el-select v-model="searchForm.status" placeholder="状态" style="width: 120px; margin-right: 10px;" clearable>
        <el-option label="运行中" :value="0" />
        <el-option label="成功" :value="1" />
        <el-option label="失败" :value="2" />
        <el-option label="取消" :value="3" />
      </el-select>
      <el-date-picker
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="开始日期"
        end-placeholder="结束日期"
        value-format="yyyy-MM-dd HH:mm:ss"
        :default-time="['00:00:00', '23:59:59']"
        style="margin-right: 10px;"
      />
      <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
      <el-button type="success" icon="el-icon-download" @click="handleExport">导出</el-button>
    </div>
    <div class="main">
      <el-table :data="list" class="table-list">
        <el-table-column align="center" label="序号" width="80" type="index" />
        <el-table-column align="left" label="任务ID" prop="taskId" width="150" />
        <el-table-column align="left" label="任务名称" prop="taskName" width="180" />
        <el-table-column align="left" label="计算类型" prop="computeType" width="120" />
        <el-table-column align="left" label="项目名称" prop="projectName" width="150" />
        <el-table-column align="left" label="用户名" prop="userName" width="120" />
        <el-table-column align="left" label="机构名称" prop="organName" width="150" />
        <el-table-column align="center" label="状态" prop="status" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 0" type="info">运行中</el-tag>
            <el-tag v-else-if="scope.row.status === 1" type="success">成功</el-tag>
            <el-tag v-else-if="scope.row.status === 2" type="danger">失败</el-tag>
            <el-tag v-else type="warning">取消</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="执行时长(ms)" prop="executionTime" width="130" />
        <el-table-column align="center" label="创建时间" prop="createDate" width="180" />
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </div>
  </div>
</template>

<script>
import { getComputeLogPage, exportComputeLog } from '@/api/logManagement'
import Pagination from '@/components/Pagination'

export default {
  name: 'ComputeLog',
  components: {
    Pagination
  },
  data() {
    return {
      list: [],
      searchForm: {
        taskId: '',
        taskName: '',
        computeType: '',
        status: null
      },
      dateRange: [],
      pageNum: 1,
      pageSize: 10,
      pageCount: 0,
      itemTotalCount: 0
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      const params = {
        taskId: this.searchForm.taskId,
        taskName: this.searchForm.taskName,
        computeType: this.searchForm.computeType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange[0] ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange[1] ? this.dateRange[1] : '',
        pageNum: this.pageNum,
        pageSize: this.pageSize
      }
      getComputeLogPage(params).then(res => {
        if (res.code === 0 && res.result) {
          this.list = res.result.list || []
          this.itemTotalCount = res.result.pageParam?.itemTotalCount || 0
          this.pageCount = res.result.pageParam?.pageCount || 0
        }
      })
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        taskId: '',
        taskName: '',
        computeType: '',
        status: null
      }
      this.dateRange = []
      this.pageNum = 1
      this.fetchData()
    },
    handleExport() {
      const params = {
        taskId: this.searchForm.taskId,
        taskName: this.searchForm.taskName,
        computeType: this.searchForm.computeType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange[0] ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange[1] ? this.dateRange[1] : ''
      }
      exportComputeLog(params).then(response => {
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `计算日志_${new Date().getTime()}.xlsx`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      }).catch(() => {
        this.$message.error('导出失败')
      })
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchData()
    }
  }
}
</script>

<style scoped>
.container {
  padding: 20px;
}
.filter-bar {
  margin-bottom: 20px;
}
.main {
  margin-top: 20px;
}
</style>
