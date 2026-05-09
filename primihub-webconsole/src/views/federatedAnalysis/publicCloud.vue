<template>
  <div class="app-container">
    <el-page-header content="联邦分析对接主流公有云平台" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>云平台连接配置</span></div>
          <el-form ref="cloudForm" :model="cloudFormData" :rules="cloudRules" label-width="100px">
            <el-form-item label="连接名称" prop="connectionName">
              <el-input v-model="cloudFormData.connectionName" placeholder="请输入连接名称" />
            </el-form-item>
            <el-form-item label="云平台" prop="cloudProvider">
              <el-select v-model="cloudFormData.cloudProvider" placeholder="请选择云平台" style="width: 100%;" @change="handleProviderChange">
                <el-option label="阿里云" value="ALIYUN" />
                <el-option label="腾讯云" value="TENCENT" />
                <el-option label="华为云" value="HUAWEI" />
                <el-option label="AWS" value="AWS" />
                <el-option label="Azure" value="AZURE" />
                <el-option label="Google Cloud" value="GCP" />
              </el-select>
            </el-form-item>
            <el-form-item label="服务类型" prop="serviceType">
              <el-select v-model="cloudFormData.serviceType" placeholder="请选择服务类型" style="width: 100%;">
                <el-option label="对象存储 (OSS/S3)" value="OBJECT_STORAGE" />
                <el-option label="数据仓库" value="DATA_WAREHOUSE" />
                <el-option label="大数据服务" value="BIG_DATA" />
                <el-option label="数据库服务" value="DATABASE" />
              </el-select>
            </el-form-item>
            <el-form-item label="Access Key" prop="accessKey">
              <el-input v-model="cloudFormData.accessKey" placeholder="请输入Access Key" />
            </el-form-item>
            <el-form-item label="Secret Key" prop="secretKey">
              <el-input v-model="cloudFormData.secretKey" type="password" placeholder="请输入Secret Key" show-password />
            </el-form-item>
            <el-form-item label="区域" prop="region">
              <el-select v-model="cloudFormData.region" placeholder="请选择区域" style="width: 100%;">
                <el-option v-for="r in regionList" :key="r.value" :label="r.label" :value="r.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="Endpoint">
              <el-input v-model="cloudFormData.endpoint" placeholder="请输入自定义Endpoint（可选）" />
            </el-form-item>
            <el-form-item>
              <el-button type="info" @click="handleTestConnection">测试连接</el-button>
              <el-button type="primary" @click="handleSaveConnection">保存连接</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>已配置的云平台连接</span></div>
          <el-table :data="connectionList" border max-height="400">
            <el-table-column prop="name" label="连接名称" width="150" />
            <el-table-column prop="provider" label="云平台" width="100" />
            <el-table-column prop="serviceType" label="服务类型" width="120" />
            <el-table-column prop="region" label="区域" width="100" />
            <el-table-column prop="status" label="状态" width="80">
              <template slot-scope="scope">
                <el-tag :type="scope.row.status === 'connected' ? 'success' : 'danger'" size="small">
                  {{ scope.row.status === 'connected' ? '已连接' : '断开' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150">
              <template slot-scope="scope">
                <el-button size="mini" @click="handleEditConnection(scope.row)">编辑</el-button>
                <el-button size="mini" type="danger" @click="handleDeleteConnection(scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>联邦分析任务</span></div>
      <el-button type="primary" icon="el-icon-plus" style="margin-bottom: 15px;" @click="handleCreateTask">创建分析任务</el-button>
      <el-table :data="taskList" border>
        <el-table-column prop="taskId" label="任务ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="200" />
        <el-table-column prop="cloudSource" label="云平台来源" width="150" />
        <el-table-column prop="analysisType" label="分析类型" width="120" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ getStatusLabel(scope.row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleViewTask(scope.row)">查看</el-button>
            <el-button size="mini" type="primary" @click="handleRunTask(scope.row)">执行</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FederatedAnalysisPublicCloud',
  data() {
    return {
      cloudFormData: {
        connectionName: '',
        cloudProvider: 'ALIYUN',
        serviceType: 'OBJECT_STORAGE',
        accessKey: '',
        secretKey: '',
        region: '',
        endpoint: ''
      },
      cloudRules: {
        connectionName: [{ required: true, message: '请输入连接名称', trigger: 'blur' }],
        cloudProvider: [{ required: true, message: '请选择云平台', trigger: 'change' }],
        serviceType: [{ required: true, message: '请选择服务类型', trigger: 'change' }],
        accessKey: [{ required: true, message: '请输入Access Key', trigger: 'blur' }],
        secretKey: [{ required: true, message: '请输入Secret Key', trigger: 'blur' }],
        region: [{ required: true, message: '请选择区域', trigger: 'change' }]
      },
      regionList: [
        { value: 'cn-hangzhou', label: '华东1（杭州）' },
        { value: 'cn-shanghai', label: '华东2（上海）' },
        { value: 'cn-beijing', label: '华北2（北京）' },
        { value: 'cn-shenzhen', label: '华南1（深圳）' }
      ],
      connectionList: [
        { id: 1, name: '阿里云OSS', provider: '阿里云', serviceType: '对象存储', region: '华东1', status: 'connected' },
        { id: 2, name: '腾讯云数仓', provider: '腾讯云', serviceType: '数据仓库', region: '华南1', status: 'connected' },
        { id: 3, name: 'AWS S3', provider: 'AWS', serviceType: '对象存储', region: 'ap-east-1', status: 'connected' }
      ],
      taskList: [
        { taskId: 'FA-CL001', taskName: '跨云数据联邦分析', cloudSource: '阿里云OSS', analysisType: '聚合分析', createTime: '2024-01-15 10:00:00', status: 'completed' },
        { taskId: 'FA-CL002', taskName: '云端用户行为分析', cloudSource: '腾讯云数仓', analysisType: '行为分析', createTime: '2024-01-15 14:00:00', status: 'running' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleProviderChange() {
      const regionMap = {
        ALIYUN: [
          { value: 'cn-hangzhou', label: '华东1（杭州）' },
          { value: 'cn-shanghai', label: '华东2（上海）' },
          { value: 'cn-beijing', label: '华北2（北京）' }
        ],
        TENCENT: [
          { value: 'ap-guangzhou', label: '广州' },
          { value: 'ap-shanghai', label: '上海' },
          { value: 'ap-beijing', label: '北京' }
        ],
        AWS: [
          { value: 'us-east-1', label: 'US East (N. Virginia)' },
          { value: 'ap-southeast-1', label: 'Asia Pacific (Singapore)' }
        ],
        HUAWEI: [
          { value: 'cn-north-4', label: '华北-北京四' },
          { value: 'cn-south-1', label: '华南-广州' }
        ]
      }
      this.regionList = regionMap[this.cloudFormData.cloudProvider] || []
      this.cloudFormData.region = ''
    },
    handleTestConnection() {
      this.$refs.cloudForm.validate((valid) => {
        if (valid) {
          this.$message.success('云平台连接测试成功')
        }
      })
    },
    handleSaveConnection() {
      this.$refs.cloudForm.validate((valid) => {
        if (valid) {
          this.$message.success('云平台连接保存成功')
        }
      })
    },
    handleEditConnection(row) {
      this.$message.info(`编辑连接: ${row.name}`)
    },
    handleDeleteConnection(row) {
      this.$confirm('确认删除该连接?', '提示', { type: 'warning' }).then(() => {
        this.$message.success('连接已删除')
      }).catch(() => {})
    },
    handleCreateTask() {
      this.$message.info('创建联邦分析任务')
    },
    handleViewTask(row) {
      this.$message.info(`查看任务: ${row.taskName}`)
    },
    handleRunTask(row) {
      this.$message.success(`任务 ${row.taskName} 已开始执行`)
    },
    getStatusType(status) {
      const map = { completed: 'success', running: 'warning', failed: 'danger', pending: 'info' }
      return map[status] || 'info'
    },
    getStatusLabel(status) {
      const map = { completed: '已完成', running: '执行中', failed: '失败', pending: '待执行' }
      return map[status] || status
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
