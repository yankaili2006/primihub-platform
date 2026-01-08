<template>
  <div class="container">
    <!-- 搜索表单 -->
    <el-form :inline="true" :model="searchForm" class="search-form">
      <el-form-item label="白名单类型">
        <el-select v-model="searchForm.whitelistType" placeholder="请选择" clearable>
          <el-option label="邮箱" :value="1" />
          <el-option label="手机号" :value="2" />
        </el-select>
      </el-form-item>

      <el-form-item label="白名单值">
        <el-input v-model="searchForm.whitelistValue" placeholder="请输入" clearable />
      </el-form-item>

      <el-form-item label="状态">
        <el-select v-model="searchForm.status" placeholder="请选择" clearable>
          <el-option label="启用" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
      </el-form-item>

      <el-form-item>
        <el-button type="primary" @click="handleSearch">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 操作按钮 -->
    <div class="toolbar">
      <el-button v-if="hasPermission('WhitelistAdd')" type="primary" @click="handleAdd">
        新增白名单
      </el-button>
    </div>

    <!-- 数据表格 -->
    <el-table v-loading="loading" :data="list" border>
      <el-table-column prop="whitelistId" label="ID" width="80" />
      <el-table-column prop="whitelistTypeDesc" label="类型" width="100" />
      <el-table-column prop="whitelistValue" label="白名单值" min-width="200" />
      <el-table-column prop="whitelistDesc" label="备注说明" min-width="200" />
      <el-table-column prop="statusDesc" label="状态" width="100">
        <template slot-scope="scope">
          <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
            {{ scope.row.statusDesc }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="creatorName" label="创建人" width="120" />
      <el-table-column prop="cTime" label="创建时间" width="160">
        <template slot-scope="scope">
          {{ formatDate(scope.row.cTime) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" fixed="right">
        <template slot-scope="scope">
          <el-button
            v-if="hasPermission('WhitelistEdit')"
            type="text"
            size="small"
            @click="handleEdit(scope.row)"
          >
            编辑
          </el-button>
          <el-button
            v-if="hasPermission('WhitelistDelete')"
            type="text"
            size="small"
            style="color: #f56c6c"
            @click="handleDelete(scope.row)"
          >
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <pagination
      :total="total"
      :page.sync="pageNum"
      :limit.sync="pageSize"
      @pagination="fetchData"
    />

    <!-- 新增/编辑对话框 -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogVisible"
      width="600px"
      @close="handleDialogClose"
    >
      <el-form
        ref="whitelistForm"
        :model="formData"
        :rules="formRules"
        label-width="100px"
      >
        <el-form-item label="白名单类型" prop="whitelistType">
          <el-select v-model="formData.whitelistType" placeholder="请选择">
            <el-option label="邮箱" :value="1" />
            <el-option label="手机号" :value="2" />
          </el-select>
        </el-form-item>

        <el-form-item label="白名单值" prop="whitelistValue">
          <el-input
            v-model="formData.whitelistValue"
            :placeholder="formData.whitelistType === 1 ? '请输入邮箱地址' : '请输入手机号'"
          />
        </el-form-item>

        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="备注说明">
          <el-input
            v-model="formData.whitelistDesc"
            type="textarea"
            :rows="3"
            placeholder="请输入备注说明"
          />
        </el-form-item>
      </el-form>

      <div slot="footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">
          确定
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getWhitelistPage, saveOrUpdateWhitelist, deleteWhitelist } from '@/api/whitelist'
import Pagination from '@/components/Pagination'

export default {
  name: 'WhitelistManage',
  components: { Pagination },
  data() {
    // 自定义验证规则
    const validateEmail = (rule, value, callback) => {
      const emailReg = /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$/
      if (!value) {
        callback(new Error('请输入邮箱地址'))
      } else if (!emailReg.test(value)) {
        callback(new Error('邮箱格式不正确'))
      } else {
        callback()
      }
    }

    const validatePhone = (rule, value, callback) => {
      const phoneReg = /^1[3-9]\d{9}$/
      if (!value) {
        callback(new Error('请输入手机号'))
      } else if (!phoneReg.test(value)) {
        callback(new Error('手机号格式不正确'))
      } else {
        callback()
      }
    }

    return {
      // 搜索表单
      searchForm: {
        whitelistType: null,
        whitelistValue: '',
        status: null
      },

      // 列表数据
      list: [],
      loading: false,
      total: 0,
      pageNum: 1,
      pageSize: 10,

      // 对话框
      dialogVisible: false,
      dialogTitle: '',
      submitting: false,

      // 表单数据
      formData: {
        whitelistId: null,
        whitelistType: 1,
        whitelistValue: '',
        whitelistDesc: '',
        status: 1
      },

      // 表单验证规则
      formRules: {
        whitelistType: [
          { required: true, message: '请选择白名单类型', trigger: 'change' }
        ],
        whitelistValue: [
          {
            required: true,
            validator: (rule, value, callback) => {
              if (this.formData.whitelistType === 1) {
                validateEmail(rule, value, callback)
              } else if (this.formData.whitelistType === 2) {
                validatePhone(rule, value, callback)
              } else {
                callback()
              }
            },
            trigger: 'blur'
          }
        ],
        status: [
          { required: true, message: '请选择状态', trigger: 'change' }
        ]
      }
    }
  },

  computed: {
    // 权限检查
    hasPermission() {
      return (code) => {
        // 从 store 中获取按钮权限列表
        const permissions = this.$store.state.permission.buttonPermissionList || []
        return permissions.includes(code)
      }
    }
  },

  mounted() {
    this.fetchData()
  },

  methods: {
    // 获取列表数据
    async fetchData() {
      this.loading = true
      try {
        const params = {
          ...this.searchForm,
          pageNum: this.pageNum,
          pageSize: this.pageSize
        }
        const res = await getWhitelistPage(params)
        if (res.code === 0) {
          this.list = res.result.list || []
          this.total = res.result.total || 0
        }
      } catch (error) {
        this.$message.error('获取列表失败')
      } finally {
        this.loading = false
      }
    },

    // 搜索
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },

    // 重置
    handleReset() {
      this.searchForm = {
        whitelistType: null,
        whitelistValue: '',
        status: null
      }
      this.handleSearch()
    },

    // 新增
    handleAdd() {
      this.dialogTitle = '新增白名单'
      this.dialogVisible = true
      this.formData = {
        whitelistId: null,
        whitelistType: 1,
        whitelistValue: '',
        whitelistDesc: '',
        status: 1
      }
    },

    // 编辑
    handleEdit(row) {
      this.dialogTitle = '编辑白名单'
      this.dialogVisible = true
      this.formData = {
        whitelistId: row.whitelistId,
        whitelistType: row.whitelistType,
        whitelistValue: row.whitelistValue,
        whitelistDesc: row.whitelistDesc,
        status: row.status
      }
    },

    // 删除
    handleDelete(row) {
      this.$confirm('确定要删除该白名单吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        try {
          const res = await deleteWhitelist(row.whitelistId)
          if (res.code === 0) {
            this.$message.success('删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        } catch (error) {
          this.$message.error('删除失败')
        }
      }).catch(() => {})
    },

    // 提交表单
    handleSubmit() {
      this.$refs.whitelistForm.validate(async(valid) => {
        if (valid) {
          this.submitting = true
          try {
            const res = await saveOrUpdateWhitelist(this.formData)
            if (res.code === 0) {
              this.$message.success(this.formData.whitelistId ? '更新成功' : '新增成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || '操作失败')
            }
          } catch (error) {
            this.$message.error('操作失败')
          } finally {
            this.submitting = false
          }
        }
      })
    },

    // 对话框关闭
    handleDialogClose() {
      this.$refs.whitelistForm.resetFields()
    },

    // 格式化日期
    formatDate(date) {
      if (!date) return ''
      const d = new Date(date)
      const year = d.getFullYear()
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      const hour = String(d.getHours()).padStart(2, '0')
      const minute = String(d.getMinutes()).padStart(2, '0')
      const second = String(d.getSeconds()).padStart(2, '0')
      return `${year}-${month}-${day} ${hour}:${minute}:${second}`
    }
  }
}
</script>

<style scoped>
.container {
  padding: 20px;
}

.search-form {
  background: #fff;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 4px;
}

.toolbar {
  margin-bottom: 20px;
}
</style>
