<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-office-building stats-icon primary" />
            <div class="stats-info">
              <div class="stats-label">总租户数</div>
              <div class="stats-value">{{ statistics.totalTenants || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-check stats-icon success" />
            <div class="stats-info">
              <div class="stats-label">活跃租户</div>
              <div class="stats-value">{{ statistics.activeTenants || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-remove-outline stats-icon warning" />
            <div class="stats-info">
              <div class="stats-label">冻结租户</div>
              <div class="stats-value">{{ statistics.frozenTenants || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card">
          <div class="stats-content">
            <i class="el-icon-s-data stats-icon info" />
            <div class="stats-info">
              <div class="stats-label">资源总数</div>
              <div class="stats-value">{{ statistics.totalResources || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选条件 -->
    <div class="filter-bar">
      <el-input
        v-model="searchForm.keyword"
        placeholder="请输入租户名称或编码"
        style="width: 250px; margin-right: 10px;"
        clearable
        @clear="handleSearch"
      />
      <el-select
        v-model="searchForm.status"
        placeholder="请选择状态"
        style="width: 150px; margin-right: 10px;"
        clearable
        @change="handleSearch"
      >
        <el-option label="正常" :value="1" />
        <el-option label="冻结" :value="0" />
      </el-select>
      <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
    </div>

    <el-button v-if="hasAddPermission" type="primary" icon="el-icon-plus" @click="addTenant">新增租户</el-button>

    <!-- 租户列表 -->
    <div class="main">
      <el-table :data="list" class="table-list">
        <el-table-column align="center" label="序号" width="80" type="index" />
        <el-table-column align="left" label="租户ID" prop="id" width="80" />
        <el-table-column align="left" label="租户编码" prop="tenantCode" width="150" />
        <el-table-column align="left" label="租户名称" prop="tenantName" min-width="200" />
        <el-table-column align="left" label="联系人" prop="contactPerson" width="120" />
        <el-table-column align="left" label="联系电话" prop="contactPhone" width="130" />
        <el-table-column align="center" label="状态" prop="status" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 1" type="success">正常</el-tag>
            <el-tag v-else type="danger">冻结</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="资源数量" prop="resourceCount" width="100" />
        <el-table-column align="center" label="创建时间" prop="createTime" width="180" />
        <el-table-column v-if="hasEditPermission || hasDeletePermission || hasFreezePermission" align="center" label="操作" fixed="right" width="280">
          <template slot-scope="scope">
            <el-button v-if="hasEditPermission" type="text" @click="openEdit(scope.row)"><i class="el-icon-edit" />编辑</el-button>
            <el-button type="text" @click="viewResource(scope.row)"><i class="el-icon-s-data" />资源分配</el-button>
            <el-button v-if="hasFreezePermission && scope.row.status === 1" type="text" @click="handleFreeze(scope.row)"><i class="el-icon-lock" />冻结</el-button>
            <el-button v-if="hasFreezePermission && scope.row.status === 0" type="text" @click="handleUnfreeze(scope.row)"><i class="el-icon-unlock" />解冻</el-button>
            <el-button v-if="hasDeletePermission" type="text" @click="handleDelete(scope.row)"><i class="el-icon-delete" />删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </div>

    <!-- 新增/编辑租户弹窗 -->
    <el-dialog :visible.sync="dialogVisible" custom-class="tenant-dialog" :title="dialogTitle" width="600px" :before-close="closeDialog">
      <el-form ref="tenantForm" :model="tenantInfo" label-width="120px" :rules="rules" label-position="right">
        <el-form-item label="租户编码" prop="tenantCode">
          <el-input v-model="tenantInfo.tenantCode" :disabled="dialogFlag === 'edit'" placeholder="请输入租户编码" />
        </el-form-item>
        <el-form-item label="租户名称" prop="tenantName">
          <el-input v-model="tenantInfo.tenantName" placeholder="请输入租户名称" />
        </el-form-item>
        <el-form-item label="联系人" prop="contactPerson">
          <el-input v-model="tenantInfo.contactPerson" placeholder="请输入联系人" />
        </el-form-item>
        <el-form-item label="联系电话" prop="contactPhone">
          <el-input v-model="tenantInfo.contactPhone" placeholder="请输入联系电话" />
        </el-form-item>
        <el-form-item label="联系邮箱" prop="contactEmail">
          <el-input v-model="tenantInfo.contactEmail" placeholder="请输入联系邮箱" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="tenantInfo.description" type="textarea" :rows="3" placeholder="请输入描述信息" />
        </el-form-item>
        <el-form-item label="数据隔离" prop="dataIsolation">
          <el-switch v-model="tenantInfo.dataIsolation" active-text="启用" inactive-text="禁用" />
        </el-form-item>
        <el-form-item label="计算流程隔离" prop="computeIsolation">
          <el-switch v-model="tenantInfo.computeIsolation" active-text="启用" inactive-text="禁用" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="closeDialog">取 消</el-button>
          <el-button type="primary" @click="enterDialog">确 定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { getTenantPage, addTenant, updateTenant, deleteTenant, freezeTenant, unfreezeTenant, getTenantStatistics } from '@/api/tenant'
import Pagination from '@/components/Pagination'
import { mapGetters } from 'vuex'

export default {
  name: 'TenantList',
  components: { Pagination },
  data() {
    return {
      list: [],
      statistics: {},
      searchForm: { keyword: '', status: '' },
      dialogFlag: '',
      dialogTitle: '',
      tenantInfo: {
        id: '',
        tenantCode: '',
        tenantName: '',
        contactPerson: '',
        contactPhone: '',
        contactEmail: '',
        description: '',
        dataIsolation: true,
        computeIsolation: true
      },
      dialogVisible: false,
      rules: {
        tenantCode: [{ required: true, message: '请输入租户编码', trigger: 'blur' }],
        tenantName: [{ required: true, message: '请输入租户名称', trigger: 'blur' }],
        contactPerson: [{ required: true, message: '请输入联系人', trigger: 'blur' }],
        contactPhone: [{ required: true, message: '请输入联系电话', trigger: 'blur' }]
      },
      itemTotalCount: 0,
      pageSize: 10,
      pageCount: 0,
      pageNum: 1
    }
  },
  computed: {
    hasAddPermission() { return this.buttonPermissionList.includes('TenantAdd') },
    hasEditPermission() { return this.buttonPermissionList.includes('TenantEdit') },
    hasDeletePermission() { return this.buttonPermissionList.includes('TenantDelete') },
    hasFreezePermission() { return this.buttonPermissionList.includes('TenantFreeze') },
    ...mapGetters(['buttonPermissionList'])
  },
  created() {
    this.fetchData()
    this.fetchStatistics()
  },
  methods: {
    fetchData() {
      const params = { pageSize: this.pageSize, pageNum: this.pageNum, keyword: this.searchForm.keyword, status: this.searchForm.status }
      getTenantPage(params).then((res) => {
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
      getTenantStatistics().then((res) => {
        if (res.code === 0) this.statistics = res.result || {}
      })
    },
    handleSearch() { this.pageNum = 1; this.fetchData() },
    handleReset() { this.searchForm = { keyword: '', status: '' }; this.pageNum = 1; this.fetchData() },
    handlePagination(data) { this.pageNum = data.page; this.fetchData() },
    openEdit(row) {
      this.dialogFlag = 'edit'
      this.dialogTitle = '编辑租户'
      this.tenantInfo = { ...row }
      this.dialogVisible = true
    },
    addTenant() {
      this.dialogTitle = '新增租户'
      this.dialogVisible = true
      this.dialogFlag = 'add'
      this.tenantInfo = { id: '', tenantCode: '', tenantName: '', contactPerson: '', contactPhone: '', contactEmail: '', description: '', dataIsolation: true, computeIsolation: true }
    },
    viewResource(row) {
      this.$router.push({ name: 'TenantResource', params: { id: row.id }})
    },
    async handleFreeze(row) {
      this.$confirm('是否冻结该租户?', '提示', { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }).then(async() => {
        const res = await freezeTenant({ id: row.id })
        if (res.code === 0) {
          this.$message({ type: 'success', message: '冻结成功' })
          this.fetchData()
          this.fetchStatistics()
        }
      })
    },
    async handleUnfreeze(row) {
      const res = await unfreezeTenant({ id: row.id })
      if (res.code === 0) {
        this.$message({ type: 'success', message: '解冻成功' })
        this.fetchData()
        this.fetchStatistics()
      }
    },
    async handleDelete(row) {
      this.$confirm('此操作将永久删除该租户, 是否继续?', '提示', { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }).then(async() => {
        const res = await deleteTenant({ id: row.id })
        if (res.code === 0) {
          this.$message({ type: 'success', message: '删除成功' })
          this.fetchData()
          this.fetchStatistics()
        }
      })
    },
    closeDialog() { this.dialogVisible = false; this.$refs['tenantForm'].resetFields() },
    enterDialog() {
      this.$refs['tenantForm'].validate(async valid => {
        if (valid) {
          const apiMethod = this.dialogFlag === 'add' ? addTenant : updateTenant
          const res = await apiMethod(this.tenantInfo)
          if (res.code === 0) {
            this.$message({ type: 'success', message: this.dialogFlag === 'add' ? '添加成功' : '更新成功' })
            this.closeDialog()
            this.fetchData()
            this.fetchStatistics()
          }
        }
      })
    }
  }
}
</script>

<style lang="scss" scoped>
.container { padding: 20px; background-color: #f0f2f5; }
.stats-row { margin-bottom: 20px; }
.stats-card .stats-content { display: flex; align-items: center; }
.stats-icon { font-size: 48px; margin-right: 20px; &.primary { color: #409eff; } &.success { color: #67c23a; } &.warning { color: #e6a23c; } &.info { color: #909399; } }
.stats-info { flex: 1; .stats-label { font-size: 14px; color: #909399; margin-bottom: 8px; } .stats-value { font-size: 28px; font-weight: bold; color: #303133; } }
.filter-bar { background-color: #fff; padding: 20px; margin-bottom: 15px; border-radius: 4px; }
.main { background-color: #fff; padding: 20px; border-radius: 4px; }
.table-list { margin-top: 15px; }
::v-deep .el-table th { background: #fafafa; }
</style>
