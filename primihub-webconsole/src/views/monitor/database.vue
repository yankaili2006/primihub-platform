<template>
  <div class="app-container">
    <h2>数据库监控及报警</h2>
    <div class="filter-container"><el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增配置</el-button></div>
    <el-table v-loading="loading" :data="list" border class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="数据库类型" prop="dbType" width="120"><template slot-scope="{row}"><el-tag>{{ row.dbType }}</el-tag></template></el-table-column>
      <el-table-column label="名称" prop="dbName" min-width="160" />
      <el-table-column label="连接地址" prop="host" width="140" />
      <el-table-column label="端口" prop="port" width="70" align="center" />
      <el-table-column label="用户名" prop="dbUser" width="100" />
      <el-table-column label="连接数阈值(%)" prop="warningThreshold" width="130" align="center" />
      <el-table-column label="严重阈值(%)" prop="criticalThreshold" width="120" align="center" />
      <el-table-column label="检查间隔(秒)" prop="checkInterval" width="110" align="center" />
      <el-table-column label="状态" width="70" align="center" prop="enabled">
        <template slot-scope="{row}"><el-tag :type="row.enabled===1?'success':'danger'" size="mini">{{ row.enabled===1?'启用':'禁用' }}</el-tag></template>
      </el-table-column>
      <el-table-column align="center" label="操作" fixed="right" width="150">
        <template slot-scope="{row}">
          <el-button type="text" icon="el-icon-setting" style="color:#409eff" @click="handleEdit(row)">告警配置</el-button>
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="600px" :before-close="closeDialog">
      <el-form ref="form" :model="form" :rules="rules" label-width="130px">
        <el-form-item label="数据库类型" prop="dbType"><el-select v-model="form.dbType" style="width:100%" :disabled="!!form.id"><el-option label="MySQL" value="MYSQL" /><el-option label="PostgreSQL" value="POSTGRESQL" /><el-option label="ClickHouse" value="CLICKHOUSE" /></el-select></el-form-item>
        <el-form-item label="名称" prop="dbName"><el-input v-model="form.dbName" placeholder="如 MySQL主库" /></el-form-item>
        <el-form-item label="连接地址" prop="host"><el-input v-model="form.host" placeholder="127.0.0.1" /></el-form-item>
        <el-form-item label="端口" prop="port"><el-input-number v-model="form.port" :min="1" :max="65535" /></el-form-item>
        <el-form-item label="用户名" prop="dbUser"><el-input v-model="form.dbUser" /></el-form-item>
        <el-form-item label="密码" prop="dbPassword"><el-input v-model="form.dbPassword" type="password" show-password /></el-form-item>
        <el-form-item label="连接超时(ms)" prop="connectTimeout"><el-input-number v-model="form.connectTimeout" :min="100" :max="30000" :step="100" /></el-form-item>
        <el-form-item label="连接数阈值(%)" prop="warningThreshold"><el-input-number v-model="form.warningThreshold" :min="0" :max="100" :precision="2" :step="5" /></el-form-item>
        <el-form-item label="严重阈值(%)" prop="criticalThreshold"><el-input-number v-model="form.criticalThreshold" :min="0" :max="100" :precision="2" :step="5" /></el-form-item>
        <el-form-item label="检查间隔(秒)" prop="checkInterval"><el-input-number v-model="form.checkInterval" :min="10" :max="3600" :step="10" /></el-form-item>
        <el-form-item label="通知方式" prop="notifyType"><el-select v-model="form.notifyType" style="width:100%"><el-option label="邮件" value="email" /><el-option label="短信" value="sms" /><el-option label="Webhook" value="webhook" /></el-select></el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="状态" prop="enabled"><el-radio-group v-model="form.enabled"><el-radio :label="1">启用</el-radio><el-radio :label="0">禁用</el-radio></el-radio-group></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="closeDialog">取消</el-button><el-button type="primary" :loading="submitLoading" @click="submitForm">保存</el-button></span>
    </el-dialog>
  </div>
</template>
<script>

import { getDatabaseMonitorList, saveDatabaseMonitor, deleteDatabaseMonitor } from '@/api/databaseMonitor'
export default {
  name: 'DatabaseMonitor',
  data() {
    return {
      loading: false, submitLoading: false, list: [], dialogVisible: false, dialogType: 'add', dialogTitle: '新增告警配置',
      form: { id: null, dbType: 'MYSQL', dbName: '', host: '127.0.0.1', port: 3306, dbUser: 'root', dbPassword: '', connectTimeout: 5000, warningThreshold: 80, criticalThreshold: 95, checkInterval: 60, enabled: 1, notifyType: 'email', remark: '' },
      rules: { dbType: [{ required: true, message: '请选择类型', trigger: 'change' }], dbName: [{ required: true, message: '请输入名称', trigger: 'blur' }], host: [{ required: true, message: '请输入连接地址', trigger: 'blur' }] }
    }
  },
  created() { this.getList() },
  methods: {
    async getList() { this.loading = true; try { const res = await getDatabaseMonitorList(); if (res.code === 0) this.list = res.result || []; } catch(e) { console.error(e); this.$message({type:"error",message:"请求异常"}) } finally { this.loading = false } },
    handleAdd() { this.dialogType = 'add'; this.dialogTitle = '新增告警配置'; this.form = { id: null, dbType: 'MYSQL', dbName: '', host: '127.0.0.1', port: 3306, dbUser: 'root', dbPassword: '', connectTimeout: 5000, warningThreshold: 80, criticalThreshold: 95, checkInterval: 60, enabled: 1, notifyType: 'email', remark: '' }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleEdit(row) { this.dialogType = 'edit'; this.dialogTitle = '编辑告警配置'; this.form = { ...row }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleDelete(row) { this.$confirm('确定删除?', '提示', { type: 'warning' }).then(async () => { await deleteDatabaseMonitor({ id: row.id }); this.$message({ type: 'success', message: '删除成功' }); this.getList() }).catch(() => {}) },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    submitForm() {
      this.$refs.form.validate(async valid => {
        if (!valid) return; this.submitLoading = true
        try { const res = await saveDatabaseMonitor(this.form); if (res.code === 0) { this.$message({ type: 'success', message: '保存成功' }); this.closeDialog(); this.getList() } else { this.$message({ type: 'error', message: res.msg || '请求异常' }) } }
        catch (e) { this.$message({ type: 'error', message: '请求异常' }) } finally { this.submitLoading = false }
      })
    }
  }
}

</script>
<style lang="scss" scoped>
.filter-container { padding: 12px 0; }
.table-list { margin-top: 10px; }
</style>