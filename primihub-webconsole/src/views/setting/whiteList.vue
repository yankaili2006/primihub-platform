<template>
  <div class="app-container">
    <h2>白名单管理</h2>

    <!-- 搜索栏 -->
    <div class="filter-container">
      <el-select v-model="listQuery.wlType" placeholder="白名单类型" clearable class="filter-item" style="width: 140px">
        <el-option v-for="item in typeOptions" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-input v-model="listQuery.wlValue" placeholder="白名单值" clearable style="width: 200px" class="filter-item" @keyup.enter.native="handleFilter" />
      <el-select v-model="listQuery.status" placeholder="状态" clearable class="filter-item" style="width: 120px">
        <el-option label="启用" :value="1" />
        <el-option label="禁用" :value="0" />
      </el-select>
      <el-button class="filter-item" type="primary" icon="el-icon-search" @click="handleFilter">搜索</el-button>
      <el-button class="filter-item" type="success" icon="el-icon-plus" @click="handleAdd">新增白名单</el-button>
    </div>

    <!-- 数据表格 -->
    <el-table
      v-loading="listLoading"
      :data="list"
      border
      fit
      highlight-current-row
      class="table-list"
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="55" />
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="白名单类型" width="120" prop="wlType">
        <template slot-scope="{ row }">
          <el-tag :type="row.wlType | typeFilter('tag')">{{ row.wlType | typeFilter('label') }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="白名单值" prop="wlValue" min-width="200" />
      <el-table-column label="备注" prop="wlReason" min-width="150" show-overflow-tooltip />
      <el-table-column label="状态" width="80" prop="status">
        <template slot-scope="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="mini">
            {{ row.status === 1 ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="创建人" width="120" prop="creatorName" />
      <el-table-column label="创建时间" width="160" prop="cTime" />
      <el-table-column align="center" label="操作" fixed="right" width="200">
        <template slot-scope="{ row }">
          <el-button type="text" icon="el-icon-edit" @click="handleEdit(row)">编辑</el-button>
          <el-button v-if="row.status === 1" type="text" icon="el-icon-video-pause" style="color:#e6a23c" @click="handleToggleStatus(row, 0)">禁用</el-button>
          <el-button v-else type="text" icon="el-icon-video-play" style="color:#67c23a" @click="handleToggleStatus(row, 1)">启用</el-button>
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 批量操作 -->
    <div v-if="multipleSelection.length > 0" class="batch-bar">
      <span class="batch-info">已选择 {{ multipleSelection.length }} 项</span>
      <el-button type="danger" size="small" icon="el-icon-delete" @click="handleBatchDelete">批量删除</el-button>
    </div>

    <!-- 分页 -->
    <pagination v-show="total > 0" :total="total" :page.sync="listQuery.pageNum" :limit.sync="listQuery.pageSize" @pagination="getList" />

    <!-- 新增/编辑对话框 -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogFormVisible"
      width="500px"
      :before-close="closeDialog"
    >
      <el-form ref="form" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="白名单类型" prop="wlType">
          <el-select v-model="form.wlType" placeholder="请选择类型" style="width: 100%">
            <el-option v-for="item in typeOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="白名单值" prop="wlValue">
          <el-input v-model="form.wlValue" placeholder="请输入手机号/IP地址/邮箱" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注" prop="wlReason">
          <el-input v-model="form.wlReason" type="textarea" :rows="3" placeholder="请输入添加原因或备注" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="closeDialog">取 消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="submitForm">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getWhiteListPage, saveWhiteList, updateWhiteList, deleteWhiteList, batchDeleteWhiteList } from '@/api/whiteList'
import Pagination from '@/components/Pagination'

const typeOptions = [
  { value: 1, label: '手机号', tag: 'primary' },
  { value: 2, label: 'IP地址', tag: 'warning' },
  { value: 3, label: '邮箱', tag: 'info' }
]

export default {
  name: 'WhiteListManage',
  components: { Pagination },
  filters: {
    typeFilter(val, type) {
      const opt = typeOptions.find(t => t.value === val)
      return opt ? opt[type] || opt.label : val
    }
  },
  data() {
    // 白名单值校验
    const validateWlValue = (rule, value, callback) => {
      if (!value) {
        callback(new Error('请输入白名单值'))
      } else if (this.form.wlType === 1 && !/^1[3-9]\d{9}$/.test(value)) {
        callback(new Error('请输入正确的手机号格式'))
      } else if (this.form.wlType === 2 && !/^(\d{1,3}\.){3}\d{1,3}$/.test(value)) {
        callback(new Error('请输入正确的IP地址格式'))
      } else if (this.form.wlType === 3 && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        callback(new Error('请输入正确的邮箱格式'))
      } else {
        callback()
      }
    }
    return {
      list: null,
      total: 0,
      listLoading: false,
      submitLoading: false,
      listQuery: {
        pageNum: 1,
        pageSize: 10,
        wlType: null,
        wlValue: '',
        status: null
      },
      typeOptions,
      dialogFormVisible: false,
      dialogType: 'add',
      dialogTitle: '新增白名单',
      form: {
        id: null,
        wlType: 1,
        wlValue: '',
        status: 1,
        wlReason: ''
      },
      rules: {
        wlType: [{ required: true, message: '请选择白名单类型', trigger: 'change' }],
        wlValue: [{ required: true, validator: validateWlValue, trigger: 'blur' }]
      },
      multipleSelection: []
    }
  },
  created() {
    this.getList()
  },
  methods: {
    async getList() {
      this.listLoading = true
      try {
        const res = await getWhiteListPage(this.listQuery)
        if (res.code === 0) {
          this.list = res.result.whiteList || []
          this.total = res.result.total || 0
        }
      } catch (e) {
        console.error(e)
        this.$message({ type: 'error', message: '请求异常' })
      } finally {
        setTimeout(() => { this.listLoading = false }, 200)
      }
    },
    handleFilter() {
      this.listQuery.pageNum = 1
      this.getList()
    },
    handleAdd() {
      this.dialogType = 'add'
      this.dialogTitle = '新增白名单'
      this.dialogFormVisible = true
      this.form = { id: null, wlType: 1, wlValue: '', status: 1, wlReason: '' }
      this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() })
    },
    handleEdit(row) {
      this.dialogType = 'edit'
      this.dialogTitle = '编辑白名单'
      this.dialogFormVisible = true
      this.form = {
        id: row.id,
        wlType: row.wlType,
        wlValue: row.wlValue,
        status: row.status,
        wlReason: row.wlReason
      }
      this.$nextTick(() => { this.$refs.form && this.$refs.form.clearValidate() })
    },
    handleToggleStatus(row, status) {
      const msg = status === 1 ? '启用' : '禁用'
      this.$confirm(`确定${msg}该白名单?`, '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        await updateWhiteList({ id: row.id, status })
        this.$message({ type: 'success', message: `${msg}成功` })
        this.getList()
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm('确定删除该白名单?', '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        await deleteWhiteList({ id: row.id })
        this.$message({ type: 'success', message: '删除成功' })
        this.getList()
      }).catch(() => {})
    },
    handleBatchDelete() {
      const ids = this.multipleSelection.map(s => s.id)
      this.$confirm(`确定删除选中的 ${ids.length} 项白名单?`, '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        await batchDeleteWhiteList(ids)
        this.$message({ type: 'success', message: '批量删除成功' })
        this.multipleSelection = []
        this.getList()
      }).catch(() => {})
    },
    handleSelectionChange(val) {
      this.multipleSelection = val
    },
    closeDialog() {
      this.dialogFormVisible = false
      this.$refs.form && this.$refs.form.resetFields()
    },
    submitForm() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.submitLoading = true
        try {
          if (this.dialogType === 'add') {
            await saveWhiteList(this.form)
          } else {
            await updateWhiteList(this.form)
          }
          this.$message({ type: 'success', message: this.dialogType === 'add' ? '添加成功' : '更新成功' })
          this.closeDialog()
          this.getList()
        } catch (e) {
          console.error(e)
        } finally {
          this.submitLoading = false
        }
      })
    }
  }
}
</script>

<style lang="scss" scoped>
.filter-container {
  padding: 12px 0;
  .filter-item {
    margin-right: 10px;
    vertical-align: middle;
  }
}
.table-list {
  margin-top: 10px;
}
.batch-bar {
  margin: 10px 0;
  padding: 10px;
  background: #f0f9eb;
  border-radius: 4px;
  .batch-info {
    margin-right: 15px;
    color: #67c23a;
    font-size: 13px;
  }
}
</style>