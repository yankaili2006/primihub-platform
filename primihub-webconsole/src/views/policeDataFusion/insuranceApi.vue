<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="保险机构接口对接" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header">
        <span>接口配置</span>
        <el-button style="float: right;" size="mini" type="primary" @click="handleAddApi">新增接口</el-button>
      </div>
      <el-table :data="apiList" border>
        <el-table-column prop="apiId" label="接口ID" width="100" />
        <el-table-column prop="apiName" label="接口名称" width="180" />
        <el-table-column prop="orgName" label="机构名称" width="150" />
        <el-table-column prop="apiUrl" label="接口地址" width="280" />
        <el-table-column prop="protocol" label="协议" width="80" />
        <el-table-column prop="authType" label="认证方式" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'active' ? 'success' : 'danger'" size="small">
              {{ scope.row.status === 'active' ? '正常' : '异常' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleTest(scope.row)">测试</el-button>
            <el-button size="mini" type="text" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="mini" type="text" style="color: #F56C6C;" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="600px">
      <el-form ref="apiForm" :model="apiForm" label-width="100px">
        <el-form-item label="接口名称">
          <el-input v-model="apiForm.apiName" placeholder="请输入接口名称" />
        </el-form-item>
        <el-form-item label="机构名称">
          <el-select v-model="apiForm.orgName" placeholder="请选择机构" style="width: 100%;">
            <el-option label="平安保险" value="平安保险" />
            <el-option label="中国人寿" value="中国人寿" />
            <el-option label="太平洋保险" value="太平洋保险" />
            <el-option label="新华保险" value="新华保险" />
          </el-select>
        </el-form-item>
        <el-form-item label="接口地址">
          <el-input v-model="apiForm.apiUrl" placeholder="请输入接口地址" />
        </el-form-item>
        <el-form-item label="协议">
          <el-radio-group v-model="apiForm.protocol">
            <el-radio label="HTTPS">HTTPS</el-radio>
            <el-radio label="gRPC">gRPC</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="认证方式">
          <el-select v-model="apiForm.authType" placeholder="请选择认证方式" style="width: 100%;">
            <el-option label="API Key" value="API Key" />
            <el-option label="OAuth2.0" value="OAuth2.0" />
            <el-option label="证书认证" value="证书认证" />
          </el-select>
        </el-form-item>
        <el-form-item label="API Key" v-if="apiForm.authType === 'API Key'">
          <el-input v-model="apiForm.apiKey" placeholder="请输入API Key" />
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
  name: 'InsuranceApiConnect',
  data() {
    return {
      dialogVisible: false,
      dialogTitle: '新增接口',
      apiForm: { apiName: '', orgName: '', apiUrl: '', protocol: 'HTTPS', authType: 'API Key', apiKey: '' },
      apiList: [
        { apiId: 'API001', apiName: '理赔数据查询接口', orgName: '平安保险', apiUrl: 'https://api.pingan.com/v1/claim', protocol: 'HTTPS', authType: 'API Key', status: 'active' },
        { apiId: 'API002', apiName: '投保信息接口', orgName: '中国人寿', apiUrl: 'https://api.chinalife.com/v1/policy', protocol: 'HTTPS', authType: 'OAuth2.0', status: 'active' },
        { apiId: 'API003', apiName: '车险数据接口', orgName: '太平洋保险', apiUrl: 'https://api.cpic.com/v1/auto', protocol: 'gRPC', authType: '证书认证', status: 'error' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleAddApi() {
      this.dialogTitle = '新增接口'
      this.apiForm = { apiName: '', orgName: '', apiUrl: '', protocol: 'HTTPS', authType: 'API Key', apiKey: '' }
      this.dialogVisible = true
    },
    handleTest(row) {
      this.$message.info(`正在测试接口: ${row.apiName}`)
      setTimeout(() => {
        this.$message.success(`接口 ${row.apiName} 连接正常`)
      }, 1500)
    },
    handleEdit(row) {
      this.dialogTitle = '编辑接口'
      this.apiForm = { ...row }
      this.dialogVisible = true
    },
    handleDelete(row) {
      this.$confirm(`确定删除接口 ${row.apiName}?`, '提示', { type: 'warning' }).then(() => {
        this.apiList = this.apiList.filter(item => item.apiId !== row.apiId)
        this.$message.success('删除成功')
      }).catch(() => {})
    },
    handleSave() {
      if (this.dialogTitle === '新增接口') {
        this.apiList.unshift({ ...this.apiForm, apiId: `API${Date.now()}`, status: 'active' })
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
