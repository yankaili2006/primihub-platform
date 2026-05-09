<template>
  <div class="app-container">
    <el-page-header content="警务数据对接" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header">
        <span>警务数据源管理</span>
        <el-button style="float: right;" size="mini" type="primary" @click="handleAddSource">新增数据源</el-button>
      </div>
      <el-table :data="dataSourceList" border>
        <el-table-column prop="sourceId" label="数据源ID" width="100" />
        <el-table-column prop="sourceName" label="数据源名称" width="180" />
        <el-table-column prop="dataType" label="数据类型" width="120" />
        <el-table-column prop="department" label="所属部门" width="120" />
        <el-table-column prop="connectionInfo" label="连接信息" width="250" />
        <el-table-column prop="recordCount" label="数据量" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'connected' ? 'success' : 'danger'" size="small">
              {{ scope.row.status === 'connected' ? '已连接' : '断开' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleTest(scope.row)">测试</el-button>
            <el-button size="mini" type="text" @click="handleSync(scope.row)">同步</el-button>
            <el-button size="mini" type="text" @click="handleEdit(scope.row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>证件数据统计</span></div>
      <el-row :gutter="20">
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">12,580,000</div>
            <div class="stat-label">身份证记录</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">3,250,000</div>
            <div class="stat-label">驾驶证记录</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">850,000</div>
            <div class="stat-label">护照记录</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">2,150,000</div>
            <div class="stat-label">其他证件</div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="600px">
      <el-form ref="sourceForm" :model="sourceForm" label-width="100px">
        <el-form-item label="数据源名称">
          <el-input v-model="sourceForm.sourceName" placeholder="请输入数据源名称" />
        </el-form-item>
        <el-form-item label="数据类型">
          <el-select v-model="sourceForm.dataType" placeholder="请选择数据类型" style="width: 100%;">
            <el-option label="身份证数据" value="身份证数据" />
            <el-option label="驾驶证数据" value="驾驶证数据" />
            <el-option label="护照数据" value="护照数据" />
            <el-option label="社保卡数据" value="社保卡数据" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属部门">
          <el-select v-model="sourceForm.department" placeholder="请选择部门" style="width: 100%;">
            <el-option label="户籍管理科" value="户籍管理科" />
            <el-option label="出入境管理科" value="出入境管理科" />
            <el-option label="车辆管理所" value="车辆管理所" />
          </el-select>
        </el-form-item>
        <el-form-item label="连接地址">
          <el-input v-model="sourceForm.host" placeholder="请输入连接地址" />
        </el-form-item>
        <el-form-item label="端口">
          <el-input v-model="sourceForm.port" placeholder="请输入端口" style="width: 150px;" />
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
  name: 'ElectronicCertPoliceConnect',
  data() {
    return {
      dialogVisible: false,
      dialogTitle: '新增数据源',
      sourceForm: { sourceName: '', dataType: '', department: '', host: '', port: '' },
      dataSourceList: [
        { sourceId: 'ECS001', sourceName: '省级身份证数据库', dataType: '身份证数据', department: '户籍管理科', connectionInfo: '10.0.2.100:3306/idcard_db', recordCount: '12,580,000', status: 'connected' },
        { sourceId: 'ECS002', sourceName: '驾驶证信息系统', dataType: '驾驶证数据', department: '车辆管理所', connectionInfo: '10.0.2.101:3306/driver_db', recordCount: '3,250,000', status: 'connected' },
        { sourceId: 'ECS003', sourceName: '出入境证件系统', dataType: '护照数据', department: '出入境管理科', connectionInfo: '10.0.2.102:1521/passport_db', recordCount: '850,000', status: 'disconnected' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleAddSource() {
      this.dialogTitle = '新增数据源'
      this.sourceForm = { sourceName: '', dataType: '', department: '', host: '', port: '' }
      this.dialogVisible = true
    },
    handleTest(row) {
      this.$message.info(`测试连接: ${row.sourceName}`)
      setTimeout(() => { this.$message.success('连接正常') }, 1500)
    },
    handleSync(row) {
      this.$message.info(`同步数据: ${row.sourceName}`)
    },
    handleEdit(row) {
      this.dialogTitle = '编辑数据源'
      this.sourceForm = { ...row }
      this.dialogVisible = true
    },
    handleSave() {
      this.dialogVisible = false
      this.$message.success('保存成功')
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.stat-card { background: #f5f7fa; padding: 20px; text-align: center; border-radius: 8px; }
.stat-value { font-size: 28px; font-weight: bold; color: #409EFF; }
.stat-label { font-size: 14px; color: #909399; margin-top: 8px; }
</style>
