<template>
  <div class="app-container">
    <el-page-header content="联邦学习模型导入" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>模型导入</span></div>
      <el-form ref="importForm" :model="importForm" label-width="120px">
        <el-form-item label="模型名称">
          <el-input v-model="importForm.modelName" placeholder="请输入模型名称" />
        </el-form-item>
        <el-form-item label="模型类型">
          <el-select v-model="importForm.modelType" placeholder="请选择模型类型" style="width: 100%;">
            <el-option label="逻辑回归" value="LR" />
            <el-option label="神经网络" value="NN" />
            <el-option label="XGBoost" value="XGB" />
            <el-option label="随机森林" value="RF" />
          </el-select>
        </el-form-item>
        <el-form-item label="模型文件">
          <el-upload
            class="upload-demo"
            drag
            action="#"
            :auto-upload="false"
            :on-change="handleFileChange"
            :file-list="fileList"
          >
            <i class="el-icon-upload" />
            <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
            <div slot="tip" class="el-upload__tip">支持 .pkl, .h5, .pt, .onnx 格式</div>
          </el-upload>
        </el-form-item>
        <el-form-item label="模型描述">
          <el-input v-model="importForm.description" type="textarea" :rows="3" placeholder="请输入模型描述" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="importing" @click="handleImport">开始导入</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>导入历史</span></div>
      <el-table :data="importHistory" border>
        <el-table-column prop="modelName" label="模型名称" width="200" />
        <el-table-column prop="modelType" label="模型类型" width="120" />
        <el-table-column prop="fileName" label="文件名" width="200" />
        <el-table-column prop="fileSize" label="文件大小" width="120" />
        <el-table-column prop="importTime" label="导入时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { importModel, getModelList } from '@/api/federatedLearning'

export default {
  name: 'FederatedModelImport',
  data() {
    return {
      importing: false,
      importForm: {
        modelName: '',
        modelType: '',
        description: ''
      },
      fileList: [],
      importHistory: []
    }
  },
  created() {
    this.loadImportHistory()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    // 缺陷整改：导入历史改从真实模型列表加载（原写死 3 行 mock）
    loadImportHistory() {
      getModelList({ modelType: 'imported', pageNo: 1, pageSize: 100 }).then(res => {
        const r = (res && res.result) || {}
        const list = r.list || r.data || (Array.isArray(r) ? r : [])
        this.importHistory = (list || []).map(m => ({
          modelName: m.modelName,
          modelType: m.modelType,
          fileName: m.fileName || m.fileUrl || '',
          fileSize: m.fileSize || '',
          importTime: m.createTime || m.importTime || '',
          status: m.status || 'success',
          statusText: m.statusText || '成功'
        }))
      }).catch(() => { this.importHistory = [] })
    },
    getStatusType(status) {
      const types = { success: 'success', failed: 'danger', importing: 'warning' }
      return types[status] || 'info'
    },
    handleFileChange(file, fileList) {
      this.fileList = fileList
    },
    handleImport() {
      if (!this.importForm.modelName || !this.importForm.modelType || this.fileList.length === 0) {
        this.$message.warning('请填写完整信息并上传模型文件')
        return
      }
      this.importing = true
      const raw = this.fileList[0].raw || this.fileList[0]
      const fd = new FormData()
      fd.append('file', raw)
      fd.append('modelName', this.importForm.modelName)
      fd.append('modelType', this.importForm.modelType)
      fd.append('description', this.importForm.description || '')
      // 缺陷整改：改为真实 multipart 上传导入（原 setTimeout 假成功、不落盘）
      importModel(fd).then(res => {
        this.importing = false
        if (!res || res.code !== 0) {
          this.$message.error((res && (res.message || res.msg)) || '导入失败')
          return
        }
        this.$message.success('模型导入成功')
        this.handleReset()
        this.loadImportHistory()
      }).catch(() => {
        this.importing = false
        this.$message.error('请求异常')
      })
    },
    handleReset() {
      this.importForm = { modelName: '', modelType: '', description: '' }
      this.fileList = []
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
