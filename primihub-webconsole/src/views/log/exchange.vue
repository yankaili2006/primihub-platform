<template>
  <div class="app-container">
    <h2>数据交换日志</h2>
    <div class="filter-container">
      <el-button type="primary" icon="el-icon-s-promotion" @click="handleTrigger">触发同步</el-button>
    </div>
    <el-table v-loading="loading" :data="list" border class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="交换类型" prop="exchangeType" width="120"><template slot-scope="{row}"><el-tag>{{ row.exchangeType }}</el-tag></template></el-table-column>
      <el-table-column label="交换名称" prop="exchangeName" min-width="200" />
      <el-table-column label="源机构" prop="sourceOrgan" width="150" />
      <el-table-column label="目标机构" prop="targetOrgan" width="150" />
      <el-table-column label="数据量" prop="dataSize" width="100" align="center" />
      <el-table-column label="同步状态" width="100" align="center" prop="syncStatus">
        <template slot-scope="{row}">
          <el-tag :type="row.syncStatus===2?'success':row.syncStatus===3?'danger':'warning'" size="mini">
            {{ {0:'待同步',1:'同步中',2:'成功',3:'失败'}[row.syncStatus] || '未知' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="同步结果" prop="syncMsg" min-width="200" show-overflow-tooltip />
      <el-table-column label="触发方式" prop="triggerType" width="100" />
      <el-table-column label="创建时间" prop="cTime" width="160" />
      <el-table-column align="center" label="操作" fixed="right" width="100">
        <template slot-scope="{row}">
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog title="触发同步" :visible.sync="dialogVisible" width="500px" :before-close="closeDialog">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="交换类型" prop="exchangeType">
          <el-select v-model="form.exchangeType" style="width:100%">
            <el-option label="资源" value="RESOURCE" /><el-option label="模型" value="MODEL" /><el-option label="任务" value="TASK" />
          </el-select>
        </el-form-item>
        <el-form-item label="交换名称" prop="exchangeName"><el-input v-model="form.exchangeName" placeholder="请输入交换名称" /></el-form-item>
        <el-form-item label="源机构" prop="sourceOrgan"><el-input v-model="form.sourceOrgan" placeholder="源机构名称" /></el-form-item>
        <el-form-item label="目标机构" prop="targetOrgan"><el-input v-model="form.targetOrgan" placeholder="目标机构名称" /></el-form-item>
        <el-form-item label="数据量" prop="dataSize"><el-input-number v-model="form.dataSize" :min="0" :max="99999999" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="closeDialog">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="submitForm">触发</el-button>
      </span>
    </el-dialog>
  </div>
</template>
<script>

import { getExchangeLogList, triggerSync, deleteExchangeLog } from '@/api/dataExchange'
export default {
  name: 'DataExchangeLog',
  data() {
    return {
      loading: false, submitLoading: false, list: [], dialogVisible: false,
      form: { exchangeType: 'RESOURCE', exchangeName: '', sourceOrgan: '', targetOrgan: '', dataSize: 0 },
      rules: { exchangeName: [{ required: true, message: '请输入交换名称', trigger: 'blur' }] }
    }
  },
  created() { this.getList() },
  methods: {
    async getList() { this.loading = true; try { const res = await getExchangeLogList(); if (res.code === 0) this.list = res.result || []; } catch(e) { console.error(e); this.$message({type:"error",message:"请求异常"}) } finally { this.loading = false } },
    handleTrigger() { this.form = { exchangeType: 'RESOURCE', exchangeName: '', sourceOrgan: '', targetOrgan: '', dataSize: 0 }; this.dialogVisible = true; this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() }) },
    handleDelete(row) { this.$confirm('确定删除?', '提示', { type: 'warning' }).then(async () => { await deleteExchangeLog({ id: row.id }); this.$message({ type: 'success', message: '删除成功' }); this.getList() }).catch(() => {}) },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    submitForm() {
      this.$refs.form.validate(async valid => {
        if (!valid) return; this.submitLoading = true
        try {
          const res = await triggerSync(this.form)
          if (res.code === 0) {
            this.$message({ type: 'success', message: '触发同步成功' })
            this.closeDialog(); this.getList()
          } else {
            this.$message({ type: 'error', message: res.msg || '触发同步失败' })
          }
        } catch (e) {
          this.$message({ type: 'error', message: '请求异常' })
        } finally { this.submitLoading = false }
      })
    }
  }
}

</script>
<style lang="scss" scoped>
.filter-container { padding: 12px 0; }
.table-list { margin-top: 10px; }
</style>