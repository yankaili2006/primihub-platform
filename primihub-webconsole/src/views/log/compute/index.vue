<template>
  <div class="app-container">
    <h2>计算日志定义</h2>
    <div class="filter-container"><el-button type="success" icon="el-icon-plus" @click="handleAdd">新增定义</el-button></div>
    <el-table v-loading="loading" :data="list" border class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="类型名称" prop="typeName" width="150" />
      <el-table-column label="类型编码" prop="typeCode" width="150">
        <template slot-scope="{row}"><el-tag>{{ row.typeCode }}</el-tag></template>
      </el-table-column>
      <el-table-column label="描述" prop="typeDesc" min-width="250" show-overflow-tooltip />
      <el-table-column label="排序" prop="sortOrder" width="80" align="center" />
      <el-table-column label="状态" width="80" align="center" prop="status">
        <template slot-scope="{row}"><el-tag :type="row.status===1?'success':'danger'" size="mini">{{ row.status===1?'启用':'禁用' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" prop="cTime" width="160" />
      <el-table-column align="center" label="操作" fixed="right" width="150">
        <template slot-scope="{row}">
          <el-button type="text" icon="el-icon-edit" @click="handleEdit(row)">编辑</el-button>
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="500px" :before-close="closeDialog">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="类型名称" prop="typeName"><el-input v-model="form.typeName" placeholder="请输入类型名称" maxlength="100" /></el-form-item>
        <el-form-item label="类型编码" prop="typeCode"><el-input v-model="form.typeCode" placeholder="如 MPC" maxlength="64" :disabled="!!form.id" /></el-form-item>
        <el-form-item label="描述" prop="typeDesc"><el-input v-model="form.typeDesc" type="textarea" :rows="3" placeholder="描述信息" /></el-form-item>
        <el-form-item label="排序" prop="sortOrder"><el-input-number v-model="form.sortOrder" :min="0" :max="999" /></el-form-item>
        <el-form-item label="状态" prop="status"><el-radio-group v-model="form.status"><el-radio :label="1">启用</el-radio><el-radio :label="0">禁用</el-radio></el-radio-group></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="closeDialog">取消</el-button><el-button type="primary" :loading="submitLoading" @click="submitForm">确定</el-button></span>
    </el-dialog>
  </div>
</template>
<script>

import { getComputeLogTypeList, saveComputeLogType, deleteComputeLogType } from '@/api/computeLogType'
export default {
  name: 'ComputeLogDefine',
  data() {
    return {
      loading: false, submitLoading: false, list: [], dialogVisible: false, dialogType: 'add', dialogTitle: '新增定义',
      form: { id: null, typeName: '', typeCode: '', typeDesc: '', sortOrder: 0, status: 1 },
      rules: { typeName: [{ required: true, message: '请输入类型名称', trigger: 'blur' }], typeCode: [{ required: true, message: '请输入类型编码', trigger: 'blur' }] }
    }
  },
  created() { this.getList() },
  methods: {
    async getList() { this.loading = true; try { const res = await getComputeLogTypeList(); if (res.code === 0) this.list = res.result || []; } catch(e) { console.error(e); this.$message({type:"error",message:"请求异常"}) } finally { this.loading = false } },
    handleAdd() { this.dialogType = 'add'; this.dialogTitle = '新增定义'; this.form = { id: null, typeName: '', typeCode: '', typeDesc: '', sortOrder: 0, status: 1 }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleEdit(row) { this.dialogType = 'edit'; this.dialogTitle = '编辑定义'; this.form = { ...row }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleDelete(row) { this.$confirm('确定删除?', '提示', { type: 'warning' }).then(async () => { await deleteComputeLogType({ id: row.id }); this.$message.success('删除成功'); this.getList() }).catch(() => {}) },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    submitForm() {
      this.$refs.form.validate(async valid => {
        if (!valid) return; this.submitLoading = true
        try { const res = await saveComputeLogType(this.form); if (res.code === 0) { this.$message.success(this.dialogType === 'add' ? '添加成功' : '更新成功'); this.closeDialog(); this.getList() } else { this.$message.error(res.msg || '请求异常') } }
        catch (e) { this.$message.error('请求异常') } finally { this.submitLoading = false }
      })
    }
  }
}

</script>
<style lang="scss" scoped>
.filter-container { padding: 12px 0; }
.table-list { margin-top: 10px; }
</style>