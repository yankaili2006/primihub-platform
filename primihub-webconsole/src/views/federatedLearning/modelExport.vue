<template>
  <div class="app-container">
    <el-page-header content="联邦学习模型导出" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>选择导出模型</span></div>
      <el-form ref="exportForm" :model="exportForm" label-width="120px">
        <el-form-item label="选择模型">
          <el-select v-model="exportForm.modelId" placeholder="请选择要导出的模型" style="width: 100%;" @change="handleModelChange">
            <el-option v-for="item in modelList" :key="item.modelId" :label="item.modelName" :value="item.modelId" />
          </el-select>
        </el-form-item>
        <el-form-item label="导出格式">
          <el-radio-group v-model="exportForm.format">
            <el-radio label="pkl">Pickle (.pkl)</el-radio>
            <el-radio label="h5">HDF5 (.h5)</el-radio>
            <el-radio label="onnx">ONNX (.onnx)</el-radio>
            <el-radio label="pt">PyTorch (.pt)</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="包含元数据">
          <el-switch v-model="exportForm.includeMetadata" />
        </el-form-item>
        <el-form-item label="加密导出">
          <el-switch v-model="exportForm.encrypt" />
        </el-form-item>
        <el-form-item v-if="exportForm.encrypt" label="加密密码">
          <el-input v-model="exportForm.password" type="password" placeholder="请输入加密密码" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="exporting" @click="handleExport">导出模型</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card v-if="selectedModel" style="margin-top: 20px;">
      <div slot="header"><span>模型信息</span></div>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="模型ID">{{ selectedModel.modelId }}</el-descriptions-item>
        <el-descriptions-item label="模型名称">{{ selectedModel.modelName }}</el-descriptions-item>
        <el-descriptions-item label="模型类型">{{ selectedModel.modelType }}</el-descriptions-item>
        <el-descriptions-item label="准确率">{{ selectedModel.accuracy }}%</el-descriptions-item>
        <el-descriptions-item label="参与方数量">{{ selectedModel.participants }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ selectedModel.createTime }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>导出历史</span></div>
      <el-table :data="exportHistory" border>
        <el-table-column prop="modelName" label="模型名称" width="200" />
        <el-table-column prop="format" label="格式" width="100" />
        <el-table-column prop="fileSize" label="文件大小" width="120" />
        <el-table-column prop="exportTime" label="导出时间" width="180" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleDownload(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FederatedModelExport',
  data() {
    return {
      exporting: false,
      exportForm: {
        modelId: '',
        format: 'pkl',
        includeMetadata: true,
        encrypt: false,
        password: ''
      },
      selectedModel: null,
      modelList: [
        { modelId: 'FL-M-001', modelName: '逻辑回归模型', modelType: 'LR', accuracy: 92.5, participants: 3, createTime: '2024-01-15 10:30:00' },
        { modelId: 'FL-M-002', modelName: '神经网络模型', modelType: 'NN', accuracy: 95.8, participants: 5, createTime: '2024-01-14 14:20:00' },
        { modelId: 'FL-M-003', modelName: 'XGBoost模型', modelType: 'XGB', accuracy: 94.2, participants: 4, createTime: '2024-01-16 09:15:00' }
      ],
      exportHistory: [
        { modelName: '逻辑回归模型', format: 'pkl', fileSize: '2.5MB', exportTime: '2024-01-15 15:30:00' },
        { modelName: '神经网络模型', format: 'h5', fileSize: '15.8MB', exportTime: '2024-01-14 16:20:00' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleModelChange(modelId) {
      this.selectedModel = this.modelList.find(m => m.modelId === modelId)
    },
    handleExport() {
      if (!this.exportForm.modelId) {
        this.$message.warning('请选择要导出的模型')
        return
      }
      if (this.exportForm.encrypt && !this.exportForm.password) {
        this.$message.warning('请输入加密密码')
        return
      }
      this.exporting = true
      setTimeout(() => {
        this.exporting = false
        this.$message.success('模型导出成功')
        this.exportHistory.unshift({
          modelName: this.selectedModel.modelName,
          format: this.exportForm.format,
          fileSize: Math.floor(Math.random() * 20 + 1) + 'MB',
          exportTime: new Date().toLocaleString()
        })
      }, 2000)
    },
    handleReset() {
      this.exportForm = { modelId: '', format: 'pkl', includeMetadata: true, encrypt: false, password: '' }
      this.selectedModel = null
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.modelName}.${row.format}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
