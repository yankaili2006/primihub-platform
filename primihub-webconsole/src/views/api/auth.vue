<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper primary">
              <i class="el-icon-key" />
            </div>
            <div class="stats-info">
              <div class="stats-label">授权总数</div>
              <div class="stats-value">{{ statistics.totalAuths || 0 }}</div>
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
              <div class="stats-label">有效授权</div>
              <div class="stats-value">{{ statistics.validAuths || 0 }}</div>
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
              <div class="stats-label">即将过期</div>
              <div class="stats-value">{{ statistics.expiringAuths || 0 }}</div>
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
              <div class="stats-label">已过期</div>
              <div class="stats-value">{{ statistics.expiredAuths || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 操作按钮 -->
    <div class="action-bar">
      <el-button type="primary" icon="el-icon-plus" @click="openAddDialog">新增授权</el-button>
      <el-button type="success" icon="el-icon-circle-check" @click="openValidateDialog">校验授权</el-button>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-bar">
        <el-input
          v-model="searchForm.keyword"
          placeholder="应用名称/AppKey"
          style="width: 250px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
        />
        <el-select
          v-model="searchForm.authType"
          placeholder="授权类型"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="API Key" value="API_KEY" />
          <el-option label="OAuth2" value="OAUTH2" />
          <el-option label="JWT" value="JWT" />
        </el-select>
        <el-select
          v-model="searchForm.status"
          placeholder="状态"
          style="width: 120px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="有效" value="VALID" />
          <el-option label="过期" value="EXPIRED" />
          <el-option label="禁用" value="DISABLED" />
        </el-select>
        <el-date-picker
          v-model="dateRange"
          type="datetimerange"
          range-separator="至"
          start-placeholder="授权开始时间"
          end-placeholder="授权结束时间"
          style="width: 380px; margin-right: 10px;"
        />
        <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
        <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
      </div>
    </el-card>

    <!-- 授权列表 -->
    <el-card class="table-card" shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-key" /> 授权列表</span>
      </div>

      <el-table
        v-loading="loading"
        :data="list"
        stripe
      >
        <el-table-column label="序号" width="70" type="index" align="center" />
        <el-table-column label="应用名称" prop="appName" min-width="150" />
        <el-table-column label="AppKey" prop="appKey" width="200" show-overflow-tooltip>
          <template slot-scope="scope">
            <span class="key-text">{{ scope.row.appKey }}</span>
            <el-button type="text" icon="el-icon-document-copy" size="small" @click="copyText(scope.row.appKey)" />
          </template>
        </el-table-column>
        <el-table-column label="AppSecret" prop="appSecret" width="120" align="center">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="viewSecret(scope.row)">
              <i class="el-icon-view" />查看
            </el-button>
          </template>
        </el-table-column>
        <el-table-column label="授权类型" prop="authType" width="120" align="center">
          <template slot-scope="scope">
            <el-tag size="small">{{ scope.row.authType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="授权接口数" prop="apiCount" width="100" align="center" />
        <el-table-column label="有效期" width="180">
          <template slot-scope="scope">
            {{ scope.row.startTime }} 至<br>{{ scope.row.endTime }}
          </template>
        </el-table-column>
        <el-table-column label="状态" prop="status" width="100" align="center">
          <template slot-scope="scope">
            <el-tag
              :type="scope.row.status === 'VALID' ? 'success' : scope.row.status === 'EXPIRED' ? 'info' : 'danger'"
              size="small"
            >
              {{ scope.row.status === 'VALID' ? '有效' : scope.row.status === 'EXPIRED' ? '过期' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="调用次数" prop="callCount" width="100" align="center" />
        <el-table-column label="操作" width="220" fixed="right">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="viewDetail(scope.row)">
              <i class="el-icon-view" />详情
            </el-button>
            <el-button type="text" size="small" @click="openEditDialog(scope.row)">
              <i class="el-icon-edit" />编辑
            </el-button>
            <el-button type="text" size="small" @click="refreshToken(scope.row)">
              <i class="el-icon-refresh" />刷新令牌
            </el-button>
            <el-button type="text" size="small" style="color: #f56c6c;" @click="handleDelete(scope.row)">
              <i class="el-icon-delete" />删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </el-card>

    <!-- 新增/编辑授权弹窗 -->
    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="700px">
      <el-form ref="authForm" :model="authForm" :rules="authRules" label-width="120px">
        <el-form-item label="应用名称" prop="appName">
          <el-input v-model="authForm.appName" placeholder="请输入应用名称" />
        </el-form-item>
        <el-form-item label="授权类型" prop="authType">
          <el-select v-model="authForm.authType" placeholder="请选择授权类型" style="width: 100%;">
            <el-option label="API Key" value="API_KEY" />
            <el-option label="OAuth2" value="OAUTH2" />
            <el-option label="JWT" value="JWT" />
          </el-select>
        </el-form-item>
        <el-form-item label="授权接口" prop="apiIds">
          <el-select v-model="authForm.apiIds" multiple placeholder="请选择授权接口" style="width: 100%;">
            <el-option
              v-for="api in apiList"
              :key="api.id"
              :label="api.apiName"
              :value="api.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="有效期" prop="dateRange">
          <el-date-picker
            v-model="authForm.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="IP白名单">
          <el-input v-model="authForm.ipWhitelist" type="textarea" :rows="3" placeholder="多个IP用逗号分隔，不填则不限制" />
        </el-form-item>
        <el-form-item label="限流配置">
          <el-input-number v-model="authForm.rateLimit" :min="0" :max="10000" />
          <span style="margin-left: 10px;">次/分钟（0表示不限流）</span>
        </el-form-item>
        <el-form-item label="应用描述">
          <el-input v-model="authForm.description" type="textarea" :rows="3" placeholder="请输入应用描述" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitForm">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 授权详情弹窗 -->
    <el-dialog :visible.sync="detailVisible" title="授权详情" width="800px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="应用名称">{{ detailInfo.appName }}</el-descriptions-item>
        <el-descriptions-item label="授权类型">
          <el-tag size="small">{{ detailInfo.authType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="AppKey" :span="2">
          <span class="key-text">{{ detailInfo.appKey }}</span>
          <el-button type="text" icon="el-icon-document-copy" size="small" @click="copyText(detailInfo.appKey)" />
        </el-descriptions-item>
        <el-descriptions-item label="授权接口数">{{ detailInfo.apiCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="限流配置">{{ detailInfo.rateLimit || 0 }} 次/分钟</el-descriptions-item>
        <el-descriptions-item label="开始时间">{{ detailInfo.startTime }}</el-descriptions-item>
        <el-descriptions-item label="结束时间">{{ detailInfo.endTime }}</el-descriptions-item>
        <el-descriptions-item label="调用次数">{{ detailInfo.callCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="成功次数">{{ detailInfo.successCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="失败次数">{{ detailInfo.failCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="最后调用时间">{{ detailInfo.lastCallTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag
            :type="detailInfo.status === 'VALID' ? 'success' : detailInfo.status === 'EXPIRED' ? 'info' : 'danger'"
            size="small"
          >
            {{ detailInfo.status === 'VALID' ? '有效' : detailInfo.status === 'EXPIRED' ? '过期' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailInfo.createTime }}</el-descriptions-item>
        <el-descriptions-item label="IP白名单" :span="2">{{ detailInfo.ipWhitelist || '不限制' }}</el-descriptions-item>
        <el-descriptions-item label="应用描述" :span="2">{{ detailInfo.description || '-' }}</el-descriptions-item>
      </el-descriptions>

      <div v-if="detailInfo.authorizedApis && detailInfo.authorizedApis.length > 0" style="margin-top: 20px;">
        <el-divider content-position="left">授权接口列表</el-divider>
        <el-table :data="detailInfo.authorizedApis" size="small" stripe>
          <el-table-column label="接口名称" prop="apiName" />
          <el-table-column label="请求方法" prop="method" width="100" align="center">
            <template slot-scope="scope">
              <el-tag size="mini">{{ scope.row.method }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="接口路径" prop="apiPath" show-overflow-tooltip />
        </el-table>
      </div>

      <div slot="footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
      </div>
    </el-dialog>

    <!-- 查看Secret弹窗 -->
    <el-dialog :visible.sync="secretVisible" title="AppSecret" width="500px">
      <el-alert
        title="请妥善保管AppSecret，泄露后可能导致安全风险"
        type="warning"
        :closable="false"
        style="margin-bottom: 20px;"
      />
      <div class="secret-display">
        <span class="key-text">{{ currentSecret }}</span>
        <el-button type="primary" icon="el-icon-document-copy" size="small" @click="copyText(currentSecret)">复制</el-button>
      </div>
      <div slot="footer">
        <el-button type="primary" @click="secretVisible = false">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 校验授权弹窗 -->
    <el-dialog :visible.sync="validateVisible" title="校验授权" width="600px">
      <el-form ref="validateForm" :model="validateForm" label-width="120px">
        <el-form-item label="AppKey" prop="appKey">
          <el-input v-model="validateForm.appKey" placeholder="请输入AppKey" />
        </el-form-item>
        <el-form-item label="AppSecret" prop="appSecret">
          <el-input v-model="validateForm.appSecret" type="password" show-password placeholder="请输入AppSecret" />
        </el-form-item>
        <el-form-item label="接口路径" prop="apiPath">
          <el-input v-model="validateForm.apiPath" placeholder="如：/api/user/getUserList" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="validating" @click="submitValidate">开始校验</el-button>
        </el-form-item>
      </el-form>

      <div v-if="validateResult" class="validate-result">
        <el-divider content-position="left">校验结果</el-divider>
        <el-result
          :icon="validateResult.valid ? 'success' : 'error'"
          :title="validateResult.valid ? '授权校验通过' : '授权校验失败'"
          :sub-title="validateResult.message"
        >
          <template v-if="validateResult.valid" slot="extra">
            <div class="result-details">
              <p><strong>应用名称：</strong>{{ validateResult.appName }}</p>
              <p><strong>授权类型：</strong>{{ validateResult.authType }}</p>
              <p><strong>剩余有效期：</strong>{{ validateResult.remainingDays }}天</p>
              <p><strong>剩余调用次数：</strong>{{ validateResult.remainingCalls || '不限制' }}</p>
            </div>
          </template>
        </el-result>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApiAuthPage, addApiAuth, updateApiAuth, deleteApiAuth, validateApiAuth, refreshAuthToken, getApiPage } from '@/api/apiManage'
import Pagination from '@/components/Pagination'

export default {
  name: 'ApiAuth',
  components: { Pagination },
  data() {
    return {
      statistics: {},
      list: [],
      searchForm: {
        keyword: '',
        authType: '',
        status: ''
      },
      dateRange: [],
      loading: false,
      dialogVisible: false,
      dialogTitle: '新增授权',
      isEdit: false,
      authForm: {
        id: null,
        appName: '',
        authType: 'API_KEY',
        apiIds: [],
        dateRange: [],
        ipWhitelist: '',
        rateLimit: 0,
        description: ''
      },
      authRules: {
        appName: [{ required: true, message: '请输入应用名称', trigger: 'blur' }],
        authType: [{ required: true, message: '请选择授权类型', trigger: 'change' }],
        apiIds: [{ required: true, message: '请选择授权接口', trigger: 'change' }],
        dateRange: [{ required: true, message: '请选择有效期', trigger: 'change' }]
      },
      submitting: false,
      detailVisible: false,
      detailInfo: {},
      secretVisible: false,
      currentSecret: '',
      validateVisible: false,
      validateForm: {
        appKey: '',
        appSecret: '',
        apiPath: ''
      },
      validateResult: null,
      validating: false,
      apiList: [],
      itemTotalCount: 0,
      pageSize: 10,
      pageCount: 0,
      pageNum: 1
    }
  },
  created() {
    this.fetchData()
    this.fetchStatistics()
    this.fetchApiList()
  },
  methods: {
    async fetchData() {
      this.loading = true
      const params = {
        pageSize: this.pageSize,
        pageNum: this.pageNum,
        keyword: this.searchForm.keyword,
        authType: this.searchForm.authType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange.length > 0 ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange.length > 1 ? this.dateRange[1] : ''
      }
      // TODO: 调用实际接口
      const res = await getApiAuthPage(params)
      if (res && res.code === 0) {
        const { list, pageParam } = res.result
        this.list = list || []
        this.pageCount = Number(pageParam?.pageCount || 0)
        this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
      } else {
        // 模拟数据
        this.list = [
          { id: 1, appName: '数据平台应用', appKey: 'ak_1a2b3c4d5e6f7g8h', authType: 'API_KEY', apiCount: 15, startTime: '2026-01-01 00:00:00', endTime: '2026-12-31 23:59:59', status: 'VALID', callCount: 8523, createTime: '2026-01-01 10:00:00' },
          { id: 2, appName: '第三方系统', appKey: 'ak_9i8h7g6f5e4d3c2b', authType: 'JWT', apiCount: 8, startTime: '2025-12-01 00:00:00', endTime: '2026-06-30 23:59:59', status: 'VALID', callCount: 2341, createTime: '2025-12-01 14:30:00' }
        ]
        this.pageCount = 1
        this.itemTotalCount = 2
      }
      this.loading = false
    },
    async fetchStatistics() {
      // TODO: 调用实际接口
      this.statistics = {
        totalAuths: 25,
        validAuths: 20,
        expiringAuths: 3,
        expiredAuths: 2
      }
    },
    async fetchApiList() {
      // TODO: 调用实际接口，获取所有可授权的接口
      const res = await getApiPage({ pageSize: 1000, status: 1 })
      if (res && res.code === 0) {
        this.apiList = res.result?.list || []
      } else {
        this.apiList = [
          { id: 1, apiName: '获取用户列表' },
          { id: 2, apiName: '创建资源' },
          { id: 3, apiName: '删除项目' }
        ]
      }
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        keyword: '',
        authType: '',
        status: ''
      }
      this.dateRange = []
      this.pageNum = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchData()
    },
    openAddDialog() {
      this.isEdit = false
      this.dialogTitle = '新增授权'
      this.authForm = {
        id: null,
        appName: '',
        authType: 'API_KEY',
        apiIds: [],
        dateRange: [],
        ipWhitelist: '',
        rateLimit: 0,
        description: ''
      }
      this.dialogVisible = true
    },
    openEditDialog(row) {
      this.isEdit = true
      this.dialogTitle = '编辑授权'
      this.authForm = {
        ...row,
        dateRange: [row.startTime, row.endTime]
      }
      this.dialogVisible = true
    },
    submitForm() {
      this.$refs.authForm.validate(async(valid) => {
        if (valid) {
          this.submitting = true
          const data = {
            ...this.authForm,
            startTime: this.authForm.dateRange[0],
            endTime: this.authForm.dateRange[1]
          }
          // TODO: 调用实际接口
          const res = this.isEdit ? await updateApiAuth(data) : await addApiAuth(data)
          this.submitting = false
          if (res && res.code === 0) {
            this.$message.success(this.isEdit ? '授权更新成功' : '授权创建成功')
            this.dialogVisible = false
            this.fetchData()
            this.fetchStatistics()
          }
        }
      })
    },
    handleDelete(row) {
      this.$confirm('确定要删除该授权吗？', '警告', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        // TODO: 调用实际接口
        const res = await deleteApiAuth({ id: row.id })
        if (res && res.code === 0) {
          this.$message.success('删除成功')
          this.fetchData()
          this.fetchStatistics()
        }
      })
    },
    async viewDetail(row) {
      // TODO: 调用实际接口
      this.detailInfo = {
        ...row,
        authorizedApis: [
          { apiName: '获取用户列表', method: 'GET', apiPath: '/api/user/getUserList' },
          { apiName: '创建资源', method: 'POST', apiPath: '/api/resource/createResource' }
        ]
      }
      this.detailVisible = true
    },
    viewSecret(row) {
      // TODO: 调用实际接口获取Secret
      this.currentSecret = 'sk_' + Math.random().toString(36).substring(2, 34)
      this.secretVisible = true
    },
    async refreshToken(row) {
      this.$confirm('刷新令牌后，旧令牌将失效，确定要继续吗？', '警告', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        // TODO: 调用实际接口
        const res = await refreshAuthToken({ id: row.id })
        if (res && res.code === 0) {
          this.$message.success('令牌刷新成功')
          this.fetchData()
        }
      })
    },
    openValidateDialog() {
      this.validateForm = {
        appKey: '',
        appSecret: '',
        apiPath: ''
      }
      this.validateResult = null
      this.validateVisible = true
    },
    async submitValidate() {
      if (!this.validateForm.appKey || !this.validateForm.appSecret || !this.validateForm.apiPath) {
        this.$message.warning('请填写完整信息')
        return
      }
      this.validating = true
      // TODO: 调用实际接口
      const res = await validateApiAuth(this.validateForm)
      this.validating = false
      if (res && res.code === 0) {
        this.validateResult = res.result || { valid: false, message: '校验失败' }
      } else {
        // 模拟结果
        this.validateResult = {
          valid: true,
          message: '授权有效，可以正常调用接口',
          appName: '数据平台应用',
          authType: 'API_KEY',
          remainingDays: 325,
          remainingCalls: null
        }
      }
    },
    copyText(text) {
      navigator.clipboard.writeText(text)
      this.$message.success('已复制到剪贴板')
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
  font-size: 14px;
  color: #409eff;
}

.secret-display {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 15px;
  background: #f5f7fa;
  border-radius: 4px;
}

.validate-result {
  margin-top: 20px;
  .result-details {
    text-align: left;
    padding: 20px;
    background: #f5f7fa;
    border-radius: 4px;
    p {
      margin: 10px 0;
      line-height: 1.8;
    }
  }
}

::v-deep .el-table th {
  background: #fafafa;
}
</style>
