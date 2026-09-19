<template>
  <div class="app-container">
    <!-- Tab Navigation -->
    <el-tabs v-model="activeTab" type="card" @tab-click="handleTabClick">
      <el-tab-pane label="联邦学习任务" name="tasks" />
      <el-tab-pane label="建模工作台" name="workbench" />
      <el-tab-pane label="参数调优" name="tuning" />
      <el-tab-pane label="训练迭代" name="iteration" />
      <el-tab-pane label="训练报告" name="report" />
      <el-tab-pane label="日志记录" name="logs" />
    </el-tabs>

    <!-- Tasks Panel（真实数据：/federatedLearning/getTaskList） -->
    <div v-show="activeTab === 'tasks'">
      <!-- Search filters -->
      <el-form :inline="true" :model="queryForm" class="demo-form-inline">
        <el-form-item label="任务名称">
          <el-input v-model="queryForm.taskName" placeholder="请输入任务名称" clearable />
        </el-form-item>
        <el-form-item label="算法类型">
          <el-select v-model="queryForm.algorithmType" placeholder="请选择" clearable>
            <el-option label="线性回归（纵向）" :value="9" />
            <el-option label="逻辑回归（纵向）" :value="5" />
            <el-option label="XGBoost（纵向）" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="任务状态">
          <el-select v-model="queryForm.taskState" placeholder="请选择" clearable>
            <el-option label="待运行" :value="0" />
            <el-option label="成功" :value="1" />
            <el-option label="运行中" :value="2" />
            <el-option label="失败" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- Action buttons -->
      <el-row style="margin-bottom: 20px;">
        <el-button type="primary" icon="el-icon-plus" @click="handleCreate">创建联邦学习任务</el-button>
        <el-button type="info" icon="el-icon-document" @click="handleViewLogs">日志记录</el-button>
      </el-row>

      <!-- Table -->
      <el-table v-loading="loading" :data="tableData" border>
        <el-table-column prop="taskId" label="任务ID" min-width="280" show-overflow-tooltip />
        <el-table-column prop="taskName" label="任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="algorithmType" label="算法类型" width="130">
          <template slot-scope="scope">
            <el-tag :type="getAlgorithmTag(scope.row.algorithmType)">
              {{ getAlgorithmLabel(scope.row.algorithmType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="federatedType" label="学习类型" width="90">
          <template slot-scope="scope">
            <span>{{ scope.row.federatedType === 1 ? '横向' : '纵向' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="taskState" label="任务状态" width="90">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.taskState === 0" type="info">待运行</el-tag>
            <el-tag v-else-if="scope.row.taskState === 1" type="success">成功</el-tag>
            <el-tag v-else-if="scope.row.taskState === 2" type="warning">运行中</el-tag>
            <el-tag v-else-if="scope.row.taskState === 3" type="danger">失败</el-tag>
            <el-tag v-else type="info">{{ scope.row.taskState }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="进度" width="140">
          <template slot-scope="scope">
            <el-progress :percentage="getProgress(scope.row)" :status="getProgressStatus(scope.row)" />
          </template>
        </el-table-column>
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" fixed="right" width="230">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
            <el-button v-if="scope.row.taskState === 2" size="mini" type="warning" @click="handleCancel(scope.row)">取消</el-button>
            <el-button v-if="scope.row.taskState === 1" size="mini" type="success" @click="handleDownloadModel(scope.row)">下载模型</el-button>
            <el-button size="mini" type="danger" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- Pagination -->
      <el-pagination
        style="margin-top: 20px;"
        :current-page="queryForm.pageNo"
        :page-sizes="[10, 20, 50, 100]"
        :page-size="queryForm.pageSize"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- Workbench Panel：真实工作台在独立页面，这里只做入口，不摆假表单 -->
    <div v-show="activeTab === 'workbench'">
      <el-card>
        <div slot="header"><span>联邦建模工作台</span></div>
        <p style="color: #606266;">
          联邦建模工作台（数据集选择 / 特征配置 / 模型配置 / 工作流编排）已有独立的真实页面，
          请在其中完成建模配置并发起训练。
        </p>
        <el-button type="primary" icon="el-icon-right" @click="goModelingWorkbench">前往联邦建模工作台</el-button>
      </el-card>
    </div>

    <!-- Tuning Panel（createParamTuning / getParamTuningResult / applyBestParams） -->
    <div v-show="activeTab === 'tuning'">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>参数搜索配置</span></div>
            <el-form ref="tuningForm" :model="tuningFormData" label-width="120px">
              <el-form-item label="关联任务">
                <el-select v-model="tuningFormData.taskId" placeholder="请选择任务" style="width: 100%;" @change="loadTuningResults">
                  <el-option v-for="t in tableData" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
                </el-select>
              </el-form-item>
              <el-form-item label="搜索方法">
                <el-select v-model="tuningFormData.searchMethod" style="width: 100%;">
                  <el-option label="网格搜索" value="GRID" />
                  <el-option label="随机搜索" value="RANDOM" />
                  <el-option label="贝叶斯优化" value="BAYESIAN" />
                </el-select>
              </el-form-item>
              <el-form-item label="学习率范围">
                <el-slider v-model="tuningFormData.learningRateRange" range :min="0.0001" :max="0.1" :step="0.0001" />
              </el-form-item>
              <el-form-item label="迭代次数范围">
                <el-slider v-model="tuningFormData.iterationsRange" range :min="10" :max="1000" :step="10" />
              </el-form-item>
              <el-form-item label="批次大小">
                <el-checkbox-group v-model="tuningFormData.batchSizes">
                  <el-checkbox :label="16">16</el-checkbox>
                  <el-checkbox :label="32">32</el-checkbox>
                  <el-checkbox :label="64">64</el-checkbox>
                  <el-checkbox :label="128">128</el-checkbox>
                </el-checkbox-group>
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="handleStartTuning">开始调优</el-button>
              </el-form-item>
            </el-form>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>调优结果</span></div>
            <el-table :data="tuningResults" border max-height="400">
              <el-table-column prop="rank" label="排名" width="60" />
              <el-table-column prop="learningRate" label="学习率" width="100" />
              <el-table-column prop="iterations" label="迭代次数" width="80" />
              <el-table-column prop="batchSize" label="批次大小" width="80" />
              <el-table-column prop="accuracy" label="精度" width="80" />
              <el-table-column prop="auc" label="AUC" width="80" />
              <el-table-column label="操作" width="80">
                <template slot-scope="scope">
                  <el-button size="mini" type="primary" @click="handleApplyParams(scope.row)">应用</el-button>
                </template>
              </el-table-column>
            </el-table>
            <div v-if="tuningResults.length === 0" style="text-align: center; color: #999; padding: 20px;">
              暂无调优结果
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Iteration Panel（getTrainingIterations） -->
    <div v-show="activeTab === 'iteration'">
      <el-row style="margin-bottom: 15px;">
        <el-select v-model="iterationTaskId" placeholder="选择任务" style="width: 300px;" @change="handleIterationTaskChange">
          <el-option v-for="t in runningTasks" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
        </el-select>
        <el-button type="primary" style="margin-left: 10px;" @click="refreshIterationData">刷新数据</el-button>
      </el-row>
      <el-row :gutter="20">
        <el-col :span="24">
          <el-card>
            <div slot="header"><span>迭代详情</span></div>
            <el-table :data="iterationData" border max-height="400">
              <el-table-column prop="epoch" label="轮次" width="80" />
              <el-table-column prop="loss" label="损失值" width="120" />
              <el-table-column prop="accuracy" label="精度" width="120" />
              <el-table-column prop="learningRate" label="学习率" width="120" />
              <el-table-column prop="duration" label="耗时(s)" width="100" />
              <el-table-column prop="timestamp" label="时间" width="180" />
            </el-table>
            <div v-if="iterationData.length === 0" style="text-align: center; color: #999; padding: 20px;">
              暂无迭代数据（任务需处于运行中且后端已接通训练迭代接口）
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Report Panel（getTrainingReport / generateTrainingReport / exportTrainingReport） -->
    <div v-show="activeTab === 'report'">
      <el-row style="margin-bottom: 15px;">
        <el-select v-model="reportTaskId" placeholder="选择已成功任务" style="width: 300px;" @change="handleReportTaskChange">
          <el-option v-for="t in completedTasks" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
        </el-select>
        <el-button type="primary" style="margin-left: 10px;" @click="handleGenerateReport">生成报告</el-button>
        <el-button type="success" @click="handleExportReport">导出报告</el-button>
      </el-row>
      <el-row v-if="reportData.taskId" :gutter="20">
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>模型评估指标</span></div>
            <el-descriptions :column="1" border>
              <el-descriptions-item label="准确率">{{ reportData.accuracy || '-' }}</el-descriptions-item>
              <el-descriptions-item label="AUC">{{ reportData.auc || '-' }}</el-descriptions-item>
              <el-descriptions-item label="精确率">{{ reportData.precision || '-' }}</el-descriptions-item>
              <el-descriptions-item label="召回率">{{ reportData.recall || '-' }}</el-descriptions-item>
              <el-descriptions-item label="F1分数">{{ reportData.f1Score || '-' }}</el-descriptions-item>
              <el-descriptions-item label="KS值">{{ reportData.ks || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>训练摘要</span></div>
            <el-descriptions :column="1" border>
              <el-descriptions-item label="任务名称">{{ reportData.taskName || '-' }}</el-descriptions-item>
              <el-descriptions-item label="算法类型">{{ getAlgorithmLabel(reportData.algorithmType) }}</el-descriptions-item>
              <el-descriptions-item label="总迭代次数">{{ reportData.totalIterations || '-' }}</el-descriptions-item>
              <el-descriptions-item label="训练耗时">{{ reportData.trainingTime || '-' }}</el-descriptions-item>
              <el-descriptions-item label="模型大小">{{ reportData.modelSize || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>
      </el-row>
      <div v-else style="text-align: center; color: #999; padding: 30px;">
        请选择已成功任务并生成报告
      </div>
    </div>

    <!-- Logs Panel（getFederatedLearningLogs） -->
    <div v-show="activeTab === 'logs'">
      <el-form :inline="true" :model="logQueryForm" class="demo-form-inline">
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
          <el-date-picker v-model="logQueryForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 340px;" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleLogQuery">查询</el-button>
          <el-button @click="handleLogReset">重置</el-button>
        </el-form-item>
      </el-form>
      <el-row style="margin-bottom: 15px;">
        <el-button type="primary" icon="el-icon-download" @click="handleExportLogs">导出日志</el-button>
        <el-button type="success" icon="el-icon-download" :disabled="selectedLogs.length === 0" @click="handleExportSelectedLogs">导出选中</el-button>
      </el-row>
      <el-table :data="logData" border @selection-change="handleLogSelectionChange">
        <el-table-column type="selection" width="50" />
        <el-table-column prop="logId" label="日志ID" width="100" />
        <el-table-column prop="taskId" label="任务ID" width="120" show-overflow-tooltip />
        <el-table-column prop="taskName" label="任务名称" width="150" show-overflow-tooltip />
        <el-table-column prop="logType" label="日志类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType || '-' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="日志内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="createTime" label="记录时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewLogDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top: 15px;" :current-page="logQueryForm.pageNum" :page-sizes="[10, 20, 50]" :page-size="logQueryForm.pageSize" :total="logTotal" layout="total, sizes, prev, pager, next" @size-change="handleLogSizeChange" @current-change="handleLogCurrentChange" />
    </div>

    <!-- View Dialog（真实详情：getTaskDetails → task + federatedLearning） -->
    <el-dialog title="联邦学习任务详情" :visible.sync="viewDialogVisible" width="70%">
      <el-tabs v-model="detailTab">
        <el-tab-pane label="基本信息" name="basic">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="任务ID">{{ viewTask.taskId || '-' }}</el-descriptions-item>
            <el-descriptions-item label="任务名称">{{ viewFl.taskName || '-' }}</el-descriptions-item>
            <el-descriptions-item label="算法类型">{{ getAlgorithmLabel(viewFl.algorithmType) }}</el-descriptions-item>
            <el-descriptions-item label="学习类型">{{ viewFl.federatedType === 1 ? '横向联邦' : '纵向联邦' }}</el-descriptions-item>
            <el-descriptions-item label="任务状态">
              <el-tag v-if="viewTask.taskState === 1" type="success">成功</el-tag>
              <el-tag v-else-if="viewTask.taskState === 2" type="warning">运行中</el-tag>
              <el-tag v-else-if="viewTask.taskState === 3" type="danger">失败</el-tag>
              <el-tag v-else type="info">待运行</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ viewTask.createDate || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="资源与参与方" name="resources">
          <el-descriptions :column="1" border>
            <el-descriptions-item label="发起方机构">{{ viewFl.ownOrganId || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发起方资源">{{ viewFl.ownResourceId || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发起方特征">{{ viewFl.ownFeatures || '-' }}</el-descriptions-item>
            <el-descriptions-item label="标签字段">{{ viewFl.labelFeature || '-' }}</el-descriptions-item>
            <el-descriptions-item label="参与方机构">{{ viewFl.participantOrganIds || '-' }}</el-descriptions-item>
            <el-descriptions-item label="参与方资源">{{ viewFl.participantResourceIds || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="进度与结果" name="result">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="当前轮次">{{ viewTask.currentRound != null ? viewTask.currentRound : '-' }}</el-descriptions-item>
            <el-descriptions-item label="总轮次">{{ viewTask.totalRounds != null ? viewTask.totalRounds : '-' }}</el-descriptions-item>
            <el-descriptions-item label="精度">{{ viewTask.accuracy != null ? viewTask.accuracy : '-' }}</el-descriptions-item>
            <el-descriptions-item label="损失">{{ viewTask.loss != null ? viewTask.loss : '-' }}</el-descriptions-item>
          </el-descriptions>
          <div v-if="viewTask.executionLog" style="margin-top: 15px;">
            <div style="font-weight: bold; margin-bottom: 5px;">执行记录</div>
            <pre style="white-space: pre-wrap; word-wrap: break-word; background: #f5f7fa; padding: 10px; margin: 0; font-size: 12px;">{{ viewTask.executionLog }}</pre>
          </div>
        </el-tab-pane>
      </el-tabs>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Create Dialog：真实建任务需要选资源/机构/特征，入口在联邦学习训练页 -->
    <el-dialog title="创建联邦学习任务" :visible.sync="createDialogVisible" width="480px">
      <p style="color: #606266; margin-top: 0;">
        创建真实联邦学习任务需要选择本方/参与方资源与特征，请前往对应算法的训练页面：
      </p>
      <el-radio-group v-model="createAlgorithm" style="display: block; margin-bottom: 10px;">
        <el-radio label="verticalLinearTrain" style="display: block; margin: 8px 0;">线性回归建模（纵向）</el-radio>
        <el-radio label="verticalLogisticTrain" style="display: block; margin: 8px 0;">逻辑回归建模（纵向）</el-radio>
        <el-radio label="verticalXGBoostTrain" style="display: block; margin: 8px 0;">XGBoost建模（纵向）</el-radio>
      </el-radio-group>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="goCreatePage">前往创建</el-button>
      </span>
    </el-dialog>

    <!-- Log Detail Dialog -->
    <el-dialog title="日志详情" :visible.sync="logDetailDialogVisible" width="50%">
      <el-descriptions :column="1" border>
        <el-descriptions-item label="日志ID">{{ logDetailData.logId }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ logDetailData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ logDetailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="日志类型">
          <el-tag :type="getLogTypeTag(logDetailData.logType)" size="small">{{ logDetailData.logType || '-' }}</el-tag>
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
          <el-select v-model="logExportFormData.exportFormat" style="width: 100%;">
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
        <el-form-item label="包含堆栈信息">
          <el-switch v-model="logExportFormData.includeStackTrace" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="logExportDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="logExportLoading" @click="handleLogExportSubmit">确认导出</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getTaskList,
  getTaskDetails,
  cancelTask,
  deleteTask,
  downloadModel,
  getFederatedLearningLogs,
  exportFederatedLearningLog,
  batchExportFederatedLearningLogs,
  getParamTuningResult,
  createParamTuning,
  applyBestParams,
  getTrainingIterations,
  getTrainingReport,
  generateTrainingReport,
  exportTrainingReport
} from '@/api/federatedLearning'

// 后端 algorithmType（int）↔ 展示名。纵向：9=线性 5=逻辑 2=XGBoost（FederatedLearningService.mapModelType）
const ALGORITHM_LABELS = { 9: '线性回归', 5: '逻辑回归', 2: 'XGBoost', 3: '横向LR' }
const ALGORITHM_TAGS = { 9: 'info', 5: 'success', 2: 'warning', 3: '' }

export default {
  name: 'ProjectFederatedLearning',
  data() {
    return {
      activeTab: 'tasks',
      loading: false,
      tableData: [],
      total: 0,
      queryForm: {
        taskName: '',
        algorithmType: null,
        taskState: null,
        pageNo: 1,
        pageSize: 10
      },
      viewDialogVisible: false,
      viewTask: {},
      viewFl: {},
      detailTab: 'basic',
      createDialogVisible: false,
      createAlgorithm: 'verticalLogisticTrain',
      // Tuning
      tuningFormData: {
        taskId: '',
        searchMethod: 'GRID',
        learningRateRange: [0.001, 0.01],
        iterationsRange: [50, 200],
        batchSizes: [32, 64]
      },
      tuningResults: [],
      // Iteration
      iterationTaskId: '',
      iterationData: [],
      // Report
      reportTaskId: '',
      reportData: {},
      // Logs
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
      logExportDialogVisible: false,
      logExportLoading: false,
      logExportFormData: {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        includeStackTrace: true
      }
    }
  },
  computed: {
    // 后端状态词汇：1=成功 2=运行中（详情/进度读取会触发 data_task 终态懒同步回写）
    runningTasks() {
      return this.tableData.filter(t => t.taskState === 2)
    },
    completedTasks() {
      return this.tableData.filter(t => t.taskState === 1)
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    async fetchData() {
      this.loading = true
      try {
        const params = { pageNo: this.queryForm.pageNo, pageSize: this.queryForm.pageSize }
        if (this.queryForm.taskName) params.taskName = this.queryForm.taskName
        if (this.queryForm.algorithmType != null) params.algorithmType = this.queryForm.algorithmType
        if (this.queryForm.taskState != null) params.taskState = this.queryForm.taskState
        const res = await getTaskList(params)
        if (res && res.code === 0 && res.result) {
          this.tableData = res.result.data || res.result.list || []
          this.total = res.result.total || 0
        } else {
          this.tableData = []
          this.total = 0
          this.$message.warning('任务列表查询失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.tableData = []
        this.total = 0
        this.$message.error('任务列表接口不可用: ' + (e.message || e))
      }
      this.loading = false
    },
    handleQuery() {
      this.queryForm.pageNo = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = { taskName: '', algorithmType: null, taskState: null, pageNo: 1, pageSize: 10 }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNo = val
      this.fetchData()
    },
    async handleView(row) {
      try {
        const res = await getTaskDetails({ taskId: row.taskId })
        if (res && res.code === 0 && res.result) {
          this.viewTask = res.result.task || {}
          this.viewFl = res.result.federatedLearning || {}
          this.detailTab = 'basic'
          this.viewDialogVisible = true
          // 详情读取会触发后端终态懒同步；状态变了就刷新列表
          if (this.viewTask.taskState !== row.taskState) this.fetchData()
        } else {
          this.$message.warning('查询详情失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.$message.error('详情接口不可用: ' + (e.message || e))
      }
    },
    handleCreate() {
      this.createDialogVisible = true
    },
    goCreatePage() {
      this.createDialogVisible = false
      this.$router.push('/federatedLearning/' + this.createAlgorithm)
    },
    goModelingWorkbench() {
      this.$router.push('/FederatedLearning/modelingWorkbench')
    },
    handleCancel(row) {
      this.$confirm('确认取消该运行中的联邦学习任务吗?', '提示', { type: 'warning' }).then(async() => {
        try {
          const res = await cancelTask({ taskId: row.taskId })
          if (res && res.code === 0) {
            this.$message.success('任务已取消')
            this.fetchData()
          } else {
            this.$message.warning('取消失败: ' + ((res && res.msg) || '未知错误'))
          }
        } catch (e) {
          this.$message.error('取消接口不可用: ' + (e.message || e))
        }
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm('确认删除该联邦学习任务吗？删除不可恢复。', '提示', { type: 'warning' }).then(async() => {
        try {
          const res = await deleteTask({ taskId: row.taskId })
          if (res && res.code === 0) {
            this.$message.success('任务已删除')
            this.fetchData()
          } else {
            this.$message.warning('删除失败: ' + ((res && res.msg) || '未知错误'))
          }
        } catch (e) {
          this.$message.error('删除接口不可用: ' + (e.message || e))
        }
      }).catch(() => {})
    },
    async handleDownloadModel(row) {
      try {
        const blob = await downloadModel({ taskId: row.taskId })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = (row.taskName || row.taskId) + '_model'
        link.click()
        window.URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('模型下载失败: ' + (e.message || e))
      }
    },
    getAlgorithmLabel(type) {
      return ALGORITHM_LABELS[type] || (type != null ? String(type) : '-')
    },
    getAlgorithmTag(type) {
      return ALGORITHM_TAGS[type] || ''
    },
    getProgress(row) {
      if (row.taskState === 1) return 100
      if (row.totalRounds) {
        const pct = Math.round(((row.currentRound || 0) * 100) / row.totalRounds)
        return Math.min(99, Math.max(0, pct))
      }
      return 0
    },
    getProgressStatus(row) {
      if (row.taskState === 1) return 'success'
      if (row.taskState === 3) return 'exception'
      return null
    },
    // Tab handling
    handleTabClick(tab) {
      if (tab.name === 'logs') {
        this.fetchLogs()
      }
    },
    // Tuning methods
    async handleStartTuning() {
      if (!this.tuningFormData.taskId) {
        this.$message.warning('请选择关联任务')
        return
      }
      try {
        const res = await createParamTuning(this.tuningFormData)
        if (res && res.code === 0) {
          this.$message.success('参数调优任务已启动')
          this.loadTuningResults()
        } else {
          this.$message.warning('调优启动失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.$message.error('参数调优接口不可用: ' + (e.message || e))
      }
    },
    async loadTuningResults() {
      if (!this.tuningFormData.taskId) return
      try {
        const res = await getParamTuningResult({ taskId: this.tuningFormData.taskId })
        if (res && res.code === 0) {
          this.tuningResults = res.result || []
        } else {
          this.tuningResults = []
        }
      } catch (e) {
        this.tuningResults = []
      }
    },
    async handleApplyParams(row) {
      try {
        const res = await applyBestParams({ ...row, taskId: this.tuningFormData.taskId })
        if (res && res.code === 0) {
          this.$message.success('最优参数已应用')
        } else {
          this.$message.warning('应用失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.$message.error('应用参数接口不可用: ' + (e.message || e))
      }
    },
    // Iteration methods
    handleIterationTaskChange() {
      this.refreshIterationData()
    },
    async refreshIterationData() {
      if (!this.iterationTaskId) return
      try {
        const res = await getTrainingIterations({ taskId: this.iterationTaskId })
        if (res && res.code === 0) {
          this.iterationData = res.result || []
        } else {
          this.iterationData = []
          this.$message.warning('训练迭代查询失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.iterationData = []
        this.$message.error('训练迭代接口不可用: ' + (e.message || e))
      }
    },
    // Report methods
    async handleReportTaskChange() {
      if (!this.reportTaskId) return
      try {
        const res = await getTrainingReport({ taskId: this.reportTaskId })
        if (res && res.code === 0) {
          this.reportData = res.result || {}
        } else {
          this.reportData = {}
          this.$message.warning('训练报告查询失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.reportData = {}
        this.$message.error('训练报告接口不可用: ' + (e.message || e))
      }
    },
    async handleGenerateReport() {
      if (!this.reportTaskId) {
        this.$message.warning('请选择任务')
        return
      }
      try {
        const res = await generateTrainingReport({ taskId: this.reportTaskId })
        if (res && res.code === 0) {
          this.$message.success('训练报告已生成')
          this.handleReportTaskChange()
        } else {
          this.$message.warning('生成报告失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.$message.error('生成报告接口不可用: ' + (e.message || e))
      }
    },
    async handleExportReport() {
      if (!this.reportTaskId) {
        this.$message.warning('请选择任务')
        return
      }
      try {
        await exportTrainingReport({ taskId: this.reportTaskId })
        this.$message.success('训练报告导出成功')
      } catch (e) {
        this.$message.error('导出报告失败: ' + (e.message || e))
      }
    },
    // Log methods
    async fetchLogs() {
      try {
        const params = {
          ...this.logQueryForm,
          startTime: this.logQueryForm.dateRange?.[0] || '',
          endTime: this.logQueryForm.dateRange?.[1] || ''
        }
        const res = await getFederatedLearningLogs(params)
        if (res && res.code === 0 && res.result) {
          const rows = res.result.list || res.result.data || []
          this.logData = rows.map(r => ({
            logId: r.logId || r.id,
            taskId: r.taskId,
            taskName: r.taskName,
            logType: r.logType || r.logLevel,
            content: r.content || r.logContent,
            createTime: r.createTime || r.createDate,
            stackTrace: r.stackTrace
          }))
          this.logTotal = res.result.total || this.logData.length
        } else {
          this.logData = []
          this.logTotal = 0
          this.$message.warning('日志查询失败: ' + ((res && res.msg) || '未知错误'))
        }
      } catch (e) {
        this.logData = []
        this.logTotal = 0
        this.$message.error('日志接口不可用: ' + (e.message || e))
      }
    },
    handleLogQuery() {
      this.logQueryForm.pageNum = 1
      this.fetchLogs()
    },
    handleLogReset() {
      this.logQueryForm = { taskId: '', logType: '', dateRange: [], pageNum: 1, pageSize: 10 }
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
    handleViewLogs() {
      this.activeTab = 'logs'
      this.fetchLogs()
    },
    handleExportLogs() {
      this.logExportFormData = {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        includeStackTrace: true
      }
      this.logExportDialogVisible = true
    },
    handleExportSelectedLogs() {
      if (this.selectedLogs.length === 0) {
        this.$message.warning('请选择要导出的日志')
        return
      }
      this.logExportFormData.exportScope = 'SELECTED'
      this.logExportDialogVisible = true
    },
    async handleLogExportSubmit() {
      this.logExportLoading = true
      try {
        const data = {
          ...this.logExportFormData,
          logIds: this.logExportFormData.exportScope === 'SELECTED' ? this.selectedLogs.map(l => l.logId) : []
        }
        if (this.logExportFormData.exportScope === 'SELECTED') {
          await batchExportFederatedLearningLogs(data)
        } else {
          await exportFederatedLearningLog(data)
        }
        this.$message.success('日志导出成功')
        this.logExportDialogVisible = false
      } catch (e) {
        this.$message.error('日志导出失败: ' + (e.message || e))
      }
      this.logExportLoading = false
    },
    getLogTypeTag(type) {
      const map = { 'INFO': 'info', 'WARN': 'warning', 'ERROR': 'danger', 'DEBUG': '' }
      return map[type] || 'info'
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
