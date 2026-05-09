<template>
  <div class="app-container">
    <el-page-header content="联邦分析对接主流关系型数据库" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>数据库连接配置</span></div>
          <el-form ref="dbForm" :model="dbFormData" :rules="dbRules" label-width="100px">
            <el-form-item label="连接名称" prop="connectionName">
              <el-input v-model="dbFormData.connectionName" placeholder="请输入连接名称" />
            </el-form-item>
            <el-form-item label="数据库类型" prop="dbType">
              <el-select v-model="dbFormData.dbType" placeholder="请选择数据库类型" style="width: 100%;">
                <el-option label="MySQL" value="MYSQL" />
                <el-option label="PostgreSQL" value="POSTGRESQL" />
                <el-option label="Oracle" value="ORACLE" />
                <el-option label="SQL Server" value="SQLSERVER" />
                <el-option label="MariaDB" value="MARIADB" />
              </el-select>
            </el-form-item>
            <el-form-item label="主机地址" prop="host">
              <el-input v-model="dbFormData.host" placeholder="请输入主机地址" />
            </el-form-item>
            <el-form-item label="端口" prop="port">
              <el-input-number v-model="dbFormData.port" :min="1" :max="65535" style="width: 100%;" />
            </el-form-item>
            <el-form-item label="数据库名" prop="database">
              <el-input v-model="dbFormData.database" placeholder="请输入数据库名" />
            </el-form-item>
            <el-form-item label="用户名" prop="username">
              <el-input v-model="dbFormData.username" placeholder="请输入用户名" />
            </el-form-item>
            <el-form-item label="密码" prop="password">
              <el-input v-model="dbFormData.password" type="password" placeholder="请输入密码" show-password />
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
          <div slot="header"><span>已配置的数据库连接</span></div>
          <el-table :data="connectionList" border max-height="400">
            <el-table-column prop="name" label="连接名称" width="150" />
            <el-table-column prop="dbType" label="数据库类型" width="100" />
            <el-table-column prop="host" label="主机" />
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
        <el-table-column prop="dbSource" label="数据库来源" width="150" />
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
  name: 'FederatedAnalysisRelationalDB',
  data() {
    return {
      dbFormData: {
        connectionName: '',
        dbType: 'MYSQL',
        host: '',
        port: 3306,
        database: '',
        username: '',
        password: ''
      },
      dbRules: {
        connectionName: [{ required: true, message: '请输入连接名称', trigger: 'blur' }],
        dbType: [{ required: true, message: '请选择数据库类型', trigger: 'change' }],
        host: [{ required: true, message: '请输入主机地址', trigger: 'blur' }],
        port: [{ required: true, message: '请输入端口', trigger: 'blur' }],
        database: [{ required: true, message: '请输入数据库名', trigger: 'blur' }],
        username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
        password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
      },
      connectionList: [
        { id: 1, name: 'MySQL生产库', dbType: 'MySQL', host: '192.168.1.100', status: 'connected' },
        { id: 2, name: 'PostgreSQL数据仓库', dbType: 'PostgreSQL', host: '192.168.1.101', status: 'connected' },
        { id: 3, name: 'Oracle历史库', dbType: 'Oracle', host: '192.168.1.102', status: 'disconnected' }
      ],
      taskList: [
        { taskId: 'FA-DB001', taskName: '用户行为联邦分析', dbSource: 'MySQL生产库', analysisType: '统计分析', createTime: '2024-01-15 10:00:00', status: 'completed' },
        { taskId: 'FA-DB002', taskName: '交易数据关联分析', dbSource: 'PostgreSQL数据仓库', analysisType: '关联分析', createTime: '2024-01-15 14:00:00', status: 'running' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleTestConnection() {
      this.$refs.dbForm.validate((valid) => {
        if (valid) {
          this.$message.success('数据库连接测试成功')
        }
      })
    },
    handleSaveConnection() {
      this.$refs.dbForm.validate((valid) => {
        if (valid) {
          this.$message.success('数据库连接保存成功')
          this.connectionList.push({
            id: Date.now(),
            name: this.dbFormData.connectionName,
            dbType: this.dbFormData.dbType,
            host: this.dbFormData.host,
            status: 'connected'
          })
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
