<template>
  <div class="app-container">
    <el-page-header content="联邦建模参数调优" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>参数搜索配置</span></div>
          <el-form ref="tuningForm" :model="tuningFormData" label-width="120px">
            <el-form-item label="关联任务">
              <el-select v-model="tuningFormData.taskId" placeholder="请选择任务" style="width: 100%;">
                <el-option v-for="t in taskList" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
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

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>调优历史记录</span></div>
      <el-table :data="tuningHistory" border>
        <el-table-column prop="id" label="记录ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="200" />
        <el-table-column prop="searchMethod" label="搜索方法" width="120" />
        <el-table-column prop="bestAccuracy" label="最佳精度" width="100" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="100">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleViewHistory(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FederatedLearningParamTuning',
  data() {
    return {
      tuningFormData: {
        taskId: '',
        searchMethod: 'GRID',
        learningRateRange: [0.001, 0.01],
        iterationsRange: [50, 200],
        batchSizes: [32, 64]
      },
      taskList: [
        { taskId: 'FL-001', taskName: '联合风控模型训练' },
        { taskId: 'FL-002', taskName: '用户画像特征学习' },
        { taskId: 'FL-003', taskName: '信用评分模型' }
      ],
      tuningResults: [
        { rank: 1, learningRate: 0.005, iterations: 150, batchSize: 64, accuracy: '0.92', auc: '0.95' },
        { rank: 2, learningRate: 0.01, iterations: 100, batchSize: 32, accuracy: '0.90', auc: '0.93' },
        { rank: 3, learningRate: 0.001, iterations: 200, batchSize: 64, accuracy: '0.88', auc: '0.91' }
      ],
      tuningHistory: [
        { id: 'TH001', taskName: '联合风控模型训练', searchMethod: '网格搜索', bestAccuracy: '0.92', createTime: '2024-01-15 11:00:00' },
        { id: 'TH002', taskName: '信用评分模型', searchMethod: '贝叶斯优化', bestAccuracy: '0.89', createTime: '2024-01-14 16:00:00' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleStartTuning() {
      if (!this.tuningFormData.taskId) {
        this.$message.warning('请选择关联任务')
        return
      }
      this.$message.success('参数调优任务已启动')
    },
    handleApplyParams(row) {
      this.$message.success(`最优参数已应用: 学习率=${row.learningRate}, 迭代次数=${row.iterations}`)
    },
    handleViewHistory(row) {
      this.$message.info(`查看调优历史: ${row.id}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
