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
import { getPoliceDataSourceList, savePoliceDataSource, syncPoliceDataSource, testPoliceDataSource } from '@/api/scene'
export default {
  name: 'PoliceDataConnect',
  data() {
    return {
      dialogVisible: false,
      dialogTitle: '新增数据源',
      sourceForm: { sourceName: '', sourceType: '', department: '', host: '', port: '', database: '', username: '', password: '' },
      dataSourceList: [],
      syncRecords: []
    }
  },
  created() {
    this.fetchDataSourceList()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    fetchDataSourceList() {
      getPoliceDataSourceList().then(res => {
        if (res && res.code === 0 && res.result) {
          this.dataSourceList = res.result.list || []
          // 同步记录随数据源列表返回（如后端下发），否则保持为空
          this.syncRecords = res.result.syncRecords || []
        }
      }).catch(() => {})
    },
    handleAddSource() {
      this.dialogTitle = '新增数据源'
      this.sourceForm = { sourceName: '', sourceType: '', department: '', host: '', port: '', database: '', username: '', password: '' }
      this.dialogVisible = true
    },
    handleSync(row) {
      this.$message.info(`正在同步数据源: ${row.sourceName}`)
      syncPoliceDataSource({ sourceId: row.sourceId }).then(res => {
        if (res && res.code === 0) {
          this.$message.success('同步完成')
          this.fetchDataSourceList()
        } else {
          this.$message.error((res && (res.msg || res.message)) || '同步失败')
        }
      }).catch(() => { this.$message.error('同步请求异常') })
    },
    handleTest(row) {
      this.$message.info(`正在测试连接: ${row.sourceName}`)
      testPoliceDataSource({ sourceId: row.sourceId }).then(res => {
        if (res && res.code === 0) {
          this.$message.success(`数据源 ${row.sourceName} 连接正常`)
        } else {
          this.$message.error((res && (res.msg || res.message)) || `数据源 ${row.sourceName} 连接失败`)
        }
      }).catch(() => { this.$message.error('测试请求异常') })
    },
    handleEdit(row) {
      this.dialogTitle = '编辑数据源'
      this.sourceForm = { ...row }
      this.dialogVisible = true
    },
    handleSave() {
      const payload = Object.assign({}, this.sourceForm, {
        connectionInfo: `${this.sourceForm.host}:${this.sourceForm.port}/${this.sourceForm.database}`
      })
      savePoliceDataSource(payload).then(res => {
        if (res && res.code === 0) {
          this.dialogVisible = false
          this.$message.success('保存成功')
          this.fetchDataSourceList()
        } else {
          this.$message.error((res && (res.msg || res.message)) || '保存失败')
        }
      }).catch(() => { this.$message.error('保存请求异常') })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
