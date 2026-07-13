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
import { decryptPoliceData, getPoliceTaskList } from '@/api/scene'
export default {
  name: 'InsuranceDataDecrypt',
  data() {
    return {
      decrypting: false,
      previewDialogVisible: false,
      decryptForm: { ciphertextId: '', privateKeyFile: null, outputFormat: 'CSV' },
      ciphertextList: [],
      decryptTaskList: [],
      // 预览绑定真实解密输出（当解密任务完成后），暂无真实明文时保持为空，不伪造数据
      previewData: []
    }
  },
  created() {
    this.fetchTaskList()
    this.fetchCiphertextList()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    normalizeSceneTask(row) {
      let p = {}
      try { p = row.params ? JSON.parse(row.params) : {} } catch (e) { p = {} }
      const st = row.taskState
      const statusText = st === 2 ? '已完成' : st === 3 ? '失败' : st === 1 ? '运行中' : '等待执行'
      const status = st === 2 ? 'completed' : st === 3 ? 'failed' : 'running'
      return Object.assign({}, p, {
        taskId: row.id,
        taskName: row.taskName,
        taskType: row.taskType,
        status,
        statusText,
        progress: st === 2 ? 100 : st === 3 ? 0 : 50,
        createTime: row.createdAt
      })
    },
    fetchTaskList() {
      getPoliceTaskList({ taskType: 'decrypt', pageNo: 1, pageSize: 100 }).then(res => {
        if (res && res.code === 0 && res.result) {
          this.decryptTaskList = (res.result.list || []).map(this.normalizeSceneTask)
        }
      }).catch(() => {})
    },
    fetchCiphertextList() {
      getPoliceTaskList({ taskType: 'encryptedCompute', pageNo: 1, pageSize: 100 }).then(res => {
        if (res && res.code === 0 && res.result) {
          this.ciphertextList = (res.result.list || [])
            .filter(row => row.taskState === 2)
            .map(row => ({ id: row.id, name: row.taskName }))
        }
      }).catch(() => {})
    },
    handleFileChange(file) {
      this.decryptForm.privateKeyFile = file.raw
    },
    async handleDecrypt() {
      if (!this.decryptForm.ciphertextId || !this.decryptForm.privateKeyFile) {
        this.$message.warning('请选择密文结果并上传私钥文件')
        return
      }
      this.decrypting = true
      try {
        const res = await decryptPoliceData({ keyId: 1, encryptedData: this.decryptForm.ciphertextId })
        if (res && res.code === 0) {
          this.$message.success('解密任务已提交')
          this.fetchTaskList()
        }
      } catch (e) {
        this.$message.error('解密失败')
      } finally {
        this.decrypting = false
      }
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
