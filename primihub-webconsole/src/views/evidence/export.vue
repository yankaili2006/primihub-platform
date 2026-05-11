<template>
  <div class="container">
    <el-row :gutter="20">
      <el-col :span="16">
        <el-card class="export-card">
          <div slot="header"><i class="el-icon-download" /> 存证导出</div>
          <el-form ref="exportForm" :model="exportForm" :rules="exportRules" label-width="120px">
            <el-form-item label="导出方式">
              <el-radio-group v-model="exportType" @change="handleExportTypeChange">
                <el-radio label="SINGLE">单个导出</el-radio>
                <el-radio label="BATCH">批量导出</el-radio>
                <el-radio label="CONDITION">条件导出</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item v-if="exportType === 'SINGLE'" label="存证ID" prop="evidenceId">
              <el-input v-model="exportForm.evidenceId" placeholder="请输入存证ID" />
            </el-form-item>
            <el-form-item v-if="exportType === 'BATCH'" label="存证ID列表" prop="evidenceIds">
              <el-input v-model="exportForm.evidenceIds" type="textarea" :rows="4" placeholder="多个ID用逗号分隔" />
            </el-form-item>
            <el-form-item v-if="exportType === 'CONDITION'" label="时间范围" prop="dateRange">
              <el-date-picker v-model="exportForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" style="width: 100%;" />
            </el-form-item>
            <el-form-item label="加密方式">
              <el-select v-model="exportForm.encryptType" style="width: 100%;">
                <el-option label="不加密" value="NONE" />
                <el-option label="AES-256" value="AES256" />
                <el-option label="RSA-2048" value="RSA2048" />
                <el-option label="SM4国密" value="SM4" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="exportForm.encryptType !== 'NONE'" label="加密密码" prop="password">
              <el-input v-model="exportForm.password" type="password" show-password placeholder="请输入加密密码，至少6位" />
              <el-tooltip v-if="exportForm.password" placement="right" :content="passwordStrengthText">
                <el-progress :percentage="passwordStrength" :status="passwordStrengthStatus" style="width:120px;display:inline-block;margin-left:10px;" />
              </el-tooltip>
            </el-form-item>
            <el-form-item label="导出格式">
              <el-select v-model="exportForm.format" style="width: 100%;">
                <el-option label="ZIP压缩包" value="ZIP" />
                <el-option label="JSON格式" value="JSON" />
                <el-option label="PDF证书" value="PDF" />
              </el-select>
            </el-form-item>
            <el-form-item label="包含内容">
              <el-checkbox-group v-model="exportForm.includeItems">
                <el-checkbox label="EVIDENCE">存证数据</el-checkbox>
                <el-checkbox label="TIMESTAMP">时间戳</el-checkbox>
                <el-checkbox label="CERTIFICATE">证书</el-checkbox>
                <el-checkbox label="BLOCKCHAIN">区块链信息</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="exporting" @click="handleExport">开始导出</el-button>
              <el-button @click="resetForm">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card class="history-card">
          <div slot="header"><i class="el-icon-time" /> 导出历史</div>
          <el-timeline>
            <el-timeline-item v-for="item in historyList" :key="item.id" :timestamp="item.createTime" placement="top">
              <el-card><h4>{{ item.fileName }}</h4><p>格式：{{ item.format }} | 大小：{{ item.fileSize }}</p><el-button type="text" size="small" @click="downloadHistory(item)">下载</el-button></el-card>
            </el-timeline-item>
            <el-empty v-if="historyList.length === 0" description="暂无导出历史" />
          </el-timeline>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { exportEvidence, encryptExport, getExportHistory } from '@/api/evidence'

export default {
  name: 'EvidenceExport',
  data() {
    return {
      exportType: 'SINGLE', exporting: false,
      exportForm: { evidenceId: '', evidenceIds: '', dateRange: [], encryptType: 'NONE', password: '', format: 'ZIP', includeItems: ['EVIDENCE'] },
      exportRules: {
        evidenceId: [{ required: true, message: '请输入存证ID', trigger: 'blur' }],
        evidenceIds: [{ required: true, message: '请输入存证ID列表', trigger: 'blur' }],
        dateRange: [{ required: true, message: '请选择时间范围', trigger: 'change' }],
        password: [{ min: 6, message: '密码至少6位', trigger: 'blur' }]
      },
      historyList: []
    }
  },
  computed: {
    passwordStrength() {
      const pwd = this.exportForm.password || ''
      let score = 0
      if (pwd.length >= 6) score += 20
      if (pwd.length >= 10) score += 20
      if (/[a-z]/.test(pwd) && /[A-Z]/.test(pwd)) score += 20
      if (/\d/.test(pwd)) score += 20
      if (/[^a-zA-Z0-9]/.test(pwd)) score += 20
      return score
    },
    passwordStrengthText() {
      if (this.passwordStrength < 40) return '弱'
      if (this.passwordStrength < 80) return '中'
      return '强'
    },
    passwordStrengthStatus() {
      if (this.passwordStrength < 40) return 'exception'
      if (this.passwordStrength < 80) return 'warning'
      return 'success'
    }
  },
  created() { this.fetchHistory() },
  methods: {
    handleExportTypeChange() { this.$refs.exportForm?.clearValidate() },
    async handleExport() {
      this.$refs.exportForm.validate(async valid => {
        if (!valid) return
        this.exporting = true
        try {
          const params = { ...this.exportForm, exportType: this.exportType }
          const res = this.exportForm.encryptType !== 'NONE' ? await encryptExport(params) : await exportEvidence(params)
          const blob = new Blob([res]); const url = window.URL.createObjectURL(blob)
          const link = document.createElement('a'); link.href = url; link.download = `evidence_export_${Date.now()}.zip`
          link.click(); window.URL.revokeObjectURL(url); this.$message.success('导出成功')
          this.fetchHistory()
        } catch (e) { this.$message.error('导出失败') }
        this.exporting = false
      })
    },
    resetForm() {
      this.exportForm = { evidenceId: '', evidenceIds: '', dateRange: [], encryptType: 'NONE', password: '', format: 'ZIP', includeItems: ['EVIDENCE'] }
      this.exportType = 'SINGLE'
      this.$refs.exportForm?.clearValidate()
    },
    async fetchHistory() {
      try { const res = await getExportHistory(); if (res.code === 0) this.historyList = res.result || [] } catch (e) { console.error(e) }
    },
    downloadHistory(item) {
      this.$message.info('历史文件下载: ' + item.fileName)
    }
  }
}
</script>

<style lang="scss" scoped>
.container { padding: 20px; background-color: #f0f2f5; }
</style>
