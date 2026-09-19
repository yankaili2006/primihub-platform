<template>
  <div class="app-container">
    <!-- 标签页切换 -->
    <el-tabs v-model="activeTab" @tab-click="handleTabClick">
      <!-- 合作节点列表 -->
      <el-tab-pane label="合作节点列表" name="nodeList">
        <!-- Search filters -->
        <el-form :inline="true" :model="queryForm" class="demo-form-inline">
          <el-form-item label="关键字">
            <el-input v-model="queryForm.keyword" placeholder="节点ID或节点名称" clearable />
          </el-form-item>
          <el-form-item label="合作状态">
            <el-select v-model="queryForm.cooperationStatus" placeholder="请选择" clearable>
              <el-option label="进行中" :value="1" />
              <el-option label="已暂停" :value="2" />
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
          <el-button type="danger" icon="el-icon-close" :disabled="selectedRows.length === 0" @click="handleBatchCancel">
            批量取消合作
          </el-button>
        </el-row>

        <!-- Table -->
        <el-table
          v-loading="loading"
          :data="tableData"
          border
          @selection-change="handleSelectionChange"
        >
          <el-table-column type="selection" width="55" />
          <el-table-column prop="organId" label="节点ID" width="150" />
          <el-table-column prop="organName" label="节点名称" width="150" />
          <el-table-column prop="organGateway" label="网关地址" width="180" />
          <el-table-column prop="cooperationType" label="合作类型" width="120">
            <template slot-scope="scope">
              {{ getCooperationTypeLabel(scope.row.cooperationType) }}
            </template>
          </el-table-column>
          <el-table-column prop="cooperationStatus" label="合作状态" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.cooperationStatus === 1" type="success">进行中</el-tag>
              <el-tag v-else-if="scope.row.cooperationStatus === 2" type="warning">已暂停</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="startDate" label="开始时间" width="160" />
          <el-table-column prop="endDate" label="结束时间" width="160" />
          <el-table-column prop="healthScore" label="健康评分" width="100">
            <template slot-scope="scope">
              <el-progress
                :percentage="scope.row.healthScore || 0"
                :color="getHealthScoreColor(scope.row.healthScore)"
              />
            </template>
          </el-table-column>
          <el-table-column label="操作" fixed="right" width="150">
            <template slot-scope="scope">
              <el-button size="mini" type="danger" @click="handleCancel(scope.row)">取消合作</el-button>
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
      </el-tab-pane>

      <!-- 取消记录 -->
      <el-tab-pane label="取消合作记录" name="cancelHistory">
        <!-- Search filters -->
        <el-form :inline="true" :model="historyQueryForm" class="demo-form-inline">
          <el-form-item label="关键字">
            <el-input v-model="historyQueryForm.keyword" placeholder="节点ID或节点名称" clearable />
          </el-form-item>
          <el-form-item label="取消时间">
            <el-date-picker
              v-model="historyQueryForm.dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="yyyy-MM-dd"
            />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleHistoryQuery">查询</el-button>
            <el-button @click="handleHistoryReset">重置</el-button>
          </el-form-item>
        </el-form>

        <!-- History Table -->
        <el-table
          v-loading="historyLoading"
          :data="historyTableData"
          border
        >
          <el-table-column prop="organId" label="节点ID" width="150" />
          <el-table-column prop="organName" label="节点名称" width="150" />
          <el-table-column prop="cooperationType" label="原合作类型" width="120">
            <template slot-scope="scope">
              {{ getCooperationTypeLabel(scope.row.cooperationType) }}
            </template>
          </el-table-column>
          <el-table-column prop="cancelReason" label="取消原因" min-width="200" />
          <el-table-column prop="cancelUserName" label="操作人" width="100" />
          <el-table-column prop="cancelDate" label="取消时间" width="160" />
          <el-table-column prop="cooperationDuration" label="合作时长" width="120" />
          <el-table-column label="操作" fixed="right" width="100">
            <template slot-scope="scope">
              <el-button size="mini" type="primary" @click="handleReestablish(scope.row)">重新合作</el-button>
            </template>
          </el-table-column>
        </el-table>

        <!-- History Pagination -->
        <el-pagination
          style="margin-top: 20px;"
          :current-page="historyQueryForm.pageNum"
          :page-sizes="[10, 20, 50, 100]"
          :page-size="historyQueryForm.pageSize"
          :total="historyTotal"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleHistorySizeChange"
          @current-change="handleHistoryCurrentChange"
        />
      </el-tab-pane>
    </el-tabs>

    <!-- Cancel Dialog -->
    <el-dialog
      title="取消合作"
      :visible.sync="cancelDialogVisible"
      width="50%"
    >
      <el-alert
        title="取消合作后，将停止与该节点的所有数据交换和计算任务，请谨慎操作。"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 20px;"
      />
      <el-form ref="cancelForm" :model="cancelForm" :rules="cancelFormRules" label-width="100px">
        <el-form-item label="节点信息">
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="节点ID">{{ cancelForm.organId }}</el-descriptions-item>
            <el-descriptions-item label="节点名称">{{ cancelForm.organName }}</el-descriptions-item>
            <el-descriptions-item label="合作类型">{{ getCooperationTypeLabel(cancelForm.cooperationType) }}</el-descriptions-item>
            <el-descriptions-item label="合作开始时间">{{ cancelForm.startDate }}</el-descriptions-item>
          </el-descriptions>
        </el-form-item>
        <el-form-item label="取消原因" prop="cancelReason">
          <el-input
            v-model="cancelForm.cancelReason"
            type="textarea"
            :rows="4"
            placeholder="请输入取消合作的原因（必填）"
          />
        </el-form-item>
        <el-form-item label="确认操作">
          <el-checkbox v-model="cancelForm.confirmed">
            我确认取消与该节点的合作关系，并了解此操作的影响
          </el-checkbox>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="cancelDialogVisible = false">取 消</el-button>
        <el-button type="danger" :disabled="!cancelForm.confirmed" @click="handleCancelSubmit">确认取消合作</el-button>
      </span>
    </el-dialog>

    <!-- Batch Cancel Dialog -->
    <el-dialog
      title="批量取消合作"
      :visible.sync="batchCancelDialogVisible"
      width="50%"
    >
      <el-alert
        :title="`您将取消与 ${selectedRows.length} 个节点的合作关系，请谨慎操作。`"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 20px;"
      />
      <el-table :data="selectedRows" border max-height="300">
        <el-table-column prop="organId" label="节点ID" width="150" />
        <el-table-column prop="organName" label="节点名称" />
        <el-table-column prop="cooperationType" label="合作类型" width="120">
          <template slot-scope="scope">
            {{ getCooperationTypeLabel(scope.row.cooperationType) }}
          </template>
        </el-table-column>
      </el-table>
      <el-form ref="batchCancelForm" :model="batchCancelForm" :rules="batchCancelFormRules" label-width="100px" style="margin-top: 20px;">
        <el-form-item label="取消原因" prop="cancelReason">
          <el-input
            v-model="batchCancelForm.cancelReason"
            type="textarea"
            :rows="3"
            placeholder="请输入批量取消合作的原因（必填）"
          />
        </el-form-item>
        <el-form-item label="确认操作">
          <el-checkbox v-model="batchCancelForm.confirmed">
            我确认批量取消这些合作关系，并了解此操作的影响
          </el-checkbox>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="batchCancelDialogVisible = false">取 消</el-button>
        <el-button type="danger" :disabled="!batchCancelForm.confirmed" @click="handleBatchCancelSubmit">确认批量取消</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findCooperationPartyPage,
  cancelCooperation,
  establishCooperation
} from '@/api/nodeEnhanced'
import {
  findCancelCooperationHistory,
  batchCancelCooperation
} from '@/api/cancelCooperation'
import { mapGetters } from 'vuex'

export default {
  name: 'CancelCooperation',
  data() {
    return {
      activeTab: 'nodeList',
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
      historyLoading: false,
      historyTableData: [],
      historyTotal: 0,
      historyQueryForm: {
        keyword: '',
        dateRange: null,
        pageNum: 1,
        pageSize: 10
      },
      cancelDialogVisible: false,
      cancelForm: {
        id: null,
        organId: '',
        organName: '',
        cooperationType: '',
        startDate: '',
        cancelReason: '',
        confirmed: false
      },
      cancelFormRules: {
        cancelReason: [
          { required: true, message: '请输入取消原因', trigger: 'blur' },
          { min: 10, message: '取消原因不少于10个字符', trigger: 'blur' }
        ]
      },
      batchCancelDialogVisible: false,
      batchCancelForm: {
        cancelReason: '',
        confirmed: false
      },
      batchCancelFormRules: {
        cancelReason: [
          { required: true, message: '请输入取消原因', trigger: 'blur' },
          { min: 10, message: '取消原因不少于10个字符', trigger: 'blur' }
        ]
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
      // 只查询进行中和已暂停的合作
      const params = {
        ...this.queryForm,
        cooperationStatusList: [1, 2]
      }
      findCooperationPartyPage(params).then(res => {
        this.loading = false
        if (res.code === 0) {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          // 使用测试数据
          this.tableData = []  // 不造假：接口失败/无数据即空
          this.total = this.tableData.length
        }
      }).catch(() => {
        this.loading = false
        // 使用测试数据
        this.tableData = []  // 不造假：接口失败/无数据即空
        this.total = this.tableData.length
      })
    },
    fetchHistoryData() {
      this.historyLoading = true
      findCancelCooperationHistory(this.historyQueryForm).then(res => {
        this.historyLoading = false
        if (res.code === 0) {
          this.historyTableData = res.result.list || []
          this.historyTotal = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          // 使用测试数据
          this.historyTableData = []  // 不造假：接口失败/无数据即空
          this.historyTotal = this.historyTableData.length
        }
      }).catch(() => {
        this.historyLoading = false
        // 使用测试数据
        this.historyTableData = []  // 不造假：接口失败/无数据即空
        this.historyTotal = this.historyTableData.length
      })
    },
    handleTabClick(tab) {
      if (tab.name === 'cancelHistory') {
        this.fetchHistoryData()
      }
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
    handleHistoryQuery() {
      this.historyQueryForm.pageNum = 1
      this.fetchHistoryData()
    },
    handleHistoryReset() {
      this.historyQueryForm = {
        keyword: '',
        dateRange: null,
        pageNum: 1,
        pageSize: 10
      }
      this.fetchHistoryData()
    },
    handleHistorySizeChange(val) {
      this.historyQueryForm.pageSize = val
      this.fetchHistoryData()
    },
    handleHistoryCurrentChange(val) {
      this.historyQueryForm.pageNum = val
      this.fetchHistoryData()
    },
    handleCancel(row) {
      this.cancelForm = {
        id: row.id,
        organId: row.organId,
        organName: row.organName,
        cooperationType: row.cooperationType,
        startDate: row.startDate,
        cancelReason: '',
        confirmed: false
      }
      this.cancelDialogVisible = true
    },
    handleCancelSubmit() {
      this.$refs.cancelForm.validate((valid) => {
        if (valid) {
          cancelCooperation(this.cancelForm.id, this.cancelForm.cancelReason, this.userName).then(res => {
            if (res.code === 0) {
              this.$message.success('取消合作成功')
              this.cancelDialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || '取消合作失败')
            }
          }).catch((e) => {
            this.$message.error('请求异常：' + (e.message || '取消合作失败'))
          })
        }
      })
    },
    handleBatchCancel() {
      this.batchCancelForm = {
        cancelReason: '',
        confirmed: false
      }
      this.batchCancelDialogVisible = true
    },
    handleBatchCancelSubmit() {
      this.$refs.batchCancelForm.validate((valid) => {
        if (valid) {
          const ids = this.selectedRows.map(row => row.id)
          batchCancelCooperation(ids, this.batchCancelForm.cancelReason, this.userName).then(res => {
            if (res.code === 0) {
              this.$message.success('批量取消合作成功')
              this.batchCancelDialogVisible = false
              this.selectedRows = []
              this.fetchData()
            } else {
              this.$message.error(res.msg || '批量取消合作失败')
            }
          }).catch((e) => {
            this.$message.error('请求异常：' + (e.message || '批量取消合作失败'))
          })
        }
      })
    },
    handleReestablish(row) {
      this.$confirm(`确认重新建立与 ${row.organName} 的合作关系吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'info'
      }).then(() => {
        const data = {
          organId: row.organId,
          organName: row.organName,
          cooperationType: row.cooperationType
        }
        establishCooperation(data).then(res => {
          if (res.code === 0) {
            this.$message.success('重新建立合作成功')
            this.fetchHistoryData()
          } else {
            this.$message.error(res.msg || '建立合作失败')
          }
        }).catch((e) => {
          this.$message.error('请求异常：' + (e.message || '建立合作失败'))
        })
      }).catch(() => {})
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
</style>
