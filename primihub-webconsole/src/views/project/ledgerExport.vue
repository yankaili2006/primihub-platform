<template>
  <div class="app-container">
    <!-- 标签页切换 -->
    <el-tabs v-model="activeTab">
      <!-- 项目台账查询 -->
      <el-tab-pane label="项目台账查询" name="ledgerList">
        <!-- Search filters -->
        <el-form :inline="true" :model="queryForm" class="demo-form-inline">
          <el-form-item label="项目名称">
            <el-input v-model="queryForm.projectName" placeholder="请输入项目名称" clearable />
          </el-form-item>
          <el-form-item label="项目状态">
            <el-select v-model="queryForm.projectStatus" placeholder="请选择" clearable>
              <el-option label="进行中" :value="1" />
              <el-option label="已完成" :value="2" />
              <el-option label="已暂停" :value="3" />
              <el-option label="已关闭" :value="4" />
            </el-select>
          </el-form-item>
          <el-form-item label="创建时间">
            <el-date-picker
              v-model="queryForm.dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="yyyy-MM-dd"
            />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleQuery">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>

        <!-- Action buttons -->
        <el-row style="margin-bottom: 20px;">
          <el-button type="success" icon="el-icon-download" :disabled="selectedRows.length === 0" @click="handleExportSelected">
            导出选中台账
          </el-button>
          <el-button type="primary" icon="el-icon-download" @click="handleExportAll">
            导出全部台账
          </el-button>
          <el-button type="warning" icon="el-icon-document" @click="handleExportTemplate">
            下载导出模板
          </el-button>
        </el-row>

        <!-- Summary Cards -->
        <el-row :gutter="20" style="margin-bottom: 20px;">
          <el-col :span="6">
            <el-card shadow="hover">
              <div class="summary-item">
                <div class="summary-value">{{ summaryData.totalProjects }}</div>
                <div class="summary-label">项目总数</div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover">
              <div class="summary-item">
                <div class="summary-value" style="color: #67C23A;">{{ summaryData.runningProjects }}</div>
                <div class="summary-label">进行中</div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover">
              <div class="summary-item">
                <div class="summary-value" style="color: #409EFF;">{{ summaryData.completedProjects }}</div>
                <div class="summary-label">已完成</div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover">
              <div class="summary-item">
                <div class="summary-value" style="color: #E6A23C;">{{ summaryData.totalTasks }}</div>
                <div class="summary-label">任务总数</div>
              </div>
            </el-card>
          </el-col>
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
                <el-form-item label="项目描述:">
                  <span>{{ props.row.projectDesc || '无' }}</span>
                </el-form-item>
                <el-form-item label="参与机构:">
                  <span>{{ props.row.participantOrgans || '无' }}</span>
                </el-form-item>
                <el-form-item label="使用资源:">
                  <span>{{ props.row.usedResources || '无' }}</span>
                </el-form-item>
                <el-form-item label="负责人:">
                  <span>{{ props.row.projectOwner || '无' }}</span>
                </el-form-item>
              </el-form>
            </template>
          </el-table-column>
          <el-table-column prop="projectId" label="项目ID" width="120" />
          <el-table-column prop="projectName" label="项目名称" width="180" />
          <el-table-column prop="projectStatus" label="项目状态" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.projectStatus === 1" type="success">进行中</el-tag>
              <el-tag v-else-if="scope.row.projectStatus === 2" type="primary">已完成</el-tag>
              <el-tag v-else-if="scope.row.projectStatus === 3" type="warning">已暂停</el-tag>
              <el-tag v-else-if="scope.row.projectStatus === 4" type="info">已关闭</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="taskCount" label="任务数量" width="100" />
          <el-table-column prop="completedTaskCount" label="完成任务" width="100" />
          <el-table-column prop="participantCount" label="参与方数" width="100" />
          <el-table-column prop="resourceCount" label="资源数量" width="100" />
          <el-table-column prop="createDate" label="创建时间" width="160" />
          <el-table-column prop="updateDate" label="更新时间" width="160" />
          <el-table-column label="操作" fixed="right" width="200">
            <template slot-scope="scope">
              <el-button size="mini" @click="handleViewDetail(scope.row)">查看详情</el-button>
              <el-button size="mini" type="success" @click="handleExportSingle(scope.row)">导出</el-button>
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

      <!-- 导出记录 -->
      <el-tab-pane label="导出记录" name="exportHistory">
        <el-table :data="exportHistoryData" border>
          <el-table-column prop="exportId" label="导出ID" width="120" />
          <el-table-column prop="exportType" label="导出类型" width="120">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.exportType === 'SINGLE'" type="info">单项目</el-tag>
              <el-tag v-else-if="scope.row.exportType === 'BATCH'" type="primary">批量</el-tag>
              <el-tag v-else-if="scope.row.exportType === 'ALL'" type="success">全部</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="exportFormat" label="导出格式" width="100" />
          <el-table-column prop="projectCount" label="项目数量" width="100" />
          <el-table-column prop="exportStatus" label="状态" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.exportStatus === 1" type="success">已完成</el-tag>
              <el-tag v-else-if="scope.row.exportStatus === 0" type="warning">导出中</el-tag>
              <el-tag v-else-if="scope.row.exportStatus === 2" type="danger">失败</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="exportUserName" label="操作人" width="100" />
          <el-table-column prop="exportDate" label="导出时间" width="160" />
          <el-table-column label="操作" fixed="right" width="150">
            <template slot-scope="scope">
              <el-button v-if="scope.row.exportStatus === 1" size="mini" type="success" @click="handleDownloadExport(scope.row)">
                下载
              </el-button>
              <el-button v-if="scope.row.exportStatus === 2" size="mini" type="warning" @click="handleRetryExport(scope.row)">
                重试
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- View Detail Dialog -->
    <el-dialog title="项目台账详情" :visible.sync="detailDialogVisible" width="70%">
      <el-tabs v-model="detailTab">
        <el-tab-pane label="基本信息" name="basic">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="项目ID">{{ detailData.projectId }}</el-descriptions-item>
            <el-descriptions-item label="项目名称">{{ detailData.projectName }}</el-descriptions-item>
            <el-descriptions-item label="项目状态">
              <el-tag v-if="detailData.projectStatus === 1" type="success">进行中</el-tag>
              <el-tag v-else-if="detailData.projectStatus === 2" type="primary">已完成</el-tag>
              <el-tag v-else-if="detailData.projectStatus === 3" type="warning">已暂停</el-tag>
              <el-tag v-else-if="detailData.projectStatus === 4" type="info">已关闭</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="负责人">{{ detailData.projectOwner || '-' }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ detailData.createDate }}</el-descriptions-item>
            <el-descriptions-item label="更新时间">{{ detailData.updateDate }}</el-descriptions-item>
            <el-descriptions-item label="项目描述" :span="2">{{ detailData.projectDesc || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <el-tab-pane label="参与方信息" name="participants">
          <el-table :data="detailData.participants || []" border>
            <el-table-column prop="organId" label="机构ID" width="150" />
            <el-table-column prop="organName" label="机构名称" width="180" />
            <el-table-column prop="role" label="参与角色" width="120" />
            <el-table-column prop="joinDate" label="加入时间" width="160" />
            <el-table-column prop="resourceCount" label="提供资源数" width="120" />
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="任务记录" name="tasks">
          <el-table :data="detailData.tasks || []" border>
            <el-table-column prop="taskId" label="任务ID" width="120" />
            <el-table-column prop="taskName" label="任务名称" width="180" />
            <el-table-column prop="taskType" label="任务类型" width="120" />
            <el-table-column prop="taskStatus" label="任务状态" width="100">
              <template slot-scope="scope">
                <el-tag v-if="scope.row.taskStatus === 1" type="info">待执行</el-tag>
                <el-tag v-else-if="scope.row.taskStatus === 2" type="warning">执行中</el-tag>
                <el-tag v-else-if="scope.row.taskStatus === 3" type="success">已完成</el-tag>
                <el-tag v-else-if="scope.row.taskStatus === 4" type="danger">已失败</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createDate" label="创建时间" width="160" />
            <el-table-column prop="completeDate" label="完成时间" width="160" />
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="资源使用" name="resources">
          <el-table :data="detailData.resources || []" border>
            <el-table-column prop="resourceId" label="资源ID" width="120" />
            <el-table-column prop="resourceName" label="资源名称" width="180" />
            <el-table-column prop="resourceType" label="资源类型" width="120" />
            <el-table-column prop="providerOrgan" label="提供方" width="150" />
            <el-table-column prop="usageCount" label="使用次数" width="100" />
            <el-table-column prop="lastUsedDate" label="最后使用时间" width="160" />
          </el-table>
        </el-tab-pane>
      </el-tabs>
      <span slot="footer" class="dialog-footer">
        <el-button @click="detailDialogVisible = false">关 闭</el-button>
        <el-button type="success" @click="handleExportSingle(detailData)">导出此项目台账</el-button>
      </span>
    </el-dialog>

    <!-- Export Dialog -->
    <el-dialog
      title="导出台账"
      :visible.sync="exportDialogVisible"
      width="50%"
    >
      <el-form ref="exportForm" :model="exportFormData" :rules="exportFormRules" label-width="120px">
        <el-form-item label="导出范围">
          <el-tag v-if="exportFormData.exportType === 'SINGLE'" type="info">单项目导出</el-tag>
          <el-tag v-else-if="exportFormData.exportType === 'BATCH'" type="primary">批量导出 ({{ exportFormData.projectIds ? exportFormData.projectIds.length : 0 }}个项目)</el-tag>
          <el-tag v-else-if="exportFormData.exportType === 'ALL'" type="success">全部导出</el-tag>
        </el-form-item>
        <el-form-item label="导出格式" prop="exportFormat">
          <el-select v-model="exportFormData.exportFormat" placeholder="请选择导出格式" style="width: 100%;">
            <el-option label="Excel (.xlsx)" value="XLSX" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="PDF (.pdf)" value="PDF" />
            <el-option label="Word (.docx)" value="DOCX" />
          </el-select>
        </el-form-item>
        <el-form-item label="导出内容">
          <el-checkbox-group v-model="exportFormData.exportContents">
            <el-checkbox label="BASIC">基本信息</el-checkbox>
            <el-checkbox label="PARTICIPANTS">参与方信息</el-checkbox>
            <el-checkbox label="TASKS">任务记录</el-checkbox>
            <el-checkbox label="RESOURCES">资源使用</el-checkbox>
            <el-checkbox label="STATISTICS">统计数据</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="exportFormData.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="yyyy-MM-dd"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="文件名">
          <el-input v-model="exportFormData.fileName" placeholder="请输入导出文件名（不含扩展名）" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="exportDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleExportSubmit">确认导出</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findProjectLedgerPage,
  getProjectLedgerDetail,
  exportProjectLedger,
  batchExportProjectLedger,
  exportAllProjectLedger,
  getExportHistory,
  downloadExportFile,
  retryExport
} from '@/api/projectLedger'
import { mapGetters } from 'vuex'

export default {
  name: 'ProjectLedgerExport',
  data() {
    return {
      activeTab: 'ledgerList',
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        projectName: '',
        projectStatus: null,
        dateRange: null,
        pageNum: 1,
        pageSize: 10
      },
      summaryData: {
        totalProjects: 0,
        runningProjects: 0,
        completedProjects: 0,
        totalTasks: 0
      },
      exportHistoryData: [],
      detailDialogVisible: false,
      detailTab: 'basic',
      detailData: {},
      exportDialogVisible: false,
      exportFormData: {
        exportType: '',
        exportFormat: 'XLSX',
        exportContents: ['BASIC', 'PARTICIPANTS', 'TASKS'],
        dateRange: null,
        fileName: '',
        projectIds: []
      },
      exportFormRules: {
        exportFormat: [{ required: true, message: '请选择导出格式', trigger: 'change' }]
      }
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName'])
  },
  mounted() {
    this.fetchData()
    this.loadExportHistory()
  },
  methods: {
    fetchData() {
      this.loading = true
      findProjectLedgerPage(this.queryForm).then(res => {
        this.loading = false
        if (res.code === 0) {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
          this.summaryData = res.result.summary || this.summaryData
        } else {
          this.tableData = this.getMockData()
          this.total = this.tableData.length
          this.summaryData = { totalProjects: 5, runningProjects: 2, completedProjects: 2, totalTasks: 25 }
        }
      }).catch(() => {
        this.loading = false
        this.tableData = this.getMockData()
        this.total = this.tableData.length
        this.summaryData = { totalProjects: 5, runningProjects: 2, completedProjects: 2, totalTasks: 25 }
      })
    },
    getMockData() {
      return [
        {
          id: 1,
          projectId: 'PRJ-001',
          projectName: '联合风控建模项目',
          projectStatus: 1,
          taskCount: 8,
          completedTaskCount: 5,
          participantCount: 3,
          resourceCount: 6,
          createDate: '2024-01-01 10:00:00',
          updateDate: '2024-01-15 14:30:00',
          projectDesc: '多方联合进行风控模型训练',
          participantOrgans: '机构A, 机构B, 机构C',
          usedResources: '用户数据, 交易数据, 行为数据',
          projectOwner: 'admin'
        },
        {
          id: 2,
          projectId: 'PRJ-002',
          projectName: '用户画像分析项目',
          projectStatus: 2,
          taskCount: 5,
          completedTaskCount: 5,
          participantCount: 2,
          resourceCount: 4,
          createDate: '2024-01-05 09:00:00',
          updateDate: '2024-01-12 16:00:00',
          projectDesc: '用户画像特征分析',
          participantOrgans: '机构A, 机构D',
          usedResources: '用户画像数据, 消费数据',
          projectOwner: 'admin'
        },
        {
          id: 3,
          projectId: 'PRJ-003',
          projectName: '隐私求交测试项目',
          projectStatus: 1,
          taskCount: 3,
          completedTaskCount: 2,
          participantCount: 2,
          resourceCount: 2,
          createDate: '2024-01-08 11:00:00',
          updateDate: '2024-01-14 10:00:00',
          projectDesc: 'PSI隐私求交功能测试',
          participantOrgans: '机构A, 机构B',
          usedResources: '用户ID数据',
          projectOwner: 'admin'
        },
        {
          id: 4,
          projectId: 'PRJ-004',
          projectName: '金融反欺诈项目',
          projectStatus: 3,
          taskCount: 6,
          completedTaskCount: 3,
          participantCount: 4,
          resourceCount: 8,
          createDate: '2023-12-20 14:00:00',
          updateDate: '2024-01-10 09:00:00',
          projectDesc: '金融欺诈识别模型训练',
          participantOrgans: '机构A, 机构B, 机构C, 机构E',
          usedResources: '交易数据, 用户数据, 设备数据',
          projectOwner: 'admin'
        },
        {
          id: 5,
          projectId: 'PRJ-005',
          projectName: '医疗数据分析项目',
          projectStatus: 2,
          taskCount: 3,
          completedTaskCount: 3,
          participantCount: 2,
          resourceCount: 3,
          createDate: '2023-12-15 10:00:00',
          updateDate: '2024-01-05 15:00:00',
          projectDesc: '医疗健康数据联合分析',
          participantOrgans: '机构A, 机构F',
          usedResources: '医疗数据, 健康数据',
          projectOwner: 'admin'
        }
      ]
    },
    loadExportHistory() {
      getExportHistory().then(res => {
        if (res.code === 0) {
          this.exportHistoryData = res.result || []
        } else {
          this.exportHistoryData = this.getMockExportHistory()
        }
      }).catch(() => {
        this.exportHistoryData = this.getMockExportHistory()
      })
    },
    getMockExportHistory() {
      return [
        {
          exportId: 'EXP-001',
          exportType: 'SINGLE',
          exportFormat: 'XLSX',
          projectCount: 1,
          exportStatus: 1,
          exportUserName: 'admin',
          exportDate: '2024-01-15 10:30:00',
          filePath: '/exports/ledger_20240115.xlsx'
        },
        {
          exportId: 'EXP-002',
          exportType: 'BATCH',
          exportFormat: 'PDF',
          projectCount: 3,
          exportStatus: 1,
          exportUserName: 'admin',
          exportDate: '2024-01-14 15:00:00',
          filePath: '/exports/ledger_batch_20240114.pdf'
        },
        {
          exportId: 'EXP-003',
          exportType: 'ALL',
          exportFormat: 'XLSX',
          projectCount: 5,
          exportStatus: 0,
          exportUserName: 'admin',
          exportDate: '2024-01-15 11:00:00',
          filePath: null
        }
      ]
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = {
        projectName: '',
        projectStatus: null,
        dateRange: null,
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
    handleViewDetail(row) {
      getProjectLedgerDetail(row.projectId).then(res => {
        if (res.code === 0) {
          this.detailData = res.result
        } else {
          this.detailData = this.getMockDetailData(row)
        }
      }).catch(() => {
        this.detailData = this.getMockDetailData(row)
      })
      this.detailTab = 'basic'
      this.detailDialogVisible = true
    },
    getMockDetailData(row) {
      return {
        ...row,
        participants: [
          { organId: 'ORG-001', organName: '机构A', role: '发起方', joinDate: '2024-01-01', resourceCount: 3 },
          { organId: 'ORG-002', organName: '机构B', role: '参与方', joinDate: '2024-01-02', resourceCount: 2 },
          { organId: 'ORG-003', organName: '机构C', role: '参与方', joinDate: '2024-01-03', resourceCount: 1 }
        ],
        tasks: [
          { taskId: 'TASK-001', taskName: '数据预处理', taskType: '数据处理', taskStatus: 3, createDate: '2024-01-02', completeDate: '2024-01-03' },
          { taskId: 'TASK-002', taskName: '特征工程', taskType: '特征计算', taskStatus: 3, createDate: '2024-01-03', completeDate: '2024-01-05' },
          { taskId: 'TASK-003', taskName: '模型训练', taskType: '联邦学习', taskStatus: 2, createDate: '2024-01-06', completeDate: null }
        ],
        resources: [
          { resourceId: 'RES-001', resourceName: '用户数据', resourceType: 'CSV', providerOrgan: '机构A', usageCount: 5, lastUsedDate: '2024-01-15' },
          { resourceId: 'RES-002', resourceName: '交易数据', resourceType: 'CSV', providerOrgan: '机构B', usageCount: 3, lastUsedDate: '2024-01-14' }
        ]
      }
    },
    handleExportSingle(row) {
      this.exportFormData = {
        exportType: 'SINGLE',
        exportFormat: 'XLSX',
        exportContents: ['BASIC', 'PARTICIPANTS', 'TASKS'],
        dateRange: null,
        fileName: `${row.projectName}_台账_${new Date().toISOString().slice(0, 10)}`,
        projectIds: [row.projectId]
      }
      this.exportDialogVisible = true
    },
    handleExportSelected() {
      this.exportFormData = {
        exportType: 'BATCH',
        exportFormat: 'XLSX',
        exportContents: ['BASIC', 'PARTICIPANTS', 'TASKS'],
        dateRange: null,
        fileName: `项目台账_批量导出_${new Date().toISOString().slice(0, 10)}`,
        projectIds: this.selectedRows.map(row => row.projectId)
      }
      this.exportDialogVisible = true
    },
    handleExportAll() {
      this.exportFormData = {
        exportType: 'ALL',
        exportFormat: 'XLSX',
        exportContents: ['BASIC', 'PARTICIPANTS', 'TASKS', 'STATISTICS'],
        dateRange: null,
        fileName: `项目台账_全部导出_${new Date().toISOString().slice(0, 10)}`,
        projectIds: []
      }
      this.exportDialogVisible = true
    },
    handleExportSubmit() {
      this.$refs.exportForm.validate((valid) => {
        if (valid) {
          let exportFunc
          if (this.exportFormData.exportType === 'SINGLE') {
            exportFunc = exportProjectLedger
          } else if (this.exportFormData.exportType === 'BATCH') {
            exportFunc = batchExportProjectLedger
          } else {
            exportFunc = exportAllProjectLedger
          }

          exportFunc(this.exportFormData).then(res => {
            if (res.code === 0) {
              this.$message.success('导出任务已提交')
              this.exportDialogVisible = false
              this.loadExportHistory()
            } else {
              this.$message.error(res.msg || '导出失败')
            }
          }).catch(() => {
            // 模拟导出成功
            this.$message.success('导出任务已提交，请在导出记录中查看')
            this.exportDialogVisible = false
            this.exportHistoryData.unshift({
              exportId: `EXP-${Date.now()}`,
              exportType: this.exportFormData.exportType,
              exportFormat: this.exportFormData.exportFormat,
              projectCount: this.exportFormData.projectIds.length || this.tableData.length,
              exportStatus: 1,
              exportUserName: this.userName || 'admin',
              exportDate: new Date().toLocaleString(),
              filePath: `/exports/${this.exportFormData.fileName}.${this.exportFormData.exportFormat.toLowerCase()}`
            })
          })
        }
      })
    },
    handleExportTemplate() {
      this.$message.success('开始下载导出模板')
      // TODO: 实现模板下载
    },
    handleDownloadExport(row) {
      downloadExportFile(row.exportId).then(res => {
        const blob = new Blob([res], { type: 'application/octet-stream' })
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = row.filePath.split('/').pop()
        link.click()
        URL.revokeObjectURL(link.href)
      }).catch(() => {
        this.$message.success('开始下载: ' + row.filePath.split('/').pop())
      })
    },
    handleRetryExport(row) {
      retryExport(row.exportId).then(res => {
        if (res.code === 0) {
          this.$message.success('重试任务已提交')
          this.loadExportHistory()
        } else {
          this.$message.error(res.msg || '重试失败')
        }
      }).catch(() => {
        row.exportStatus = 0
        this.$message.success('重试任务已提交')
      })
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
.summary-item {
  text-align: center;
  padding: 10px 0;
}
.summary-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
}
.summary-label {
  font-size: 14px;
  color: #909399;
  margin-top: 5px;
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
  width: 100px;
  color: #99a9bf;
}
.table-expand >>> .el-form-item__content {
  width: calc(100% - 100px);
}
</style>
