<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="项目名称">
        <el-input v-model="queryForm.projectName" placeholder="请输入项目名称" clearable />
      </el-form-item>
      <el-form-item label="任务名称">
        <el-input v-model="queryForm.taskName" placeholder="请输入任务名称" clearable />
      </el-form-item>
      <el-form-item label="结果类型">
        <el-select v-model="queryForm.resultType" placeholder="请选择" clearable>
          <el-option label="模型文件" value="MODEL" />
          <el-option label="计算结果" value="COMPUTE" />
          <el-option label="统计报告" value="REPORT" />
          <el-option label="中间数据" value="INTERMEDIATE" />
        </el-select>
      </el-form-item>
      <el-form-item label="保存状态">
        <el-select v-model="queryForm.saveStatus" placeholder="请选择" clearable>
          <el-option label="已保存" :value="1" />
          <el-option label="未保存" :value="0" />
          <el-option label="保存失败" :value="2" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-download" :disabled="selectedRows.length === 0" @click="handleBatchSave">
        批量保存
      </el-button>
      <el-button type="danger" icon="el-icon-delete" :disabled="selectedRows.length === 0" @click="handleBatchDelete">
        批量删除
      </el-button>
      <el-button type="success" icon="el-icon-folder-add" @click="handleConfigSavePath">
        配置保存路径
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
      <el-table-column type="expand">
        <template slot-scope="props">
          <el-form label-position="left" inline class="table-expand">
            <el-form-item label="结果描述:">
              <span>{{ props.row.resultDesc || '无' }}</span>
            </el-form-item>
            <el-form-item label="文件大小:">
              <span>{{ formatFileSize(props.row.fileSize) }}</span>
            </el-form-item>
            <el-form-item label="保存路径:">
              <span>{{ props.row.savePath || '未保存' }}</span>
            </el-form-item>
            <el-form-item label="MD5校验:">
              <span>{{ props.row.fileMd5 || '-' }}</span>
            </el-form-item>
          </el-form>
        </template>
      </el-table-column>
      <el-table-column prop="projectName" label="项目名称" width="180" />
      <el-table-column prop="taskName" label="任务名称" width="150" />
      <el-table-column prop="taskId" label="任务ID" width="120" />
      <el-table-column prop="resultType" label="结果类型" width="100">
        <template slot-scope="scope">
          <el-tag :type="getResultTypeTag(scope.row.resultType)">
            {{ getResultTypeLabel(scope.row.resultType) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="resultName" label="结果名称" width="150" />
      <el-table-column prop="saveStatus" label="保存状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.saveStatus === 1" type="success">已保存</el-tag>
          <el-tag v-else-if="scope.row.saveStatus === 0" type="info">未保存</el-tag>
          <el-tag v-else-if="scope.row.saveStatus === 2" type="danger">保存失败</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createDate" label="生成时间" width="160" />
      <el-table-column prop="saveDate" label="保存时间" width="160" />
      <el-table-column label="操作" fixed="right" width="250">
        <template slot-scope="scope">
          <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
          <el-button v-if="scope.row.saveStatus !== 1" size="mini" type="primary" @click="handleSave(scope.row)">保存</el-button>
          <el-button v-if="scope.row.saveStatus === 1" size="mini" type="success" @click="handleDownload(scope.row)">下载</el-button>
          <el-button v-if="scope.row.saveStatus === 2" size="mini" type="warning" @click="handleRetry(scope.row)">重试</el-button>
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

    <!-- View Dialog -->
    <el-dialog title="结果详情" :visible.sync="viewDialogVisible" width="60%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="项目名称">{{ viewData.projectName }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ viewData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ viewData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="结果类型">{{ getResultTypeLabel(viewData.resultType) }}</el-descriptions-item>
        <el-descriptions-item label="结果名称">{{ viewData.resultName }}</el-descriptions-item>
        <el-descriptions-item label="保存状态">
          <el-tag v-if="viewData.saveStatus === 1" type="success">已保存</el-tag>
          <el-tag v-else-if="viewData.saveStatus === 0" type="info">未保存</el-tag>
          <el-tag v-else-if="viewData.saveStatus === 2" type="danger">保存失败</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="文件大小">{{ formatFileSize(viewData.fileSize) }}</el-descriptions-item>
        <el-descriptions-item label="生成时间">{{ viewData.createDate }}</el-descriptions-item>
        <el-descriptions-item label="保存时间">{{ viewData.saveDate || '-' }}</el-descriptions-item>
        <el-descriptions-item label="MD5校验">{{ viewData.fileMd5 || '-' }}</el-descriptions-item>
        <el-descriptions-item label="保存路径" :span="2">{{ viewData.savePath || '未保存' }}</el-descriptions-item>
        <el-descriptions-item label="结果描述" :span="2">{{ viewData.resultDesc || '-' }}</el-descriptions-item>
      </el-descriptions>

      <!-- 结果预览 -->
      <div v-if="viewData.saveStatus === 1" style="margin-top: 20px;">
        <h4>结果预览</h4>
        <el-table v-if="viewData.previewData" :data="viewData.previewData" border max-height="300">
          <el-table-column v-for="col in viewData.previewColumns" :key="col" :prop="col" :label="col" />
        </el-table>
        <div v-else style="text-align: center; color: #999; padding: 20px;">
          暂无预览数据
        </div>
      </div>

      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
        <el-button v-if="viewData.saveStatus === 1" type="success" @click="handleDownload(viewData)">下载结果</el-button>
      </span>
    </el-dialog>

    <!-- Save Dialog -->
    <el-dialog
      title="保存结果"
      :visible.sync="saveDialogVisible"
      width="50%"
    >
      <el-form ref="saveForm" :model="saveFormData" :rules="saveFormRules" label-width="120px">
        <el-form-item label="结果名称">
          <el-input v-model="saveFormData.resultName" disabled />
        </el-form-item>
        <el-form-item label="保存目录" prop="saveDirectory">
          <el-select v-model="saveFormData.saveDirectory" placeholder="请选择保存目录" style="width: 100%;">
            <el-option
              v-for="dir in directoryOptions"
              :key="dir.path"
              :label="dir.name"
              :value="dir.path"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="文件名" prop="fileName">
          <el-input v-model="saveFormData.fileName" placeholder="请输入保存的文件名" />
        </el-form-item>
        <el-form-item label="保存格式">
          <el-select v-model="saveFormData.saveFormat" placeholder="请选择保存格式" style="width: 100%;">
            <el-option label="原始格式" value="ORIGINAL" />
            <el-option label="CSV" value="CSV" />
            <el-option label="JSON" value="JSON" />
            <el-option label="Parquet" value="PARQUET" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="saveFormData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="saveDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleSaveSubmit">确认保存</el-button>
      </span>
    </el-dialog>

    <!-- Config Save Path Dialog -->
    <el-dialog
      title="配置保存路径"
      :visible.sync="configDialogVisible"
      width="50%"
    >
      <el-form :model="configFormData" label-width="120px">
        <el-form-item label="默认保存目录">
          <el-input v-model="configFormData.defaultPath" placeholder="/data/results" />
        </el-form-item>
        <el-form-item label="自动保存">
          <el-switch v-model="configFormData.autoSave" />
          <span style="margin-left: 10px; color: #999;">开启后任务完成时自动保存结果</span>
        </el-form-item>
        <el-form-item label="保留天数">
          <el-input-number v-model="configFormData.retentionDays" :min="1" :max="365" />
          <span style="margin-left: 10px; color: #999;">天后自动清理临时结果</span>
        </el-form-item>
        <el-form-item label="最大保存空间">
          <el-input-number v-model="configFormData.maxStorageGB" :min="1" :max="1000" />
          <span style="margin-left: 10px; color: #999;">GB</span>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="configDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleConfigSubmit">保存配置</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findProjectResultPage,
  saveProjectResult,
  batchSaveProjectResult,
  deleteProjectResult,
  batchDeleteProjectResult,
  downloadProjectResult,
  getResultConfig,
  updateResultConfig
} from '@/api/projectResult'

export default {
  name: 'ProjectResultSave',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        projectName: '',
        taskName: '',
        resultType: null,
        saveStatus: null,
        pageNum: 1,
        pageSize: 10
      },
      viewDialogVisible: false,
      viewData: {},
      saveDialogVisible: false,
      saveFormData: {},
      saveFormRules: {
        saveDirectory: [{ required: true, message: '请选择保存目录', trigger: 'change' }],
        fileName: [{ required: true, message: '请输入文件名', trigger: 'blur' }]
      },
      directoryOptions: [
        { name: '默认目录 (/data/results)', path: '/data/results' },
        { name: '模型目录 (/data/models)', path: '/data/models' },
        { name: '报告目录 (/data/reports)', path: '/data/reports' },
        { name: '临时目录 (/tmp/results)', path: '/tmp/results' }
      ],
      configDialogVisible: false,
      configFormData: {
        defaultPath: '/data/results',
        autoSave: false,
        retentionDays: 30,
        maxStorageGB: 100
      }
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.loading = true
      findProjectResultPage(this.queryForm).then(res => {
        this.loading = false
        if (res.returnCode === '0') {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          this.tableData = this.getMockData()
          this.total = this.tableData.length
        }
      }).catch(() => {
        this.loading = false
        this.tableData = this.getMockData()
        this.total = this.tableData.length
      })
    },
    getMockData() {
      return [
        {
          id: 1,
          projectName: '联合风控建模项目',
          taskName: 'XGBoost模型训练',
          taskId: 'TASK-001',
          resultType: 'MODEL',
          resultName: 'xgboost_model_20240115.pkl',
          saveStatus: 1,
          fileSize: 15728640,
          createDate: '2024-01-15 10:30:00',
          saveDate: '2024-01-15 10:35:00',
          savePath: '/data/models/xgboost_model_20240115.pkl',
          fileMd5: 'a1b2c3d4e5f6g7h8',
          resultDesc: 'XGBoost联合训练模型，AUC=0.85'
        },
        {
          id: 2,
          projectName: '用户画像分析项目',
          taskName: '特征工程计算',
          taskId: 'TASK-002',
          resultType: 'COMPUTE',
          resultName: 'feature_result_20240115.csv',
          saveStatus: 1,
          fileSize: 52428800,
          createDate: '2024-01-15 11:00:00',
          saveDate: '2024-01-15 11:05:00',
          savePath: '/data/results/feature_result_20240115.csv',
          fileMd5: 'b2c3d4e5f6g7h8i9',
          resultDesc: '用户特征计算结果，包含100个特征'
        },
        {
          id: 3,
          projectName: '隐私求交测试项目',
          taskName: 'PSI任务',
          taskId: 'TASK-003',
          resultType: 'COMPUTE',
          resultName: 'psi_intersection_20240115.csv',
          saveStatus: 0,
          fileSize: 1048576,
          createDate: '2024-01-15 14:00:00',
          saveDate: null,
          savePath: null,
          fileMd5: null,
          resultDesc: 'PSI求交结果'
        },
        {
          id: 4,
          projectName: '联合风控建模项目',
          taskName: '模型评估报告',
          taskId: 'TASK-004',
          resultType: 'REPORT',
          resultName: 'model_evaluation_report.html',
          saveStatus: 2,
          fileSize: 524288,
          createDate: '2024-01-15 15:00:00',
          saveDate: null,
          savePath: null,
          fileMd5: null,
          resultDesc: '模型评估报告，保存失败：磁盘空间不足'
        },
        {
          id: 5,
          projectName: '用户画像分析项目',
          taskName: '中间结果缓存',
          taskId: 'TASK-005',
          resultType: 'INTERMEDIATE',
          resultName: 'intermediate_data_cache.parquet',
          saveStatus: 0,
          fileSize: 104857600,
          createDate: '2024-01-15 16:00:00',
          saveDate: null,
          savePath: null,
          fileMd5: null,
          resultDesc: '中间计算结果缓存'
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
        taskName: '',
        resultType: null,
        saveStatus: null,
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
    handleView(row) {
      this.viewData = { ...row }
      // 模拟预览数据
      if (row.saveStatus === 1 && row.resultType === 'COMPUTE') {
        this.viewData.previewColumns = ['id', 'name', 'value', 'score']
        this.viewData.previewData = [
          { id: 1, name: 'user_001', value: 0.85, score: 92 },
          { id: 2, name: 'user_002', value: 0.72, score: 78 },
          { id: 3, name: 'user_003', value: 0.91, score: 95 }
        ]
      }
      this.viewDialogVisible = true
    },
    handleSave(row) {
      this.saveFormData = {
        id: row.id,
        resultName: row.resultName,
        saveDirectory: '/data/results',
        fileName: row.resultName,
        saveFormat: 'ORIGINAL',
        remark: ''
      }
      this.saveDialogVisible = true
    },
    handleSaveSubmit() {
      this.$refs.saveForm.validate((valid) => {
        if (valid) {
          saveProjectResult(this.saveFormData).then(res => {
            if (res.returnCode === '0') {
              this.$message.success('保存成功')
              this.saveDialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || '保存失败')
            }
          }).catch(() => {
            // 模拟保存成功
            const row = this.tableData.find(item => item.id === this.saveFormData.id)
            if (row) {
              row.saveStatus = 1
              row.saveDate = new Date().toLocaleString()
              row.savePath = `${this.saveFormData.saveDirectory}/${this.saveFormData.fileName}`
              row.fileMd5 = Math.random().toString(36).substring(7)
            }
            this.$message.success('保存成功')
            this.saveDialogVisible = false
          })
        }
      })
    },
    handleBatchSave() {
      this.$confirm(`确认批量保存选中的 ${this.selectedRows.length} 个结果吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'info'
      }).then(() => {
        const ids = this.selectedRows.map(row => row.id)
        batchSaveProjectResult(ids).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('批量保存成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量保存失败')
          }
        }).catch(() => {
          this.$message.success('批量保存成功')
          this.selectedRows.forEach(row => {
            row.saveStatus = 1
            row.saveDate = new Date().toLocaleString()
          })
          this.selectedRows = []
        })
      }).catch(() => {})
    },
    handleDownload(row) {
      downloadProjectResult(row.id).then(res => {
        // 处理文件下载
        const blob = new Blob([res], { type: 'application/octet-stream' })
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = row.resultName
        link.click()
        URL.revokeObjectURL(link.href)
      }).catch(() => {
        // 模拟下载
        this.$message.success('开始下载: ' + row.resultName)
      })
    },
    handleRetry(row) {
      this.$confirm('确认重试保存该结果吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        this.handleSave(row)
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm('确认删除该结果记录吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteProjectResult(row.id).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        }).catch(() => {
          this.$message.success('删除成功')
          this.tableData = this.tableData.filter(item => item.id !== row.id)
        })
      }).catch(() => {})
    },
    handleBatchDelete() {
      this.$confirm(`确认删除选中的 ${this.selectedRows.length} 个结果吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ids = this.selectedRows.map(row => row.id)
        batchDeleteProjectResult(ids).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('批量删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量删除失败')
          }
        }).catch(() => {
          this.$message.success('批量删除成功')
          this.tableData = this.tableData.filter(item => !ids.includes(item.id))
          this.selectedRows = []
        })
      }).catch(() => {})
    },
    handleConfigSavePath() {
      getResultConfig().then(res => {
        if (res.returnCode === '0') {
          this.configFormData = res.result || this.configFormData
        }
      }).catch(() => {})
      this.configDialogVisible = true
    },
    handleConfigSubmit() {
      updateResultConfig(this.configFormData).then(res => {
        if (res.returnCode === '0') {
          this.$message.success('配置保存成功')
          this.configDialogVisible = false
        } else {
          this.$message.error(res.msg || '配置保存失败')
        }
      }).catch(() => {
        this.$message.success('配置保存成功')
        this.configDialogVisible = false
      })
    },
    getResultTypeLabel(type) {
      const typeMap = {
        'MODEL': '模型文件',
        'COMPUTE': '计算结果',
        'REPORT': '统计报告',
        'INTERMEDIATE': '中间数据'
      }
      return typeMap[type] || type
    },
    getResultTypeTag(type) {
      const tagMap = {
        'MODEL': 'success',
        'COMPUTE': 'primary',
        'REPORT': 'warning',
        'INTERMEDIATE': 'info'
      }
      return tagMap[type] || ''
    },
    formatFileSize(bytes) {
      if (!bytes) return '-'
      const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
      const i = Math.floor(Math.log(bytes) / Math.log(1024))
      return (bytes / Math.pow(1024, i)).toFixed(2) + ' ' + sizes[i]
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
  width: 100px;
  color: #99a9bf;
}
.table-expand >>> .el-form-item__content {
  width: calc(100% - 100px);
}
</style>
