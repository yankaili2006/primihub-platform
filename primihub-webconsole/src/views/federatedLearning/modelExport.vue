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
import { getModelList, downloadModel } from '@/api/federatedLearning'

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
      modelList: [],
      // 缺陷整改：后端无“模型导出历史”接口，导出为即时下载 blob，不留服务端记录；置空不再造假数据
      exportHistory: []
    }
  },
  mounted() {
    this.fetchModels()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    // 缺陷整改 T2：模型下拉改真实模型列表
    fetchModels() {
      getModelList({ pageNo: 1, pageSize: 200 }).then(res => {
        const r = res && res.result ? res.result : {}
        this.modelList = r.data || r.list || []
      }).catch(() => { this.modelList = [] })
    },
    handleModelChange(modelId) {
      this.selectedModel = this.modelList.find(m => m.modelId === modelId)
    },
    // 缺陷整改 T2：改为真实下载模型文件（原 setTimeout 假成功、不产文件）；加密/格式选项后端暂不支持
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
      downloadModel({ modelId: this.exportForm.modelId }).then(response => {
        const blob = new Blob([response], { type: 'application/octet-stream' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        const name = this.selectedModel ? this.selectedModel.modelName : 'model'
        link.download = `${name}_${new Date().getTime()}.${this.exportForm.format}`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('模型导出成功')
      }).catch(() => {
        this.$message.error('模型导出失败')
      }).finally(() => {
        this.exporting = false
      })
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
