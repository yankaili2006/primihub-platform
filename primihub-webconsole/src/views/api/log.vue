<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper primary">
              <i class="el-icon-document" />
            </div>
            <div class="stats-info">
              <div class="stats-label">今日调用</div>
              <div class="stats-value">{{ statistics.todayCalls || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper success">
              <i class="el-icon-circle-check" />
            </div>
            <div class="stats-info">
              <div class="stats-label">成功次数</div>
              <div class="stats-value">{{ statistics.successCalls || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper danger">
              <i class="el-icon-circle-close" />
            </div>
            <div class="stats-info">
              <div class="stats-label">失败次数</div>
              <div class="stats-value">{{ statistics.failedCalls || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper warning">
              <i class="el-icon-time" />
            </div>
            <div class="stats-info">
              <div class="stats-label">平均响应</div>
              <div class="stats-value">{{ statistics.avgResponseTime || 0 }}ms</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 操作按钮 -->
    <div class="action-bar">
      <el-button type="primary" icon="el-icon-download" @click="exportLog">导出日志</el-button>
      <el-button type="danger" icon="el-icon-delete" @click="clearLog">清空日志</el-button>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-bar">
        <el-input
          v-model="searchForm.keyword"
          placeholder="接口路径/AppKey"
          style="width: 250px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
        />
        <el-select
          v-model="searchForm.method"
          placeholder="请求方法"
          style="width: 120px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="GET" value="GET" />
          <el-option label="POST" value="POST" />
          <el-option label="PUT" value="PUT" />
          <el-option label="DELETE" value="DELETE" />
        </el-select>
        <el-select
          v-model="searchForm.status"
          placeholder="响应状态"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="成功(2xx)" value="SUCCESS" />
          <el-option label="客户端错误(4xx)" value="CLIENT_ERROR" />
          <el-option label="服务端错误(5xx)" value="SERVER_ERROR" />
        </el-select>
        <el-input
          v-model="searchForm.ip"
          placeholder="IP地址"
          style="width: 150px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
        />
        <el-date-picker
          v-model="dateRange"
          type="datetimerange"
          range-separator="至"
          start-placeholder="开始时间"
          end-placeholder="结束时间"
          style="width: 380px; margin-right: 10px;"
        />
        <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
        <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
      </div>
    </el-card>

    <!-- 日志列表 -->
    <el-card class="table-card" shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-document" /> 接口日志</span>
      </div>

      <el-table
        v-loading="loading"
        :data="list"
        stripe
      >
        <el-table-column label="序号" width="70" type="index" align="center" />
        <el-table-column label="调用时间" prop="callTime" width="180" />
        <el-table-column label="请求方法" prop="method" width="100" align="center">
          <template slot-scope="scope">
            <el-tag
              :type="scope.row.method === 'GET' ? 'success' : scope.row.method === 'POST' ? 'primary' : 'warning'"
              size="small"
            >
              {{ scope.row.method }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="接口路径" prop="apiPath" min-width="250" show-overflow-tooltip />
        <el-table-column label="AppKey" prop="appKey" width="150" show-overflow-tooltip>
          <template slot-scope="scope">
            <span class="key-text">{{ scope.row.appKey || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="IP地址" prop="ip" width="140" />
        <el-table-column label="响应状态" prop="statusCode" width="100" align="center">
          <template slot-scope="scope">
            <el-tag
              :type="scope.row.statusCode < 300 ? 'success' : scope.row.statusCode < 500 ? 'warning' : 'danger'"
              size="small"
            >
              {{ scope.row.statusCode }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="响应时间" prop="responseTime" width="100" align="center">
          <template slot-scope="scope">
            <span :class="getResponseTimeClass(scope.row.responseTime)">
              {{ scope.row.responseTime }}ms
            </span>
          </template>
        </el-table-column>
        <el-table-column label="数据大小" prop="dataSize" width="100" align="center">
          <template slot-scope="scope">
            {{ formatDataSize(scope.row.dataSize) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="viewDetail(scope.row)">
              <i class="el-icon-view" />详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </el-card>

    <!-- 日志详情弹窗 -->
    <el-dialog :visible.sync="detailVisible" title="日志详情" width="900px" top="5vh">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="调用时间">{{ detailInfo.callTime }}</el-descriptions-item>
        <el-descriptions-item label="请求方法">
          <el-tag :type="detailInfo.method === 'GET' ? 'success' : 'primary'" size="small">
            {{ detailInfo.method }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="接口路径" :span="2">{{ detailInfo.apiPath }}</el-descriptions-item>
        <el-descriptions-item label="AppKey">
          <span class="key-text">{{ detailInfo.appKey || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="应用名称">{{ detailInfo.appName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="IP地址">{{ detailInfo.ip }}</el-descriptions-item>
        <el-descriptions-item label="User-Agent">{{ detailInfo.userAgent || '-' }}</el-descriptions-item>
        <el-descriptions-item label="响应状态码">
          <el-tag
            :type="detailInfo.statusCode < 300 ? 'success' : detailInfo.statusCode < 500 ? 'warning' : 'danger'"
            size="small"
          >
            {{ detailInfo.statusCode }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="响应时间">
          <span :class="getResponseTimeClass(detailInfo.responseTime)">
            {{ detailInfo.responseTime }}ms
          </span>
        </el-descriptions-item>
        <el-descriptions-item label="请求数据大小">{{ formatDataSize(detailInfo.requestSize) }}</el-descriptions-item>
        <el-descriptions-item label="响应数据大小">{{ formatDataSize(detailInfo.responseSize) }}</el-descriptions-item>
        <el-descriptions-item label="错误信息" :span="2">
          <span :style="{color: detailInfo.errorMessage ? '#f56c6c' : '#909399'}">
            {{ detailInfo.errorMessage || '无' }}
          </span>
        </el-descriptions-item>
      </el-descriptions>

      <div style="margin-top: 20px;">
        <el-tabs type="border-card">
          <el-tab-pane label="请求参数">
            <div v-if="detailInfo.requestParams" class="json-view">
              <pre>{{ formatJson(detailInfo.requestParams) }}</pre>
            </div>
            <el-empty v-else description="无请求参数" :image-size="60" />
          </el-tab-pane>
          <el-tab-pane label="请求头">
            <div v-if="detailInfo.requestHeaders" class="json-view">
              <pre>{{ formatJson(detailInfo.requestHeaders) }}</pre>
            </div>
            <el-empty v-else description="无请求头信息" :image-size="60" />
          </el-tab-pane>
          <el-tab-pane label="响应数据">
            <div v-if="detailInfo.responseData" class="json-view">
              <pre>{{ formatJson(detailInfo.responseData) }}</pre>
            </div>
            <el-empty v-else description="无响应数据" :image-size="60" />
          </el-tab-pane>
          <el-tab-pane label="响应头">
            <div v-if="detailInfo.responseHeaders" class="json-view">
              <pre>{{ formatJson(detailInfo.responseHeaders) }}</pre>
            </div>
            <el-empty v-else description="无响应头信息" :image-size="60" />
          </el-tab-pane>
        </el-tabs>
      </div>

      <div slot="footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApiLogPage, getApiLogDetail, exportApiLog, clearApiLog, getApiStatistics } from '@/api/apiManage'
import Pagination from '@/components/Pagination'

export default {
  name: 'ApiLog',
  components: { Pagination },
  data() {
    return {
      statistics: {},
      list: [],
      searchForm: {
        keyword: '',
        method: '',
        status: '',
        ip: ''
      },
      dateRange: [],
      loading: false,
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
    async fetchData() {
      this.loading = true
      const params = {
        pageSize: this.pageSize,
        pageNum: this.pageNum,
        keyword: this.searchForm.keyword,
        method: this.searchForm.method,
        status: this.searchForm.status,
        ip: this.searchForm.ip,
        startTime: this.dateRange && this.dateRange.length > 0 ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange.length > 1 ? this.dateRange[1] : ''
      }
      // TODO: 调用实际接口
      const res = await getApiLogPage(params)
      if (res && res.code === 0) {
        const { list, pageParam } = res.result
        this.list = list || []
        this.pageCount = Number(pageParam?.pageCount || 0)
        this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
      } else {
        // 模拟数据
        this.list = [
          { id: 1, callTime: '2026-01-09 15:23:45', method: 'GET', apiPath: '/api/user/getUserList', appKey: 'ak_1a2b3c4d', ip: '192.168.1.100', statusCode: 200, responseTime: 125, dataSize: 2048 },
          { id: 2, callTime: '2026-01-09 15:22:18', method: 'POST', apiPath: '/api/resource/createResource', appKey: 'ak_1a2b3c4d', ip: '192.168.1.100', statusCode: 201, responseTime: 358, dataSize: 512 },
          { id: 3, callTime: '2026-01-09 15:20:52', method: 'GET', apiPath: '/api/project/getProjectDetail', appKey: 'ak_9i8h7g6f', ip: '192.168.1.105', statusCode: 404, responseTime: 45, dataSize: 256 },
          { id: 4, callTime: '2026-01-09 15:18:30', method: 'DELETE', apiPath: '/api/task/deleteTask', appKey: 'ak_1a2b3c4d', ip: '192.168.1.100', statusCode: 500, responseTime: 1250, dataSize: 128 }
        ]
        this.pageCount = 1
        this.itemTotalCount = 4
      }
      this.loading = false
    },
    async fetchStatistics() {
      // TODO: 调用实际接口
      const res = await getApiStatistics()
      if (res && res.code === 0) {
        this.statistics = res.result || {}
      } else {
        this.statistics = {
          todayCalls: 8523,
          successCalls: 8211,
          failedCalls: 312,
          avgResponseTime: 245
        }
      }
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        keyword: '',
        method: '',
        status: '',
        ip: ''
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
      // TODO: 调用实际接口
      const res = await getApiLogDetail({ id: row.id })
      if (res && res.code === 0) {
        this.detailInfo = res.result || {}
      } else {
        // 模拟数据
        this.detailInfo = {
          ...row,
          appName: '数据平台应用',
          userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          requestSize: 256,
          responseSize: 2048,
          errorMessage: row.statusCode >= 400 ? '请求处理失败' : '',
          requestParams: '{"pageNum": 1, "pageSize": 10}',
          requestHeaders: '{"Content-Type": "application/json", "Authorization": "Bearer token123"}',
          responseData: '{"code": 0, "message": "success", "result": {"list": [], "pageParam": {}}}',
          responseHeaders: '{"Content-Type": "application/json", "Server": "nginx"}'
        }
      }
      this.detailVisible = true
    },
    async exportLog() {
      // TODO: 调用实际接口导出日志
      const params = {
        keyword: this.searchForm.keyword,
        method: this.searchForm.method,
        status: this.searchForm.status,
        ip: this.searchForm.ip,
        startTime: this.dateRange && this.dateRange.length > 0 ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange.length > 1 ? this.dateRange[1] : ''
      }
      const res = await exportApiLog(params)
      if (res) {
        // TODO: 处理文件下载
        this.$message.success('日志导出成功')
      }
    },
    clearLog() {
      this.$confirm('确定要清空所有接口日志吗？此操作不可恢复！', '警告', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        // TODO: 调用实际接口
        const res = await clearApiLog({})
        if (res && res.code === 0) {
          this.$message.success('日志清空成功')
          this.fetchData()
          this.fetchStatistics()
        }
      })
    },
    getResponseTimeClass(time) {
      if (time < 200) return 'response-time-fast'
      if (time < 500) return 'response-time-normal'
      return 'response-time-slow'
    },
    formatDataSize(bytes) {
      if (!bytes) return '0 B'
      if (bytes < 1024) return bytes + ' B'
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB'
      return (bytes / 1024 / 1024).toFixed(2) + ' MB'
    },
    formatJson(str) {
      try {
        return JSON.stringify(JSON.parse(str), null, 2)
      } catch {
        return str
      }
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
    .stats-icon-wrapper {
      width: 60px;
      height: 60px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 15px;
      i {
        font-size: 32px;
        color: #fff;
      }
      &.primary {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      }
      &.success {
        background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
      }
      &.warning {
        background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
      }
      &.danger {
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
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

.action-bar {
  margin-bottom: 20px;
}

.filter-card {
  margin-bottom: 20px;
}

.filter-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.table-card {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    .card-title {
      font-size: 16px;
      font-weight: bold;
      i {
        margin-right: 8px;
      }
    }
  }
}

.key-text {
  font-family: 'Courier New', monospace;
  font-size: 13px;
  color: #409eff;
}

.response-time-fast {
  color: #67c23a;
  font-weight: bold;
}

.response-time-normal {
  color: #e6a23c;
  font-weight: bold;
}

.response-time-slow {
  color: #f56c6c;
  font-weight: bold;
}

.json-view {
  background: #f5f7fa;
  padding: 15px;
  border-radius: 4px;
  max-height: 400px;
  overflow: auto;
  pre {
    font-size: 12px;
    margin: 0;
    white-space: pre-wrap;
    word-wrap: break-word;
  }
}

::v-deep .el-table th {
  background: #fafafa;
}

::v-deep .el-tabs--border-card {
  border: none;
  box-shadow: none;
}
</style>
