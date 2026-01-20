<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦统计结果存储" style="margin-bottom: 20px;" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>存储配置</span></div>
          <el-form ref="storageForm" :model="storageFormData" :rules="storageRules" label-width="100px">
            <el-form-item label="存储名称" prop="storageName">
              <el-input v-model="storageFormData.storageName" placeholder="请输入存储名称" />
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
            <el-form-item label="数据格式">
              <el-select v-model="storageFormData.dataFormat" style="width: 100%;">
                <el-option label="CSV" value="CSV" />
                <el-option label="JSON" value="JSON" />
                <el-option label="Parquet" value="PARQUET" />
                <el-option label="ORC" value="ORC" />
              </el-select>
            </el-form-item>
            <el-form-item label="压缩方式">
              <el-select v-model="storageFormData.compression" style="width: 100%;">
                <el-option label="无压缩" value="NONE" />
                <el-option label="GZIP" value="GZIP" />
                <el-option label="SNAPPY" value="SNAPPY" />
                <el-option label="LZ4" value="LZ4" />
              </el-select>
            </el-form-item>
            <el-form-item label="保留策略">
              <el-select v-model="storageFormData.retentionPolicy" style="width: 100%;">
                <el-option label="永久保留" value="FOREVER" />
                <el-option label="7天" value="7D" />
                <el-option label="30天" value="30D" />
                <el-option label="90天" value="90D" />
                <el-option label="1年" value="1Y" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handleSaveConfig">保存配置</el-button>
              <el-button @click="handleTestStorage">测试存储</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>存储统计</span></div>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="总存储量">{{ storageStats.totalSize }}</el-descriptions-item>
            <el-descriptions-item label="已用空间">{{ storageStats.usedSize }}</el-descriptions-item>
            <el-descriptions-item label="剩余空间">{{ storageStats.freeSize }}</el-descriptions-item>
            <el-descriptions-item label="结果文件数">{{ storageStats.fileCount }}</el-descriptions-item>
            <el-descriptions-item label="最近存储时间">{{ storageStats.lastStorageTime }}</el-descriptions-item>
          </el-descriptions>
          <div style="margin-top: 20px;">
            <el-progress :percentage="storageStats.usagePercent" :status="storageStats.usagePercent > 80 ? 'exception' : ''" />
            <p style="text-align: center; margin-top: 10px; color: #666;">存储空间使用率</p>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>存储结果列表</span></div>
      <el-table :data="resultList" border>
        <el-table-column prop="id" label="结果ID" width="100" />
        <el-table-column prop="taskName" label="统计任务" width="200" />
        <el-table-column prop="fileName" label="文件名" width="200" />
        <el-table-column prop="fileSize" label="文件大小" width="100" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="createTime" label="存储时间" width="180" />
        <el-table-column prop="expireTime" label="过期时间" width="180" />
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
export default {
  name: 'FederatedStatisticsResultStorage',
  data() {
    return {
      storageFormData: {
        storageName: '',
        storageType: 'LOCAL',
        storagePath: '/data/federated_statistics/',
        dataFormat: 'CSV',
        compression: 'NONE',
        retentionPolicy: '30D'
      },
      storageRules: {
        storageName: [{ required: true, message: '请输入存储名称', trigger: 'blur' }],
        storageType: [{ required: true, message: '请选择存储类型', trigger: 'change' }],
        storagePath: [{ required: true, message: '请输入存储路径', trigger: 'blur' }]
      },
      storageStats: {
        totalSize: '100 GB',
        usedSize: '35.6 GB',
        freeSize: '64.4 GB',
        fileCount: 156,
        lastStorageTime: '2024-01-15 15:30:00',
        usagePercent: 35.6
      },
      resultList: [
        { id: 'SR001', taskName: '用户分布统计', fileName: 'user_distribution_20240115.csv', fileSize: '2.5 MB', format: 'CSV', createTime: '2024-01-15 10:00:00', expireTime: '2024-02-14 10:00:00' },
        { id: 'SR002', taskName: '交易金额统计', fileName: 'transaction_stats_20240115.json', fileSize: '1.8 MB', format: 'JSON', createTime: '2024-01-15 14:00:00', expireTime: '2024-02-14 14:00:00' },
        { id: 'SR003', taskName: '风险评分分布', fileName: 'risk_score_dist_20240114.parquet', fileSize: '5.2 MB', format: 'Parquet', createTime: '2024-01-14 16:00:00', expireTime: '2024-02-13 16:00:00' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleSaveConfig() {
      this.$refs.storageForm.validate((valid) => {
        if (valid) {
          this.$message.success('存储配置保存成功')
        }
      })
    },
    handleTestStorage() {
      this.$message.success('存储连接测试成功')
    },
    handlePreview(row) {
      this.$message.info(`预览结果: ${row.fileName}`)
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.fileName}`)
    },
    handleDelete(row) {
      this.$confirm('确认删除该结果文件?', '提示', { type: 'warning' }).then(() => {
        this.$message.success('结果文件已删除')
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
