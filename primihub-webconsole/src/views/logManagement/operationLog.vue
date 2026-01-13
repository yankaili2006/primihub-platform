<template>
  <div class="container">
    <div class="filter-bar">
      <el-input v-model="searchForm.userName" placeholder="请输入用户名" style="width: 200px; margin-right: 10px;" clearable />
      <el-select v-model="searchForm.operationType" placeholder="操作类型" style="width: 150px; margin-right: 10px;" clearable>
        <el-option label="登录" value="登录" />
        <el-option label="登出" value="登出" />
        <el-option label="新增" value="新增" />
        <el-option label="修改" value="修改" />
        <el-option label="删除" value="删除" />
      </el-select>
      <el-select v-model="searchForm.status" placeholder="状态" style="width: 120px; margin-right: 10px;" clearable>
        <el-option label="成功" :value="1" />
        <el-option label="失败" :value="0" />
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
        <el-table-column align="left" label="用户名" prop="userName" width="120" />
        <el-table-column align="left" label="机构名称" prop="organName" width="150" />
        <el-table-column align="left" label="操作类型" prop="operationType" width="100" />
        <el-table-column align="left" label="操作模块" prop="operationModule" width="120" />
        <el-table-column align="left" label="操作描述" prop="operationDesc" min-width="200" show-overflow-tooltip />
        <el-table-column align="left" label="IP地址" prop="ipAddress" width="130" />
        <el-table-column align="center" label="状态" prop="status" width="80">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 1" type="success">成功</el-tag>
            <el-tag v-else type="danger">失败</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="执行时长(ms)" prop="executionTime" width="120" />
        <el-table-column align="center" label="创建时间" prop="createDate" width="180" />
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </div>
  </div>
</template>

<script>
import { getOperationLogPage, exportOperationLog } from '@/api/logManagement'
import Pagination from '@/components/Pagination'

export default {
  name: 'OperationLog',
  components: {
    Pagination
  },
  data() {
    return {
      list: [],
      searchForm: {
        userName: '',
        operationType: '',
        status: null,
        startTime: '',
        endTime: ''
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
        userName: this.searchForm.userName,
        operationType: this.searchForm.operationType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange[0] ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange[1] ? this.dateRange[1] : '',
        pageNum: this.pageNum,
        pageSize: this.pageSize
      }
      getOperationLogPage(params).then(res => {
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
        userName: '',
        operationType: '',
        status: null
      }
      this.dateRange = []
      this.pageNum = 1
      this.fetchData()
    },
    handleExport() {
      const params = {
        userName: this.searchForm.userName,
        operationType: this.searchForm.operationType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange[0] ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange[1] ? this.dateRange[1] : ''
      }
      exportOperationLog(params).then(response => {
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `操作日志_${new Date().getTime()}.xlsx`
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
