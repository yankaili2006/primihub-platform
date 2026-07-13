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
import { getParamTuningList, createParamTuning, getParamTuningResult, applyBestParams } from '@/api/federatedLearning'

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
      // 缺陷整改：全部改从真实接口加载（原写死 mock）
      taskList: [],
      tuningResults: [],
      tuningHistory: []
    }
  },
  created() {
    this.loadTuningList()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    loadTuningList() {
      getParamTuningList({ pageNo: 1, pageSize: 100 }).then(res => {
        const list = (res && res.result && (res.result.list || res.result)) || []
        this.tuningHistory = Array.isArray(list) ? list : []
        // 关联任务下拉：从调优历史里去重任务，避免造假任务
        const seen = {}
        this.taskList = this.tuningHistory
          .filter(t => t.taskId && !seen[t.taskId] && (seen[t.taskId] = true))
          .map(t => ({ taskId: t.taskId, taskName: t.taskName }))
      }).catch(() => { this.tuningHistory = []; this.taskList = [] })
    },
    handleStartTuning() {
      if (!this.tuningFormData.taskId) {
        this.$message.warning('请选择关联任务')
        return
      }
      createParamTuning(this.tuningFormData).then(res => {
        if (!res || res.code !== 0) {
          this.$message.error((res && (res.message || res.msg)) || '启动失败')
          return
        }
        this.$message.success('参数调优任务已启动')
        this.loadTuningList()
      }).catch(() => this.$message.error('请求异常'))
    },
    handleApplyParams(row) {
      applyBestParams({ ...row, taskId: this.tuningFormData.taskId }).then(res => {
        if (!res || res.code !== 0) {
          this.$message.error((res && (res.message || res.msg)) || '应用失败')
          return
        }
        this.$message.success('最优参数已应用')
      }).catch(() => this.$message.error('请求异常'))
    },
    handleViewHistory(row) {
      getParamTuningResult({ tuningId: row.id || row.tuningId, taskId: row.taskId }).then(res => {
        const list = (res && res.result && (res.result.list || res.result)) || []
        this.tuningResults = Array.isArray(list) ? list : []
      }).catch(() => { this.tuningResults = [] })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
