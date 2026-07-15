<template>
  <div class="app-container">
    <h2>操作系统监控及报警</h2>
    <div class="filter-container">
      <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增配置</el-button>
    </div>
    <el-table v-loading="loading" :data="list" border class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="配置项" prop="configKey" width="120">
        <template slot-scope="{row}"><el-tag>{{ row.configKey }}</el-tag></template>
      </el-table-column>
      <el-table-column label="配置名称" prop="configName" width="150" />
      <el-table-column label="告警阈值(%)" prop="warningThreshold" width="120" align="center" />
      <el-table-column label="严重阈值(%)" prop="criticalThreshold" width="120" align="center" />
      <el-table-column label="采集间隔(秒)" prop="intervalSec" width="120" align="center" />
      <el-table-column label="状态" width="80" align="center" prop="enabled">
        <template slot-scope="{row}"><el-tag :type="row.enabled===1?'success':'danger'" size="mini">{{ row.enabled===1?'启用':'禁用' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="通知方式" prop="notifyType" width="120" />
      <el-table-column align="center" label="操作" fixed="right" width="150">
        <template slot-scope="{row}">
          <el-button type="text" icon="el-icon-setting" style="color:#409eff" @click="handleEdit(row)">告警配置</el-button>
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="600px" :before-close="closeDialog">
      <el-form ref="form" :model="form" :rules="rules" label-width="130px">
        <el-form-item label="配置项" prop="configKey"><el-input v-model="form.configKey" placeholder="如 CPU" :disabled="!!form.id" /></el-form-item>
        <el-form-item label="配置名称" prop="configName"><el-input v-model="form.configName" placeholder="如 CPU使用率" /></el-form-item>
        <el-form-item label="告警阈值(%)" prop="warningThreshold">
          <el-input-number v-model="form.warningThreshold" :min="0" :max="100" :precision="2" :step="5" />
          <span style="margin-left:10px;color:#999">超过此值触发告警</span>
        </el-form-item>
        <el-form-item label="严重阈值(%)" prop="criticalThreshold">
          <el-input-number v-model="form.criticalThreshold" :min="0" :max="100" :precision="2" :step="5" />
          <span style="margin-left:10px;color:#999">超过此值触发严重告警</span>
        </el-form-item>
        <el-form-item label="采集间隔(秒)" prop="intervalSec">
          <el-input-number v-model="form.intervalSec" :min="10" :max="3600" :step="10" />
        </el-form-item>
        <el-form-item label="通知方式" prop="notifyType">
          <el-select v-model="form.notifyType" style="width:100%">
            <el-option label="邮件" value="email" /><el-option label="短信" value="sms" /><el-option label="Webhook" value="webhook" />
          </el-select>
        </el-form-item>
        <el-form-item label="通知联系人" prop="notifyContact">
          <el-input v-model="form.notifyContact" placeholder="邮箱地址或手机号" />
        </el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="状态" prop="enabled">
          <el-radio-group v-model="form.enabled"><el-radio :label="1">启用</el-radio><el-radio :label="0">禁用</el-radio></el-radio-group>
        </el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="closeDialog">取消</el-button><el-button type="primary" :loading="submitLoading" @click="submitForm">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getMonitorConfigList, saveMonitorConfig, deleteMonitorConfig } from '@/api/monitorConfig'
export default {
  name: 'OsMonitorConfig',
  data() {
    return {
      loading: false, submitLoading: false, list: [], dialogVisible: false, dialogType: 'add', dialogTitle: '新增告警配置',
      form: { id: null, configKey: '', configName: '', warningThreshold: 80, criticalThreshold: 95, intervalSec: 60, enabled: 1, notifyType: 'email', notifyContact: '', remark: '' },
      rules: { configKey: [{ required: true, message: '请输入配置项', trigger: 'blur' }], configName: [{ required: true, message: '请输入配置名称', trigger: 'blur' }] }
    }
  },
  created() { this.getList() },
  methods: {
    async getList() { this.loading = true; try { const res = await getMonitorConfigList(); if (res.code === 0) this.list = res.result || []; } catch(e) { console.error(e); this.$message({type:"error",message:"请求异常"}) } finally { this.loading = false } },
    handleAdd() { this.dialogType = 'add'; this.dialogTitle = '新增告警配置'; this.resetForm(); this.dialogVisible = true },
    handleEdit(row) { this.dialogType = 'edit'; this.dialogTitle = '编辑告警配置'; this.form = { ...row }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleDelete(row) { this.$confirm('确定删除?', '提示', { type: 'warning' }).then(async () => { await deleteMonitorConfig({ id: row.id }); this.$message.success('删除成功'); this.getList() }).catch(() => {}) },
    resetForm() { this.form = { id: null, configKey: '', configName: '', warningThreshold: 80, criticalThreshold: 95, intervalSec: 60, enabled: 1, notifyType: 'email', notifyContact: '', remark: '' }; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    submitForm() {
      if (!this.$refs.form) return
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.submitLoading = true
        try {
          const res = await saveMonitorConfig(this.form)
          if (res && res.code === 0) {
            this.$message({ type: 'success', message: '保存成功' })
            this.closeDialog()
            this.getList()
          } else {
            this.$message({ type: 'error', message: (res && res.msg) || '请求异常' })
          }
        } catch (e) {
          console.error(e)
          this.$message({ type: 'error', message: '请求异常' })
        } finally {
          this.submitLoading = false
        }
      })
    }
  }
}

</script>

<style lang="scss" scoped>
.filter-container { padding: 12px 0; }
.table-list { margin-top: 10px; }
</style>