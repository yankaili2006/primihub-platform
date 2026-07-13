<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="关键字">
        <el-input v-model="queryForm.keyword" placeholder="节点ID或节点名称" clearable />
      </el-form-item>
      <el-form-item label="合作状态">
        <el-select v-model="queryForm.cooperationStatus" placeholder="请选择" clearable>
          <el-option label="待确认" :value="0" />
          <el-option label="进行中" :value="1" />
          <el-option label="已暂停" :value="2" />
          <el-option label="已终止" :value="3" />
          <el-option label="已完成" :value="4" />
        </el-select>
      </el-form-item>
      <el-form-item label="合作类型">
        <el-select v-model="queryForm.cooperationType" placeholder="请选择" clearable>
          <el-option label="数据共享" value="DATA_SHARE" />
          <el-option label="联合计算" value="JOINT_COMPUTE" />
          <el-option label="模型训练" value="MODEL_TRAINING" />
          <el-option label="其他" value="OTHER" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="handleEstablish">建立合作</el-button>
      <el-button type="danger" icon="el-icon-delete" :disabled="selectedRows.length === 0" @click="handleBatchDelete">批量删除</el-button>
      <el-button type="warning" icon="el-icon-warning" @click="handleShowExpiring">即将过期</el-button>
      <el-button type="info" icon="el-icon-info" @click="handleShowUnhealthy">健康度低</el-button>
    </el-row>

    <!-- Table -->
    <el-table
      v-loading="loading"
      :data="tableData"
      border
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="55" />
      <el-table-column type="expand">
        <template slot-scope="props">
          <el-form label-position="left" inline class="table-expand">
            <el-form-item label="合作协议:">
              <span>{{ props.row.cooperationAgreement || '无' }}</span>
            </el-form-item>
            <el-form-item label="合作范围:">
              <span>{{ props.row.cooperationScope || '无' }}</span>
            </el-form-item>
            <el-form-item label="数据交换频率:">
              <span>{{ props.row.dataExchangeFrequency || '无' }}</span>
            </el-form-item>
            <el-form-item label="服务等级:">
              <span>{{ props.row.sla || '无' }}</span>
            </el-form-item>
            <el-form-item label="备注:">
              <span>{{ props.row.remarks || '无' }}</span>
            </el-form-item>
          </el-form>
        </template>
      </el-table-column>
      <el-table-column prop="partnerOrganId" label="合作方ID" width="150" />
      <el-table-column prop="partnerOrganName" label="合作方名称" width="150" />
      <el-table-column prop="cooperationType" label="合作类型" width="120">
        <template slot-scope="scope">
          {{ getCooperationTypeLabel(scope.row.cooperationType) }}
        </template>
      </el-table-column>
      <el-table-column prop="cooperationStatus" label="合作状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.cooperationStatus === 0" type="info">待确认</el-tag>
          <el-tag v-else-if="scope.row.cooperationStatus === 1" type="success">进行中</el-tag>
          <el-tag v-else-if="scope.row.cooperationStatus === 2" type="warning">已暂停</el-tag>
          <el-tag v-else-if="scope.row.cooperationStatus === 3" type="danger">已终止</el-tag>
          <el-tag v-else-if="scope.row.cooperationStatus === 4" type="info">已完成</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="startDate" label="开始时间" width="160" />
      <el-table-column prop="endDate" label="结束时间" width="160">
        <template slot-scope="scope">
          <span :style="{color: isExpiringSoon(scope.row.endDate) ? 'red' : ''}">
            {{ scope.row.endDate }}
          </span>
        </template>
      </el-table-column>
      <el-table-column prop="healthScore" label="健康评分" width="100">
        <template slot-scope="scope">
          <el-progress
            :percentage="scope.row.healthScore || 0"
            :color="getHealthScoreColor(scope.row.healthScore)"
            :status="scope.row.healthScore < 60 ? 'exception' : ''"
          />
        </template>
      </el-table-column>
      <el-table-column label="操作" fixed="right" width="300">
        <template slot-scope="scope">
          <el-button v-if="scope.row.cooperationStatus === 1" size="mini" type="info" @click="handlePause(scope.row)">暂停</el-button>
          <el-button v-if="scope.row.cooperationStatus === 2" size="mini" type="success" @click="handleResume(scope.row)">恢复</el-button>
          <el-button v-if="scope.row.cooperationStatus === 1" size="mini" type="warning" @click="handleRenew(scope.row)">续约</el-button>
          <el-button size="mini" type="primary" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button v-if="scope.row.cooperationStatus !== 3" size="mini" type="danger" @click="handleTerminate(scope.row)">终止</el-button>
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

    <!-- Establish/Edit Dialog -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogVisible"
      width="60%"
      @close="handleDialogClose"
    >
      <el-form ref="dataForm" :model="formData" :rules="formRules" label-width="140px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="合作方节点" prop="partnerOrganId">
              <el-select
                v-model="formData.partnerOrganId"
                placeholder="搜索节点"
                filterable
                remote
                :remote-method="searchNodes"
                :loading="nodeSearchLoading"
                :disabled="isEdit"
                style="width: 100%;"
                @change="handleNodeChange"
              >
                <el-option
                  v-for="node in nodeOptions"
                  :key="node.organId"
                  :label="`${node.organName} (${node.organId})`"
                  :value="node.organId"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="合作类型" prop="cooperationType">
              <el-select v-model="formData.cooperationType" placeholder="请选择" style="width: 100%;">
                <el-option label="数据共享" value="DATA_SHARE" />
                <el-option label="联合计算" value="JOINT_COMPUTE" />
                <el-option label="模型训练" value="MODEL_TRAINING" />
                <el-option label="其他" value="OTHER" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="开始时间" prop="startDate">
              <el-date-picker
                v-model="formData.startDate"
                type="datetime"
                placeholder="选择开始时间"
                style="width: 100%;"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束时间" prop="endDate">
              <el-date-picker
                v-model="formData.endDate"
                type="datetime"
                placeholder="选择结束时间"
                style="width: 100%;"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="合作协议" prop="cooperationAgreement">
          <el-input v-model="formData.cooperationAgreement" placeholder="请输入合作协议内容" />
        </el-form-item>

        <el-form-item label="合作范围">
          <el-input
            v-model="formData.cooperationScope"
            type="textarea"
            :rows="2"
            placeholder="请描述合作范围"
          />
        </el-form-item>

        <el-form-item label="数据交换频率">
          <el-input v-model="formData.dataExchangeFrequency" placeholder="如：每日、每周、实时等" />
        </el-form-item>

        <el-form-item label="服务等级(SLA)">
          <el-input v-model="formData.sla" placeholder="服务等级协议" />
        </el-form-item>

        <el-form-item label="联系人信息">
          <el-input v-model="formData.contactInfo" placeholder="联系人及联系方式" />
        </el-form-item>

        <el-form-item label="备注">
          <el-input
            v-model="formData.remarks"
            type="textarea"
            :rows="3"
            placeholder="其他备注信息"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- Terminate Dialog -->
    <el-dialog
      title="终止合作"
      :visible.sync="terminateDialogVisible"
      width="40%"
    >
      <el-form :model="terminateForm" label-width="100px">
        <el-form-item label="终止原因">
          <el-input
            v-model="terminateForm.reason"
            type="textarea"
            :rows="4"
            placeholder="请输入终止合作的原因"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="terminateDialogVisible = false">取 消</el-button>
        <el-button type="danger" @click="handleTerminateSubmit">确认终止</el-button>
      </span>
    </el-dialog>

    <!-- Renew Dialog -->
    <el-dialog
      title="续约合作"
      :visible.sync="renewDialogVisible"
      width="40%"
    >
      <el-form :model="renewForm" label-width="120px">
        <el-form-item label="新的结束时间">
          <el-date-picker
            v-model="renewForm.newEndDate"
            type="datetime"
            placeholder="选择新的结束时间"
            style="width: 100%;"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="renewDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleRenewSubmit">确认续约</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findCooperationPartyPage,
  getCooperationPartyById,
  establishCooperation,
  updateCooperationParty,
  cancelCooperation,
  terminateCooperation,
  renewCooperation,
  updateCooperationStatus,
  batchDeleteCooperationParty,
  getExpiringCooperationParties,
  getUnhealthyCooperationParties,
  searchCooperationNodes
} from '@/api/nodeEnhanced'

export default {
  name: 'CooperationManagement',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        keyword: '',
        cooperationStatus: null,
        cooperationType: null,
        pageNum: 1,
        pageSize: 10
      },
      dialogVisible: false,
      dialogTitle: '',
      isEdit: false,
      formData: {},
      formRules: {
        partnerOrganId: [{ required: true, message: '请选择合作方节点', trigger: 'change' }],
        cooperationType: [{ required: true, message: '请选择合作类型', trigger: 'change' }],
        startDate: [{ required: true, message: '请选择开始时间', trigger: 'change' }],
        endDate: [{ required: true, message: '请选择结束时间', trigger: 'change' }],
        cooperationAgreement: [{ required: true, message: '请输入合作协议', trigger: 'blur' }]
      },
      nodeOptions: [],
      nodeSearchLoading: false,
      terminateDialogVisible: false,
      terminateForm: {
        reason: '',
        row: null
      },
      renewDialogVisible: false,
      renewForm: {
        newEndDate: null,
        row: null
      }
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.loading = true
      findCooperationPartyPage(this.queryForm).then(res => {
        this.loading = false
        if (res.code === 0) {
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
        cooperationStatus: null,
        cooperationType: null,
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
    handleEstablish() {
      this.dialogTitle = '建立合作关系'
      this.isEdit = false
      this.formData = {
        cooperationType: 'DATA_SHARE'
      }
      this.nodeOptions = []
      this.dialogVisible = true
    },
    handleEdit(row) {
      this.dialogTitle = '编辑合作关系'
      this.isEdit = true
      this.formData = { ...row }
      if (row.startDate) {
        this.formData.startDate = new Date(row.startDate)
      }
      if (row.endDate) {
        this.formData.endDate = new Date(row.endDate)
      }
      this.dialogVisible = true
    },
    handleTerminate(row) {
      this.terminateForm = {
        reason: '',
        row: row
      }
      this.terminateDialogVisible = true
    },
    handleTerminateSubmit() {
      if (!this.terminateForm.reason) {
        this.$message.warning('请输入终止原因')
        return
      }
      terminateCooperation(this.terminateForm.row.id, this.terminateForm.reason).then(res => {
        if (res.code === 0) {
          this.$message.success('终止成功')
          this.terminateDialogVisible = false
          this.fetchData()
        } else {
          this.$message.error(res.msg || '终止失败')
        }
      }).catch(err => {
        this.$message.error('终止失败')
        console.error(err)
      })
    },
    handlePause(row) {
      this.$confirm('确认暂停该合作关系吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        updateCooperationStatus(row.id, 2).then(res => {
          if (res.code === 0) {
            this.$message.success('暂停成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '暂停失败')
          }
        }).catch(err => {
          this.$message.error('暂停失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleResume(row) {
      this.$confirm('确认恢复该合作关系吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'success'
      }).then(() => {
        updateCooperationStatus(row.id, 1).then(res => {
          if (res.code === 0) {
            this.$message.success('恢复成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '恢复失败')
          }
        }).catch(err => {
          this.$message.error('恢复失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleRenew(row) {
      this.renewForm = {
        newEndDate: null,
        row: row
      }
      this.renewDialogVisible = true
    },
    handleRenewSubmit() {
      if (!this.renewForm.newEndDate) {
        this.$message.warning('请选择新的结束时间')
        return
      }
      const newEndDateTimestamp = new Date(this.renewForm.newEndDate).getTime()
      renewCooperation(this.renewForm.row.id, newEndDateTimestamp).then(res => {
        if (res.code === 0) {
          this.$message.success('续约成功')
          this.renewDialogVisible = false
          this.fetchData()
        } else {
          this.$message.error(res.msg || '续约失败')
        }
      }).catch(err => {
        this.$message.error('续约失败')
        console.error(err)
      })
    },
    handleBatchDelete() {
      this.$confirm(`确认删除选中的${this.selectedRows.length}条记录吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ids = this.selectedRows.map(row => row.id)
        batchDeleteCooperationParty(ids).then(res => {
          if (res.code === 0) {
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
    handleShowExpiring() {
      this.$prompt('请输入天数', '查询即将过期的合作', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPattern: /^\d+$/,
        inputErrorMessage: '请输入有效的天数',
        inputValue: '30'
      }).then(({ value }) => {
        getExpiringCooperationParties(parseInt(value)).then(res => {
          if (res.code === 0) {
            this.tableData = res.result || []
            this.total = this.tableData.length
            this.$message.success(`找到${this.tableData.length}条即将过期的合作`)
          } else {
            this.$message.error(res.msg || '查询失败')
          }
        }).catch(err => {
          this.$message.error('查询失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleShowUnhealthy() {
      this.$prompt('请输入健康评分阈值(0-100)', '查询健康度低的合作', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPattern: /^\d+$/,
        inputErrorMessage: '请输入有效的分数(0-100)',
        inputValue: '60'
      }).then(({ value }) => {
        const threshold = parseInt(value)
        if (threshold < 0 || threshold > 100) {
          this.$message.error('请输入0-100之间的分数')
          return
        }
        getUnhealthyCooperationParties(threshold).then(res => {
          if (res.code === 0) {
            this.tableData = res.result || []
            this.total = this.tableData.length
            this.$message.success(`找到${this.tableData.length}条健康度低的合作`)
          } else {
            this.$message.error(res.msg || '查询失败')
          }
        }).catch(err => {
          this.$message.error('查询失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    searchNodes(keyword) {
      if (keyword) {
        this.nodeSearchLoading = true
        searchCooperationNodes(keyword).then(res => {
          this.nodeSearchLoading = false
          if (res.code === 0) {
            this.nodeOptions = res.result || []
          } else {
            this.$message.error(res.msg || '搜索失败')
          }
        }).catch(err => {
          this.nodeSearchLoading = false
          this.$message.error('搜索失败')
          console.error(err)
        })
      } else {
        this.nodeOptions = []
      }
    },
    handleNodeChange(organId) {
      const node = this.nodeOptions.find(n => n.organId === organId)
      if (node) {
        this.formData.partnerOrganName = node.organName
        this.formData.partnerOrganGateway = node.organGateway
      }
    },
    handleSubmit() {
      this.$refs.dataForm.validate((valid) => {
        if (valid) {
          const apiFunc = this.isEdit ? updateCooperationParty : establishCooperation
          apiFunc(this.formData).then(res => {
            if (res.code === 0) {
              this.$message.success(this.isEdit ? '更新成功' : '建立合作成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || (this.isEdit ? '更新失败' : '建立合作失败'))
            }
          }).catch(err => {
            this.$message.error(this.isEdit ? '更新失败' : '建立合作失败')
            console.error(err)
          })
        }
      })
    },
    handleDialogClose() {
      this.$refs.dataForm.resetFields()
      this.formData = {}
      this.nodeOptions = []
    },
    getCooperationTypeLabel(type) {
      const typeMap = {
        'DATA_SHARE': '数据共享',
        'JOINT_COMPUTE': '联合计算',
        'MODEL_TRAINING': '模型训练',
        'OTHER': '其他'
      }
      return typeMap[type] || type
    },
    isExpiringSoon(endDate) {
      if (!endDate) return false
      const end = new Date(endDate).getTime()
      const now = new Date().getTime()
      const days = (end - now) / (1000 * 60 * 60 * 24)
      return days > 0 && days <= 30
    },
    getHealthScoreColor(score) {
      if (score >= 80) return '#67C23A'
      if (score >= 60) return '#E6A23C'
      return '#F56C6C'
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
.table-expand {
  font-size: 0;
}
.table-expand >>> .el-form-item {
  margin-right: 0;
  margin-bottom: 0;
  width: 50%;
}
.table-expand >>> .el-form-item__label {
  width: 120px;
  color: #99a9bf;
}
.table-expand >>> .el-form-item__content {
  width: calc(100% - 120px);
}
</style>
