<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="源节点">
        <el-input v-model="queryForm.sourceOrganName" placeholder="源节点名称" clearable />
      </el-form-item>
      <el-form-item label="目标节点">
        <el-input v-model="queryForm.targetOrganName" placeholder="目标节点名称" clearable />
      </el-form-item>
      <el-form-item label="交换类型">
        <el-select v-model="queryForm.exchangeType" placeholder="请选择" clearable>
          <el-option label="推送" value="PUSH" />
          <el-option label="拉取" value="PULL" />
          <el-option label="同步" value="SYNC" />
        </el-select>
      </el-form-item>
      <el-form-item label="数据类型">
        <el-select v-model="queryForm.dataType" placeholder="请选择" clearable>
          <el-option label="资源数据" value="RESOURCE" />
          <el-option label="任务数据" value="TASK" />
          <el-option label="模型数据" value="MODEL" />
          <el-option label="其他" value="OTHER" />
        </el-select>
      </el-form-item>
      <el-form-item label="交换状态">
        <el-select v-model="queryForm.exchangeStatus" placeholder="请选择" clearable>
          <el-option label="准备中" :value="0" />
          <el-option label="进行中" :value="1" />
          <el-option label="成功" :value="2" />
          <el-option label="失败" :value="3" />
          <el-option label="部分成功" :value="4" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-upload2" @click="handleTriggerSync">触发同步</el-button>
      <el-button type="info" icon="el-icon-s-data" @click="handleShowStatistics">交换统计</el-button>
      <el-button type="warning" icon="el-icon-warning" @click="handleShowFailed">查看失败</el-button>
      <el-button type="success" icon="el-icon-time" @click="handleShowRecent">最近记录</el-button>
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
      <el-table-column type="expand">
        <template slot-scope="props">
          <el-form label-position="left" inline class="table-expand">
            <el-form-item label="交换ID:">
              <span>{{ props.row.exchangeId }}</span>
            </el-form-item>
            <el-form-item label="数据名称:">
              <span>{{ props.row.dataName || '无' }}</span>
            </el-form-item>
            <el-form-item label="数据大小:">
              <span>{{ formatDataSize(props.row.dataSize) }}</span>
            </el-form-item>
            <el-form-item label="传输速率:">
              <span>{{ props.row.transferRate || '无' }}</span>
            </el-form-item>
            <el-form-item label="失败原因:">
              <span :style="{color: 'red'}">{{ props.row.failureReason || '无' }}</span>
            </el-form-item>
            <el-form-item label="重试次数:">
              <span>{{ props.row.retryCount || 0 }}</span>
            </el-form-item>
            <el-form-item label="校验和:">
              <span style="word-break: break-all;">{{ props.row.checksum || '无' }}</span>
            </el-form-item>
            <el-form-item label="备注:">
              <span>{{ props.row.remarks || '无' }}</span>
            </el-form-item>
          </el-form>
        </template>
      </el-table-column>
      <el-table-column prop="sourceOrganName" label="源节点" width="150" />
      <el-table-column prop="targetOrganName" label="目标节点" width="150" />
      <el-table-column prop="exchangeType" label="交换类型" width="100">
        <template slot-scope="scope">
          {{ getExchangeTypeLabel(scope.row.exchangeType) }}
        </template>
      </el-table-column>
      <el-table-column prop="dataType" label="数据类型" width="120">
        <template slot-scope="scope">
          {{ getDataTypeLabel(scope.row.dataType) }}
        </template>
      </el-table-column>
      <el-table-column prop="exchangeStatus" label="交换状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.exchangeStatus === 0" type="info">准备中</el-tag>
          <el-tag v-else-if="scope.row.exchangeStatus === 1" type="primary">进行中</el-tag>
          <el-tag v-else-if="scope.row.exchangeStatus === 2" type="success">成功</el-tag>
          <el-tag v-else-if="scope.row.exchangeStatus === 3" type="danger">失败</el-tag>
          <el-tag v-else-if="scope.row.exchangeStatus === 4" type="warning">部分成功</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="startTime" label="开始时间" width="160" />
      <el-table-column prop="endTime" label="结束时间" width="160" />
      <el-table-column prop="duration" label="耗时(秒)" width="100" />
      <el-table-column label="操作" fixed="right" width="200">
        <template slot-scope="scope">
          <el-button size="mini" type="primary" @click="handleViewDetail(scope.row)">详情</el-button>
          <el-button
            v-if="scope.row.exchangeStatus === 3"
            size="mini"
            type="warning"
            @click="handleRetry(scope.row)"
          >
            重试
          </el-button>
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

    <!-- Trigger Sync Dialog -->
    <el-dialog
      title="触发数据同步"
      :visible.sync="triggerSyncDialogVisible"
      width="50%"
      @close="handleTriggerSyncDialogClose"
    >
      <el-form ref="syncForm" :model="syncFormData" :rules="syncFormRules" label-width="120px">
        <el-form-item label="源节点ID" prop="sourceOrganId">
          <el-input v-model="syncFormData.sourceOrganId" placeholder="请输入源节点ID" />
        </el-form-item>
        <el-form-item label="目标节点ID" prop="targetOrganId">
          <el-input v-model="syncFormData.targetOrganId" placeholder="请输入目标节点ID" />
        </el-form-item>
        <el-form-item label="交换类型" prop="exchangeType">
          <el-select v-model="syncFormData.exchangeType" placeholder="请选择" style="width: 100%;">
            <el-option label="推送" value="PUSH" />
            <el-option label="拉取" value="PULL" />
            <el-option label="同步" value="SYNC" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据类型" prop="dataType">
          <el-select v-model="syncFormData.dataType" placeholder="请选择" style="width: 100%;">
            <el-option label="资源数据" value="RESOURCE" />
            <el-option label="任务数据" value="TASK" />
            <el-option label="模型数据" value="MODEL" />
            <el-option label="其他" value="OTHER" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据ID">
          <el-input v-model="syncFormData.dataId" placeholder="请输入数据ID" />
        </el-form-item>
        <el-form-item label="数据名称">
          <el-input v-model="syncFormData.dataName" placeholder="请输入数据名称" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="triggerSyncDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleTriggerSyncSubmit">触 发</el-button>
      </span>
    </el-dialog>

    <!-- Statistics Dialog -->
    <el-dialog
      title="交换统计信息"
      :visible.sync="statisticsDialogVisible"
      width="60%"
    >
      <el-form label-width="140px">
        <el-form-item label="统计节点ID">
          <el-input v-model="statisticsOrganId" placeholder="请输入节点ID">
            <el-button slot="append" icon="el-icon-search" @click="loadStatistics">查询</el-button>
          </el-input>
        </el-form-item>
      </el-form>
      <div v-if="statisticsData">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card>
              <div slot="header">发送统计</div>
              <p>总次数: {{ statisticsData.sendTotalCount || 0 }}</p>
              <p>成功次数: {{ statisticsData.sendSuccessCount || 0 }}</p>
              <p>失败次数: {{ statisticsData.sendFailureCount || 0 }}</p>
              <p>总数据量: {{ formatDataSize(statisticsData.sendTotalSize) }}</p>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card>
              <div slot="header">接收统计</div>
              <p>总次数: {{ statisticsData.receiveTotalCount || 0 }}</p>
              <p>成功次数: {{ statisticsData.receiveSuccessCount || 0 }}</p>
              <p>失败次数: {{ statisticsData.receiveFailureCount || 0 }}</p>
              <p>总数据量: {{ formatDataSize(statisticsData.receiveTotalSize) }}</p>
            </el-card>
          </el-col>
        </el-row>
        <el-row :gutter="20" style="margin-top: 20px;">
          <el-col :span="24">
            <el-card>
              <div slot="header">其他统计</div>
              <p>平均传输速率: {{ statisticsData.avgTransferRate || '无' }}</p>
              <p>最后交换时间: {{ statisticsData.lastExchangeTime || '无' }}</p>
              <p>活跃合作伙伴数: {{ statisticsData.activePartnerCount || 0 }}</p>
            </el-card>
          </el-col>
        </el-row>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="statisticsDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findDataExchangeLogPage,
  getDataExchangeLogById,
  triggerDataSync,
  getExchangeStatistics,
  getRecentExchangeLogs,
  getFailedExchangeLogs,
  batchDeleteDataExchangeLog
} from '@/api/nodeEnhanced'

export default {
  name: 'DataExchangeLog',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        sourceOrganName: '',
        targetOrganName: '',
        exchangeType: null,
        dataType: null,
        exchangeStatus: null,
        pageNum: 1,
        pageSize: 10
      },
      triggerSyncDialogVisible: false,
      syncFormData: {},
      syncFormRules: {
        sourceOrganId: [{ required: true, message: '请输入源节点ID', trigger: 'blur' }],
        targetOrganId: [{ required: true, message: '请输入目标节点ID', trigger: 'blur' }],
        exchangeType: [{ required: true, message: '请选择交换类型', trigger: 'change' }],
        dataType: [{ required: true, message: '请选择数据类型', trigger: 'change' }]
      },
      statisticsDialogVisible: false,
      statisticsOrganId: '',
      statisticsData: null
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.loading = true
      findDataExchangeLogPage(this.queryForm).then(res => {
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
        sourceOrganName: '',
        targetOrganName: '',
        exchangeType: null,
        dataType: null,
        exchangeStatus: null,
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
    handleTriggerSync() {
      this.syncFormData = {
        exchangeType: 'SYNC',
        dataType: 'RESOURCE'
      }
      this.triggerSyncDialogVisible = true
    },
    handleTriggerSyncSubmit() {
      this.$refs.syncForm.validate((valid) => {
        if (valid) {
          const { sourceOrganId, targetOrganId, exchangeType, dataType, dataId, dataName } = this.syncFormData
          triggerDataSync(sourceOrganId, targetOrganId, exchangeType, dataType, dataId, dataName).then(res => {
            if (res.code === 0) {
              this.$message.success('触发同步成功')
              this.triggerSyncDialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || '触发同步失败')
            }
          }).catch(err => {
            this.$message.error('触发同步失败')
            console.error(err)
          })
        }
      })
    },
    handleTriggerSyncDialogClose() {
      this.$refs.syncForm.resetFields()
      this.syncFormData = {}
    },
    handleShowStatistics() {
      this.statisticsOrganId = ''
      this.statisticsData = null
      this.statisticsDialogVisible = true
    },
    loadStatistics() {
      if (!this.statisticsOrganId) {
        this.$message.warning('请输入节点ID')
        return
      }
      getExchangeStatistics(this.statisticsOrganId).then(res => {
        if (res.code === 0) {
          this.statisticsData = res.result || {}
          this.$message.success('加载统计信息成功')
        } else {
          this.$message.error(res.msg || '加载统计信息失败')
        }
      }).catch(err => {
        this.$message.error('加载统计信息失败')
        console.error(err)
      })
    },
    handleShowFailed() {
      this.loading = true
      getFailedExchangeLogs().then(res => {
        this.loading = false
        if (res.code === 0) {
          this.tableData = res.result || []
          this.total = this.tableData.length
          this.$message.success(`找到${this.tableData.length}条失败记录`)
        } else {
          this.$message.error(res.msg || '查询失败')
        }
      }).catch(err => {
        this.loading = false
        this.$message.error('查询失败')
        console.error(err)
      })
    },
    handleShowRecent() {
      this.$prompt('请输入天数', '查询最近的交换记录', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPattern: /^\d+$/,
        inputErrorMessage: '请输入有效的天数',
        inputValue: '7'
      }).then(({ value }) => {
        this.loading = true
        getRecentExchangeLogs(parseInt(value)).then(res => {
          this.loading = false
          if (res.code === 0) {
            this.tableData = res.result || []
            this.total = this.tableData.length
            this.$message.success(`找到${this.tableData.length}条记录`)
          } else {
            this.$message.error(res.msg || '查询失败')
          }
        }).catch(err => {
          this.loading = false
          this.$message.error('查询失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleViewDetail(row) {
      getDataExchangeLogById(row.id).then(res => {
        if (res.code === 0) {
          const log = res.result
          this.$alert(
            `<div style="max-height: 400px; overflow-y: auto;">
              <p><strong>交换ID:</strong> ${log.exchangeId}</p>
              <p><strong>源节点:</strong> ${log.sourceOrganName}</p>
              <p><strong>目标节点:</strong> ${log.targetOrganName}</p>
              <p><strong>交换类型:</strong> ${this.getExchangeTypeLabel(log.exchangeType)}</p>
              <p><strong>数据类型:</strong> ${this.getDataTypeLabel(log.dataType)}</p>
              <p><strong>数据名称:</strong> ${log.dataName || '无'}</p>
              <p><strong>数据大小:</strong> ${this.formatDataSize(log.dataSize)}</p>
              <p><strong>交换状态:</strong> ${this.getExchangeStatusLabel(log.exchangeStatus)}</p>
              <p><strong>开始时间:</strong> ${log.startTime}</p>
              <p><strong>结束时间:</strong> ${log.endTime || '无'}</p>
              <p><strong>耗时:</strong> ${log.duration || 0} 秒</p>
              <p><strong>传输速率:</strong> ${log.transferRate || '无'}</p>
              <p><strong>重试次数:</strong> ${log.retryCount || 0}</p>
              <p><strong>失败原因:</strong> <span style="color:red">${log.failureReason || '无'}</span></p>
            </div>`,
            '数据交换详情',
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
    handleRetry(row) {
      this.$confirm('确认重试该数据交换吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        triggerDataSync(
          row.sourceOrganId,
          row.targetOrganId,
          row.exchangeType,
          row.dataType,
          row.dataId,
          row.dataName
        ).then(res => {
          if (res.code === 0) {
            this.$message.success('重试成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '重试失败')
          }
        }).catch(err => {
          this.$message.error('重试失败')
          console.error(err)
        })
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm('确认删除该交换记录吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        batchDeleteDataExchangeLog([row.id]).then(res => {
          if (res.code === 0) {
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
        batchDeleteDataExchangeLog(ids).then(res => {
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
    getExchangeTypeLabel(type) {
      const typeMap = {
        'PUSH': '推送',
        'PULL': '拉取',
        'SYNC': '同步'
      }
      return typeMap[type] || type
    },
    getDataTypeLabel(type) {
      const typeMap = {
        'RESOURCE': '资源数据',
        'TASK': '任务数据',
        'MODEL': '模型数据',
        'OTHER': '其他'
      }
      return typeMap[type] || type
    },
    getExchangeStatusLabel(status) {
      const statusMap = {
        0: '准备中',
        1: '进行中',
        2: '成功',
        3: '失败',
        4: '部分成功'
      }
      return statusMap[status] || '未知'
    },
    formatDataSize(bytes) {
      if (!bytes || bytes === 0) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return (bytes / Math.pow(k, i)).toFixed(2) + ' ' + sizes[i]
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
  margin-bottom: 10px;
  width: 50%;
}
.table-expand >>> .el-form-item__label {
  width: 100px;
  color: #99a9bf;
}
.table-expand >>> .el-form-item__content {
  width: calc(100% - 100px);
}
</style>
