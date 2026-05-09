<template>
  <div class="app-container">
    <el-page-header content="保险机构数据解密" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>解密配置</span></div>
      <el-form ref="decryptForm" :model="decryptForm" label-width="120px">
        <el-form-item label="选择密文结果">
          <el-select v-model="decryptForm.ciphertextId" placeholder="请选择要解密的密文结果" style="width: 400px;">
            <el-option v-for="c in ciphertextList" :key="c.id" :label="c.name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="私钥文件">
          <el-upload :auto-upload="false" :on-change="handleFileChange" :limit="1" action="">
            <el-button size="small" type="primary">选择私钥文件</el-button>
          </el-upload>
          <span v-if="decryptForm.privateKeyFile" style="margin-left: 10px; color: #67C23A;">{{ decryptForm.privateKeyFile.name }}</span>
        </el-form-item>
        <el-form-item label="解密输出格式">
          <el-select v-model="decryptForm.outputFormat" style="width: 200px;">
            <el-option label="CSV" value="CSV" />
            <el-option label="JSON" value="JSON" />
            <el-option label="Excel" value="EXCEL" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="decrypting" @click="handleDecrypt">开始解密</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>解密任务列表</span></div>
      <el-table :data="decryptTaskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="ciphertextName" label="密文结果" width="200" />
        <el-table-column prop="recordCount" label="记录数" width="100" />
        <el-table-column prop="decryptedSize" label="解密后大小" width="120" />
        <el-table-column prop="outputFormat" label="输出格式" width="100" />
        <el-table-column prop="progress" label="进度" width="150">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.progress" :status="scope.row.progress === 100 ? 'success' : ''" />
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="180">
          <template slot-scope="scope">
            <el-button size="mini" type="text" :disabled="scope.row.progress < 100" @click="handlePreview(scope.row)">预览</el-button>
            <el-button size="mini" type="text" :disabled="scope.row.progress < 100" @click="handleDownload(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog :visible.sync="previewDialogVisible" title="解密结果预览" width="800px">
      <el-table :data="previewData" border max-height="400">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="idCard" label="身份证号" width="180" />
        <el-table-column prop="riskScore" label="风险评分" width="100" />
        <el-table-column prop="fraudProbability" label="欺诈概率" width="100" />
        <el-table-column prop="recommendation" label="建议" />
      </el-table>
      <span slot="footer">
        <el-button @click="previewDialogVisible = false">关闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'InsuranceDataDecrypt',
  data() {
    return {
      decrypting: false,
      previewDialogVisible: false,
      decryptForm: { ciphertextId: '', privateKeyFile: null, outputFormat: 'CSV' },
      ciphertextList: [
        { id: 'CT001', name: '车险欺诈检测结果-20240115' },
        { id: 'CT002', name: '理赔风险评估结果-20240114' },
        { id: 'CT003', name: '客户信用评分结果-20240113' }
      ],
      decryptTaskList: [
        { taskId: 'DT-001', ciphertextName: '车险欺诈检测结果', recordCount: 15000, decryptedSize: '12.5 MB', outputFormat: 'CSV', progress: 100, createTime: '2024-01-15 15:00:00' },
        { taskId: 'DT-002', ciphertextName: '理赔风险评估结果', recordCount: 8000, decryptedSize: '6.8 MB', outputFormat: 'JSON', progress: 65, createTime: '2024-01-15 16:30:00' }
      ],
      previewData: [
        { id: 1, idCard: '310***********1234', riskScore: 85, fraudProbability: '0.12', recommendation: '需人工复核' },
        { id: 2, idCard: '320***********5678', riskScore: 32, fraudProbability: '0.02', recommendation: '正常通过' },
        { id: 3, idCard: '330***********9012', riskScore: 95, fraudProbability: '0.89', recommendation: '高度可疑' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleFileChange(file) {
      this.decryptForm.privateKeyFile = file.raw
    },
    handleDecrypt() {
      if (!this.decryptForm.ciphertextId || !this.decryptForm.privateKeyFile) {
        this.$message.warning('请选择密文结果并上传私钥文件')
        return
      }
      this.decrypting = true
      const ct = this.ciphertextList.find(c => c.id === this.decryptForm.ciphertextId)
      const newTask = {
        taskId: `DT-${Date.now()}`,
        ciphertextName: ct.name,
        recordCount: Math.floor(Math.random() * 10000) + 5000,
        decryptedSize: '计算中...',
        outputFormat: this.decryptForm.outputFormat,
        progress: 0,
        createTime: new Date().toLocaleString()
      }
      this.decryptTaskList.unshift(newTask)
      const timer = setInterval(() => {
        if (newTask.progress < 100) {
          newTask.progress += 10
        } else {
          clearInterval(timer)
          newTask.decryptedSize = `${(Math.random() * 15 + 5).toFixed(1)} MB`
          this.decrypting = false
          this.$message.success('解密完成')
        }
      }, 400)
    },
    handlePreview(row) {
      this.previewDialogVisible = true
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.ciphertextName}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
