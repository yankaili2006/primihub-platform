<template>
  <div class="app-container">
    <el-page-header content="联邦统计结果存储" style="margin-bottom: 20px;" @back="goBack" />
    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>存储配置</span></div>
          <el-form ref="storageForm" :model="storageFormData" :rules="storageRules" label-width="100px">
            <el-form-item label="存储名称" prop="configName">
              <el-input v-model="storageFormData.configName" placeholder="请输入存储名称" />
            </el-form-item>
            <el-form-item label="存储类型" prop="storageType">
              <el-select v-model="storageFormData.storageType" placeholder="请选择存储类型" style="width: 100%;">
                <el-option label="本地文件系统" value="LOCAL" />
                <el-option label="HDFS" value="HDFS" />
                <el-option label="对象存储(OSS/S3)" value="OBJECT_STORAGE" />
                <el-option label="数据库表" value="DATABASE" />
              </el-select>
            </el-form-item>
            <el-form-item label="存储路径" prop="storagePath">
              <el-input v-model="storageFormData.storagePath" placeholder="请输入存储路径" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="saving" @click="handleSaveConfig">保存配置</el-button>
              <el-button :loading="testing" @click="handleTestStorage">测试存储</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>存储统计</span></div>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="存储配置数">{{ storageStats.configCount }}</el-descriptions-item>
            <el-descriptions-item label="已用空间">{{ storageStats.usedSize || '-' }}</el-descriptions-item>
            <el-descriptions-item label="结果文件数">{{ storageStats.fileCount }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>
    <el-card style="margin-top: 20px;">
      <div slot="header"><span>存储结果列表</span></div>
      <el-table v-loading="listLoading" :data="resultList" border empty-text="暂无存储结果">
        <el-table-column prop="id" label="结果ID" width="100" />
        <el-table-column prop="taskName" label="统计任务" width="200" />
        <el-table-column prop="fileName" label="文件名" width="200" />
        <el-table-column prop="fileSize" label="文件大小" width="100" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="createTime" label="存储时间" width="180" />
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" @click="handlePreview(scope.row)">预览</el-button>
            <el-button size="mini" type="primary" @click="handleDownload(scope.row)">下载</el-button>
            <el-button size="mini" type="danger" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getStatsStorageConfig, saveStatsStorageConfig, testStatsStorageConnection, getStoredResults, downloadStoredResult, deleteStoredResult } from '@/api/federatedStatistics'

export default {
  name: 'FederatedStatisticsResultStorage',
  data() {
    return {
      saving: false, testing: false, listLoading: false,
      storageFormData: { configName: '', storageType: 'LOCAL', storagePath: '/data/federated_statistics/' },
      storageRules: {
        configName: [{ required: true, message: '请输入存储名称', trigger: 'blur' }],
        storageType: [{ required: true, message: '请选择存储类型', trigger: 'change' }],
        storagePath: [{ required: true, message: '请输入存储路径', trigger: 'blur' }]
      },
      storageStats: { configCount: 0, usedSize: '-', fileCount: 0 },
      resultList: []
    }
  },
  created() {
    this.fetchConfig()
    this.fetchResults()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    async fetchConfig() {
      try {
        const res = await getStatsStorageConfig()
        if (res.code === 0 && res.result?.length) {
          this.storageFormData = res.result[0]
          this.storageStats.configCount = res.result.length
        }
      } catch (e) { console.error(e) }
    },
    async handleSaveConfig() {
      this.$refs.storageForm.validate(async valid => {
        if (!valid) return
        this.saving = true
        try {
          const res = await saveStatsStorageConfig(this.storageFormData)
          if (res.code === 0) { this.$message.success('存储配置保存成功') } else { this.$message.error(res.message || '保存失败') }
        } catch (e) { this.$message.error('请求异常') }
        this.saving = false
      })
    },
    async handleTestStorage() {
      this.testing = true
      try {
        const res = await testStatsStorageConnection(this.storageFormData)
        if (res.code === 0 && res.result?.connected) { this.$message.success('存储连接测试成功') } else { this.$message.warning('存储连接测试失败: ' + (res.result?.message || '')) }
      } catch (e) { this.$message.error('请求异常') }
      this.testing = false
    },
    async fetchResults() {
      this.listLoading = true
      try { const res = await getStoredResults(); if (res.code === 0) this.resultList = res.result?.list || [] } catch (e) { console.error(e) }
      this.listLoading = false
    },
    handlePreview(row) { this.$message.info('预览功能: ' + row.fileName) },
    async handleDownload(row) {
      try {
        const res = await downloadStoredResult({ resultId: row.id })
        const blob = new Blob([res]); const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a'); link.href = url; link.download = row.fileName
        link.click(); window.URL.revokeObjectURL(url); this.$message.success('下载成功')
      } catch (e) { this.$message.error('下载失败') }
    },
    handleDelete(row) {
      this.$confirm('确认删除该结果文件?', '提示', { type: 'warning' }).then(async() => {
        try {
          const res = await deleteStoredResult({ resultId: row.id })
          if (res.code === 0) { this.$message.success('已删除'); this.fetchResults() } else { this.$message.error(res.message || '删除失败') }
        } catch (e) { this.$message.error('请求异常') }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
