<template>
  <div>
    <el-row style="margin-bottom: 15px;">
      <el-select v-model="taskId" placeholder="选择运行中任务" style="width: 300px;" @change="refresh">
        <el-option v-for="t in taskOptions" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
      </el-select>
      <el-button type="primary" style="margin-left: 10px;" @click="refresh">刷新数据</el-button>
      <el-button style="margin-left: 10px;" @click="loadTaskOptions">刷新任务列表</el-button>
    </el-row>
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
  </div>
</template>

<script>
import { getTrainingIterations } from '@/api/federatedLearning'
import { fetchTaskOptions } from './constants'

export default {
  name: 'FlIteration',
  props: {
    projectId: { type: [String, Number], default: null }
  },
  data() {
    return {
      taskOptions: [],
      taskId: '',
      iterationData: []
    }
  },
  mounted() {
    this.loadTaskOptions()
  },
  methods: {
    async loadTaskOptions() {
      // 迭代数据只对运行中(2)任务有意义
      this.taskOptions = await fetchTaskOptions({ projectId: this.projectId, taskState: 2 })
    },
    async refresh() {
      if (!this.taskId) return
      try {
        const res = await getTrainingIterations({ taskId: this.taskId })
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
    }
  }
}
</script>
