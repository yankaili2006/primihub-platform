<template>
  <div class="container">
    <div class="filter-bar">
      <el-input v-model="searchForm.keyword" placeholder="请输入日志代码或名称" style="width: 250px; margin-right: 10px;" clearable />
      <el-select v-model="searchForm.scheduleType" placeholder="请选择调度类型" style="width: 150px; margin-right: 10px;" clearable>
        <el-option label="数据同步" value="数据同步" />
        <el-option label="报表生成" value="报表生成" />
        <el-option label="日志清理" value="日志清理" />
        <el-option label="数据备份" value="数据备份" />
      </el-select>
      <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
    </div>
    <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增定义</el-button>
    <div class="main">
      <el-table :data="list" class="table-list">
        <el-table-column align="center" label="序号" width="80" type="index" />
        <el-table-column align="left" label="日志代码" prop="logCode" width="150" />
        <el-table-column align="left" label="日志名称" prop="logName" width="180" />
        <el-table-column align="left" label="调度类型" prop="scheduleType" width="120" />
        <el-table-column align="left" label="模块名称" prop="moduleName" width="150" />
        <el-table-column align="left" label="描述" prop="description" min-width="200" show-overflow-tooltip />
        <el-table-column align="center" label="保留天数" prop="retentionDays" width="100" />
        <el-table-column align="center" label="状态" prop="isEnabled" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.isEnabled === 1" type="success">启用</el-tag>
            <el-tag v-else type="danger">禁用</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="操作" fixed="right" width="180">
          <template slot-scope="scope">
            <el-button type="text" @click="handleEdit(scope.row)"><i class="el-icon-edit" />编辑</el-button>
            <el-button type="text" @click="handleDelete(scope.row)"><i class="el-icon-delete" />删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </div>

    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="600px" :before-close="closeDialog">
      <el-form ref="form" :model="formData" label-width="120px" :rules="rules">
        <el-form-item label="日志代码" prop="logCode">
          <el-input v-model="formData.logCode" :disabled="dialogFlag === 'edit'" placeholder="请输入日志代码" />
        </el-form-item>
        <el-form-item label="日志名称" prop="logName">
          <el-input v-model="formData.logName" placeholder="请输入日志名称" />
        </el-form-item>
        <el-form-item label="调度类型" prop="scheduleType">
          <el-select v-model="formData.scheduleType" placeholder="请选择调度类型" style="width: 100%;">
            <el-option label="数据同步" value="数据同步" />
            <el-option label="报表生成" value="报表生成" />
            <el-option label="日志清理" value="日志清理" />
            <el-option label="数据备份" value="数据备份" />
          </el-select>
        </el-form-item>
        <el-form-item label="模块名称" prop="moduleName">
          <el-input v-model="formData.moduleName" placeholder="请输入模块名称" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="formData.description" type="textarea" :rows="3" placeholder="请输入描述" />
        </el-form-item>
        <el-form-item label="保留天数" prop="retentionDays">
          <el-input-number v-model="formData.retentionDays" :min="1" :max="3650" />
        </el-form-item>
        <el-form-item label="状态" prop="isEnabled">
          <el-radio-group v-model="formData.isEnabled">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="closeDialog">取 消</el-button>
          <el-button type="primary" @click="submitForm">确 定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { getScheduleLogDefinitionPage, addScheduleLogDefinition, updateScheduleLogDefinition, deleteScheduleLogDefinition } from '@/api/logManagement'
import Pagination from '@/components/Pagination'

export default {
  name: 'ScheduleLogDefinition',
  components: { Pagination },
  data() {
    return {
      list: [],
      searchForm: { keyword: '', scheduleType: '' },
      dialogFlag: '',
      dialogTitle: '',
      dialogVisible: false,
      formData: {
        id: null, logCode: '', logName: '', scheduleType: '', moduleName: '',
        description: '', retentionDays: 30, isEnabled: 1
      },
      rules: {
        logCode: [{ required: true, message: '请输入日志代码', trigger: 'blur' }],
        logName: [{ required: true, message: '请输入日志名称', trigger: 'blur' }],
        scheduleType: [{ required: true, message: '请选择调度类型', trigger: 'change' }]
      },
      pageNum: 1, pageSize: 10, pageCount: 0, itemTotalCount: 0
    }
  },
  mounted() { this.fetchData() },
  methods: {
    fetchData() {
      getScheduleLogDefinitionPage({ ...this.searchForm, pageNum: this.pageNum, pageSize: this.pageSize }).then(res => {
        if (res.code === 0 && res.result) {
          this.list = res.result.list || []
          this.itemTotalCount = res.result.pageParam?.itemTotalCount || 0
          this.pageCount = res.result.pageParam?.pageCount || 0
        }
      })
    },
    handleSearch() { this.pageNum = 1; this.fetchData() },
    handleReset() { this.searchForm = { keyword: '', scheduleType: '' }; this.pageNum = 1; this.fetchData() },
    handleAdd() {
      this.dialogFlag = 'add'; this.dialogTitle = '新增调度日志定义'
      this.formData = { id: null, logCode: '', logName: '', scheduleType: '', moduleName: '', description: '', retentionDays: 30, isEnabled: 1 }
      this.dialogVisible = true
    },
    handleEdit(row) { this.dialogFlag = 'edit'; this.dialogTitle = '编辑调度日志定义'; this.formData = { ...row }; this.dialogVisible = true },
    submitForm() {
      this.$refs.form.validate((valid) => {
        if (valid) {
          const action = this.dialogFlag === 'add' ? addScheduleLogDefinition : updateScheduleLogDefinition
          action(this.formData).then(res => {
            if (res.code === 0) {
              this.$message.success(this.dialogFlag === 'add' ? '添加成功' : '更新成功')
              this.closeDialog(); this.fetchData()
            } else { this.$message.error(res.msg || '操作失败') }
          })
        }
      })
    },
    closeDialog() { this.dialogVisible = false; this.$refs.form && this.$refs.form.resetFields() },
    handleDelete(row) {
      this.$confirm('确认删除该日志定义吗？', '提示', { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' })
        .then(() => {
          deleteScheduleLogDefinition({ id: row.id }).then(res => {
            if (res.code === 0) { this.$message.success('删除成功'); this.fetchData() }
            else { this.$message.error(res.msg || '删除失败') }
          })
        }).catch(() => {})
    },
    handlePagination(data) { this.pageNum = data.page; this.fetchData() }
  }
}
</script>

<style scoped>
.container { padding: 20px; }
.filter-bar { margin-bottom: 20px; }
.main { margin-top: 20px; }
</style>
