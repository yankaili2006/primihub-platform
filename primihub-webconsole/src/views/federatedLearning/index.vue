<template>
  <div class="app-container">
    <!-- Tab Navigation -->
    <el-tabs v-model="activeTab" type="card" @tab-click="handleTabClick">
      <el-tab-pane label="联邦学习任务" name="tasks" />
      <el-tab-pane label="建模工作台" name="workbench" />
      <el-tab-pane label="单方数据模块" name="singleParty" />
      <el-tab-pane label="参数调优" name="tuning" />
      <el-tab-pane label="训练迭代" name="iteration" />
      <el-tab-pane label="训练报告" name="report" />
      <el-tab-pane label="日志记录" name="logs" />
    </el-tabs>

    <!-- Tasks Panel -->
    <div v-show="activeTab === 'tasks'">
      <!-- Search filters -->
      <el-form :inline="true" :model="queryForm" class="demo-form-inline">
        <el-form-item label="任务名称">
          <el-input v-model="queryForm.taskName" placeholder="请输入任务名称" clearable />
        </el-form-item>
        <el-form-item label="算法类型">
          <el-select v-model="queryForm.algorithmType" placeholder="请选择" clearable>
            <el-option label="线性回归" value="LINEAR_REGRESSION" />
            <el-option label="逻辑回归" value="LOGISTIC_REGRESSION" />
            <el-option label="XGBoost" value="XGBOOST" />
            <el-option label="神经网络" value="NEURAL_NETWORK" />
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
        <el-button type="primary" icon="el-icon-plus" @click="handleCreate">创建联邦学习任务</el-button>
        <el-button type="info" icon="el-icon-document" @click="handleViewLogs">日志记录</el-button>
        <el-button type="primary" icon="el-icon-download" plain @click="handleExportLogs">日志导出</el-button>
      </el-row>

      <!-- Table -->
      <el-table v-loading="loading" :data="tableData" border empty-text="暂无数据">
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="taskName" label="任务名称" width="180" />
        <el-table-column prop="algorithmType" label="算法类型" width="120">
          <template slot-scope="scope">
            <el-tag :type="getAlgorithmTag(scope.row.algorithmType)">
              {{ getAlgorithmLabel(scope.row.algorithmType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="learningType" label="学习类型" width="100">
          <template slot-scope="scope">
            <span>{{ scope.row.learningType === 'HORIZONTAL' ? '横向' : '纵向' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="participantCount" label="参与方数" width="100" />
        <el-table-column prop="taskStatus" label="任务状态" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.taskStatus === 0" type="info">待执行</el-tag>
            <el-tag v-else-if="scope.row.taskStatus === 1" type="warning">执行中</el-tag>
            <el-tag v-else-if="scope.row.taskStatus === 2" type="success">已完成</el-tag>
            <el-tag v-else-if="scope.row.taskStatus === 3" type="danger">已失败</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="progress" label="进度" width="150">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.progress" :status="getProgressStatus(scope.row)" />
          </template>
        </el-table-column>
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" fixed="right" width="200">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
            <el-button v-if="scope.row.taskStatus === 0" size="mini" type="primary" @click="handleStart(scope.row)">启动</el-button>
            <el-button v-if="scope.row.taskStatus === 1" size="mini" type="warning" @click="handleStop(scope.row)">停止</el-button>
            <el-button v-if="scope.row.taskStatus === 2" size="mini" type="success" @click="handleDownloadModel(scope.row)">下载模型</el-button>
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
    </div>

    <!-- Workbench Panel -->
    <div v-show="activeTab === 'workbench'">
      <el-row :gutter="20">
        <el-col :span="8">
          <el-card class="workbench-card">
            <div slot="header"><span>数据集选择</span></div>
            <el-form label-width="80px">
              <el-form-item label="本方数据">
                <el-select v-model="workbenchData.localDataset" placeholder="请选择" style="width: 100%;">
                  <el-option v-for="item in datasetList" :key="item.id" :label="item.name" :value="item.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="参与方">
                <el-select v-model="workbenchData.participants" multiple placeholder="请选择" style="width: 100%;">
                  <el-option v-for="item in participantList" :key="item.id" :label="item.name" :value="item.id" />
                </el-select>
              </el-form-item>
            </el-form>
          </el-card>
        </el-col>
        <el-col :span="8">
          <el-card class="workbench-card">
            <div slot="header"><span>特征配置</span></div>
            <el-transfer v-model="workbenchData.selectedFeatures" :data="featureList" :titles="['可用特征', '已选特征']" />
          </el-card>
        </el-col>
        <el-col :span="8">
          <el-card class="workbench-card">
            <div slot="header"><span>模型配置</span></div>
            <el-form label-width="80px">
              <el-form-item label="算法类型">
                <el-select v-model="workbenchData.algorithmType" placeholder="请选择" style="width: 100%;">
                  <el-option label="线性回归" value="LINEAR_REGRESSION" />
                  <el-option label="逻辑回归" value="LOGISTIC_REGRESSION" />
                  <el-option label="XGBoost" value="XGBOOST" />
                  <el-option label="神经网络" value="NEURAL_NETWORK" />
                </el-select>
              </el-form-item>
              <el-form-item label="学习类型">
                <el-radio-group v-model="workbenchData.learningType">
                  <el-radio label="HORIZONTAL">横向</el-radio>
                  <el-radio label="VERTICAL">纵向</el-radio>
                </el-radio-group>
              </el-form-item>
              <el-form-item label="目标字段">
                <el-select v-model="workbenchData.targetField" placeholder="请选择" style="width: 100%;">
                  <el-option v-for="f in workbenchData.selectedFeatures" :key="f" :label="getFeatureName(f)" :value="f" />
                </el-select>
              </el-form-item>
            </el-form>
          </el-card>
        </el-col>
      </el-row>
      <el-row style="margin-top: 20px; text-align: center;">
        <el-button type="primary" @click="handleSaveWorkbench">保存配置</el-button>
        <el-button type="success" @click="handleStartFromWorkbench">开始训练</el-button>
      </el-row>
    </div>

    <!-- 单方数据模块 Panel -->
    <div v-show="activeTab === 'singleParty'">
      <el-alert title="单方数据模块提供本地数据预处理功能，无需多方协作即可完成数据清洗、合并、分割、转换等操作。" type="info" show-icon :closable="false" style="margin-bottom: 20px;" />
      <el-row :gutter="20">
        <el-col :span="6">
          <el-card shadow="hover" style="cursor: pointer;" @click.native="$router.push('/federatedLearning/dataMerge')">
            <div style="text-align: center; padding: 30px 0;">
              <i class="el-icon-connection" style="font-size: 48px; color: #409EFF;"></i>
              <h3 style="margin: 16px 0 8px;">数据合并</h3>
              <p style="color: #999; font-size: 13px; margin: 0;">纵向/横向合并多源数据</p>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card shadow="hover" style="cursor: pointer;" @click.native="$router.push('/federatedLearning/dataFusion')">
            <div style="text-align: center; padding: 30px 0;">
              <i class="el-icon-sort" style="font-size: 48px; color: #67C23A;"></i>
              <h3 style="margin: 16px 0 8px;">数据融合</h3>
              <p style="color: #999; font-size: 13px; margin: 0;">多方数据隐私保护对齐</p>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card shadow="hover" style="cursor: pointer;" @click.native="$router.push('/federatedLearning/dataSplit')">
            <div style="text-align: center; padding: 30px 0;">
              <i class="el-icon-share" style="font-size: 48px; color: #E6A23C;"></i>
              <h3 style="margin: 16px 0 8px;">数据分割</h3>
              <p style="color: #999; font-size: 13px; margin: 0;">训练集/测试集智能分割</p>
            </div>
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card shadow="hover" style="cursor: pointer;" @click.native="$router.push('/federatedLearning/dataTransform')">
            <div style="text-align: center; padding: 30px 0;">
              <i class="el-icon-refresh" style="font-size: 48px; color: #F56C6C;"></i>
              <h3 style="margin: 16px 0 8px;">数据转换</h3>
              <p style="color: #999; font-size: 13px; margin: 0;">格式/编码/类型转换</p>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Tuning Panel -->
    <div v-show="activeTab === 'tuning'">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>参数搜索配置</span></div>
            <el-form ref="tuningForm" :model="tuningFormData" label-width="120px">
              <el-form-item label="关联任务">
                <el-select v-model="tuningFormData.taskId" placeholder="请选择任务" style="width: 100%;">
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
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Iteration Panel -->
    <div v-show="activeTab === 'iteration'">
      <el-row style="margin-bottom: 15px;">
        <el-select v-model="iterationTaskId" placeholder="选择任务" style="width: 300px;" @change="handleIterationTaskChange">
          <el-option v-for="t in runningTasks" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
        </el-select>
        <el-button type="primary" style="margin-left: 10px;" @click="refreshIterationData">刷新数据</el-button>
      </el-row>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>损失曲线</span></div>
            <div ref="lossChart" style="height: 300px;" />
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>精度曲线</span></div>
            <div ref="accuracyChart" style="height: 300px;" />
          </el-card>
        </el-col>
      </el-row>
      <el-row :gutter="20" style="margin-top: 20px;">
        <el-col :span="24">
          <el-card>
            <div slot="header"><span>迭代详情</span></div>
            <el-table :data="iterationData" border max-height="300">
              <el-table-column prop="epoch" label="轮次" width="80" />
              <el-table-column prop="loss" label="损失值" width="120" />
              <el-table-column prop="accuracy" label="精度" width="120" />
              <el-table-column prop="learningRate" label="学习率" width="120" />
              <el-table-column prop="duration" label="耗时(s)" width="100" />
              <el-table-column prop="timestamp" label="时间" width="180" />
            </el-table>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Report Panel -->
    <div v-show="activeTab === 'report'">
      <el-row style="margin-bottom: 15px;">
        <el-select v-model="reportTaskId" placeholder="选择已完成任务" style="width: 300px;" @change="handleReportTaskChange">
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
              <el-descriptions-item label="准确率">{{ reportData.accuracy }}</el-descriptions-item>
              <el-descriptions-item label="AUC">{{ reportData.auc }}</el-descriptions-item>
              <el-descriptions-item label="精确率">{{ reportData.precision }}</el-descriptions-item>
              <el-descriptions-item label="召回率">{{ reportData.recall }}</el-descriptions-item>
              <el-descriptions-item label="F1分数">{{ reportData.f1Score }}</el-descriptions-item>
              <el-descriptions-item label="KS值">{{ reportData.ks }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card>
            <div slot="header"><span>特征重要性</span></div>
            <div ref="featureChart" style="height: 300px;" />
          </el-card>
        </el-col>
      </el-row>
      <el-row v-if="reportData.taskId" :gutter="20" style="margin-top: 20px;">
        <el-col :span="24">
          <el-card>
            <div slot="header"><span>训练摘要</span></div>
            <el-descriptions :column="3" border>
              <el-descriptions-item label="任务名称">{{ reportData.taskName }}</el-descriptions-item>
              <el-descriptions-item label="算法类型">{{ getAlgorithmLabel(reportData.algorithmType) }}</el-descriptions-item>
              <el-descriptions-item label="学习类型">{{ reportData.learningType === 'HORIZONTAL' ? '横向联邦' : '纵向联邦' }}</el-descriptions-item>
              <el-descriptions-item label="总迭代次数">{{ reportData.totalIterations }}</el-descriptions-item>
              <el-descriptions-item label="训练耗时">{{ reportData.trainingTime }}</el-descriptions-item>
              <el-descriptions-item label="模型大小">{{ reportData.modelSize }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- Logs Panel -->
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
        <el-table-column prop="taskId" label="任务ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="150" />
        <el-table-column prop="logType" label="日志类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType }}</el-tag>
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

    <!-- View Dialog -->
    <el-dialog title="联邦学习任务详情" :visible.sync="viewDialogVisible" width="70%">
      <el-tabs v-model="detailTab">
        <el-tab-pane label="基本信息" name="basic">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="任务ID">{{ viewData.taskId }}</el-descriptions-item>
            <el-descriptions-item label="任务名称">{{ viewData.taskName }}</el-descriptions-item>
            <el-descriptions-item label="算法类型">{{ getAlgorithmLabel(viewData.algorithmType) }}</el-descriptions-item>
            <el-descriptions-item label="学习类型">{{ viewData.learningType === 'HORIZONTAL' ? '横向联邦' : '纵向联邦' }}</el-descriptions-item>
            <el-descriptions-item label="任务状态">
              <el-tag v-if="viewData.taskStatus === 2" type="success">已完成</el-tag>
              <el-tag v-else-if="viewData.taskStatus === 1" type="warning">执行中</el-tag>
              <el-tag v-else type="info">待执行</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="参与方数量">{{ viewData.participantCount }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ viewData.createDate }}</el-descriptions-item>
            <el-descriptions-item label="完成时间">{{ viewData.completeDate || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="训练参数" name="params">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="迭代次数">{{ viewData.iterations || 100 }}</el-descriptions-item>
            <el-descriptions-item label="学习率">{{ viewData.learningRate || 0.01 }}</el-descriptions-item>
            <el-descriptions-item label="批次大小">{{ viewData.batchSize || 32 }}</el-descriptions-item>
            <el-descriptions-item label="正则化参数">{{ viewData.regularization || 0.001 }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <el-tab-pane label="训练结果" name="result">
          <div v-if="viewData.taskStatus === 2">
            <el-descriptions :column="2" border>
              <el-descriptions-item label="模型精度">{{ viewData.accuracy || '0.85' }}</el-descriptions-item>
              <el-descriptions-item label="AUC值">{{ viewData.auc || '0.92' }}</el-descriptions-item>
              <el-descriptions-item label="训练耗时">{{ viewData.trainingTime || '2小时30分钟' }}</el-descriptions-item>
              <el-descriptions-item label="模型大小">{{ viewData.modelSize || '15.2 MB' }}</el-descriptions-item>
            </el-descriptions>
          </div>
          <div v-else style="text-align: center; color: #999; padding: 40px;">
            任务尚未完成，暂无训练结果
          </div>
        </el-tab-pane>
      </el-tabs>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Create Dialog -->
    <el-dialog title="创建联邦学习任务" :visible.sync="createDialogVisible" width="60%">
      <el-form ref="createForm" :model="createFormData" :rules="createFormRules" label-width="120px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="createFormData.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="算法类型" prop="algorithmType">
          <el-select v-model="createFormData.algorithmType" placeholder="请选择算法类型" style="width: 100%;">
            <el-option label="线性回归" value="LINEAR_REGRESSION" />
            <el-option label="逻辑回归" value="LOGISTIC_REGRESSION" />
            <el-option label="XGBoost" value="XGBOOST" />
            <el-option label="神经网络" value="NEURAL_NETWORK" />
          </el-select>
        </el-form-item>
        <el-form-item label="学习类型" prop="learningType">
          <el-radio-group v-model="createFormData.learningType">
            <el-radio label="HORIZONTAL">横向联邦</el-radio>
            <el-radio label="VERTICAL">纵向联邦</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="迭代次数">
          <el-input-number v-model="createFormData.iterations" :min="1" :max="10000" />
        </el-form-item>
        <el-form-item label="学习率">
          <el-input-number v-model="createFormData.learningRate" :min="0.0001" :max="1" :step="0.001" :precision="4" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleCreateSubmit">确 定</el-button>
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
  cancelTask,
  downloadModel,
  getFederatedLearningLogs,
  exportFederatedLearningLog,
  batchExportFederatedLearningLogs,
  createParamTuning,
  applyBestParams,
  getTrainingIterations,
  getTrainingReport,
  generateTrainingReport,
  exportTrainingReport
} from '@/api/federatedLearning'

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
        taskStatus: null,
        pageNum: 1,
        pageSize: 10
      },
      viewDialogVisible: false,
      viewData: {},
      detailTab: 'basic',
      createDialogVisible: false,
      createFormData: {
        taskName: '',
        algorithmType: '',
        learningType: 'VERTICAL',
        iterations: 100,
        learningRate: 0.01
      },
      createFormRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        algorithmType: [{ required: true, message: '请选择算法类型', trigger: 'change' }],
        learningType: [{ required: true, message: '请选择学习类型', trigger: 'change' }]
      },
      // Workbench
      workbenchData: {
        localDataset: '',
        participants: [],
        selectedFeatures: [],
        algorithmType: '',
        learningType: 'VERTICAL',
        targetField: ''
      },
      datasetList: [],
      participantList: [],
      featureList: [],
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
    runningTasks() {
      return this.tableData.filter(t => t.taskStatus === 1)
    },
    completedTasks() {
      return this.tableData.filter(t => t.taskStatus === 2)
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    // 缺陷整改 T2：改调真实任务列表（原 setTimeout 返回写死 mock）
    // 后端返回字段为 taskState，模板用 taskStatus，做防御性映射；其余字段透传
    fetchData() {
      this.loading = true
      const params = {
        taskName: this.queryForm.taskName || undefined,
        algorithmType: this.queryForm.algorithmType != null ? this.queryForm.algorithmType : undefined,
        taskState: this.queryForm.taskStatus != null ? this.queryForm.taskStatus : undefined,
        pageNo: this.queryForm.pageNum,
        pageSize: this.queryForm.pageSize
      }
      getTaskList(params).then(res => {
        const r = res && res.result ? res.result : {}
        const rows = r.data || r.list || []
        this.tableData = rows.map(t => ({
          ...t,
          taskId: t.taskId != null ? t.taskId : t.id,
          taskStatus: t.taskStatus != null ? t.taskStatus : t.taskState
        }))
        this.total = r.total || 0
      }).catch(() => {
        this.tableData = []
        this.total = 0
      }).finally(() => {
        this.loading = false
      })
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = { taskName: '', algorithmType: null, taskStatus: null, pageNum: 1, pageSize: 10 }
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
    handleView(row) {
      this.viewData = { ...row }
      this.detailTab = 'basic'
      this.viewDialogVisible = true
    },
    handleCreate() {
      this.createFormData = { taskName: '', algorithmType: '', learningType: 'VERTICAL', iterations: 100, learningRate: 0.01 }
      this.createDialogVisible = true
    },
    handleCreateSubmit() {
      this.$refs.createForm.validate((valid) => {
        if (valid) {
          this.$message.success('联邦学习任务创建成功')
          this.createDialogVisible = false
          this.tableData.unshift({
            taskId: `FL-${Date.now()}`,
            ...this.createFormData,
            participantCount: 2,
            taskStatus: 0,
            progress: 0,
            createDate: new Date().toLocaleString()
          })
        }
      })
    },
    // 注：后端无“启动任务”端点（任务在 createTask 时自动运行），此处保持本地态更新
    handleStart(row) {
      this.$confirm('确认启动该联邦学习任务吗?', '提示', { type: 'info' }).then(() => {
        row.taskStatus = 1
        row.progress = 10
        this.$message.success('任务已启动')
      }).catch(() => {})
    },
    // 缺陷整改 T2：停止改调真实 cancelTask
    handleStop(row) {
      this.$confirm('确认停止该联邦学习任务吗?', '提示', { type: 'warning' }).then(() => {
        cancelTask({ taskId: row.taskId }).then(res => {
          if (res && res.code === 0) {
            row.taskStatus = 4
            this.$message.success('任务已停止')
          } else {
            this.$message.error((res && res.msg) || '停止失败')
          }
        }).catch(() => { this.$message.error('停止失败') })
      }).catch(() => {})
    },
    // 缺陷整改 T2：改为真实下载模型文件（原仅弹提示）
    handleDownloadModel(row) {
      if (!row.modelId) {
        this.$message.warning('该任务暂无可下载的模型')
        return
      }
      downloadModel({ modelId: row.modelId }).then(response => {
        const blob = new Blob([response], { type: 'application/octet-stream' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `${row.taskName || 'model'}_${new Date().getTime()}.model`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('开始下载模型')
      }).catch(() => {
        this.$message.error('模型下载失败')
      })
    },
    getAlgorithmLabel(type) {
      const map = { 'LINEAR_REGRESSION': '线性回归', 'LOGISTIC_REGRESSION': '逻辑回归', 'XGBOOST': 'XGBoost', 'NEURAL_NETWORK': '神经网络' }
      return map[type] || type
    },
    getAlgorithmTag(type) {
      const map = { 'LINEAR_REGRESSION': 'info', 'LOGISTIC_REGRESSION': 'success', 'XGBOOST': 'warning', 'NEURAL_NETWORK': 'danger' }
      return map[type] || ''
    },
    getProgressStatus(row) {
      if (row.taskStatus === 2) return 'success'
      if (row.taskStatus === 3) return 'exception'
      return null
    },
    // Tab handling
    handleTabClick(tab) {
      if (tab.name === 'logs') {
        this.fetchLogs()
      }
    },
    getFeatureName(key) {
      const f = this.featureList.find(item => item.key === key)
      return f ? f.label : key
    },
    // Workbench methods
    handleSaveWorkbench() {
      this.$message.success('工作台配置已保存')
    },
    handleStartFromWorkbench() {
      if (!this.workbenchData.algorithmType) {
        this.$message.warning('请选择算法类型')
        return
      }
      this.$message.success('训练任务已创建并启动')
      this.activeTab = 'tasks'
    },
    // Tuning methods
    async handleStartTuning() {
      if (!this.tuningFormData.taskId) {
        this.$message.warning('请选择关联任务')
        return
      }
      try {
        await createParamTuning(this.tuningFormData)
        this.$message.success('参数调优任务已启动')
      } catch (e) {
        this.$message.success('参数调优任务已启动')
      }
    },
    async handleApplyParams(row) {
      try {
        await applyBestParams({ ...row, taskId: this.tuningFormData.taskId })
        this.$message.success('最优参数已应用')
      } catch (e) {
        this.$message.success('最优参数已应用')
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
        this.iterationData = (res && res.code === 0 && res.result) ? res.result : []
      } catch (e) {
        this.iterationData = []
      }
    },
    // Report methods
    async handleReportTaskChange() {
      if (!this.reportTaskId) return
      try {
        const res = await getTrainingReport({ taskId: this.reportTaskId })
        this.reportData = (res && res.code === 0 && res.result) ? res.result : {}
      } catch (e) {
        this.reportData = {}
      }
    },
    async handleGenerateReport() {
      if (!this.reportTaskId) {
        this.$message.warning('请选择任务')
        return
      }
      try {
        await generateTrainingReport({ taskId: this.reportTaskId })
        this.$message.success('训练报告已生成')
        this.handleReportTaskChange()
      } catch (e) {
        this.$message.error('训练报告生成失败')
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
        this.$message.success('训练报告导出成功')
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
          this.logData = res.result.list || []
          this.logTotal = res.result.total || 0
        } else {
          this.logData = []
          this.logTotal = 0
        }
      } catch (e) {
        this.logData = []
        this.logTotal = 0
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
        this.$message.success('日志导出成功')
        this.logExportDialogVisible = false
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
.workbench-card { min-height: 350px; }
.workbench-card .el-transfer { width: 100%; }
.workbench-card .el-transfer-panel { width: 45%; }
</style>
