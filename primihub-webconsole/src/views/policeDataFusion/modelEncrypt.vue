<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="保险机构模型同态加密" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>模型加密配置</span></div>
      <el-form ref="encryptForm" :model="encryptForm" label-width="120px">
        <el-form-item label="选择模型">
          <el-select v-model="encryptForm.modelId" placeholder="请选择要加密的模型" style="width: 400px;">
            <el-option v-for="m in modelList" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="选择密钥">
          <el-select v-model="encryptForm.keyId" placeholder="请选择同态加密密钥" style="width: 400px;">
            <el-option v-for="k in keyList" :key="k.id" :label="`${k.org} - ${k.scheme}`" :value="k.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="加密精度">
          <el-select v-model="encryptForm.precision" style="width: 200px;">
            <el-option label="单精度 (32位)" value="single" />
            <el-option label="双精度 (64位)" value="double" />
          </el-select>
        </el-form-item>
        <el-form-item label="批处理大小">
          <el-input-number v-model="encryptForm.batchSize" :min="1" :max="10000" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="encrypting" @click="handleEncrypt">开始加密</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>加密任务列表</span></div>
      <el-table :data="encryptTaskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="modelName" label="模型名称" width="180" />
        <el-table-column prop="keyOrg" label="密钥机构" width="120" />
        <el-table-column prop="paramCount" label="参数数量" width="100" />
        <el-table-column prop="encryptedSize" label="加密后大小" width="120" />
        <el-table-column prop="progress" label="进度" width="150">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.progress" :status="scope.row.progress === 100 ? 'success' : ''" />
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" :disabled="scope.row.progress < 100" @click="handleDownload(scope.row)">下载密文</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'ModelHomomorphicEncrypt',
  data() {
    return {
      encrypting: false,
      encryptForm: { modelId: '', keyId: '', precision: 'double', batchSize: 1000 },
      modelList: [
        { id: 'M001', name: '车险欺诈检测模型' },
        { id: 'M002', name: '理赔风险评估模型' },
        { id: 'M003', name: '客户信用评分模型' }
      ],
      keyList: [
        { id: 'HK-001', org: '平安保险', scheme: 'CKKS' },
        { id: 'HK-002', org: '中国人寿', scheme: 'BFV' }
      ],
      encryptTaskList: [
        { taskId: 'ME-001', modelName: '车险欺诈检测模型', keyOrg: '平安保险', paramCount: 125000, encryptedSize: '2.3 GB', progress: 100, createTime: '2024-01-15 10:00:00' },
        { taskId: 'ME-002', modelName: '理赔风险评估模型', keyOrg: '中国人寿', paramCount: 85000, encryptedSize: '1.5 GB', progress: 75, createTime: '2024-01-15 14:30:00' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleEncrypt() {
      if (!this.encryptForm.modelId || !this.encryptForm.keyId) {
        this.$message.warning('请选择模型和密钥')
        return
      }
      this.encrypting = true
      const model = this.modelList.find(m => m.id === this.encryptForm.modelId)
      const key = this.keyList.find(k => k.id === this.encryptForm.keyId)
      const newTask = {
        taskId: `ME-${Date.now()}`,
        modelName: model.name,
        keyOrg: key.org,
        paramCount: Math.floor(Math.random() * 100000) + 50000,
        encryptedSize: '计算中...',
        progress: 0,
        createTime: new Date().toLocaleString()
      }
      this.encryptTaskList.unshift(newTask)
      const timer = setInterval(() => {
        if (newTask.progress < 100) {
          newTask.progress += 10
        } else {
          clearInterval(timer)
          newTask.encryptedSize = `${(Math.random() * 3 + 1).toFixed(1)} GB`
          this.encrypting = false
          this.$message.success('模型加密完成')
        }
      }, 500)
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.modelName} 密文`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
