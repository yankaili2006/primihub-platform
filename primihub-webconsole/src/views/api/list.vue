<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper primary">
              <i class="el-icon-connection" />
            </div>
            <div class="stats-info">
              <div class="stats-label">总接口数</div>
              <div class="stats-value">{{ statistics.totalApis || 0 }}</div>
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
              <div class="stats-label">启用接口</div>
              <div class="stats-value">{{ statistics.enabledApis || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper warning">
              <i class="el-icon-cpu" />
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
            <div class="stats-icon-wrapper danger">
              <i class="el-icon-warning" />
            </div>
            <div class="stats-info">
              <div class="stats-label">今日异常</div>
              <div class="stats-value">{{ statistics.todayErrors || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 操作按钮 -->
    <div class="action-bar">
      <el-button type="primary" icon="el-icon-plus" @click="openAddDialog">新增接口</el-button>
      <el-button type="danger" icon="el-icon-delete" :disabled="selectedRows.length === 0" @click="batchDelete">批量删除</el-button>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-bar">
        <el-input
          v-model="searchForm.keyword"
          placeholder="接口名称/路径"
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
          v-model="searchForm.category"
          placeholder="接口分类"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="用户管理" value="USER" />
          <el-option label="资源管理" value="RESOURCE" />
          <el-option label="项目管理" value="PROJECT" />
          <el-option label="任务管理" value="TASK" />
          <el-option label="系统管理" value="SYSTEM" />
        </el-select>
        <el-select
          v-model="searchForm.status"
          placeholder="状态"
          style="width: 120px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="启用" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
        <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
        <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
      </div>
    </el-card>

    <!-- 接口列表 -->
    <el-card class="table-card" shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-connection" /> 接口列表</span>
      </div>

      <el-table
        v-loading="loading"
        :data="list"
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column label="序号" width="70" type="index" align="center" />
        <el-table-column label="接口名称" prop="apiName" min-width="180" show-overflow-tooltip />
        <el-table-column label="请求方法" prop="method" width="100" align="center">
          <template slot-scope="scope">
            <el-tag
              :type="scope.row.method === 'GET' ? 'success' : scope.row.method === 'POST' ? 'primary' : scope.row.method === 'PUT' ? 'warning' : 'danger'"
              size="small"
            >
              {{ scope.row.method }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="接口路径" prop="apiPath" min-width="250" show-overflow-tooltip />
        <el-table-column label="接口分类" prop="category" width="120" align="center">
          <template slot-scope="scope">
            <el-tag size="small">{{ getCategoryName(scope.row.category) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="需要授权" prop="needAuth" width="100" align="center">
          <template slot-scope="scope">
            <el-tag :type="scope.row.needAuth ? 'warning' : 'info'" size="small">
              {{ scope.row.needAuth ? '是' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="调用次数" prop="callCount" width="100" align="center" />
        <el-table-column label="状态" prop="status" width="80" align="center">
          <template slot-scope="scope">
            <el-switch
              v-model="scope.row.status"
              :active-value="1"
              :inactive-value="0"
              @change="toggleStatus(scope.row)"
            />
          </template>
        </el-table-column>
        <el-table-column label="创建时间" prop="createTime" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="viewDetail(scope.row)">
              <i class="el-icon-view" />详情
            </el-button>
            <el-button type="text" size="small" @click="openEditDialog(scope.row)">
              <i class="el-icon-edit" />编辑
            </el-button>
            <el-button type="text" size="small" style="color: #f56c6c;" @click="handleDelete(scope.row)">
              <i class="el-icon-delete" />删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </el-card>

    <!-- 新增/编辑接口弹窗 -->
    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="700px">
      <el-form ref="apiForm" :model="apiForm" :rules="apiRules" label-width="120px">
        <el-form-item label="接口名称" prop="apiName">
          <el-input v-model="apiForm.apiName" placeholder="请输入接口名称" />
        </el-form-item>
        <el-form-item label="请求方法" prop="method">
          <el-select v-model="apiForm.method" placeholder="请选择请求方法" style="width: 100%;">
            <el-option label="GET" value="GET" />
            <el-option label="POST" value="POST" />
            <el-option label="PUT" value="PUT" />
            <el-option label="DELETE" value="DELETE" />
          </el-select>
        </el-form-item>
        <el-form-item label="接口路径" prop="apiPath">
          <el-input v-model="apiForm.apiPath" placeholder="/api/xxx/xxx" />
        </el-form-item>
        <el-form-item label="接口分类" prop="category">
          <el-select v-model="apiForm.category" placeholder="请选择接口分类" style="width: 100%;">
            <el-option label="用户管理" value="USER" />
            <el-option label="资源管理" value="RESOURCE" />
            <el-option label="项目管理" value="PROJECT" />
            <el-option label="任务管理" value="TASK" />
            <el-option label="系统管理" value="SYSTEM" />
          </el-select>
        </el-form-item>
        <el-form-item label="需要授权">
          <el-switch v-model="apiForm.needAuth" />
        </el-form-item>
        <el-form-item label="请求参数">
          <el-input v-model="apiForm.requestParams" type="textarea" :rows="4" placeholder="JSON格式，如：{&quot;userId&quot;: &quot;用户ID&quot;, &quot;pageNum&quot;: &quot;页码&quot;}" />
        </el-form-item>
        <el-form-item label="响应示例">
          <el-input v-model="apiForm.responseExample" type="textarea" :rows="4" placeholder="JSON格式响应示例" />
        </el-form-item>
        <el-form-item label="接口描述">
          <el-input v-model="apiForm.description" type="textarea" :rows="3" placeholder="请输入接口描述" />
        </el-form-item>
        <el-form-item label="限流配置">
          <el-input-number v-model="apiForm.rateLimit" :min="0" :max="10000" placeholder="每分钟最大请求数" />
          <span style="margin-left: 10px;">次/分钟（0表示不限流）</span>
        </el-form-item>
        <el-form-item label="超时时间">
          <el-input-number v-model="apiForm.timeout" :min="1" :max="300" placeholder="超时时间" />
          <span style="margin-left: 10px;">秒</span>
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="apiForm.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitForm">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 接口详情弹窗 -->
    <el-dialog :visible.sync="detailVisible" title="接口详情" width="800px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="接口名称">{{ detailInfo.apiName }}</el-descriptions-item>
        <el-descriptions-item label="请求方法">
          <el-tag :type="detailInfo.method === 'GET' ? 'success' : 'primary'" size="small">
            {{ detailInfo.method }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="接口路径" :span="2">{{ detailInfo.apiPath }}</el-descriptions-item>
        <el-descriptions-item label="接口分类">{{ getCategoryName(detailInfo.category) }}</el-descriptions-item>
        <el-descriptions-item label="需要授权">
          <el-tag :type="detailInfo.needAuth ? 'warning' : 'info'" size="small">
            {{ detailInfo.needAuth ? '是' : '否' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="限流配置">{{ detailInfo.rateLimit || 0 }} 次/分钟</el-descriptions-item>
        <el-descriptions-item label="超时时间">{{ detailInfo.timeout || 30 }} 秒</el-descriptions-item>
        <el-descriptions-item label="调用次数">{{ detailInfo.callCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="成功次数">{{ detailInfo.successCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="失败次数">{{ detailInfo.failCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="平均响应时间">{{ detailInfo.avgResponseTime || 0 }} ms</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="detailInfo.status === 1 ? 'success' : 'info'" size="small">
            {{ detailInfo.status === 1 ? '启用' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailInfo.createTime }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detailInfo.updateTime }}</el-descriptions-item>
        <el-descriptions-item label="接口描述" :span="2">{{ detailInfo.description || '-' }}</el-descriptions-item>
      </el-descriptions>

      <div v-if="detailInfo.requestParams" style="margin-top: 20px;">
        <el-divider content-position="left">请求参数</el-divider>
        <pre class="json-view">{{ formatJson(detailInfo.requestParams) }}</pre>
      </div>

      <div v-if="detailInfo.responseExample" style="margin-top: 20px;">
        <el-divider content-position="left">响应示例</el-divider>
        <pre class="json-view">{{ formatJson(detailInfo.responseExample) }}</pre>
      </div>

      <div slot="footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApiPage, addApi, updateApi, deleteApi, batchDeleteApi, getApiDetail, toggleApiStatus, getApiStatistics } from '@/api/apiManage'
import Pagination from '@/components/Pagination'

export default {
  name: 'ApiList',
  components: { Pagination },
  data() {
    return {
      statistics: {},
      list: [],
      selectedRows: [],
      searchForm: {
        keyword: '',
        method: '',
        category: '',
        status: ''
      },
      loading: false,
      dialogVisible: false,
      dialogTitle: '新增接口',
      isEdit: false,
      apiForm: {
        id: null,
        apiName: '',
        method: 'GET',
        apiPath: '',
        category: '',
        needAuth: false,
        requestParams: '',
        responseExample: '',
        description: '',
        rateLimit: 0,
        timeout: 30,
        status: 1
      },
      apiRules: {
        apiName: [{ required: true, message: '请输入接口名称', trigger: 'blur' }],
        method: [{ required: true, message: '请选择请求方法', trigger: 'change' }],
        apiPath: [{ required: true, message: '请输入接口路径', trigger: 'blur' }],
        category: [{ required: true, message: '请选择接口分类', trigger: 'change' }]
      },
      submitting: false,
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
        category: this.searchForm.category,
        status: this.searchForm.status
      }
      // TODO: 调用实际接口
      const res = await getApiPage(params)
      if (res && res.code === 0) {
        const { list, pageParam } = res.result
        this.list = list || []
        this.pageCount = Number(pageParam?.pageCount || 0)
        this.pageNum = Number(pageParam?.pageNum || 1)
        this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
      } else {
        // 模拟数据
        this.list = [
          { id: 1, apiName: '获取用户列表', method: 'GET', apiPath: '/api/user/getUserList', category: 'USER', needAuth: true, callCount: 1523, status: 1, createTime: '2026-01-05 10:20:30' },
          { id: 2, apiName: '创建资源', method: 'POST', apiPath: '/api/resource/createResource', category: 'RESOURCE', needAuth: true, callCount: 856, status: 1, createTime: '2026-01-04 14:35:22' },
          { id: 3, apiName: '删除项目', method: 'DELETE', apiPath: '/api/project/deleteProject', category: 'PROJECT', needAuth: true, callCount: 234, status: 1, createTime: '2026-01-03 09:18:45' }
        ]
        this.pageCount = 1
        this.itemTotalCount = 3
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
          totalApis: 156,
          enabledApis: 142,
          todayCalls: 8523,
          todayErrors: 12
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
        category: '',
        status: ''
      }
      this.pageNum = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchData()
    },
    handleSelectionChange(rows) {
      this.selectedRows = rows
    },
    openAddDialog() {
      this.isEdit = false
      this.dialogTitle = '新增接口'
      this.apiForm = {
        id: null,
        apiName: '',
        method: 'GET',
        apiPath: '',
        category: '',
        needAuth: false,
        requestParams: '',
        responseExample: '',
        description: '',
        rateLimit: 0,
        timeout: 30,
        status: 1
      }
      this.dialogVisible = true
    },
    openEditDialog(row) {
      this.isEdit = true
      this.dialogTitle = '编辑接口'
      this.apiForm = { ...row }
      this.dialogVisible = true
    },
    submitForm() {
      this.$refs.apiForm.validate(async(valid) => {
        if (valid) {
          this.submitting = true
          // TODO: 调用实际接口
          const res = this.isEdit ? await updateApi(this.apiForm) : await addApi(this.apiForm)
          this.submitting = false
          if (res && res.code === 0) {
            this.$message.success(this.isEdit ? '接口更新成功' : '接口创建成功')
            this.dialogVisible = false
            this.fetchData()
            this.fetchStatistics()
          } else {
            this.$message.error((res && res.msg) || (this.isEdit ? '接口更新失败' : '接口创建失败'))
          }
        }
      })
    },
    async toggleStatus(row) {
      // TODO: 调用实际接口
      const res = await toggleApiStatus({ id: row.id, status: row.status })
      if (res && res.code === 0) {
        this.$message.success('状态更新成功')
      } else {
        row.status = row.status === 1 ? 0 : 1
      }
    },
    handleDelete(row) {
      this.$confirm('确定要删除该接口吗？', '警告', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        // TODO: 调用实际接口
        const res = await deleteApi({ id: row.id })
        if (res && res.code === 0) {
          this.$message.success('删除成功')
          this.fetchData()
          this.fetchStatistics()
        }
      })
    },
    batchDelete() {
      this.$confirm(`确定要删除选中的 ${this.selectedRows.length} 个接口吗？`, '警告', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        const ids = this.selectedRows.map(row => row.id)
        // TODO: 调用实际接口
        const res = await batchDeleteApi({ ids })
        if (res && res.code === 0) {
          this.$message.success('批量删除成功')
          this.fetchData()
          this.fetchStatistics()
        }
      })
    },
    async viewDetail(row) {
      // TODO: 调用实际接口
      const res = await getApiDetail({ id: row.id })
      if (res && res.code === 0) {
        this.detailInfo = res.result || {}
      } else {
        this.detailInfo = { ...row }
      }
      this.detailVisible = true
    },
    getCategoryName(category) {
      const map = {
        USER: '用户管理',
        RESOURCE: '资源管理',
        PROJECT: '项目管理',
        TASK: '任务管理',
        SYSTEM: '系统管理'
      }
      return map[category] || category
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

.json-view {
  background: #f5f7fa;
  padding: 15px;
  border-radius: 4px;
  font-size: 12px;
  overflow-x: auto;
}

::v-deep .el-table th {
  background: #fafafa;
}
</style>
