<template>
  <div class="app-container">
    <h2>接入方管理</h2>
    <div class="filter-container"><el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增接入方</el-button></div>
    <el-table v-loading="loading" :data="list" border class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="接入方名称" prop="partyName" min-width="180" />
      <el-table-column label="编码" prop="partyCode" width="120"><template slot-scope="{row}"><el-tag>{{ row.partyCode }}</el-tag></template></el-table-column>
      <el-table-column label="联系人" prop="contactPerson" width="120" />
      <el-table-column label="联系电话" prop="contactPhone" width="140" />
      <el-table-column label="状态" width="80" align="center" prop="status">
        <template slot-scope="{row}"><el-tag :type="row.status===1?'success':'danger'" size="mini">{{ row.status===1?'启用':'禁用' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="备注" prop="remark" min-width="150" show-overflow-tooltip />
      <el-table-column label="创建时间" prop="cTime" width="160" />
      <el-table-column align="center" label="操作" fixed="right" width="150">
        <template slot-scope="{row}">
          <el-button type="text" icon="el-icon-edit" @click="handleEdit(row)">编辑</el-button>
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="500px" :before-close="closeDialog">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="接入方名称" prop="partyName"><el-input v-model="form.partyName" placeholder="请输入接入方名称" /></el-form-item>
        <el-form-item label="编码" prop="partyCode"><el-input v-model="form.partyCode" placeholder="唯一编码" :disabled="!!form.id" /></el-form-item>
        <el-form-item label="联系人" prop="contactPerson"><el-input v-model="form.contactPerson" /></el-form-item>
        <el-form-item label="联系电话" prop="contactPhone"><el-input v-model="form.contactPhone" /></el-form-item>
        <el-form-item label="API密钥" prop="apiKey"><el-input v-model="form.apiKey" type="textarea" :rows="2" placeholder="可选" /></el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="状态" prop="status"><el-radio-group v-model="form.status"><el-radio :label="1">启用</el-radio><el-radio :label="0">禁用</el-radio></el-radio-group></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="closeDialog">取消</el-button><el-button type="primary" :loading="submitLoading" @click="submitForm">确定</el-button></span>
    </el-dialog>
  </div>
</template>
<script>

import { getAccessPartyList, saveAccessParty, deleteAccessParty } from '@/api/accessParty'
export default {
  name: 'AccessPartyManage',
  data() {
    return {
      loading: false, submitLoading: false, list: [], dialogVisible: false, dialogType: 'add', dialogTitle: '新增接入方',
      form: { id: null, partyName: '', partyCode: '', apiKey: '', contactPerson: '', contactPhone: '', status: 1, remark: '' },
      rules: { partyName: [{ required: true, message: '请输入接入方名称', trigger: 'blur' }] }
    }
  },
  created() { this.getList() },
  methods: {
    async getList() { this.loading = true; try { const res = await getAccessPartyList(); if (res.code === 0) this.list = res.result || []; } catch(e) { console.error(e); this.$message({type:"error",message:"请求异常"}) } finally { this.loading = false } },
    handleAdd() { this.dialogType = 'add'; this.dialogTitle = '新增接入方'; this.form = { id: null, partyName: '', partyCode: '', apiKey: '', contactPerson: '', contactPhone: '', status: 1, remark: '' }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleEdit(row) { this.dialogType = 'edit'; this.dialogTitle = '编辑接入方'; this.form = { ...row }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleDelete(row) { this.$confirm('确定删除?', '提示', { type: 'warning' }).then(async () => { await deleteAccessParty({ id: row.id }); this.$message({ type: 'success', message: '删除成功' }); this.getList() }).catch(() => {}) },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    submitForm() {
      this.$refs.form.validate(async valid => {
        if (!valid) return; this.submitLoading = true
        try { const res = await saveAccessParty(this.form); if (res.code === 0) { this.$message({ type: 'success', message: this.dialogType === 'add' ? '添加成功' : '更新成功' }); this.closeDialog(); this.getList() } else { this.$message({ type: 'error', message: res.msg || '请求异常' }) } }
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