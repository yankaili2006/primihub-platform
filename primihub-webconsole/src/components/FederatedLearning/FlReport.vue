<template>
  <div>
    <el-row style="margin-bottom: 15px;">
      <el-select v-model="taskId" placeholder="选择已成功任务" style="width: 300px;" @change="loadReport">
        <el-option v-for="t in taskOptions" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
      </el-select>
      <el-button type="primary" style="margin-left: 10px;" @click="handleGenerate">生成报告</el-button>
      <el-button type="success" @click="handleExport">导出报告</el-button>
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
</template>

<script>
import { getTrainingReport, generateTrainingReport, exportTrainingReport } from '@/api/federatedLearning'
import { fetchTaskOptions } from './constants'

export default {
  name: 'FlReport',
  props: {
    projectId: { type: [String, Number], default: null }
  },
  data() {
    return {
      taskOptions: [],
      taskId: '',
      reportData: {}
    }
  },
  mounted() {
    this.loadTaskOptions()
  },
  methods: {
    async loadTaskOptions() {
      // 报告只对成功(1)任务有意义
      this.taskOptions = await fetchTaskOptions({ projectId: this.projectId, taskState: 1 })
    },
    async loadReport() {
      if (!this.taskId) return
      try {
        const res = await getTrainingReport({ taskId: this.taskId })
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
    async handleGenerate() {
      if (!this.taskId) {
        this.$message.warning('请选择任务')
        return
      }
      try {
        const res = await generateTrainingReport({ taskId: this.taskId })
        if (res && res.code === 0) {
          this.$message.success('训练报告已生成')
          this.loadReport()
        } else {
          this.$message.warning('生成报告失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.$message.error('生成报告接口不可用: ' + (e.message || e))
      }
    },
    async handleExport() {
      if (!this.taskId) {
        this.$message.warning('请选择任务')
        return
      }
      try {
        await exportTrainingReport({ taskId: this.taskId })
        this.$message.success('训练报告导出成功')
      } catch (e) {
        this.$message.error('导出报告失败: ' + (e.message || e))
      }
    }
  }
}
</script>
