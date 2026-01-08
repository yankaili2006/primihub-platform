<template>
  <div class="container">
    <!-- 搜索表单 -->
    <el-form :inline="true" :model="searchForm" class="search-form">
      <el-form-item label="操作人">
        <el-input v-model="searchForm.operatorName" placeholder="请输入操作人" clearable />
      </el-form-item>

      <el-form-item label="操作模块">
        <el-input v-model="searchForm.operationModule" placeholder="请输入操作模块" clearable />
      </el-form-item>

      <el-form-item label="操作类型">
        <el-select v-model="searchForm.operationType" placeholder="请选择" clearable>
          <el-option label="新增" value="新增" />
          <el-option label="修改" value="修改" />
          <el-option label="删除" value="删除" />
          <el-option label="查询" value="查询" />
          <el-option label="导出" value="导出" />
          <el-option label="登录" value="登录" />
          <el-option label="登出" value="登出" />
        </el-select>
      </el-form-item>

      <el-form-item label="操作时间">
        <el-date-picker
          v-model="searchForm.timeRange"
          type="datetimerange"
          range-separator="至"
          start-placeholder="开始时间"
          end-placeholder="结束时间"
          value-format="yyyy-MM-dd HH:mm:ss"
          :default-time="['00:00:00', '23:59:59']"
        />
      </el-form-item>

      <el-form-item>
        <el-button type="primary" @click="handleSearch">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
        <el-button type="success" @click="handleExport">导出</el-button>
      </el-form-item>
    </el-form>

    <!-- 数据表格 -->
    <el-table v-loading="loading" :data="list" border>
      <el-table-column prop="logId" label="日志ID" width="80" />
      <el-table-column prop="operatorName" label="操作人" width="120" />
      <el-table-column prop="operationModule" label="操作模块" width="150" />
      <el-table-column prop="operationType" label="操作类型" width="100">
        <template slot-scope="scope">
          <el-tag :type="getOperationTypeTag(scope.row.operationType)">
            {{ scope.row.operationType }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="operationDesc" label="操作描述" min-width="200" show-overflow-tooltip />
      <el-table-column prop="requestIp" label="请求IP" width="130" />
      <el-table-column prop="operationTime" label="操作时间" width="160">
        <template slot-scope="scope">
          {{ formatDate(scope.row.operationTime) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="150" fixed="right">
        <template slot-scope="scope">
          <el-button
            type="text"
            size="small"
            @click="handleViewDetail(scope.row)"
          >
            查看详情
          </el-button>
          <el-button
            v-if="hasPermission('OperationLogDelete')"
            type="text"
            size="small"
            style="color: #f56c6c"
            @click="handleDelete(scope.row)"
          >
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <pagination
      :total="total"
      :page.sync="pageNum"
      :limit.sync="pageSize"
      @pagination="fetchData"
    />

    <!-- 详情对话框 -->
    <el-dialog
      title="操作日志详情"
      :visible.sync="detailDialogVisible"
      width="800px"
    >
      <el-descriptions :column="2" border>
        <el-descriptions-item label="日志ID">
          {{ detailData.logId }}
        </el-descriptions-item>
        <el-descriptions-item label="操作人">
          {{ detailData.operatorName }}
        </el-descriptions-item>
        <el-descriptions-item label="操作模块">
          {{ detailData.operationModule }}
        </el-descriptions-item>
        <el-descriptions-item label="操作类型">
          <el-tag :type="getOperationTypeTag(detailData.operationType)">
            {{ detailData.operationType }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="操作描述" :span="2">
          {{ detailData.operationDesc }}
        </el-descriptions-item>
        <el-descriptions-item label="请求方法" :span="2">
          {{ detailData.requestMethod }}
        </el-descriptions-item>
        <el-descriptions-item label="请求URL" :span="2">
          {{ detailData.requestUrl }}
        </el-descriptions-item>
        <el-descriptions-item label="请求参数" :span="2">
          <pre style="max-height: 200px; overflow-y: auto;">{{ formatJson(detailData.requestParams) }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="响应结果" :span="2">
          <pre style="max-height: 200px; overflow-y: auto;">{{ formatJson(detailData.responseResult) }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="请求IP">
          {{ detailData.requestIp }}
        </el-descriptions-item>
        <el-descriptions-item label="操作时间">
          {{ formatDate(detailData.operationTime) }}
        </el-descriptions-item>
        <el-descriptions-item label="执行时长">
          {{ detailData.executionTime }} ms
        </el-descriptions-item>
        <el-descriptions-item label="操作状态">
          <el-tag :type="detailData.operationStatus === 1 ? 'success' : 'danger'">
            {{ detailData.operationStatus === 1 ? '成功' : '失败' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item v-if="detailData.errorMsg" label="错误信息" :span="2">
          <pre style="max-height: 200px; overflow-y: auto; color: #f56c6c;">{{ detailData.errorMsg }}</pre>
        </el-descriptions-item>
      </el-descriptions>

      <div slot="footer">
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getOperationLogPage, getOperationLogDetail, deleteOperationLog, exportOperationLog } from '@/api/operationLog'
import Pagination from '@/components/Pagination'

export default {
  name: 'OperationLog',
  components: { Pagination },
  data() {
    return {
      // 搜索表单
      searchForm: {
        operatorName: '',
        operationModule: '',
        operationType: '',
        timeRange: null
      },

      // 列表数据
      list: [],
      loading: false,
      total: 0,
      pageNum: 1,
      pageSize: 10,

      // 详情对话框
      detailDialogVisible: false,
      detailData: {}
    }
  },

  computed: {
    // 权限检查
    hasPermission() {
      return (code) => {
        const permissions = this.$store.state.permission.buttonPermissionList || []
        return permissions.includes(code)
      }
    }
  },

  mounted() {
    this.fetchData()
  },

  methods: {
    // 获取列表数据
    async fetchData() {
      this.loading = true
      try {
        const params = {
          operatorName: this.searchForm.operatorName || null,
          operationModule: this.searchForm.operationModule || null,
          operationType: this.searchForm.operationType || null,
          startTime: this.searchForm.timeRange ? this.searchForm.timeRange[0] : null,
          endTime: this.searchForm.timeRange ? this.searchForm.timeRange[1] : null,
          pageNum: this.pageNum,
          pageSize: this.pageSize
        }
        const res = await getOperationLogPage(params)
        if (res.code === 0) {
          this.list = res.result.list || []
          this.total = res.result.total || 0
        } else {
          this.$message.error(res.msg || '获取列表失败')
        }
      } catch (error) {
        console.error('获取列表失败:', error)
        this.$message.error('获取列表失败')
      } finally {
        this.loading = false
      }
    },

    // 搜索
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },

    // 重置
    handleReset() {
      this.searchForm = {
        operatorName: '',
        operationModule: '',
        operationType: '',
        timeRange: null
      }
      this.handleSearch()
    },

    // 查看详情
    async handleViewDetail(row) {
      try {
        const res = await getOperationLogDetail(row.logId)
        if (res.code === 0) {
          this.detailData = res.result || {}
          this.detailDialogVisible = true
        } else {
          this.$message.error(res.msg || '获取详情失败')
        }
      } catch (error) {
        console.error('获取详情失败:', error)
        this.$message.error('获取详情失败')
      }
    },

    // 删除
    handleDelete(row) {
      this.$confirm('确定要删除该操作日志吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        try {
          const res = await deleteOperationLog(row.logId)
          if (res.code === 0) {
            this.$message.success('删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        } catch (error) {
          console.error('删除失败:', error)
          this.$message.error('删除失败')
        }
      }).catch(() => {})
    },

    // 导出
    async handleExport() {
      try {
        const params = {
          operatorName: this.searchForm.operatorName || null,
          operationModule: this.searchForm.operationModule || null,
          operationType: this.searchForm.operationType || null,
          startTime: this.searchForm.timeRange ? this.searchForm.timeRange[0] : null,
          endTime: this.searchForm.timeRange ? this.searchForm.timeRange[1] : null
        }
        const res = await exportOperationLog(params)

        // 创建下载链接
        const blob = new Blob([res], { type: 'application/vnd.ms-excel' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `操作日志_${new Date().getTime()}.xlsx`
        link.click()
        window.URL.revokeObjectURL(url)

        this.$message.success('导出成功')
      } catch (error) {
        console.error('导出失败:', error)
        this.$message.error('导出失败')
      }
    },

    // 获取操作类型标签颜色
    getOperationTypeTag(type) {
      const tagMap = {
        '新增': 'success',
        '修改': 'warning',
        '删除': 'danger',
        '查询': 'info',
        '导出': 'primary',
        '登录': 'success',
        '登出': 'info'
      }
      return tagMap[type] || 'info'
    },

    // 格式化日期
    formatDate(date) {
      if (!date) return ''
      const d = new Date(date)
      const year = d.getFullYear()
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      const hour = String(d.getHours()).padStart(2, '0')
      const minute = String(d.getMinutes()).padStart(2, '0')
      const second = String(d.getSeconds()).padStart(2, '0')
      return `${year}-${month}-${day} ${hour}:${minute}:${second}`
    },

    // 格式化JSON
    formatJson(jsonStr) {
      if (!jsonStr) return ''
      try {
        const obj = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr
        return JSON.stringify(obj, null, 2)
      } catch (e) {
        return jsonStr
      }
    }
  }
}
</script>

<style scoped>
.container {
  padding: 20px;
}

.search-form {
  background: #fff;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 4px;
}

pre {
  background: #f5f5f5;
  padding: 10px;
  border-radius: 4px;
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
}
</style>
