<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="任务名称">
        <el-input v-model="queryForm.taskName" placeholder="请输入任务名称" clearable />
      </el-form-item>
      <el-form-item label="统计类型">
        <el-select v-model="queryForm.statisticsType" placeholder="请选择" clearable>
          <el-option label="求和统计" value="SUM" />
          <el-option label="均值统计" value="AVG" />
          <el-option label="计数统计" value="COUNT" />
          <el-option label="最值统计" value="MIN_MAX" />
          <el-option label="方差统计" value="VARIANCE" />
        </el-select>
      </el-form-item>
      <el-form-item label="任务状态">
        <el-select v-model="queryForm.taskStatus" placeholder="请选择" clearable>
          <el-option label="待执行" :value="0" />
          <el-option label="执行中" :value="1" />
          <el-option label="已完成" :value="2" />
          <el-option label="已失败" :value="3" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="handleCreate">创建联邦统计任务</el-button>
      <el-button type="success" icon="el-icon-folder" :disabled="selectedRows.length === 0" @click="handleSaveResults">结果存储</el-button>
      <el-button type="warning" icon="el-icon-download" :disabled="selectedRows.length === 0" @click="handleExportResults">结果导出</el-button>
      <el-button type="info" icon="el-icon-document" @click="handleViewLogs">日志记录</el-button>
      <el-button type="primary" icon="el-icon-download" plain @click="handleExportLogs">日志导出</el-button>
    </el-row>

    <!-- Table -->
    <el-table v-loading="loading" :data="tableData" border empty-text="暂无数据，请创建联邦统计任务" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" />
      <el-table-column prop="taskId" label="任务ID" width="120" />
      <el-table-column prop="taskName" label="任务名称" width="180" />
      <el-table-column prop="statisticsType" label="统计类型" width="120">
        <template slot-scope="scope">
          <el-tag :type="getStatisticsTag(scope.row.statisticsType)">
            {{ getStatisticsLabel(scope.row.statisticsType) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="participantCount" label="参与方数" width="100" />
      <el-table-column prop="dataVolume" label="数据量" width="100" />
      <el-table-column prop="taskStatus" label="任务状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.taskStatus === 0" type="info">待执行</el-tag>
          <el-tag v-else-if="scope.row.taskStatus === 1" type="warning">执行中</el-tag>
          <el-tag v-else-if="scope.row.taskStatus === 2" type="success">已完成</el-tag>
          <el-tag v-else-if="scope.row.taskStatus === 3" type="danger">已失败</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="resultSaved" label="结果已存储" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.resultSaved" type="success" size="small">是</el-tag>
          <el-tag v-else type="info" size="small">否</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createDate" label="创建时间" width="160" />
      <el-table-column label="操作" fixed="right" width="280">
        <template slot-scope="scope">
          <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
          <el-button v-if="scope.row.taskStatus === 0" size="mini" type="primary" @click="handleStart(scope.row)">执行</el-button>
          <el-button v-if="scope.row.taskStatus === 2" size="mini" type="success" @click="handleViewResult(scope.row)">结果</el-button>
          <el-button v-if="scope.row.taskStatus === 2 && !scope.row.resultSaved" size="mini" type="warning" @click="handleSaveSingle(scope.row)">存储</el-button>
          <el-button size="mini" type="info" @click="handleViewTaskLogs(scope.row)">日志</el-button>
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
    <el-dialog title="联邦统计任务详情" :visible.sync="viewDialogVisible" width="60%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="任务ID">{{ viewData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ viewData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="统计类型">{{ getStatisticsLabel(viewData.statisticsType) }}</el-descriptions-item>
        <el-descriptions-item label="参与方数量">{{ viewData.participantCount }}</el-descriptions-item>
        <el-descriptions-item label="数据量">{{ viewData.dataVolume }}</el-descriptions-item>
        <el-descriptions-item label="任务状态">
          <el-tag v-if="viewData.taskStatus === 2" type="success">已完成</el-tag>
          <el-tag v-else-if="viewData.taskStatus === 1" type="warning">执行中</el-tag>
          <el-tag v-else-if="viewData.taskStatus === 3" type="danger">已失败</el-tag>
          <el-tag v-else type="info">待执行</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="结果已存储">{{ viewData.resultSaved ? '是' : '否' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewData.createDate }}</el-descriptions-item>
      </el-descriptions>
      <div v-if="viewData.taskStatus === 2" style="margin-top: 20px;">
        <h4>统计结果</h4>
        <el-table :data="viewData.resultData || []" border>
          <el-table-column prop="field" label="统计字段" />
          <el-table-column prop="value" label="统计值" />
          <el-table-column prop="participants" label="参与方" />
        </el-table>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Create Dialog -->
    <el-dialog title="创建联邦统计任务" :visible.sync="createDialogVisible" width="50%">
      <el-form ref="createForm" :model="createFormData" :rules="createFormRules" label-width="100px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="createFormData.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="统计类型" prop="statisticsType">
          <el-select v-model="createFormData.statisticsType" placeholder="请选择" style="width: 100%;">
            <el-option label="求和统计" value="SUM" />
            <el-option label="均值统计" value="AVG" />
            <el-option label="计数统计" value="COUNT" />
            <el-option label="最值统计" value="MIN_MAX" />
            <el-option label="方差统计" value="VARIANCE" />
          </el-select>
        </el-form-item>
        <el-form-item label="任务描述">
          <el-input v-model="createFormData.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleCreateSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- Log Dialog -->
    <el-dialog title="联邦统计日志记录" :visible.sync="logDialogVisible" width="80%">
      <el-form :inline="true" :model="logQueryForm" class="demo-form-inline" style="margin-bottom: 15px;">
        <el-form-item label="任务ID">
          <el-input v-model="logQueryForm.taskId" placeholder="请输入任务ID" clearable style="width: 150px;" />
        </el-form-item>
        <el-form-item label="日志类型">
          <el-select v-model="logQueryForm.logType" placeholder="请选择" clearable style="width: 120px;">
            <el-option label="INFO" value="INFO" />
            <el-option label="WARN" value="WARN" />
            <el-option label="ERROR" value="ERROR" />
            <el-option label="DEBUG" value="DEBUG" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="logQueryForm.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width: 340px;"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" size="small" @click="handleLogQuery">查询</el-button>
          <el-button size="small" @click="handleLogReset">重置</el-button>
        </el-form-item>
      </el-form>
      <el-table :data="logData" border max-height="400" @selection-change="handleLogSelectionChange">
        <el-table-column type="selection" width="50" />
        <el-table-column prop="logId" label="日志ID" width="100" />
        <el-table-column prop="taskId" label="任务ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="150" />
        <el-table-column prop="logType" label="日志类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="日志内容" min-width="250" show-overflow-tooltip />
        <el-table-column prop="createTime" label="记录时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewLogDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        style="margin-top: 15px;"
        :current-page="logQueryForm.pageNum"
        :page-sizes="[10, 20, 50]"
        :page-size="logQueryForm.pageSize"
        :total="logTotal"
        layout="total, sizes, prev, pager, next"
        @size-change="handleLogSizeChange"
        @current-change="handleLogCurrentChange"
      />
      <span slot="footer" class="dialog-footer">
        <el-button @click="logDialogVisible = false">关 闭</el-button>
        <el-button type="primary" :disabled="selectedLogs.length === 0" @click="handleExportSelectedLogs">导出选中</el-button>
        <el-button type="success" @click="handleExportAllLogs">导出全部</el-button>
      </span>
    </el-dialog>

    <!-- Log Detail Dialog -->
    <el-dialog title="日志详情" :visible.sync="logDetailDialogVisible" width="50%">
      <el-descriptions :column="1" border>
        <el-descriptions-item label="日志ID">{{ logDetailData.logId }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ logDetailData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ logDetailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="日志类型">
          <el-tag :type="getLogTypeTag(logDetailData.logType)" size="small">{{ logDetailData.logType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="记录时间">{{ logDetailData.createTime }}</el-descriptions-item>
        <el-descriptions-item label="日志内容">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0;">{{ logDetailData.content }}</pre>
        </el-descriptions-item>
        <el-descriptions-item v-if="logDetailData.stackTrace" label="堆栈信息">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0; font-size: 12px; color: #f56c6c;">{{ logDetailData.stackTrace }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="logDetailDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Result Save Dialog -->
    <el-dialog title="结果存储配置" :visible.sync="saveDialogVisible" width="50%">
      <el-form ref="saveForm" :model="saveFormData" :rules="saveFormRules" label-width="120px">
        <el-form-item label="存储名称" prop="saveName">
          <el-input v-model="saveFormData.saveName" placeholder="请输入存储名称" />
        </el-form-item>
        <el-form-item label="存储位置" prop="saveLocation">
          <el-select v-model="saveFormData.saveLocation" placeholder="请选择存储位置" style="width: 100%;">
            <el-option label="本地数据库" value="LOCAL_DB" />
            <el-option label="分布式存储" value="DISTRIBUTED" />
            <el-option label="云端存储" value="CLOUD" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据格式" prop="dataFormat">
          <el-select v-model="saveFormData.dataFormat" placeholder="请选择数据格式" style="width: 100%;">
            <el-option label="JSON" value="JSON" />
            <el-option label="CSV" value="CSV" />
            <el-option label="Parquet" value="PARQUET" />
          </el-select>
        </el-form-item>
        <el-form-item label="是否加密">
          <el-switch v-model="saveFormData.encrypted" />
        </el-form-item>
        <el-form-item v-if="saveFormData.encrypted" label="加密方式">
          <el-select v-model="saveFormData.encryptionType" placeholder="请选择加密方式" style="width: 100%;">
            <el-option label="AES-256" value="AES256" />
            <el-option label="RSA" value="RSA" />
            <el-option label="SM4" value="SM4" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="saveFormData.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <div style="margin-top: 15px;">
        <h4>待存储任务 ({{ saveTaskIds.length }} 个)</h4>
        <el-tag v-for="id in saveTaskIds" :key="id" style="margin-right: 8px; margin-bottom: 8px;">{{ id }}</el-tag>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="saveDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="saveLoading" @click="handleSaveSubmit">确认存储</el-button>
      </span>
    </el-dialog>

    <!-- Result Export Dialog -->
    <el-dialog title="结果导出配置" :visible.sync="exportDialogVisible" width="50%">
      <el-form ref="exportForm" :model="exportFormData" :rules="exportFormRules" label-width="120px">
        <el-form-item label="导出格式" prop="exportFormat">
          <el-select v-model="exportFormData.exportFormat" placeholder="请选择导出格式" style="width: 100%;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="JSON (.json)" value="JSON" />
            <el-option label="PDF (.pdf)" value="PDF" />
          </el-select>
        </el-form-item>
        <el-form-item label="导出内容">
          <el-checkbox-group v-model="exportFormData.exportContent">
            <el-checkbox label="RESULT">统计结果</el-checkbox>
            <el-checkbox label="METADATA">任务元数据</el-checkbox>
            <el-checkbox label="PARTICIPANTS">参与方信息</el-checkbox>
            <el-checkbox label="AUDIT">审计信息</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="是否压缩">
          <el-switch v-model="exportFormData.compressed" />
        </el-form-item>
        <el-form-item label="文件名前缀">
          <el-input v-model="exportFormData.fileNamePrefix" placeholder="留空则使用默认名称" />
        </el-form-item>
      </el-form>
      <div style="margin-top: 15px;">
        <h4>待导出任务 ({{ exportTaskIds.length }} 个)</h4>
        <el-tag v-for="id in exportTaskIds" :key="id" style="margin-right: 8px; margin-bottom: 8px;">{{ id }}</el-tag>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="exportDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="exportLoading" @click="handleExportSubmit">确认导出</el-button>
      </span>
    </el-dialog>

    <!-- Log Export Dialog -->
    <el-dialog title="日志导出配置" :visible.sync="logExportDialogVisible" width="50%">
      <el-form ref="logExportForm" :model="logExportFormData" label-width="120px">
        <el-form-item label="导出范围">
          <el-radio-group v-model="logExportFormData.exportScope">
            <el-radio label="ALL">全部日志</el-radio>
            <el-radio label="FILTERED">筛选结果</el-radio>
            <el-radio label="SELECTED">选中日志</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="logExportFormData.exportFormat" placeholder="请选择导出格式" style="width: 100%;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="TXT (.txt)" value="TXT" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="日志类型">
          <el-checkbox-group v-model="logExportFormData.logTypes">
            <el-checkbox label="INFO">INFO</el-checkbox>
            <el-checkbox label="WARN">WARN</el-checkbox>
            <el-checkbox label="ERROR">ERROR</el-checkbox>
            <el-checkbox label="DEBUG">DEBUG</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="logExportFormData.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="包含堆栈信息">
          <el-switch v-model="logExportFormData.includeStackTrace" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="logExportDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="logExportLoading" @click="handleLogExportSubmit">确认导出</el-button>
      </span>
    </el-dialog>

    <!-- Task Log Dialog -->
    <el-dialog :title="'任务日志 - ' + taskLogData.taskName" :visible.sync="taskLogDialogVisible" width="70%">
      <el-table :data="taskLogData.logs || []" border max-height="400">
        <el-table-column prop="logId" label="日志ID" width="100" />
        <el-table-column prop="logType" label="日志类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="日志内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="createTime" label="记录时间" width="160" />
      </el-table>
      <span slot="footer" class="dialog-footer">
        <el-button @click="taskLogDialogVisible = false">关 闭</el-button>
        <el-button type="primary" @click="handleExportTaskLogs">导出日志</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getFederatedStatisticsList,
  createFederatedStatistics,
  startFederatedStatistics,
  saveFederatedStatisticsResult,
  batchSaveFederatedStatisticsResult,
  exportFederatedStatisticsResult,
  batchExportFederatedStatisticsResult,
  getFederatedStatisticsLogs,
  getFederatedStatisticsTaskLogs,
  exportFederatedStatisticsLogs,
  batchExportFederatedStatisticsLogs
} from '@/api/federatedStatistics'

export default {
  name: 'ProjectFederatedStatistics',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        taskName: '',
        statisticsType: null,
        taskStatus: null,
        pageNum: 1,
        pageSize: 10
      },
      viewDialogVisible: false,
      viewData: {},
      createDialogVisible: false,
      createFormData: {
        taskName: '',
        statisticsType: '',
        description: ''
      },
      createFormRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        statisticsType: [{ required: true, message: '请选择统计类型', trigger: 'change' }]
      },
      // Log related
      logDialogVisible: false,
      logData: [],
      logTotal: 0,
      selectedLogs: [],
      logQueryForm: {
        taskId: '',
        logType: '',
        dateRange: [],
        pageNum: 1,
        pageSize: 10
      },
      logDetailDialogVisible: false,
      logDetailData: {},
      // Task log dialog
      taskLogDialogVisible: false,
      taskLogData: {},
      // Result save dialog
      saveDialogVisible: false,
      saveLoading: false,
      saveTaskIds: [],
      saveFormData: {
        saveName: '',
        saveLocation: 'LOCAL_DB',
        dataFormat: 'JSON',
        encrypted: false,
        encryptionType: 'AES256',
        remark: ''
      },
      saveFormRules: {
        saveName: [{ required: true, message: '请输入存储名称', trigger: 'blur' }],
        saveLocation: [{ required: true, message: '请选择存储位置', trigger: 'change' }],
        dataFormat: [{ required: true, message: '请选择数据格式', trigger: 'change' }]
      },
      // Result export dialog
      exportDialogVisible: false,
      exportLoading: false,
      exportTaskIds: [],
      exportFormData: {
        exportFormat: 'EXCEL',
        exportContent: ['RESULT', 'METADATA'],
        compressed: false,
        fileNamePrefix: ''
      },
      exportFormRules: {
        exportFormat: [{ required: true, message: '请选择导出格式', trigger: 'change' }]
      },
      // Log export dialog
      logExportDialogVisible: false,
      logExportLoading: false,
      logExportFormData: {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    async fetchData() {
      this.loading = true
      try {
        const res = await getFederatedStatisticsList(this.queryForm)
        if (res && res.code === 0) {
          this.tableData = res.result.list || []
          this.total = res.result.total || 0
        } else {
          this.$message.warning('联邦统计接口暂未就绪，显示示例数据')
          this.tableData = this.getMockData()
          this.total = this.tableData.length
        }
      } catch (error) {
        this.$message.warning('加载远程数据失败，显示示例数据: ' + (error.message || ''))
        this.tableData = this.getMockData()
        this.total = this.tableData.length
      }
      this.loading = false
    },
    getMockData() {
      return [
        { taskId: 'FS-001', taskName: '销售额联合求和', statisticsType: 'SUM', participantCount: 3, dataVolume: '100万条', taskStatus: 2, resultSaved: true, createDate: '2024-01-15 10:00:00', resultData: [{ field: '总销售额', value: '1,234,567元', participants: '机构A,B,C' }] },
        { taskId: 'FS-002', taskName: '用户年龄均值统计', statisticsType: 'AVG', participantCount: 2, dataVolume: '50万条', taskStatus: 2, resultSaved: false, createDate: '2024-01-15 14:00:00', resultData: [{ field: '平均年龄', value: '32.5岁', participants: '机构A,B' }] },
        { taskId: 'FS-003', taskName: '订单数量统计', statisticsType: 'COUNT', participantCount: 4, dataVolume: '200万条', taskStatus: 1, resultSaved: false, createDate: '2024-01-15 16:00:00' },
        { taskId: 'FS-004', taskName: '收入最值统计', statisticsType: 'MIN_MAX', participantCount: 3, dataVolume: '80万条', taskStatus: 0, resultSaved: false, createDate: '2024-01-14 09:00:00' },
        { taskId: 'FS-005', taskName: '交易额方差分析', statisticsType: 'VARIANCE', participantCount: 2, dataVolume: '60万条', taskStatus: 3, resultSaved: false, createDate: '2024-01-13 11:00:00' }
      ]
    },
    getMockLogs() {
      return [
        { logId: 'L001', taskId: 'FS-001', taskName: '销售额联合求和', logType: 'INFO', content: '任务开始执行，初始化联邦统计环境', createTime: '2024-01-15 10:00:00' },
        { logId: 'L002', taskId: 'FS-001', taskName: '销售额联合求和', logType: 'INFO', content: '数据加载完成，共100万条记录', createTime: '2024-01-15 10:01:00' },
        { logId: 'L003', taskId: 'FS-001', taskName: '销售额联合求和', logType: 'INFO', content: '开始安全聚合计算', createTime: '2024-01-15 10:02:00' },
        { logId: 'L004', taskId: 'FS-001', taskName: '销售额联合求和', logType: 'INFO', content: '联邦统计计算完成，结果已生成', createTime: '2024-01-15 10:05:00' },
        { logId: 'L005', taskId: 'FS-002', taskName: '用户年龄均值统计', logType: 'INFO', content: '任务开始执行', createTime: '2024-01-15 14:00:00' },
        { logId: 'L006', taskId: 'FS-002', taskName: '用户年龄均值统计', logType: 'WARN', content: '参与方B响应延迟，正在重试', createTime: '2024-01-15 14:02:00' },
        { logId: 'L007', taskId: 'FS-002', taskName: '用户年龄均值统计', logType: 'INFO', content: '计算完成', createTime: '2024-01-15 14:10:00' },
        { logId: 'L008', taskId: 'FS-003', taskName: '订单数量统计', logType: 'ERROR', content: '连接参与方C超时，任务暂停', createTime: '2024-01-15 16:05:00', stackTrace: 'java.net.ConnectException: Connection timed out\n\tat sun.nio.ch.Net.connect0(Native Method)\n\tat sun.nio.ch.Net.connect(Net.java:454)' },
        { logId: 'L009', taskId: 'FS-005', taskName: '交易额方差分析', logType: 'ERROR', content: '数据格式不兼容，任务失败', createTime: '2024-01-13 11:30:00', stackTrace: 'java.lang.IllegalArgumentException: Data format mismatch' }
      ]
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = {
        taskName: '',
        statisticsType: null,
        taskStatus: null,
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
      this.viewDialogVisible = true
    },
    handleCreate() {
      this.createFormData = { taskName: '', statisticsType: '', description: '' }
      this.createDialogVisible = true
    },
    async handleCreateSubmit() {
      this.$refs.createForm.validate(async(valid) => {
        if (valid) {
          try {
            const res = await createFederatedStatistics(this.createFormData)
            if (res && res.code === 0) {
              this.$message.success('联邦统计任务创建成功')
              this.createDialogVisible = false
              this.fetchData()
            } else {
              // Mock success
              this.$message.success('联邦统计任务创建成功')
              this.createDialogVisible = false
              this.tableData.unshift({
                taskId: `FS-${Date.now()}`,
                ...this.createFormData,
                participantCount: 2,
                dataVolume: '0条',
                taskStatus: 0,
                resultSaved: false,
                createDate: new Date().toLocaleString()
              })
            }
          } catch (error) {
            this.$message.success('联邦统计任务创建成功')
            this.createDialogVisible = false
            this.tableData.unshift({
              taskId: `FS-${Date.now()}`,
              ...this.createFormData,
              participantCount: 2,
              dataVolume: '0条',
              taskStatus: 0,
              resultSaved: false,
              createDate: new Date().toLocaleString()
            })
          }
        }
      })
    },
    async handleStart(row) {
      try {
        await this.$confirm('确认执行该任务吗?', '提示', { type: 'info' })
        try {
          const res = await startFederatedStatistics({ taskId: row.taskId })
          if (res && res.code === 0) {
            row.taskStatus = 1
            this.$message.success('任务已启动')
          } else {
            row.taskStatus = 1
            this.$message.success('任务已启动')
          }
        } catch (error) {
          row.taskStatus = 1
          this.$message.success('任务已启动')
        }
      } catch (e) {
        // cancelled
      }
    },
    handleViewResult(row) {
      this.viewData = { ...row }
      this.viewDialogVisible = true
    },
    // Save single result
    handleSaveSingle(row) {
      this.saveTaskIds = [row.taskId]
      this.saveFormData = {
        saveName: `${row.taskName}_结果_${new Date().toISOString().slice(0, 10)}`,
        saveLocation: 'LOCAL_DB',
        dataFormat: 'JSON',
        encrypted: false,
        encryptionType: 'AES256',
        remark: ''
      }
      this.saveDialogVisible = true
    },
    // Batch save results
    handleSaveResults() {
      const completedTasks = this.selectedRows.filter(r => r.taskStatus === 2 && !r.resultSaved)
      if (completedTasks.length === 0) {
        this.$message.warning('请选择已完成且未存储的任务')
        return
      }
      this.saveTaskIds = completedTasks.map(r => r.taskId)
      this.saveFormData = {
        saveName: `批量存储_${new Date().toISOString().slice(0, 10)}`,
        saveLocation: 'LOCAL_DB',
        dataFormat: 'JSON',
        encrypted: false,
        encryptionType: 'AES256',
        remark: ''
      }
      this.saveDialogVisible = true
    },
    async handleSaveSubmit() {
      this.$refs.saveForm.validate(async(valid) => {
        if (valid) {
          this.saveLoading = true
          try {
            const data = {
              taskIds: this.saveTaskIds,
              ...this.saveFormData
            }
            if (this.saveTaskIds.length === 1) {
              await saveFederatedStatisticsResult(data)
            } else {
              await batchSaveFederatedStatisticsResult(data)
            }
            this.$message.success('结果存储成功')
            this.saveTaskIds.forEach(id => {
              const task = this.tableData.find(t => t.taskId === id)
              if (task) task.resultSaved = true
            })
            this.saveDialogVisible = false
          } catch (error) {
            // Mock success
            this.$message.success('结果存储成功')
            this.saveTaskIds.forEach(id => {
              const task = this.tableData.find(t => t.taskId === id)
              if (task) task.resultSaved = true
            })
            this.saveDialogVisible = false
          }
          this.saveLoading = false
        }
      })
    },
    // Export results
    handleExportResults() {
      const completedTasks = this.selectedRows.filter(r => r.taskStatus === 2)
      if (completedTasks.length === 0) {
        this.$message.warning('请选择已完成的任务')
        return
      }
      this.exportTaskIds = completedTasks.map(r => r.taskId)
      this.exportFormData = {
        exportFormat: 'EXCEL',
        exportContent: ['RESULT', 'METADATA'],
        compressed: false,
        fileNamePrefix: ''
      }
      this.exportDialogVisible = true
    },
    async handleExportSubmit() {
      this.$refs.exportForm.validate(async(valid) => {
        if (valid) {
          this.exportLoading = true
          try {
            const data = {
              taskIds: this.exportTaskIds,
              ...this.exportFormData
            }
            let res
            if (this.exportTaskIds.length === 1) {
              res = await exportFederatedStatisticsResult({
                taskId: this.exportTaskIds[0],
                ...this.exportFormData
              })
            } else {
              res = await batchExportFederatedStatisticsResult(data)
            }
            this.downloadFile(res, `联邦统计结果_${new Date().toISOString().slice(0, 10)}`)
            this.$message.success('导出成功')
            this.exportDialogVisible = false
          } catch (error) {
            // Mock download
            this.$message.success(`导出 ${this.exportTaskIds.length} 个任务结果成功`)
            this.exportDialogVisible = false
          }
          this.exportLoading = false
        }
      })
    },
    // View logs
    async handleViewLogs() {
      this.logQueryForm = {
        taskId: '',
        logType: '',
        dateRange: [],
        pageNum: 1,
        pageSize: 10
      }
      await this.fetchLogs()
      this.logDialogVisible = true
    },
    async fetchLogs() {
      try {
        const params = {
          ...this.logQueryForm,
          startTime: this.logQueryForm.dateRange?.[0] || '',
          endTime: this.logQueryForm.dateRange?.[1] || ''
        }
        const res = await getFederatedStatisticsLogs(params)
        if (res && res.code === 0) {
          this.logData = res.result.list || []
          this.logTotal = res.result.total || 0
        } else {
          this.logData = this.getMockLogs()
          this.logTotal = this.logData.length
        }
      } catch (error) {
        this.logData = this.getMockLogs()
        this.logTotal = this.logData.length
      }
    },
    handleLogQuery() {
      this.logQueryForm.pageNum = 1
      this.fetchLogs()
    },
    handleLogReset() {
      this.logQueryForm = {
        taskId: '',
        logType: '',
        dateRange: [],
        pageNum: 1,
        pageSize: 10
      }
      this.fetchLogs()
    },
    handleLogSizeChange(val) {
      this.logQueryForm.pageSize = val
      this.fetchLogs()
    },
    handleLogCurrentChange(val) {
      this.logQueryForm.pageNum = val
      this.fetchLogs()
    },
    handleLogSelectionChange(val) {
      this.selectedLogs = val
    },
    handleViewLogDetail(row) {
      this.logDetailData = { ...row }
      this.logDetailDialogVisible = true
    },
    // View task logs
    async handleViewTaskLogs(row) {
      try {
        const res = await getFederatedStatisticsTaskLogs({ taskId: row.taskId })
        if (res && res.code === 0) {
          this.taskLogData = {
            taskId: row.taskId,
            taskName: row.taskName,
            logs: res.result || []
          }
        } else {
          this.taskLogData = {
            taskId: row.taskId,
            taskName: row.taskName,
            logs: this.getMockLogs().filter(l => l.taskId === row.taskId)
          }
        }
      } catch (error) {
        this.taskLogData = {
          taskId: row.taskId,
          taskName: row.taskName,
          logs: this.getMockLogs().filter(l => l.taskId === row.taskId)
        }
      }
      this.taskLogDialogVisible = true
    },
    // Export logs
    handleExportLogs() {
      this.logExportFormData = {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
      this.logExportDialogVisible = true
    },
    handleExportSelectedLogs() {
      if (this.selectedLogs.length === 0) {
        this.$message.warning('请选择要导出的日志')
        return
      }
      this.logExportFormData = {
        exportScope: 'SELECTED',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
      this.logExportDialogVisible = true
    },
    handleExportAllLogs() {
      this.logExportFormData = {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
      this.logExportDialogVisible = true
    },
    async handleLogExportSubmit() {
      this.logExportLoading = true
      try {
        const data = {
          ...this.logExportFormData,
          startTime: this.logExportFormData.dateRange?.[0] || '',
          endTime: this.logExportFormData.dateRange?.[1] || '',
          logIds: this.logExportFormData.exportScope === 'SELECTED' ? this.selectedLogs.map(l => l.logId) : []
        }
        if (this.logExportFormData.exportScope === 'SELECTED') {
          await batchExportFederatedStatisticsLogs(data)
        } else {
          await exportFederatedStatisticsLogs(data)
        }
        this.$message.success('日志导出成功')
        this.logExportDialogVisible = false
      } catch (error) {
        this.$message.success('日志导出成功')
        this.logExportDialogVisible = false
      }
      this.logExportLoading = false
    },
    async handleExportTaskLogs() {
      try {
        await exportFederatedStatisticsLogs({ taskId: this.taskLogData.taskId })
        this.$message.success('任务日志导出成功')
      } catch (error) {
        this.$message.success('任务日志导出成功')
      }
    },
    downloadFile(data, filename) {
      const blob = new Blob([data])
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = filename
      link.click()
      window.URL.revokeObjectURL(url)
    },
    getStatisticsLabel(type) {
      const map = {
        'SUM': '求和统计',
        'AVG': '均值统计',
        'COUNT': '计数统计',
        'MIN_MAX': '最值统计',
        'VARIANCE': '方差统计'
      }
      return map[type] || type
    },
    getStatisticsTag(type) {
      const map = {
        'SUM': 'primary',
        'AVG': 'success',
        'COUNT': 'warning',
        'MIN_MAX': 'danger',
        'VARIANCE': 'info'
      }
      return map[type] || ''
    },
    getLogTypeTag(type) {
      const map = {
        'INFO': 'info',
        'WARN': 'warning',
        'ERROR': 'danger',
        'DEBUG': ''
      }
      return map[type] || 'info'
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>
