<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-success stats-icon success" />
            <div class="stats-info">
              <div class="stats-label">今日成功访问</div>
              <div class="stats-value">{{ statistics.todaySuccess || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-error stats-icon error" />
            <div class="stats-info">
              <div class="stats-label">今日拒绝访问</div>
              <div class="stats-value">{{ statistics.todayFailed || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-view stats-icon info" />
            <div class="stats-info">
              <div class="stats-label">总访问次数</div>
              <div class="stats-value">{{ statistics.totalAccess || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-warning stats-icon warning" />
            <div class="stats-info">
              <div class="stats-label">异常访问</div>
              <div class="stats-value">{{ statistics.abnormalAccess || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选条件 -->
    <div class="filter-bar">
      <el-input
        v-model="searchForm.accessIp"
        placeholder="请输入访问IP"
        style="width: 200px; margin-right: 10px;"
        clearable
        @clear="handleSearch"
      />
      <el-input
        v-model="searchForm.accessUrl"
        placeholder="请输入访问URL"
        style="width: 250px; margin-right: 10px;"
        clearable
        @clear="handleSearch"
      />
      <el-select
        v-model="searchForm.accessResult"
        placeholder="请选择访问结果"
        style="width: 150px; margin-right: 10px;"
        clearable
        @change="handleSearch"
      >
        <el-option label="成功" value="SUCCESS" />
        <el-option label="拒绝" value="DENIED" />
        <el-option label="异常" value="ERROR" />
      </el-select>
      <el-date-picker
        v-model="dateRange"
        type="datetimerange"
        range-separator="至"
        start-placeholder="开始时间"
        end-placeholder="结束时间"
        style="width: 380px; margin-right: 10px;"
        value-format="yyyy-MM-dd HH:mm:ss"
        @change="handleSearch"
      />
      <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
      <el-button icon="el-icon-download" @click="handleExport">导出</el-button>
    </div>

    <!-- 日志列表 -->
    <div class="main">
      <el-table
        :data="list"
        class="table-list"
      >
        <el-table-column align="center" label="序号" width="70" type="index" />
        <el-table-column align="left" label="访问IP" prop="accessIp" width="150" />
        <el-table-column align="left" label="访问URL" prop="accessUrl" min-width="250" show-overflow-tooltip />
        <el-table-column align="center" label="请求方法" prop="requestMethod" width="100" />
        <el-table-column align="center" label="访问结果" prop="accessResult" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.accessResult === 'SUCCESS'" type="success">成功</el-tag>
            <el-tag v-else-if="scope.row.accessResult === 'DENIED'" type="danger">拒绝</el-tag>
            <el-tag v-else-if="scope.row.accessResult === 'ERROR'" type="warning">异常</el-tag>
            <el-tag v-else type="info">{{ scope.row.accessResult }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="left" label="失败原因" prop="failReason" min-width="200" show-overflow-tooltip />
        <el-table-column align="center" label="用户ID" prop="userId" width="100" />
        <el-table-column align="center" label="白名单ID" prop="whitelistId" width="100" />
        <el-table-column align="center" label="访问时间" prop="accessTime" width="180" />
        <el-table-column align="center" label="操作" fixed="right" width="100">
          <template slot-scope="scope">
            <el-button type="text" @click="viewDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog :visible.sync="detailVisible" title="访问日志详情" width="700px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="日志ID">{{ detailInfo.id }}</el-descriptions-item>
        <el-descriptions-item label="白名单ID">{{ detailInfo.whitelistId || '-' }}</el-descriptions-item>
        <el-descriptions-item label="访问IP">{{ detailInfo.accessIp }}</el-descriptions-item>
        <el-descriptions-item label="用户ID">{{ detailInfo.userId || '-' }}</el-descriptions-item>
        <el-descriptions-item label="访问URL" :span="2">{{ detailInfo.accessUrl }}</el-descriptions-item>
        <el-descriptions-item label="请求方法">{{ detailInfo.requestMethod }}</el-descriptions-item>
        <el-descriptions-item label="访问结果">
          <el-tag v-if="detailInfo.accessResult === 'SUCCESS'" type="success">成功</el-tag>
          <el-tag v-else-if="detailInfo.accessResult === 'DENIED'" type="danger">拒绝</el-tag>
          <el-tag v-else-if="detailInfo.accessResult === 'ERROR'" type="warning">异常</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="失败原因" :span="2">{{ detailInfo.failReason || '-' }}</el-descriptions-item>
        <el-descriptions-item label="User-Agent" :span="2">{{ detailInfo.userAgent || '-' }}</el-descriptions-item>
        <el-descriptions-item label="请求参数" :span="2">
          <pre class="json-display">{{ detailInfo.requestParams || '-' }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="响应码">{{ detailInfo.responseCode || '-' }}</el-descriptions-item>
        <el-descriptions-item label="响应时间">{{ detailInfo.responseTime || '-' }}ms</el-descriptions-item>
        <el-descriptions-item label="访问时间" :span="2">{{ detailInfo.accessTime }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { getWhitelistAccessLogPage, getWhitelistAccessLogDetail, getWhitelistAccessStatistics } from '@/api/whitelist'
import Pagination from '@/components/Pagination'

export default {
  name: 'WhitelistAccessLog',
  components: {
    Pagination
  },
  data() {
    return {
      list: [],
      statistics: {
        todaySuccess: 0,
        todayFailed: 0,
        totalAccess: 0,
        abnormalAccess: 0
      },
      searchForm: {
        accessIp: '',
        accessUrl: '',
        accessResult: ''
      },
      dateRange: [],
      detailVisible: false,
      detailInfo: {},
      itemTotalCount: 0,
      pageSize: 10,
      pageCount: 0,
      pageNum: 1
    }
  },
  created() {
    this.fetchData()
    this.fetchStatistics()
  },
  methods: {
    fetchData() {
      const params = {
        pageSize: this.pageSize,
        pageNum: this.pageNum,
        accessIp: this.searchForm.accessIp,
        accessUrl: this.searchForm.accessUrl,
        accessResult: this.searchForm.accessResult,
        startTime: this.dateRange && this.dateRange.length > 0 ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange.length > 1 ? this.dateRange[1] : ''
      }
      getWhitelistAccessLogPage(params).then((res) => {
        if (res.code === 0) {
          const { list, pageParam } = res.result
          this.list = list || []
          this.pageCount = Number(pageParam?.pageCount || 0)
          this.pageNum = Number(pageParam?.pageNum || 1)
          this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
        }
      })
    },
    fetchStatistics() {
      getWhitelistAccessStatistics().then((res) => {
        if (res.code === 0) {
          this.statistics = res.result || {}
        }
      })
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        accessIp: '',
        accessUrl: '',
        accessResult: ''
      }
      this.dateRange = []
      this.pageNum = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchData()
    },
    async viewDetail(row) {
      const res = await getWhitelistAccessLogDetail({ id: row.id })
      if (res.code === 0) {
        this.detailInfo = res.result || {}
        this.detailVisible = true
      }
    },
    handleExport() {
      this.$message.info('正在导出...')
      const params = {
        keyword: this.query.keyword || '',
        startTime: this.query.createDate && this.query.createDate[0] || '',
        endTime: this.query.createDate && this.query.createDate[1] || ''
      }
      getWhitelistAccessLogPage({ ...params, pageNo: 1, pageSize: 99999 }).then(res => {
        const list = (res && res.result && (res.result.list || res.result.data)) || []
        const blob = new Blob([JSON.stringify(list, null, 2)], { type: 'application/json;charset=utf-8' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url; link.download = `白名单访问日志_${new Date().getTime()}.json`
        link.click(); window.URL.revokeObjectURL(url)
        this.$message.success(`导出成功，共 ${list.length} 条记录`)
      }).catch(() => this.$message.error('导出失败'))
    }
  }
}
</script>

<style lang="scss" scoped>
.container {
  padding: 20px;
  background-color: #f0f2f5;
}
.stats-row {
  margin-bottom: 20px;
}
.stats-card {
  .stats-content {
    display: flex;
    align-items: center;
    .stats-icon {
      font-size: 48px;
      margin-right: 20px;
      &.success {
        color: #67c23a;
      }
      &.error {
        color: #f56c6c;
      }
      &.info {
        color: #409eff;
      }
      &.warning {
        color: #e6a23c;
      }
    }
    .stats-info {
      flex: 1;
      .stats-label {
        font-size: 14px;
        color: #909399;
        margin-bottom: 8px;
      }
      .stats-value {
        font-size: 28px;
        font-weight: bold;
        color: #303133;
      }
    }
  }
}
.filter-bar {
  background-color: #fff;
  padding: 20px;
  margin-bottom: 15px;
  border-radius: 4px;
}
.table-list {
  margin-top: 0;
}
.main {
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
}
::v-deep .el-table th {
  background: #fafafa;
}
.json-display {
  max-height: 200px;
  overflow: auto;
  background-color: #f5f7fa;
  padding: 10px;
  border-radius: 4px;
  font-size: 12px;
  line-height: 1.5;
}
</style>
