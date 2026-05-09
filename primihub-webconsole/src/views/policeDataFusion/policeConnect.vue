<template>
  <div class="app-container">
    <el-page-header content="警务数据对接" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header">
        <span>数据源管理</span>
        <el-button style="float: right;" size="mini" type="primary" @click="handleAddSource">新增数据源</el-button>
      </div>
      <el-table :data="dataSourceList" border>
        <el-table-column prop="sourceId" label="数据源ID" width="100" />
        <el-table-column prop="sourceName" label="数据源名称" width="180" />
        <el-table-column prop="sourceType" label="类型" width="100" />
        <el-table-column prop="department" label="所属部门" width="150" />
        <el-table-column prop="connectionInfo" label="连接信息" width="250" />
        <el-table-column prop="dataCount" label="数据量" width="100" />
        <el-table-column prop="lastSyncTime" label="最后同步时间" width="160" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'connected' ? 'success' : 'danger'" size="small">
              {{ scope.row.status === 'connected' ? '已连接' : '断开' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleSync(scope.row)">同步</el-button>
            <el-button size="mini" type="text" @click="handleTest(scope.row)">测试</el-button>
            <el-button size="mini" type="text" @click="handleEdit(scope.row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>数据同步记录</span></div>
      <el-table :data="syncRecords" border>
        <el-table-column prop="syncId" label="同步ID" width="120" />
        <el-table-column prop="sourceName" label="数据源" width="150" />
        <el-table-column prop="syncType" label="同步类型" width="100" />
        <el-table-column prop="recordCount" label="同步数据量" width="120" />
        <el-table-column prop="duration" label="耗时" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'success' ? 'success' : 'danger'" size="small">
              {{ scope.row.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="syncTime" label="同步时间" width="160" />
      </el-table>
    </el-card>

    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="600px">
      <el-form ref="sourceForm" :model="sourceForm" label-width="100px">
        <el-form-item label="数据源名称">
          <el-input v-model="sourceForm.sourceName" placeholder="请输入数据源名称" />
        </el-form-item>
        <el-form-item label="数据源类型">
          <el-select v-model="sourceForm.sourceType" placeholder="请选择类型" style="width: 100%;">
            <el-option label="MySQL" value="MySQL" />
            <el-option label="Oracle" value="Oracle" />
            <el-option label="PostgreSQL" value="PostgreSQL" />
            <el-option label="API接口" value="API" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属部门">
          <el-select v-model="sourceForm.department" placeholder="请选择部门" style="width: 100%;">
            <el-option label="交警大队" value="交警大队" />
            <el-option label="刑侦支队" value="刑侦支队" />
            <el-option label="治安支队" value="治安支队" />
            <el-option label="户籍科" value="户籍科" />
          </el-select>
        </el-form-item>
        <el-form-item label="连接地址">
          <el-input v-model="sourceForm.host" placeholder="请输入连接地址" />
        </el-form-item>
        <el-form-item label="端口">
          <el-input v-model="sourceForm.port" placeholder="请输入端口" style="width: 150px;" />
        </el-form-item>
        <el-form-item label="数据库名">
          <el-input v-model="sourceForm.database" placeholder="请输入数据库名" />
        </el-form-item>
        <el-form-item label="用户名">
          <el-input v-model="sourceForm.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="sourceForm.password" type="password" placeholder="请输入密码" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'PoliceDataConnect',
  data() {
    return {
      dialogVisible: false,
      dialogTitle: '新增数据源',
      sourceForm: { sourceName: '', sourceType: '', department: '', host: '', port: '', database: '', username: '', password: '' },
      dataSourceList: [
        { sourceId: 'PDS001', sourceName: '交通事故数据库', sourceType: 'MySQL', department: '交警大队', connectionInfo: '10.0.1.100:3306/traffic_db', dataCount: '1,250,000', lastSyncTime: '2024-01-15 08:00:00', status: 'connected' },
        { sourceId: 'PDS002', sourceName: '驾驶员信息库', sourceType: 'Oracle', department: '交警大队', connectionInfo: '10.0.1.101:1521/driver_db', dataCount: '850,000', lastSyncTime: '2024-01-15 08:00:00', status: 'connected' },
        { sourceId: 'PDS003', sourceName: '刑侦案件库', sourceType: 'PostgreSQL', department: '刑侦支队', connectionInfo: '10.0.1.102:5432/case_db', dataCount: '320,000', lastSyncTime: '2024-01-14 20:00:00', status: 'disconnected' }
      ],
      syncRecords: [
        { syncId: 'SYNC001', sourceName: '交通事故数据库', syncType: '增量', recordCount: 1580, duration: '2min 35s', status: 'success', syncTime: '2024-01-15 08:00:00' },
        { syncId: 'SYNC002', sourceName: '驾驶员信息库', syncType: '增量', recordCount: 320, duration: '1min 12s', status: 'success', syncTime: '2024-01-15 08:00:00' },
        { syncId: 'SYNC003', sourceName: '刑侦案件库', syncType: '全量', recordCount: 0, duration: '-', status: 'failed', syncTime: '2024-01-14 20:00:00' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleAddSource() {
      this.dialogTitle = '新增数据源'
      this.sourceForm = { sourceName: '', sourceType: '', department: '', host: '', port: '', database: '', username: '', password: '' }
      this.dialogVisible = true
    },
    handleSync(row) {
      this.$message.info(`正在同步数据源: ${row.sourceName}`)
      setTimeout(() => {
        this.syncRecords.unshift({
          syncId: `SYNC${Date.now()}`,
          sourceName: row.sourceName,
          syncType: '增量',
          recordCount: Math.floor(Math.random() * 2000) + 100,
          duration: `${Math.floor(Math.random() * 5) + 1}min ${Math.floor(Math.random() * 60)}s`,
          status: 'success',
          syncTime: new Date().toLocaleString()
        })
        this.$message.success('同步完成')
      }, 2000)
    },
    handleTest(row) {
      this.$message.info(`正在测试连接: ${row.sourceName}`)
      setTimeout(() => { this.$message.success(`数据源 ${row.sourceName} 连接正常`) }, 1500)
    },
    handleEdit(row) {
      this.dialogTitle = '编辑数据源'
      this.sourceForm = { ...row }
      this.dialogVisible = true
    },
    handleSave() {
      if (this.dialogTitle === '新增数据源') {
        this.dataSourceList.unshift({
          sourceId: `PDS${Date.now()}`,
          ...this.sourceForm,
          connectionInfo: `${this.sourceForm.host}:${this.sourceForm.port}/${this.sourceForm.database}`,
          dataCount: '0',
          lastSyncTime: '-',
          status: 'connected'
        })
      }
      this.dialogVisible = false
      this.$message.success('保存成功')
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
