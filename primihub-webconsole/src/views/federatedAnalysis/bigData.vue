<template>
  <div class="app-container">
    <el-page-header content="联邦分析对接主流大数据平台" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>大数据平台连接配置</span></div>
          <el-form ref="platformForm" :model="platformFormData" :rules="platformRules" label-width="100px">
            <el-form-item label="连接名称" prop="connectionName">
              <el-input v-model="platformFormData.connectionName" placeholder="请输入连接名称" />
            </el-form-item>
            <el-form-item label="平台类型" prop="platformType">
              <el-select v-model="platformFormData.platformType" placeholder="请选择平台类型" style="width: 100%;" @change="handlePlatformChange">
                <el-option label="Hadoop/HDFS" value="HADOOP" />
                <el-option label="Apache Spark" value="SPARK" />
                <el-option label="Apache Hive" value="HIVE" />
                <el-option label="Apache HBase" value="HBASE" />
                <el-option label="Apache Kafka" value="KAFKA" />
                <el-option label="Elasticsearch" value="ELASTICSEARCH" />
              </el-select>
            </el-form-item>
            <el-form-item label="集群地址" prop="clusterAddress">
              <el-input v-model="platformFormData.clusterAddress" placeholder="请输入集群地址" />
            </el-form-item>
            <el-form-item label="端口" prop="port">
              <el-input-number v-model="platformFormData.port" :min="1" :max="65535" style="width: 100%;" />
            </el-form-item>
            <el-form-item label="认证方式">
              <el-select v-model="platformFormData.authType" style="width: 100%;">
                <el-option label="无认证" value="NONE" />
                <el-option label="Kerberos" value="KERBEROS" />
                <el-option label="用户名密码" value="PASSWORD" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="platformFormData.authType === 'PASSWORD'" label="用户名">
              <el-input v-model="platformFormData.username" placeholder="请输入用户名" />
            </el-form-item>
            <el-form-item v-if="platformFormData.authType === 'PASSWORD'" label="密码">
              <el-input v-model="platformFormData.password" type="password" placeholder="请输入密码" show-password />
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
          <div slot="header"><span>已配置的平台连接</span></div>
          <el-table :data="connectionList" border max-height="400">
            <el-table-column prop="name" label="连接名称" width="150" />
            <el-table-column prop="platformType" label="平台类型" width="120" />
            <el-table-column prop="clusterAddress" label="集群地址" />
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
        <el-table-column prop="platform" label="平台来源" width="150" />
        <el-table-column prop="analysisType" label="分析类型" width="120" />
        <el-table-column prop="dataSize" label="数据量" width="100" />
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
  name: 'FederatedAnalysisBigData',
  data() {
    return {
      platformFormData: {
        connectionName: '',
        platformType: 'HADOOP',
        clusterAddress: '',
        port: 9000,
        authType: 'NONE',
        username: '',
        password: ''
      },
      platformRules: {
        connectionName: [{ required: true, message: '请输入连接名称', trigger: 'blur' }],
        platformType: [{ required: true, message: '请选择平台类型', trigger: 'change' }],
        clusterAddress: [{ required: true, message: '请输入集群地址', trigger: 'blur' }],
        port: [{ required: true, message: '请输入端口', trigger: 'blur' }]
      },
      connectionList: [
        { id: 1, name: 'Hadoop生产集群', platformType: 'Hadoop/HDFS', clusterAddress: 'hdfs://192.168.1.100:9000', status: 'connected' },
        { id: 2, name: 'Spark计算集群', platformType: 'Apache Spark', clusterAddress: 'spark://192.168.1.101:7077', status: 'connected' },
        { id: 3, name: 'Hive数据仓库', platformType: 'Apache Hive', clusterAddress: '192.168.1.102:10000', status: 'connected' }
      ],
      taskList: [
        { taskId: 'FA-BD001', taskName: '大规模用户画像分析', platform: 'Hadoop生产集群', analysisType: '特征分析', dataSize: '50TB', createTime: '2024-01-15 09:00:00', status: 'completed' },
        { taskId: 'FA-BD002', taskName: '实时交易流分析', platform: 'Spark计算集群', analysisType: '流式分析', dataSize: '10GB/h', createTime: '2024-01-15 14:00:00', status: 'running' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handlePlatformChange() {
      const portMap = {
        HADOOP: 9000,
        SPARK: 7077,
        HIVE: 10000,
        HBASE: 16000,
        KAFKA: 9092,
        ELASTICSEARCH: 9200
      }
      this.platformFormData.port = portMap[this.platformFormData.platformType] || 9000
    },
    handleTestConnection() {
      this.$refs.platformForm.validate((valid) => {
        if (valid) {
          this.$message.success('大数据平台连接测试成功')
        }
      })
    },
    handleSaveConnection() {
      this.$refs.platformForm.validate((valid) => {
        if (valid) {
          this.$message.success('平台连接保存成功')
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
