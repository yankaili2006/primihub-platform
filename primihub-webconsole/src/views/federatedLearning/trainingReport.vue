<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦建模训练报告" style="margin-bottom: 20px;" />

    <el-row style="margin-bottom: 15px;">
      <el-select v-model="reportTaskId" placeholder="选择已完成任务" style="width: 300px;" @change="handleTaskChange">
        <el-option v-for="t in completedTasks" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
      </el-select>
      <el-button type="primary" style="margin-left: 10px;" @click="handleGenerateReport">生成报告</el-button>
      <el-button type="success" @click="handleExportReport">导出报告</el-button>
    </el-row>

    <el-row :gutter="20" v-if="reportData.taskId">
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
          <el-table :data="featureImportance" border max-height="300">
            <el-table-column prop="rank" label="排名" width="60" />
            <el-table-column prop="feature" label="特征名称" />
            <el-table-column prop="importance" label="重要性" width="100">
              <template slot-scope="scope">
                <el-progress :percentage="scope.row.importance" :show-text="false" />
              </template>
            </el-table-column>
            <el-table-column prop="importanceValue" label="数值" width="80" />
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;" v-if="reportData.taskId">
      <el-col :span="24">
        <el-card>
          <div slot="header"><span>训练摘要</span></div>
          <el-descriptions :column="3" border>
            <el-descriptions-item label="任务名称">{{ reportData.taskName }}</el-descriptions-item>
            <el-descriptions-item label="算法类型">{{ reportData.algorithmType }}</el-descriptions-item>
            <el-descriptions-item label="学习类型">{{ reportData.learningType }}</el-descriptions-item>
            <el-descriptions-item label="总迭代次数">{{ reportData.totalIterations }}</el-descriptions-item>
            <el-descriptions-item label="训练耗时">{{ reportData.trainingTime }}</el-descriptions-item>
            <el-descriptions-item label="模型大小">{{ reportData.modelSize }}</el-descriptions-item>
            <el-descriptions-item label="参与方数量">{{ reportData.participantCount }}</el-descriptions-item>
            <el-descriptions-item label="样本总数">{{ reportData.totalSamples }}</el-descriptions-item>
            <el-descriptions-item label="特征数量">{{ reportData.featureCount }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <el-empty v-if="!reportData.taskId" description="请选择已完成的任务查看报告" />
  </div>
</template>

<script>
export default {
  name: 'FederatedLearningTrainingReport',
  data() {
    return {
      reportTaskId: '',
      completedTasks: [
        { taskId: 'FL-001', taskName: '联合风控模型训练' },
        { taskId: 'FL-004', taskName: '信用评分模型V2' }
      ],
      reportData: {},
      featureImportance: []
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleTaskChange() {
      if (!this.reportTaskId) return
      const task = this.completedTasks.find(t => t.taskId === this.reportTaskId)
      this.reportData = {
        taskId: this.reportTaskId,
        taskName: task?.taskName || '',
        algorithmType: 'XGBoost',
        learningType: '纵向联邦',
        accuracy: '0.89',
        auc: '0.94',
        precision: '0.87',
        recall: '0.91',
        f1Score: '0.89',
        ks: '0.42',
        totalIterations: 100,
        trainingTime: '2小时15分钟',
        modelSize: '12.5 MB',
        participantCount: 3,
        totalSamples: '150,000',
        featureCount: 25
      }
      this.featureImportance = [
        { rank: 1, feature: '交易次数', importance: 95, importanceValue: '0.95' },
        { rank: 2, feature: '信用评分', importance: 88, importanceValue: '0.88' },
        { rank: 3, feature: '账户余额', importance: 76, importanceValue: '0.76' },
        { rank: 4, feature: '逾期次数', importance: 65, importanceValue: '0.65' },
        { rank: 5, feature: '年龄', importance: 52, importanceValue: '0.52' }
      ]
    },
    handleGenerateReport() {
      if (!this.reportTaskId) {
        this.$message.warning('请选择任务')
        return
      }
      this.$message.success('训练报告已生成')
      this.handleTaskChange()
    },
    handleExportReport() {
      if (!this.reportTaskId) {
        this.$message.warning('请选择任务')
        return
      }
      this.$message.success('训练报告导出成功')
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
