<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦建模训练迭代" style="margin-bottom: 20px;" />

    <el-row style="margin-bottom: 15px;">
      <el-select v-model="iterationTaskId" placeholder="选择任务" style="width: 300px;" @change="handleTaskChange">
        <el-option v-for="t in runningTasks" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
      </el-select>
      <el-button type="primary" style="margin-left: 10px;" @click="refreshData">刷新数据</el-button>
      <el-button type="success" style="margin-left: 10px;" @click="handleExportData">导出数据</el-button>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>损失曲线</span></div>
          <div ref="lossChart" style="height: 300px;">
            <el-empty v-if="!iterationTaskId" description="请选择任务" />
            <div v-else style="text-align: center; padding: 100px 0; color: #999;">
              损失曲线图表区域<br/>
              <small>当前损失值: {{ currentLoss }}</small>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>精度曲线</span></div>
          <div ref="accuracyChart" style="height: 300px;">
            <el-empty v-if="!iterationTaskId" description="请选择任务" />
            <div v-else style="text-align: center; padding: 100px 0; color: #999;">
              精度曲线图表区域<br/>
              <small>当前精度: {{ currentAccuracy }}</small>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;">
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
            <el-table-column prop="status" label="状态" width="100">
              <template slot-scope="scope">
                <el-tag :type="scope.row.status === 'completed' ? 'success' : 'warning'" size="small">
                  {{ scope.row.status === 'completed' ? '已完成' : '进行中' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
export default {
  name: 'FederatedLearningTrainingIteration',
  data() {
    return {
      iterationTaskId: '',
      runningTasks: [
        { taskId: 'FL-001', taskName: '联合风控模型训练' },
        { taskId: 'FL-002', taskName: '用户画像特征学习' }
      ],
      iterationData: [],
      currentLoss: '0.12',
      currentAccuracy: '0.88'
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleTaskChange() {
      this.refreshData()
    },
    refreshData() {
      if (!this.iterationTaskId) return
      this.iterationData = Array.from({ length: 10 }, (_, i) => ({
        epoch: i + 1,
        loss: (0.5 - i * 0.04).toFixed(4),
        accuracy: (0.6 + i * 0.03).toFixed(4),
        learningRate: '0.01',
        duration: (2.5 + Math.random()).toFixed(2),
        timestamp: new Date(Date.now() - (10 - i) * 60000).toLocaleString(),
        status: i < 8 ? 'completed' : 'running'
      }))
      this.$message.success('数据已刷新')
    },
    handleExportData() {
      this.$message.success('迭代数据导出成功')
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
