<template>
  <div class="app-container">
    <el-page-header content="特征密文数据安全交换（实时）" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>实时交换配置</span></div>
          <el-form ref="configForm" :model="configForm" label-width="100px">
            <el-form-item label="服务状态">
              <el-switch v-model="configForm.serviceEnabled" active-text="开启" inactive-text="关闭" @change="handleServiceToggle" />
            </el-form-item>
            <el-form-item label="监听端口">
              <el-input v-model="configForm.port" placeholder="请输入端口" style="width: 150px;" :disabled="configForm.serviceEnabled" />
            </el-form-item>
            <el-form-item label="最大并发">
              <el-input-number v-model="configForm.maxConcurrency" :min="1" :max="100" :disabled="configForm.serviceEnabled" />
            </el-form-item>
            <el-form-item label="超时时间">
              <el-input-number v-model="configForm.timeout" :min="1000" :max="60000" :step="1000" :disabled="configForm.serviceEnabled" />
              <span style="margin-left: 10px;">毫秒</span>
            </el-form-item>
            <el-form-item label="TLS加密">
              <el-switch v-model="configForm.enableTLS" :disabled="configForm.serviceEnabled" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header"><span>实时状态监控</span></div>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="服务状态">
              <el-tag :type="configForm.serviceEnabled ? 'success' : 'info'" size="small">
                {{ configForm.serviceEnabled ? '运行中' : '已停止' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="当前连接数">{{ stats.currentConnections }}</el-descriptions-item>
            <el-descriptions-item label="今日请求数">{{ stats.todayRequests }}</el-descriptions-item>
            <el-descriptions-item label="今日成功率">{{ stats.successRate }}%</el-descriptions-item>
            <el-descriptions-item label="平均响应时间">{{ stats.avgResponseTime }}ms</el-descriptions-item>
            <el-descriptions-item label="上次请求时间">{{ stats.lastRequestTime }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>实时交换记录</span>
        <el-button style="float: right;" size="mini" @click="handleRefresh">刷新</el-button>
      </div>
      <el-table :data="exchangeRecords" border max-height="400">
        <el-table-column prop="requestId" label="请求ID" width="140" />
        <el-table-column prop="sourceOrg" label="来源机构" width="120" />
        <el-table-column prop="featureType" label="特征类型" width="100" />
        <el-table-column prop="operation" label="操作类型" width="100" />
        <el-table-column prop="dataSize" label="数据大小" width="100" />
        <el-table-column prop="responseTime" label="响应时间" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'success' ? 'success' : 'danger'" size="small">
              {{ scope.row.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="requestTime" label="请求时间" width="160" />
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FeatureCipherRealTimeExchange',
  data() {
    return {
      configForm: {
        serviceEnabled: true,
        port: '8443',
        maxConcurrency: 50,
        timeout: 30000,
        enableTLS: true
      },
      stats: {
        currentConnections: 12,
        todayRequests: 8560,
        successRate: 99.2,
        avgResponseTime: 125,
        lastRequestTime: '2024-01-15 16:35:28'
      },
      exchangeRecords: [
        { requestId: 'REQ-20240115-001', sourceOrg: '工商银行', featureType: '人脸特征', operation: '验证', dataSize: '2.5 KB', responseTime: '98ms', status: 'success', requestTime: '2024-01-15 16:35:28' },
        { requestId: 'REQ-20240115-002', sourceOrg: '平安保险', featureType: '比对结果', operation: '查询', dataSize: '1.2 KB', responseTime: '65ms', status: 'success', requestTime: '2024-01-15 16:35:25' },
        { requestId: 'REQ-20240115-003', sourceOrg: '市民政局', featureType: '人脸特征', operation: '验证', dataSize: '2.8 KB', responseTime: '156ms', status: 'success', requestTime: '2024-01-15 16:35:20' },
        { requestId: 'REQ-20240115-004', sourceOrg: '工商银行', featureType: '指纹特征', operation: '验证', dataSize: '3.1 KB', responseTime: '-', status: 'failed', requestTime: '2024-01-15 16:35:15' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleServiceToggle(enabled) {
      if (enabled) {
        this.$message.success('实时交换服务已启动')
      } else {
        this.$message.warning('实时交换服务已停止')
      }
    },
    handleRefresh() {
      this.stats.todayRequests += Math.floor(Math.random() * 10)
      this.stats.currentConnections = Math.floor(Math.random() * 20) + 5
      this.stats.lastRequestTime = new Date().toLocaleString()
      this.$message.success('数据已刷新')
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
