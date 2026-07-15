<template>
  <div class="app-container">
    <h2>审批工作流</h2>
    <div class="filter-container"><el-button type="primary" icon="el-icon-plus" @click="handleAdd">创建工作流</el-button></div>
    <el-table v-loading="loading" :data="list" border class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="工作流名称" prop="workflowName" min-width="200" />
      <el-table-column label="描述" prop="workflowDesc" min-width="250" show-overflow-tooltip />
      <el-table-column label="审批类型" prop="approvalType" width="120">
        <template slot-scope="{row}"><el-tag>{{ row.approvalType }}</el-tag></template>
      </el-table-column>
      <el-table-column label="审批层级" prop="approvalLevels" width="100" align="center" />
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
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="550px" :before-close="closeDialog">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="工作流名称" prop="workflowName"><el-input v-model="form.workflowName" placeholder="请输入工作流名称" /></el-form-item>
        <el-form-item label="描述" prop="workflowDesc"><el-input v-model="form.workflowDesc" type="textarea" :rows="3" /></el-form-item>
        <el-form-item label="审批类型" prop="approvalType">
          <el-select v-model="form.approvalType" style="width:100%">
            <el-option label="项目审批" value="PROJECT" /><el-option label="资源审批" value="RESOURCE" /><el-option label="机构审批" value="ORGAN" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批层级" prop="approvalLevels"><el-input-number v-model="form.approvalLevels" :min="1" :max="5" /></el-form-item>
        <el-form-item label="审批人" prop="approvers"><el-input v-model="form.approvers" placeholder="输入审批人ID，逗号分隔" /></el-form-item>
        <el-form-item label="状态" prop="status"><el-radio-group v-model="form.status"><el-radio :label="1">启用</el-radio><el-radio :label="0">禁用</el-radio></el-radio-group></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="closeDialog">取消</el-button><el-button type="primary" :loading="submitLoading" @click="submitForm">确定</el-button></span>
    </el-dialog>
  </div>
</template>
<script>

import { getWorkflowList, saveWorkflow, deleteWorkflow } from '@/api/workflow'
export default {
  name: 'ApprovalWorkflow',
  data() {
    return {
      loading: false, submitLoading: false, list: [], dialogVisible: false, dialogType: 'add', dialogTitle: '创建工作流',
      form: { id: null, workflowName: '', workflowDesc: '', approvalType: 'PROJECT', approvalLevels: 1, approvers: '', status: 1 },
      rules: { workflowName: [{ required: true, message: '请输入工作流名称', trigger: 'blur' }] }
    }
  },
  created() { this.getList() },
  methods: {
    async getList() { this.loading = true; try { const res = await getWorkflowList(); if (res.code === 0) this.list = res.result || []; } catch(e) { console.error(e); this.$message({type:"error",message:"请求异常"}) } finally { this.loading = false } },
    handleAdd() { this.dialogType = 'add'; this.dialogTitle = '创建工作流'; this.form = { id: null, workflowName: '', workflowDesc: '', approvalType: 'PROJECT', approvalLevels: 1, approvers: '', status: 1 }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleEdit(row) { this.dialogType = 'edit'; this.dialogTitle = '编辑工作流'; this.form = { ...row }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleDelete(row) { this.$confirm('确定删除?', '提示', { type: 'warning' }).then(async () => { await deleteWorkflow({ id: row.id }); this.$message({ type: 'success', message: '删除成功' }); this.getList() }).catch(() => {}) },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    submitForm() {
      this.$refs.form.validate(async valid => {
        if (!valid) return; this.submitLoading = true
        try {
          const res = await saveWorkflow(this.form)
          if (res.code === 0) { this.$message({ type: 'success', message: this.dialogType === 'add' ? '创建成功' : '更新成功' }); this.closeDialog(); this.getList() }
          else { this.$message({ type: 'error', message: res.msg || '请求异常' }) }
        } catch (e) { this.$message({ type: 'error', message: '请求异常' }) } finally { this.submitLoading = false }
      })
    }
  }
}

</script>
<style lang="scss" scoped>
.filter-container { padding: 12px 0; }
.table-list { margin-top: 10px; }
</style>