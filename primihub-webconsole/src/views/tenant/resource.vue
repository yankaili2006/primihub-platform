<template>
  <div class="container">
    <!-- 租户信息卡片 -->
    <el-card class="tenant-info-card" shadow="never">
      <div class="tenant-header">
        <div class="tenant-title">
          <i class="el-icon-office-building" />
          <span class="tenant-name">{{ tenantInfo.tenantName || '加载中...' }}</span>
          <el-tag v-if="tenantInfo.status === 1" type="success" size="small">正常</el-tag>
          <el-tag v-else type="danger" size="small">冻结</el-tag>
        </div>
        <el-button type="primary" plain @click="goBack">返回列表</el-button>
      </div>
      <div class="tenant-details">
        <el-row :gutter="20">
          <el-col :span="6">
            <div class="detail-item">
              <span class="detail-label">租户编码：</span>
              <span class="detail-value">{{ tenantInfo.tenantCode }}</span>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="detail-item">
              <span class="detail-label">联系人：</span>
              <span class="detail-value">{{ tenantInfo.contactPerson }}</span>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="detail-item">
              <span class="detail-label">联系电话：</span>
              <span class="detail-value">{{ tenantInfo.contactPhone }}</span>
            </div>
          </el-col>
          <el-col :span="6">
            <div class="detail-item">
              <span class="detail-label">数据隔离：</span>
              <el-tag v-if="tenantInfo.dataIsolation" type="success" size="mini">已启用</el-tag>
              <el-tag v-else type="info" size="mini">未启用</el-tag>
            </div>
          </el-col>
        </el-row>
      </div>
    </el-card>

    <!-- 资源统计 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper cpu">
              <i class="el-icon-cpu" />
            </div>
            <div class="stats-info">
              <div class="stats-label">CPU配额</div>
              <div class="stats-value">{{ resourceStats.cpuQuota || 0 }} 核</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper memory">
              <i class="el-icon-coin" />
            </div>
            <div class="stats-info">
              <div class="stats-label">内存配额</div>
              <div class="stats-value">{{ resourceStats.memoryQuota || 0 }} GB</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper storage">
              <i class="el-icon-folder-opened" />
            </div>
            <div class="stats-info">
              <div class="stats-label">存储配额</div>
              <div class="stats-value">{{ resourceStats.storageQuota || 0 }} GB</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper dataset">
              <i class="el-icon-s-data" />
            </div>
            <div class="stats-info">
              <div class="stats-label">数据集数量</div>
              <div class="stats-value">{{ resourceStats.datasetCount || 0 }} 个</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 资源分配表格 -->
    <el-card class="resource-card" shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-document" /> 资源分配列表</span>
        <div class="card-actions">
          <el-button type="primary" icon="el-icon-plus" size="small" @click="openAddResource">添加资源</el-button>
          <el-button type="warning" icon="el-icon-setting" size="small" @click="openQuotaConfig">配额配置</el-button>
        </div>
      </div>

      <!-- 筛选条件 -->
      <div class="filter-bar">
        <el-input
          v-model="searchForm.resourceName"
          placeholder="请输入资源名称"
          style="width: 200px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
        />
        <el-select
          v-model="searchForm.resourceType"
          placeholder="资源类型"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="数据集" value="DATASET" />
          <el-option label="计算资源" value="COMPUTE" />
          <el-option label="存储资源" value="STORAGE" />
          <el-option label="模型" value="MODEL" />
        </el-select>
        <el-select
          v-model="searchForm.status"
          placeholder="状态"
          style="width: 120px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="正常" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
        <el-button type="primary" icon="el-icon-search" size="small" @click="handleSearch">搜索</el-button>
        <el-button icon="el-icon-refresh" size="small" @click="handleReset">重置</el-button>
      </div>

      <!-- 资源列表 -->
      <el-table
        v-loading="loading"
        :data="resourceList"
        class="resource-table"
        stripe
      >
        <el-table-column align="center" label="序号" width="70" type="index" />
        <el-table-column align="left" label="资源ID" prop="resourceId" width="100" />
        <el-table-column align="left" label="资源名称" prop="resourceName" min-width="200" show-overflow-tooltip>
          <template slot-scope="scope">
            <span class="resource-name">{{ scope.row.resourceName }}</span>
          </template>
        </el-table-column>
        <el-table-column align="center" label="资源类型" prop="resourceType" width="120">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.resourceType === 'DATASET'" type="primary" size="small">数据集</el-tag>
            <el-tag v-else-if="scope.row.resourceType === 'COMPUTE'" type="success" size="small">计算资源</el-tag>
            <el-tag v-else-if="scope.row.resourceType === 'STORAGE'" type="warning" size="small">存储资源</el-tag>
            <el-tag v-else-if="scope.row.resourceType === 'MODEL'" type="info" size="small">模型</el-tag>
            <el-tag v-else size="small">{{ scope.row.resourceType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="配额量" prop="quotaAmount" width="120">
          <template slot-scope="scope">
            <span class="quota-value">{{ scope.row.quotaAmount || '-' }} {{ scope.row.quotaUnit || '' }}</span>
          </template>
        </el-table-column>
        <el-table-column align="center" label="已使用" prop="usedAmount" width="120">
          <template slot-scope="scope">
            <el-progress
              v-if="scope.row.quotaAmount"
              :percentage="calculateUsagePercent(scope.row)"
              :color="getProgressColor(calculateUsagePercent(scope.row))"
              :format="() => `${scope.row.usedAmount || 0}${scope.row.quotaUnit || ''}`"
            />
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column align="center" label="权限级别" prop="permissionLevel" width="120">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.permissionLevel === 'READ'" type="info" size="mini">只读</el-tag>
            <el-tag v-else-if="scope.row.permissionLevel === 'WRITE'" type="warning" size="mini">读写</el-tag>
            <el-tag v-else-if="scope.row.permissionLevel === 'ADMIN'" type="danger" size="mini">管理</el-tag>
            <el-tag v-else size="mini">{{ scope.row.permissionLevel }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="状态" prop="status" width="100">
          <template slot-scope="scope">
            <el-switch
              v-model="scope.row.status"
              :active-value="1"
              :inactive-value="0"
              @change="handleStatusChange(scope.row)"
            />
          </template>
        </el-table-column>
        <el-table-column align="center" label="分配时间" prop="createTime" width="180" />
        <el-table-column align="center" label="操作" fixed="right" width="150">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="openEditResource(scope.row)"><i class="el-icon-edit" />编辑</el-button>
            <el-button type="text" size="small" style="color: #f56c6c;" @click="handleDeleteResource(scope.row)"><i class="el-icon-delete" />删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </el-card>

    <!-- 添加/编辑资源弹窗 -->
    <el-dialog :visible.sync="resourceDialogVisible" :title="resourceDialogTitle" width="600px" @close="closeResourceDialog">
      <el-form ref="resourceForm" :model="resourceForm" :rules="resourceRules" label-width="110px">
        <el-form-item label="选择资源" prop="resourceId">
          <el-select
            v-model="resourceForm.resourceId"
            placeholder="请选择要分配的资源"
            style="width: 100%;"
            filterable
            :loading="availableResourcesLoading"
            @change="handleResourceSelect"
          >
            <el-option
              v-for="item in availableResources"
              :key="item.id"
              :label="`${item.name} (${item.type})`"
              :value="item.id"
            >
              <span style="float: left">{{ item.name }}</span>
              <span style="float: right; color: #8492a6; font-size: 13px">{{ item.type }}</span>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="资源类型" prop="resourceType">
          <el-input v-model="resourceForm.resourceType" disabled />
        </el-form-item>
        <el-form-item label="权限级别" prop="permissionLevel">
          <el-radio-group v-model="resourceForm.permissionLevel">
            <el-radio label="READ">只读</el-radio>
            <el-radio label="WRITE">读写</el-radio>
            <el-radio label="ADMIN">管理</el-radio>
          </el-radio-group>
          <div class="form-tip">只读：仅查看；读写：查看和使用；管理：完全控制</div>
        </el-form-item>
        <el-form-item label="配额设置" prop="quotaAmount">
          <el-input-number
            v-model="resourceForm.quotaAmount"
            :min="0"
            :precision="2"
            style="width: 200px;"
          />
          <el-select v-model="resourceForm.quotaUnit" style="width: 100px; margin-left: 10px;">
            <el-option label="GB" value="GB" />
            <el-option label="TB" value="TB" />
            <el-option label="次" value="次" />
            <el-option label="个" value="个" />
          </el-select>
          <div class="form-tip">设置该资源的使用配额限制</div>
        </el-form-item>
        <el-form-item label="生效时间" prop="effectiveTime">
          <el-date-picker
            v-model="resourceForm.effectiveTime"
            type="datetime"
            placeholder="选择生效时间"
            style="width: 100%;"
            value-format="yyyy-MM-dd HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="过期时间" prop="expiryTime">
          <el-date-picker
            v-model="resourceForm.expiryTime"
            type="datetime"
            placeholder="选择过期时间（可选）"
            style="width: 100%;"
            value-format="yyyy-MM-dd HH:mm:ss"
          />
          <div class="form-tip">不设置则永久有效</div>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input
            v-model="resourceForm.remark"
            type="textarea"
            :rows="3"
            placeholder="请输入备注信息"
            maxlength="200"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="closeResourceDialog">取 消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="submitResourceForm">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 配额配置弹窗 -->
    <el-dialog :visible.sync="quotaDialogVisible" title="配额配置" width="700px">
      <el-form :model="quotaForm" label-width="120px">
        <el-alert
          title="配额说明"
          type="info"
          description="为租户设置资源使用的总配额限制，超过配额后将无法继续使用相关资源。"
          :closable="false"
          style="margin-bottom: 20px;"
        />
        <el-form-item label="CPU配额">
          <el-input-number v-model="quotaForm.cpuQuota" :min="0" :max="1000" />
          <span style="margin-left: 10px;">核</span>
        </el-form-item>
        <el-form-item label="内存配额">
          <el-input-number v-model="quotaForm.memoryQuota" :min="0" :max="10000" />
          <span style="margin-left: 10px;">GB</span>
        </el-form-item>
        <el-form-item label="存储配额">
          <el-input-number v-model="quotaForm.storageQuota" :min="0" :max="100000" />
          <span style="margin-left: 10px;">GB</span>
        </el-form-item>
        <el-form-item label="数据集数量限制">
          <el-input-number v-model="quotaForm.datasetLimit" :min="0" :max="1000" />
          <span style="margin-left: 10px;">个</span>
        </el-form-item>
        <el-form-item label="模型数量限制">
          <el-input-number v-model="quotaForm.modelLimit" :min="0" :max="1000" />
          <span style="margin-left: 10px;">个</span>
        </el-form-item>
        <el-form-item label="并发任务数">
          <el-input-number v-model="quotaForm.concurrentTasks" :min="1" :max="100" />
          <span style="margin-left: 10px;">个</span>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="quotaDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="saveQuotaConfig">保 存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getTenantDetail, getTenantResourceList, addTenantResource, deleteTenantResource, getAvailableResources } from '@/api/tenant'
import Pagination from '@/components/Pagination'

export default {
  name: 'TenantResource',
  components: { Pagination },
  data() {
    return {
      tenantId: null,
      tenantInfo: {},
      resourceStats: {},
      resourceList: [],
      availableResources: [],
      searchForm: {
        resourceName: '',
        resourceType: '',
        status: ''
      },
      loading: false,
      availableResourcesLoading: false,
      submitLoading: false,
      resourceDialogVisible: false,
      resourceDialogTitle: '添加资源',
      resourceForm: {
        resourceId: '',
        resourceType: '',
        permissionLevel: 'READ',
        quotaAmount: 0,
        quotaUnit: 'GB',
        effectiveTime: '',
        expiryTime: '',
        remark: ''
      },
      resourceRules: {
        resourceId: [{ required: true, message: '请选择资源', trigger: 'change' }],
        permissionLevel: [{ required: true, message: '请选择权限级别', trigger: 'change' }],
        effectiveTime: [{ required: true, message: '请选择生效时间', trigger: 'change' }]
      },
      quotaDialogVisible: false,
      quotaForm: {
        cpuQuota: 0,
        memoryQuota: 0,
        storageQuota: 0,
        datasetLimit: 0,
        modelLimit: 0,
        concurrentTasks: 10
      },
      itemTotalCount: 0,
      pageSize: 10,
      pageCount: 0,
      pageNum: 1
    }
  },
  created() {
    this.tenantId = this.$route.params.id
    if (this.tenantId) {
      this.fetchTenantInfo()
      this.fetchResourceList()
    }
  },
  methods: {
    async fetchTenantInfo() {
      const res = await getTenantDetail({ id: this.tenantId })
      if (res.code === 0) {
        this.tenantInfo = res.result || {}
        this.resourceStats = res.result?.resourceStats || {}
      }
    },
    async fetchResourceList() {
      this.loading = true
      const params = {
        tenantId: this.tenantId,
        pageSize: this.pageSize,
        pageNum: this.pageNum,
        resourceName: this.searchForm.resourceName,
        resourceType: this.searchForm.resourceType,
        status: this.searchForm.status
      }
      getTenantResourceList(params).then((res) => {
        if (res.code === 0) {
          const { list, pageParam } = res.result
          this.resourceList = list || []
          this.pageCount = Number(pageParam?.pageCount || 0)
          this.pageNum = Number(pageParam?.pageNum || 1)
          this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
        }
      }).finally(() => {
        this.loading = false
      })
    },
    async fetchAvailableResources() {
      this.availableResourcesLoading = true
      const res = await getAvailableResources({ tenantId: this.tenantId })
      if (res.code === 0) {
        this.availableResources = res.result || []
      }
      this.availableResourcesLoading = false
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchResourceList()
    },
    handleReset() {
      this.searchForm = { resourceName: '', resourceType: '', status: '' }
      this.pageNum = 1
      this.fetchResourceList()
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchResourceList()
    },
    openAddResource() {
      this.resourceDialogTitle = '添加资源'
      this.resourceForm = {
        resourceId: '',
        resourceType: '',
        permissionLevel: 'READ',
        quotaAmount: 0,
        quotaUnit: 'GB',
        effectiveTime: this.$moment().format('YYYY-MM-DD HH:mm:ss'),
        expiryTime: '',
        remark: ''
      }
      this.resourceDialogVisible = true
      this.fetchAvailableResources()
    },
    openEditResource(row) {
      this.resourceDialogTitle = '编辑资源'
      this.resourceForm = { ...row }
      this.resourceDialogVisible = true
    },
    handleResourceSelect(resourceId) {
      const resource = this.availableResources.find(r => r.id === resourceId)
      if (resource) {
        this.resourceForm.resourceType = resource.type
      }
    },
    closeResourceDialog() {
      this.resourceDialogVisible = false
      this.$refs.resourceForm.resetFields()
    },
    submitResourceForm() {
      this.$refs.resourceForm.validate(async(valid) => {
        if (valid) {
          this.submitLoading = true
          const params = {
            tenantId: this.tenantId,
            ...this.resourceForm
          }
          const res = await addTenantResource(params)
          this.submitLoading = false
          if (res.code === 0) {
            this.$message({ type: 'success', message: '操作成功' })
            this.closeResourceDialog()
            this.fetchResourceList()
            this.fetchTenantInfo()
          }
        }
      })
    },
    async handleStatusChange(row) {
      // TODO: 调用后端接口更新状态
      this.$message({ type: 'success', message: '状态已更新' })
    },
    async handleDeleteResource(row) {
      this.$confirm('确定要删除该资源分配吗？删除后租户将无法访问该资源。', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        const res = await deleteTenantResource({ id: row.id })
        if (res.code === 0) {
          this.$message({ type: 'success', message: '删除成功' })
          this.fetchResourceList()
          this.fetchTenantInfo()
        }
      })
    },
    openQuotaConfig() {
      this.quotaForm = { ...this.resourceStats }
      this.quotaDialogVisible = true
    },
    saveQuotaConfig() {
      // TODO: 调用后端接口保存配额配置
      this.$message({ type: 'success', message: '配额配置已保存' })
      this.quotaDialogVisible = false
      this.fetchTenantInfo()
    },
    calculateUsagePercent(row) {
      if (!row.quotaAmount || row.quotaAmount === 0) return 0
      const percent = (row.usedAmount / row.quotaAmount) * 100
      return Math.min(percent, 100)
    },
    getProgressColor(percent) {
      if (percent < 60) return '#67c23a'
      if (percent < 80) return '#e6a23c'
      return '#f56c6c'
    },
    goBack() {
      this.$router.push({ name: 'TenantList' })
    }
  }
}
</script>

<style lang="scss" scoped>
.container {
  padding: 20px;
  background-color: #f0f2f5;
}

.tenant-info-card {
  margin-bottom: 20px;
  .tenant-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    .tenant-title {
      display: flex;
      align-items: center;
      font-size: 18px;
      i {
        font-size: 24px;
        margin-right: 10px;
        color: #409eff;
      }
      .tenant-name {
        font-weight: bold;
        margin-right: 10px;
      }
    }
  }
  .tenant-details {
    .detail-item {
      padding: 8px 0;
      .detail-label {
        color: #909399;
        font-size: 14px;
      }
      .detail-value {
        color: #303133;
        font-size: 14px;
        font-weight: 500;
      }
    }
  }
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
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 15px;
      i {
        font-size: 32px;
        color: #fff;
      }
      &.cpu {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      }
      &.memory {
        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      }
      &.storage {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
      }
      &.dataset {
        background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
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
        font-size: 24px;
        font-weight: bold;
        color: #303133;
      }
    }
  }
}

.resource-card {
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

.filter-bar {
  padding: 15px 0;
  border-bottom: 1px solid #ebeef5;
  margin-bottom: 15px;
}

.resource-table {
  .resource-name {
    font-weight: 500;
    color: #303133;
  }
  .quota-value {
    font-weight: 500;
    color: #606266;
  }
}

.form-tip {
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
  margin-top: 5px;
}

::v-deep .el-table th {
  background: #fafafa;
}

::v-deep .el-progress__text {
  font-size: 12px !important;
}
</style>
