<template>
  <div class="app-container">
    <el-tabs v-model="activeTab" @tab-click="handleTabClick">
      <!-- 工作流列表 -->
      <el-tab-pane label="工作流列表" name="workflow">
        <!-- Search filters -->
        <el-form :inline="true" :model="workflowQueryForm" class="demo-form-inline">
          <el-form-item label="工作流类型">
            <el-select v-model="workflowQueryForm.workflowType" placeholder="请选择" clearable>
              <el-option label="接入申请" value="ACCESS_APPLICATION" />
              <el-option label="合作申请" value="COOPERATION_APPLICATION" />
              <el-option label="数据授权" value="DATA_AUTHORIZATION" />
              <el-option label="其他" value="OTHER" />
            </el-select>
          </el-form-item>
          <el-form-item label="工作流状态">
            <el-select v-model="workflowQueryForm.workflowStatus" placeholder="请选择" clearable>
              <el-option label="待审批" :value="0" />
              <el-option label="审批中" :value="1" />
              <el-option label="已通过" :value="2" />
              <el-option label="已拒绝" :value="3" />
              <el-option label="已取消" :value="4" />
            </el-select>
          </el-form-item>
          <el-form-item label="申请人">
            <el-input v-model="workflowQueryForm.requesterName" placeholder="申请人姓名" clearable />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleWorkflowQuery">查询</el-button>
            <el-button @click="handleWorkflowReset">重置</el-button>
          </el-form-item>
        </el-form>

        <!-- Action buttons -->
        <el-row style="margin-bottom: 20px;">
          <el-button type="primary" icon="el-icon-plus" @click="handleCreateWorkflow">创建工作流</el-button>
          <el-button type="info" icon="el-icon-s-order" @click="handleShowMyPending">我的待审批</el-button>
        </el-row>

        <!-- Workflow Table -->
        <el-table
          v-loading="workflowLoading"
          :data="workflowTableData"
          border
        >
          <el-table-column type="expand">
            <template slot-scope="props">
              <el-form label-position="left" inline class="table-expand">
                <el-form-item label="申请描述:">
                  <span>{{ props.row.requestDescription || '无' }}</span>
                </el-form-item>
                <el-form-item label="审批步骤:">
                  <el-steps :active="props.row.currentStep || 0" finish-status="success">
                    <el-step
                      v-for="(step, index) in props.row.steps"
                      :key="index"
                      :title="`步骤${step.stepOrder}`"
                      :description="step.approverName || '待指定'"
                    />
                  </el-steps>
                </el-form-item>
                <el-form-item label="审批历史:">
                  <el-timeline>
                    <el-timeline-item
                      v-for="(history, index) in props.row.approvalHistory"
                      :key="index"
                      :timestamp="history.approvalTime"
                    >
                      {{ history.approverName }} - {{ history.action }} - {{ history.comment }}
                    </el-timeline-item>
                  </el-timeline>
                </el-form-item>
              </el-form>
            </template>
          </el-table-column>
          <el-table-column prop="workflowNo" label="工作流编号" width="180" />
          <el-table-column prop="workflowType" label="工作流类型" width="140">
            <template slot-scope="scope">
              {{ getWorkflowTypeLabel(scope.row.workflowType) }}
            </template>
          </el-table-column>
          <el-table-column prop="workflowStatus" label="状态" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.workflowStatus === 0" type="warning">待审批</el-tag>
              <el-tag v-else-if="scope.row.workflowStatus === 1" type="primary">审批中</el-tag>
              <el-tag v-else-if="scope.row.workflowStatus === 2" type="success">已通过</el-tag>
              <el-tag v-else-if="scope.row.workflowStatus === 3" type="danger">已拒绝</el-tag>
              <el-tag v-else-if="scope.row.workflowStatus === 4" type="info">已取消</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="requesterName" label="申请人" width="120" />
          <el-table-column prop="currentApproverName" label="当前审批人" width="120" />
          <el-table-column prop="createDate" label="创建时间" width="160" />
          <el-table-column prop="priority" label="优先级" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.priority === 1" type="danger">紧急</el-tag>
              <el-tag v-else-if="scope.row.priority === 2" type="warning">重要</el-tag>
              <el-tag v-else type="info">普通</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" fixed="right" width="250">
            <template slot-scope="scope">
              <el-button
                v-if="scope.row.workflowStatus === 0 || scope.row.workflowStatus === 1"
                size="mini"
                type="success"
                @click="handleApproveWorkflow(scope.row)"
              >
                批准
              </el-button>
              <el-button
                v-if="scope.row.workflowStatus === 0 || scope.row.workflowStatus === 1"
                size="mini"
                type="danger"
                @click="handleRejectWorkflow(scope.row)"
              >
                拒绝
              </el-button>
              <el-button
                v-if="scope.row.workflowStatus === 0 || scope.row.workflowStatus === 1"
                size="mini"
                type="warning"
                @click="handleCancelWorkflow(scope.row)"
              >
                取消
              </el-button>
              <el-button size="mini" type="primary" @click="handleViewWorkflow(scope.row)">详情</el-button>
            </template>
          </el-table-column>
        </el-table>

        <!-- Pagination -->
        <el-pagination
          style="margin-top: 20px;"
          :current-page="workflowQueryForm.pageNum"
          :page-sizes="[10, 20, 50, 100]"
          :page-size="workflowQueryForm.pageSize"
          :total="workflowTotal"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleWorkflowSizeChange"
          @current-change="handleWorkflowCurrentChange"
        />
      </el-tab-pane>

      <!-- 审批配置 -->
      <el-tab-pane label="审批配置" name="config">
        <!-- Config Table -->
        <el-table
          v-loading="configLoading"
          :data="configTableData"
          border
        >
          <el-table-column prop="workflowType" label="工作流类型" width="200">
            <template slot-scope="scope">
              {{ getWorkflowTypeLabel(scope.row.workflowType) }}
            </template>
          </el-table-column>
          <el-table-column prop="approvalLevels" label="审批级数" width="100" />
          <el-table-column prop="isEnabled" label="启用状态" width="100">
            <template slot-scope="scope">
              <el-switch
                v-model="scope.row.isEnabled"
                :active-value="1"
                :inactive-value="0"
                @change="handleConfigEnabledChange(scope.row)"
              />
            </template>
          </el-table-column>
          <el-table-column prop="autoApprovalEnabled" label="自动审批" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.autoApprovalEnabled === 1" type="success">启用</el-tag>
              <el-tag v-else type="info">禁用</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
          <el-table-column label="操作" fixed="right" width="150">
            <template slot-scope="scope">
              <el-button size="mini" type="primary" @click="handleEditConfig(scope.row)">编辑</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- Create Workflow Dialog -->
    <el-dialog
      title="创建审批工作流"
      :visible.sync="createWorkflowDialogVisible"
      width="50%"
      @close="handleCreateWorkflowDialogClose"
    >
      <el-form ref="workflowForm" :model="workflowFormData" :rules="workflowFormRules" label-width="120px">
        <el-form-item label="工作流类型" prop="workflowType">
          <el-select v-model="workflowFormData.workflowType" placeholder="请选择" style="width: 100%;">
            <el-option label="接入申请" value="ACCESS_APPLICATION" />
            <el-option label="合作申请" value="COOPERATION_APPLICATION" />
            <el-option label="数据授权" value="DATA_AUTHORIZATION" />
            <el-option label="其他" value="OTHER" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级" prop="priority">
          <el-select v-model="workflowFormData.priority" placeholder="请选择" style="width: 100%;">
            <el-option label="紧急" :value="1" />
            <el-option label="重要" :value="2" />
            <el-option label="普通" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请描述" prop="requestDescription">
          <el-input
            v-model="workflowFormData.requestDescription"
            type="textarea"
            :rows="4"
            placeholder="请输入申请描述"
          />
        </el-form-item>
        <el-form-item label="关联业务ID">
          <el-input v-model="workflowFormData.businessId" placeholder="关联的业务ID(可选)" />
        </el-form-item>
        <el-form-item label="附件信息">
          <el-input
            v-model="workflowFormData.attachments"
            type="textarea"
            :rows="2"
            placeholder="附件链接或描述(可选)"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createWorkflowDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleCreateWorkflowSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- Approval Dialog -->
    <el-dialog
      :title="approvalDialogTitle"
      :visible.sync="approvalDialogVisible"
      width="40%"
    >
      <el-form :model="approvalForm" label-width="100px">
        <el-form-item label="审批意见">
          <el-input
            v-model="approvalForm.comment"
            type="textarea"
            :rows="4"
            placeholder="请输入审批意见"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="approvalDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleApprovalSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- Cancel Dialog -->
    <el-dialog
      title="取消工作流"
      :visible.sync="cancelDialogVisible"
      width="40%"
    >
      <el-form :model="cancelForm" label-width="100px">
        <el-form-item label="取消原因">
          <el-input
            v-model="cancelForm.reason"
            type="textarea"
            :rows="4"
            placeholder="请输入取消原因"
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="cancelDialogVisible = false">取 消</el-button>
        <el-button type="warning" @click="handleCancelSubmit">确认取消</el-button>
      </span>
    </el-dialog>

    <!-- Edit Config Dialog -->
    <el-dialog
      title="编辑审批配置"
      :visible.sync="editConfigDialogVisible"
      width="50%"
      @close="handleEditConfigDialogClose"
    >
      <el-form ref="configForm" :model="configFormData" label-width="140px">
        <el-form-item label="工作流类型">
          <span>{{ getWorkflowTypeLabel(configFormData.workflowType) }}</span>
        </el-form-item>
        <el-form-item label="审批级数">
          <el-input-number v-model="configFormData.approvalLevels" :min="1" :max="5" />
        </el-form-item>
        <el-form-item label="启用自动审批">
          <el-switch
            v-model="configFormData.autoApprovalEnabled"
            :active-value="1"
            :inactive-value="0"
          />
        </el-form-item>
        <el-form-item label="超时自动通过">
          <el-switch
            v-model="configFormData.timeoutAutoApprove"
            :active-value="1"
            :inactive-value="0"
          />
        </el-form-item>
        <el-form-item label="超时时间(小时)">
          <el-input-number v-model="configFormData.timeoutHours" :min="1" :max="168" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input
            v-model="configFormData.description"
            type="textarea"
            :rows="3"
            placeholder="请输入配置描述"
          />
        </el-form-item>
        <el-form-item label="审批规则(JSON)">
          <el-input
            v-model="configFormData.approvalRules"
            type="textarea"
            :rows="5"
            placeholder='{"rule1": "value1"}'
          />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="editConfigDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleEditConfigSubmit">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findWorkflowPage,
  getWorkflowById,
  createWorkflow,
  approveWorkflow,
  rejectWorkflow,
  cancelWorkflow,
  getMyPendingWorkflows,
  getAllConfigs,
  updateApprovalConfig,
  updateConfigEnabled
} from '@/api/nodeEnhanced'
import { mapGetters } from 'vuex'

export default {
  name: 'ApprovalWorkflow',
  data() {
    return {
      activeTab: 'workflow',
      workflowLoading: false,
      workflowTableData: [],
      workflowTotal: 0,
      workflowQueryForm: {
        workflowType: null,
        workflowStatus: null,
        requesterName: '',
        pageNum: 1,
        pageSize: 10
      },
      configLoading: false,
      configTableData: [],
      createWorkflowDialogVisible: false,
      workflowFormData: {},
      workflowFormRules: {
        workflowType: [{ required: true, message: '请选择工作流类型', trigger: 'change' }],
        priority: [{ required: true, message: '请选择优先级', trigger: 'change' }],
        requestDescription: [{ required: true, message: '请输入申请描述', trigger: 'blur' }]
      },
      approvalDialogVisible: false,
      approvalDialogTitle: '',
      approvalForm: {
        comment: '',
        action: '', // 'approve' or 'reject'
        row: null
      },
      cancelDialogVisible: false,
      cancelForm: {
        reason: '',
        row: null
      },
      editConfigDialogVisible: false,
      configFormData: {}
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName'])
  },
  mounted() {
    this.fetchWorkflowData()
  },
  methods: {
    handleTabClick(tab) {
      if (tab.name === 'config') {
        this.fetchConfigData()
      } else {
        this.fetchWorkflowData()
      }
    },
    fetchWorkflowData() {
      this.workflowLoading = true
      findWorkflowPage(this.workflowQueryForm).then(res => {
        this.workflowLoading = false
        if (res.returnCode === '0') {
          this.workflowTableData = res.result.list || []
          this.workflowTotal = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          this.$message.error(res.msg || '查询失败')
        }
      }).catch(err => {
        this.workflowLoading = false
        this.$message.error('查询失败')
        console.error(err)
      })
    },
    fetchConfigData() {
      this.configLoading = true
      getAllConfigs().then(res => {
        this.configLoading = false
        if (res.returnCode === '0') {
          this.configTableData = res.result || []
        } else {
          this.$message.error(res.msg || '查询失败')
        }
      }).catch(err => {
        this.configLoading = false
        this.$message.error('查询失败')
        console.error(err)
      })
    },
    handleWorkflowQuery() {
      this.workflowQueryForm.pageNum = 1
      this.fetchWorkflowData()
    },
    handleWorkflowReset() {
      this.workflowQueryForm = {
        workflowType: null,
        workflowStatus: null,
        requesterName: '',
        pageNum: 1,
        pageSize: 10
      }
      this.fetchWorkflowData()
    },
    handleWorkflowSizeChange(val) {
      this.workflowQueryForm.pageSize = val
      this.fetchWorkflowData()
    },
    handleWorkflowCurrentChange(val) {
      this.workflowQueryForm.pageNum = val
      this.fetchWorkflowData()
    },
    handleCreateWorkflow() {
      this.workflowFormData = {
        priority: 3
      }
      this.createWorkflowDialogVisible = true
    },
    handleCreateWorkflowSubmit() {
      this.$refs.workflowForm.validate((valid) => {
        if (valid) {
          this.workflowFormData.requesterId = this.userId
          this.workflowFormData.requesterName = this.userName
          createWorkflow(this.workflowFormData).then(res => {
            if (res.returnCode === '0') {
              this.$message.success('创建成功')
              this.createWorkflowDialogVisible = false
              this.fetchWorkflowData()
            } else {
              this.$message.error(res.msg || '创建失败')
            }
          }).catch(err => {
            this.$message.error('创建失败')
            console.error(err)
          })
        }
      })
    },
    handleCreateWorkflowDialogClose() {
      this.$refs.workflowForm.resetFields()
      this.workflowFormData = {}
    },
    handleApproveWorkflow(row) {
      this.approvalDialogTitle = '批准工作流'
      this.approvalForm = {
        comment: '',
        action: 'approve',
        row: row
      }
      this.approvalDialogVisible = true
    },
    handleRejectWorkflow(row) {
      this.approvalDialogTitle = '拒绝工作流'
      this.approvalForm = {
        comment: '',
        action: 'reject',
        row: row
      }
      this.approvalDialogVisible = true
    },
    handleApprovalSubmit() {
      const { action, row, comment } = this.approvalForm
      const apiFunc = action === 'approve' ? approveWorkflow : rejectWorkflow
      apiFunc(row.id, this.userId, this.userName, comment).then(res => {
        if (res.returnCode === '0') {
          this.$message.success(action === 'approve' ? '批准成功' : '拒绝成功')
          this.approvalDialogVisible = false
          this.fetchWorkflowData()
        } else {
          this.$message.error(res.msg || '操作失败')
        }
      }).catch(err => {
        this.$message.error('操作失败')
        console.error(err)
      })
    },
    handleCancelWorkflow(row) {
      this.cancelForm = {
        reason: '',
        row: row
      }
      this.cancelDialogVisible = true
    },
    handleCancelSubmit() {
      if (!this.cancelForm.reason) {
        this.$message.warning('请输入取消原因')
        return
      }
      cancelWorkflow(this.cancelForm.row.id, this.cancelForm.reason).then(res => {
        if (res.returnCode === '0') {
          this.$message.success('取消成功')
          this.cancelDialogVisible = false
          this.fetchWorkflowData()
        } else {
          this.$message.error(res.msg || '取消失败')
        }
      }).catch(err => {
        this.$message.error('取消失败')
        console.error(err)
      })
    },
    handleViewWorkflow(row) {
      getWorkflowById(row.id).then(res => {
        if (res.returnCode === '0') {
          const workflow = res.result
          this.$alert(
            `<div>
              <p><strong>工作流编号:</strong> ${workflow.workflowNo}</p>
              <p><strong>工作流类型:</strong> ${this.getWorkflowTypeLabel(workflow.workflowType)}</p>
              <p><strong>申请人:</strong> ${workflow.requesterName}</p>
              <p><strong>申请描述:</strong> ${workflow.requestDescription || '无'}</p>
              <p><strong>当前状态:</strong> ${this.getWorkflowStatusLabel(workflow.workflowStatus)}</p>
              <p><strong>创建时间:</strong> ${workflow.createDate}</p>
            </div>`,
            '工作流详情',
            {
              dangerouslyUseHTMLString: true,
              confirmButtonText: '关闭'
            }
          )
        } else {
          this.$message.error(res.msg || '获取详情失败')
        }
      }).catch(err => {
        this.$message.error('获取详情失败')
        console.error(err)
      })
    },
    handleShowMyPending() {
      getMyPendingWorkflows(this.userId).then(res => {
        if (res.returnCode === '0') {
          this.workflowTableData = res.result || []
          this.workflowTotal = this.workflowTableData.length
          this.$message.success(`找到${this.workflowTableData.length}条待审批工作流`)
        } else {
          this.$message.error(res.msg || '查询失败')
        }
      }).catch(err => {
        this.$message.error('查询失败')
        console.error(err)
      })
    },
    handleEditConfig(row) {
      this.configFormData = { ...row }
      this.editConfigDialogVisible = true
    },
    handleEditConfigSubmit() {
      updateApprovalConfig(this.configFormData).then(res => {
        if (res.returnCode === '0') {
          this.$message.success('更新成功')
          this.editConfigDialogVisible = false
          this.fetchConfigData()
        } else {
          this.$message.error(res.msg || '更新失败')
        }
      }).catch(err => {
        this.$message.error('更新失败')
        console.error(err)
      })
    },
    handleEditConfigDialogClose() {
      this.configFormData = {}
    },
    handleConfigEnabledChange(row) {
      updateConfigEnabled(row.id, row.isEnabled).then(res => {
        if (res.returnCode === '0') {
          this.$message.success('状态更新成功')
        } else {
          this.$message.error(res.msg || '状态更新失败')
          row.isEnabled = row.isEnabled === 1 ? 0 : 1
        }
      }).catch(err => {
        this.$message.error('状态更新失败')
        row.isEnabled = row.isEnabled === 1 ? 0 : 1
        console.error(err)
      })
    },
    getWorkflowTypeLabel(type) {
      const typeMap = {
        'ACCESS_APPLICATION': '接入申请',
        'COOPERATION_APPLICATION': '合作申请',
        'DATA_AUTHORIZATION': '数据授权',
        'OTHER': '其他'
      }
      return typeMap[type] || type
    },
    getWorkflowStatusLabel(status) {
      const statusMap = {
        0: '待审批',
        1: '审批中',
        2: '已通过',
        3: '已拒绝',
        4: '已取消'
      }
      return statusMap[status] || '未知'
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
  margin-bottom: 15px;
  width: 100%;
}
.table-expand >>> .el-form-item__label {
  width: 100px;
  color: #99a9bf;
}
.table-expand >>> .el-form-item__content {
  width: calc(100% - 100px);
}
</style>
