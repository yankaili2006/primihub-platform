<template>
  <div class="container">
    <el-row :gutter="20">
      <!-- 导出操作卡片 -->
      <el-col :span="16">
        <el-card class="export-card">
          <div slot="header"><i class="el-icon-download" /> 存证导出</div>
          <el-form :model="exportForm" label-width="120px">
            <el-form-item label="导出方式">
              <el-radio-group v-model="exportType">
                <el-radio label="SINGLE">单个导出</el-radio>
                <el-radio label="BATCH">批量导出</el-radio>
                <el-radio label="CONDITION">条件导出</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item v-if="exportType === 'SINGLE'" label="存证ID">
              <el-input v-model="exportForm.evidenceId" placeholder="请输入存证ID" />
            </el-form-item>
            <el-form-item v-if="exportType === 'BATCH'" label="存证ID列表">
              <el-input v-model="exportForm.evidenceIds" type="textarea" :rows="4" placeholder="多个ID用逗号分隔" />
            </el-form-item>
            <el-form-item v-if="exportType === 'CONDITION'" label="时间范围">
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
            <el-form-item v-if="exportForm.encryptType !== 'NONE'" label="加密密码">
              <el-input v-model="exportForm.password" type="password" show-password placeholder="请输入加密密码" />
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

      <!-- 导出历史 -->
      <el-col :span="8">
        <el-card class="history-card">
          <div slot="header"><i class="el-icon-time" /> 导出历史</div>
          <el-timeline>
            <el-timeline-item v-for="item in historyList" :key="item.id" :timestamp="item.createTime" placement="top">
              <el-card>
                <h4>{{ item.fileName }}</h4>
                <p>格式：{{ item.format }} | 大小：{{ item.fileSize }}</p>
                <el-button type="text" size="small" @click="downloadHistory(item)">下载</el-button>
              </el-card>
            </el-timeline-item>
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
      exportType: 'SINGLE',
      exportForm: {
        evidenceId: '',
        evidenceIds: '',
        dateRange: [],
        encryptType: 'NONE',
        password: '',
        format: 'ZIP',
        includeItems: ['EVIDENCE']
      },
      exporting: false,
      historyList: []
    }
  },
  created() {
    this.fetchHistory()
  },
  methods: {
    async fetchHistory() {
      const res = await getExportHistory()
      if (res.code === 0) {
        this.historyList = res.result || []
      }
    },
    async handleExport() {
      this.exporting = true
      const res = this.exportForm.encryptType === 'NONE'
        ? await exportEvidence(this.exportForm)
        : await encryptExport(this.exportForm)
      this.exporting = false
      if (res) {
        this.$message.success('导出成功')
        this.fetchHistory()
      }
    },
    resetForm() {
      this.exportForm = {
        evidenceId: '',
        evidenceIds: '',
        dateRange: [],
        encryptType: 'NONE',
        password: '',
        format: 'ZIP',
        includeItems: ['EVIDENCE']
      }
    },
    downloadHistory(item) {
      // TODO: 实现下载
      this.$message.info('下载功能开发中...')
    }
  }
}
</script>

<style lang="scss" scoped>
.container { padding: 20px; background-color: #f0f2f5; }
.export-card, .history-card { min-height: 600px; }
</style>
