<template>
  <el-row :gutter="20">
    <el-col :span="12">
      <el-card>
        <div slot="header"><span>参数搜索配置</span></div>
        <el-form ref="tuningForm" :model="formData" label-width="120px">
          <el-form-item label="关联任务">
            <el-select v-model="formData.taskId" placeholder="请选择任务" style="width: 100%;" @change="loadResults">
              <el-option v-for="t in taskOptions" :key="t.taskId" :label="t.taskName" :value="t.taskId" />
            </el-select>
          </el-form-item>
          <el-form-item label="搜索方法">
            <el-select v-model="formData.searchMethod" style="width: 100%;">
              <el-option label="网格搜索" value="GRID" />
              <el-option label="随机搜索" value="RANDOM" />
              <el-option label="贝叶斯优化" value="BAYESIAN" />
            </el-select>
          </el-form-item>
          <el-form-item label="学习率范围">
            <el-slider v-model="formData.learningRateRange" range :min="0.0001" :max="0.1" :step="0.0001" />
          </el-form-item>
          <el-form-item label="迭代次数范围">
            <el-slider v-model="formData.iterationsRange" range :min="10" :max="1000" :step="10" />
          </el-form-item>
          <el-form-item label="批次大小">
            <el-checkbox-group v-model="formData.batchSizes">
              <el-checkbox :label="16">16</el-checkbox>
              <el-checkbox :label="32">32</el-checkbox>
              <el-checkbox :label="64">64</el-checkbox>
              <el-checkbox :label="128">128</el-checkbox>
            </el-checkbox-group>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleStart">开始调优</el-button>
          </el-form-item>
        </el-form>
      </el-card>
    </el-col>
    <el-col :span="12">
      <el-card>
        <div slot="header"><span>调优结果</span></div>
        <el-table :data="results" border max-height="400">
          <el-table-column prop="rank" label="排名" width="60" />
          <el-table-column prop="learningRate" label="学习率" width="100" />
          <el-table-column prop="iterations" label="迭代次数" width="80" />
          <el-table-column prop="batchSize" label="批次大小" width="80" />
          <el-table-column prop="accuracy" label="精度" width="80" />
          <el-table-column prop="auc" label="AUC" width="80" />
          <el-table-column label="操作" width="80">
            <template slot-scope="scope">
              <el-button size="mini" type="primary" @click="handleApply(scope.row)">应用</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div v-if="results.length === 0" style="text-align: center; color: #999; padding: 20px;">
          暂无调优结果
        </div>
      </el-card>
    </el-col>
  </el-row>
</template>

<script>
import { createParamTuning, getParamTuningResult, applyBestParams } from '@/api/federatedLearning'
import { fetchTaskOptions } from './constants'

export default {
  name: 'FlTuning',
  props: {
    projectId: { type: [String, Number], default: null }
  },
  data() {
    return {
      taskOptions: [],
      formData: {
        taskId: '',
        searchMethod: 'GRID',
        learningRateRange: [0.001, 0.01],
        iterationsRange: [50, 200],
        batchSizes: [32, 64]
      },
      results: []
    }
  },
  mounted() {
    this.loadTaskOptions()
  },
  methods: {
    async loadTaskOptions() {
      this.taskOptions = await fetchTaskOptions({ projectId: this.projectId })
    },
    async handleStart() {
      if (!this.formData.taskId) {
        this.$message.warning('请选择关联任务')
        return
      }
      try {
        const res = await createParamTuning(this.formData)
        if (res && res.code === 0) {
          this.$message.success('参数调优任务已启动')
          this.loadResults()
        } else {
          this.$message.warning('调优启动失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.$message.error('参数调优接口不可用: ' + (e.message || e))
      }
    },
    async loadResults() {
      if (!this.formData.taskId) return
      try {
        const res = await getParamTuningResult({ taskId: this.formData.taskId })
        this.results = (res && res.code === 0 && res.result) || []
      } catch (e) {
        this.results = []
      }
    },
    async handleApply(row) {
      try {
        const res = await applyBestParams({ ...row, taskId: this.formData.taskId })
        if (res && res.code === 0) {
          this.$message.success('最优参数已应用')
        } else {
          this.$message.warning('应用失败: ' + ((res && res.msg) || '后端未接通该接口'))
        }
      } catch (e) {
        this.$message.error('应用参数接口不可用: ' + (e.message || e))
      }
    }
  }
}
</script>
