<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="关键字">
        <el-input v-model="queryForm.keyword" placeholder="节点ID或节点名称" clearable />
      </el-form-item>
      <el-form-item label="申请状态">
        <el-select v-model="queryForm.applyStatus" placeholder="请选择" clearable>
          <el-option label="待审批" :value="0" />
          <el-option label="已批准" :value="1" />
          <el-option label="已拒绝" :value="2" />
        </el-select>
      </el-form-item>
      <el-form-item label="接入级别">
        <el-select v-model="queryForm.accessLevel" placeholder="请选择" clearable>
          <el-option label="只读" :value="1" />
          <el-option label="读写" :value="2" />
          <el-option label="管理员" :value="3" />
        </el-select>
      </el-form-item>
      <el-form-item label="激活状态">
        <el-select v-model="queryForm.isActive" placeholder="请选择" clearable>
          <el-option label="激活" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增接入方</el-button>
      <el-button type="success" icon="el-icon-check" :disabled="selectedRows.length === 0" @click="handleBatchApprove">批量批准</el-button>
      <el-button type="danger" icon="el-icon-delete" :disabled="selectedRows.length === 0" @click="handleBatchDelete">批量删除</el-button>
    </el-row>

    <!-- Table -->
    <el-table
      v-loading="loading"
      :data="tableData"
      border
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="55" />
      <el-table-column prop="organId" label="节点ID" width="180" />
      <el-table-column prop="organName" label="节点名称" width="150" />
      <el-table-column prop="organGateway" label="网关地址" min-width="200" show-overflow-tooltip />
      <el-table-column prop="accessLevel" label="接入级别" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.accessLevel === 1" type="info">只读</el-tag>
          <el-tag v-else-if="scope.row.accessLevel === 2" type="warning">读写</el-tag>
          <el-tag v-else-if="scope.row.accessLevel === 3" type="danger">管理员</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="applyStatus" label="申请状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.applyStatus === 0" type="warning">待审批</el-tag>
          <el-tag v-else-if="scope.row.applyStatus === 1" type="success">已批准</el-tag>
          <el-tag v-else-if="scope.row.applyStatus === 2" type="danger">已拒绝</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="isActive" label="激活状态" width="100">
        <template slot-scope="scope">
          <el-switch
            v-model="scope.row.isActive"
            :active-value="1"
            :inactive-value="0"
            :disabled="scope.row.applyStatus !== 1"
            @change="handleActiveStatusChange(scope.row)"
          />
        </template>
      </el-table-column>
      <el-table-column prop="createDate" label="申请时间" width="160" />
      <el-table-column label="操作" fixed="right" width="280">
        <template slot-scope="scope">
          <el-button v-if="scope.row.applyStatus === 0" size="mini" type="success" @click="handleApprove(scope.row)">批准</el-button>
          <el-button v-if="scope.row.applyStatus === 0" size="mini" type="warning" @click="handleReject(scope.row)">拒绝</el-button>
          <el-button size="mini" type="primary" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button size="mini" type="danger" @click="handleDelete(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- Pagination -->
    <el-pagination
      style="margin-top: 20px;"
      :current-page="queryForm.pageNum"
      :page-sizes="[10, 20, 50, 100]"
      :page-size="queryForm.pageSize"
      :total="total"
      layout="total, sizes, prev, pager, next, jumper"
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
    />

    <!-- Add/Edit Dialog -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogVisible"
      width="50%"
      @close="handleDialogClose"
    >
      <el-form ref="dataForm" :model="formData" :rules="formRules" label-width="120px">
        <el-form-item label="节点ID" prop="organId">
          <el-input v-model="formData.organId" placeholder="请输入节点ID" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="节点名称" prop="organName">
          <el-input v-model="formData.organName" placeholder="请输入节点名称" />
        </el-form-item>
        <el-form-item label="网关地址" prop="organGateway">
          <el-input v-model="formData.organGateway" placeholder="请输入网关地址" />
        </el-form-item>
        <el-form-item label="申请理由">
          <el-input v-model="formData.applyReason" type="textarea" :rows="3" placeholder="请输入申请理由" />
        </el-form-item>
        <el-form-item label="接入级别" prop="accessLevel">
          <el-select v-model="formData.accessLevel" placeholder="请选择接入级别">
            <el-option label="只读" :value="1" />
            <el-option label="读写" :value="2" />
            <el-option label="管理员" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="IP白名单">
          <el-input v-model="formData.ipWhitelist" type="textarea" :rows="2" placeholder="请输入IP白名单(JSON格式)" />
        </el-form-item>
        <el-form-item label="有效期">
          <el-date-picker
            v-model="formData.validDateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- Approve/Reject Dialog -->
    <el-dialog
      :title="approvalDialogTitle"
      :visible.sync="approvalDialogVisible"
      width="40%"
    >
      <el-form :model="approvalForm" label-width="100px">
        <el-form-item label="审批意见">
          <el-input v-model="approvalForm.comment" type="textarea" :rows="4" placeholder="请输入审批意见" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="approvalDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleApprovalSubmit">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findAccessPartyPage,
  addAccessParty,
  updateAccessParty,
  deleteAccessParty,
  batchDeleteAccessParty,
  approveAccessParty,
  rejectAccessParty,
  batchApproveAccessParty,
  updateActiveStatus
} from '@/api/nodeEnhanced'
import { mapGetters } from 'vuex'

export default {
  name: 'AccessManagement',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        keyword: '',
        applyStatus: null,
        accessLevel: null,
        isActive: null,
        pageNum: 1,
        pageSize: 10
      },
      dialogVisible: false,
      dialogTitle: '',
      isEdit: false,
      formData: {},
      formRules: {
        organId: [{ required: true, message: '请输入节点ID', trigger: 'blur' }],
        organName: [{ required: true, message: '请输入节点名称', trigger: 'blur' }],
        organGateway: [{ required: true, message: '请输入网关地址', trigger: 'blur' }],
        accessLevel: [{ required: true, message: '请选择接入级别', trigger: 'change' }]
      },
      approvalDialogVisible: false,
      approvalDialogTitle: '',
      approvalForm: {
        comment: '',
        action: '', // 'approve' or 'reject'
        row: null
      }
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName'])
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.loading = true
      findAccessPartyPage(this.queryForm).then(res => {
        this.loading = false
        if (res.returnCode === '0') {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          this.$message.error(res.msg || '查询失败')
        }
      }).catch(err => {
        this.loading = false
        this.$message.error('查询失败')
        console.error(err)
      })
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = {
        keyword: '',
        applyStatus: null,
        accessLevel: null,
        isActive: null,
        pageNum: 1,
        pageSize: 10
      }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNum = val
      this.fetchData()
    },
    handleSelectionChange(val) {
      this.selectedRows = val
    },
    handleAdd() {
      this.dialogTitle = '新增接入方'
      this.isEdit = false
      this.formData = {
        accessLevel: 1,
        validDateRange: []
      }
      this.dialogVisible = true
    },
    handleEdit(row) {
      this.dialogTitle = '编辑接入方'
      this.isEdit = true
      this.formData = { ...row }
      if (row.validFrom && row.validUntil) {
        this.formData.validDateRange = [new Date(row.validFrom), new Date(row.validUntil)]
      }
      this.dialogVisible = true
    },
    handleDelete(row) {
      this.$confirm('确认删除该接入方吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteAccessParty(row.id).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        }).catch(err => {
          this.$message.error('删除失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleBatchDelete() {
      this.$confirm(`确认删除选中的${this.selectedRows.length}条记录吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ids = this.selectedRows.map(row => row.id)
        batchDeleteAccessParty(ids).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('批量删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量删除失败')
          }
        }).catch(err => {
          this.$message.error('批量删除失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleApprove(row) {
      this.approvalDialogTitle = '批准接入申请'
      this.approvalForm = {
        comment: '',
        action: 'approve',
        row: row
      }
      this.approvalDialogVisible = true
    },
    handleReject(row) {
      this.approvalDialogTitle = '拒绝接入申请'
      this.approvalForm = {
        comment: '',
        action: 'reject',
        row: row
      }
      this.approvalDialogVisible = true
    },
    handleBatchApprove() {
      const pendingRows = this.selectedRows.filter(row => row.applyStatus === 0)
      if (pendingRows.length === 0) {
        this.$message.warning('请选择待审批的记录')
        return
      }
      this.$confirm(`确认批准选中的${pendingRows.length}条申请吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'success'
      }).then(() => {
        const ids = pendingRows.map(row => row.id)
        batchApproveAccessParty(ids, this.userId, this.userName, '批量批准').then(res => {
          if (res.returnCode === '0') {
            this.$message.success('批量批准成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量批准失败')
          }
        }).catch(err => {
          this.$message.error('批量批准失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleApprovalSubmit() {
      const { action, row, comment } = this.approvalForm
      const apiFunc = action === 'approve' ? approveAccessParty : rejectAccessParty
      apiFunc(row.id, this.userId, this.userName, comment).then(res => {
        if (res.returnCode === '0') {
          this.$message.success(action === 'approve' ? '批准成功' : '拒绝成功')
          this.approvalDialogVisible = false
          this.fetchData()
        } else {
          this.$message.error(res.msg || '操作失败')
        }
      }).catch(err => {
        this.$message.error('操作失败')
        console.error(err)
      })
    },
    handleActiveStatusChange(row) {
      updateActiveStatus(row.id, row.isActive).then(res => {
        if (res.returnCode === '0') {
          this.$message.success('状态更新成功')
        } else {
          this.$message.error(res.msg || '状态更新失败')
          row.isActive = row.isActive === 1 ? 0 : 1
        }
      }).catch(err => {
        this.$message.error('状态更新失败')
        row.isActive = row.isActive === 1 ? 0 : 1
        console.error(err)
      })
    },
    handleSubmit() {
      this.$refs.dataForm.validate((valid) => {
        if (valid) {
          // Process date range
          if (this.formData.validDateRange && this.formData.validDateRange.length === 2) {
            this.formData.validFrom = this.formData.validDateRange[0]
            this.formData.validUntil = this.formData.validDateRange[1]
          }

          const apiFunc = this.isEdit ? updateAccessParty : addAccessParty
          apiFunc(this.formData).then(res => {
            if (res.returnCode === '0') {
              this.$message.success(this.isEdit ? '更新成功' : '添加成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || (this.isEdit ? '更新失败' : '添加失败'))
            }
          }).catch(err => {
            this.$message.error(this.isEdit ? '更新失败' : '添加失败')
            console.error(err)
          })
        }
      })
    },
    handleDialogClose() {
      this.$refs.dataForm.resetFields()
      this.formData = {}
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>
