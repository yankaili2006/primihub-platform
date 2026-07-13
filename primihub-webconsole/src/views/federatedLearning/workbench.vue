<!-- 已被 modelingWorkbench.vue(真实后端) 取代, 保留占位 -->
<template>
  <div class="app-container">
    <el-page-header content="联邦建模工作台" style="margin-bottom: 20px;" @back="goBack" />

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
      <el-button type="success" @click="handleStartTraining">开始训练</el-button>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>工作台历史配置</span></div>
      <el-table :data="historyConfigs" border>
        <el-table-column prop="id" label="配置ID" width="100" />
        <el-table-column prop="name" label="配置名称" width="200" />
        <el-table-column prop="algorithmType" label="算法类型" width="120" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleLoadConfig(scope.row)">加载</el-button>
            <el-button size="mini" type="danger" @click="handleDeleteConfig(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FederatedLearningWorkbench',
  data() {
    return {
      workbenchData: {
        localDataset: '',
        participants: [],
        selectedFeatures: [],
        algorithmType: '',
        learningType: 'VERTICAL',
        targetField: ''
      },
      // 已被 modelingWorkbench.vue(真实后端) 取代, 本页未路由, 置空占位不再造假数据
      datasetList: [],
      participantList: [],
      featureList: [],
      historyConfigs: []
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    getFeatureName(key) {
      const f = this.featureList.find(item => item.key === key)
      return f ? f.label : key
    },
    handleSaveWorkbench() {
      this.$message.success('工作台配置已保存')
    },
    handleStartTraining() {
      if (!this.workbenchData.algorithmType) {
        this.$message.warning('请选择算法类型')
        return
      }
      this.$message.success('训练任务已创建并启动')
    },
    handleLoadConfig(row) {
      this.$message.success(`已加载配置: ${row.name}`)
    },
    handleDeleteConfig(row) {
      this.$confirm('确认删除该配置?', '提示', { type: 'warning' }).then(() => {
        this.$message.success('配置已删除')
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.workbench-card { min-height: 350px; }
</style>
