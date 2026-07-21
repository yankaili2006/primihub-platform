<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="关键字">
        <el-input v-model="queryForm.keyword" placeholder="配置键或描述" clearable />
      </el-form-item>
      <el-form-item label="配置类型">
        <el-select v-model="queryForm.configType" placeholder="请选择" clearable>
          <el-option label="系统配置" value="系统配置" />
          <el-option label="匹配规则" value="匹配规则" />
          <el-option label="评分权重" value="评分权重" />
          <el-option label="其他" value="其他" />
        </el-select>
      </el-form-item>
      <el-form-item label="启用状态">
        <el-select v-model="queryForm.isEnabled" placeholder="请选择" clearable>
          <el-option label="启用" :value="1" />
          <el-option label="禁用" :value="0" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增配置</el-button>
    </el-row>

    <!-- Table -->
    <el-table
      v-loading="loading"
      :data="tableData"
      border
    >
      <el-table-column prop="configKey" label="配置键" width="200" />
      <el-table-column prop="configValue" label="配置值" width="150" />
      <el-table-column prop="configDesc" label="配置描述" min-width="250" />
      <el-table-column prop="configType" label="配置类型" width="120" />
      <el-table-column prop="isEnabled" label="启用状态" width="100">
        <template slot-scope="scope">
          <el-switch
            v-model="scope.row.isEnabled"
            :active-value="1"
            :inactive-value="0"
            @change="handleStatusChange(scope.row)"
          />
        </template>
      </el-table-column>
      <el-table-column prop="createDate" label="创建时间" width="160" />
      <el-table-column label="操作" fixed="right" width="150">
        <template slot-scope="scope">
          <el-button size="mini" type="primary" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button size="mini" type="danger" @click="handleDelete(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- Pagination -->
    <el-pagination
      style="margin-top: 20px;"
      :current-page="queryForm.pageNum"
      :page-sizes="[10, 20, 50, 100]"
      :page-size="queryForm.pageSize"
      :total="total"
      layout="total, sizes, prev, pager, next, jumper"
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
    />

    <!-- Add/Edit Dialog -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogVisible"
      width="50%"
      @close="handleDialogClose"
    >
      <el-form ref="dataForm" :model="formData" :rules="formRules" label-width="120px">
        <el-form-item label="配置键" prop="configKey">
          <el-input v-model="formData.configKey" placeholder="请输入配置键" :disabled="isEdit" />
          <span v-if="!isEdit" style="font-size: 12px; color: #999;">提示: 配置键唯一且不可修改</span>
        </el-form-item>
        <el-form-item label="配置值" prop="configValue">
          <el-input v-model="formData.configValue" placeholder="请输入配置值" />
        </el-form-item>
        <el-form-item label="配置描述">
          <el-input v-model="formData.configDesc" type="textarea" :rows="3" placeholder="请输入配置描述" />
        </el-form-item>
        <el-form-item label="配置类型" prop="configType">
          <el-select v-model="formData.configType" placeholder="请选择配置类型">
            <el-option label="系统配置" value="系统配置" />
            <el-option label="匹配规则" value="匹配规则" />
            <el-option label="评分权重" value="评分权重" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="启用状态">
          <el-switch v-model="formData.isEnabled" :active-value="1" :inactive-value="0" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleSubmit">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findConfigPage,
  addConfig,
  updateConfig,
  deleteConfig,
  updateConfigStatus
} from '@/api/dataRequirement'

export default {
  name: 'DataRequirementConfig',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      queryForm: {
        keyword: '',
        configType: '',
        isEnabled: null,
        pageNum: 1,
        pageSize: 10
      },
      dialogVisible: false,
      dialogTitle: '',
      isEdit: false,
      formData: {},
      formRules: {
        configKey: [
          { required: true, message: '请输入配置键', trigger: 'blur' }
        ],
        configValue: [
          { required: true, message: '请输入配置值', trigger: 'blur' }
        ],
        configType: [
          { required: true, message: '请选择配置类型', trigger: 'change' }
        ]
      }
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.loading = true
      findConfigPage(this.queryForm).then(res => {
        this.loading = false
        if (res.code === 0) {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          // 使用测试数据
          this.tableData = this.getMockData()
          this.total = this.tableData.length
        }
      }).catch(() => {
        this.loading = false
        // 使用测试数据
        this.tableData = this.getMockData()
        this.total = this.tableData.length
      })
    },
    getMockData() {
      return [
        {
          id: 1,
          configKey: 'match.field.weight',
          configValue: '40',
          configDesc: '字段匹配在总分中的权重百分比，用于计算数据需求与资源的匹配程度',
          configType: '评分权重',
          isEnabled: 1,
          createDate: '2024-01-10 10:00:00'
        },
        {
          id: 2,
          configKey: 'match.volume.weight',
          configValue: '25',
          configDesc: '数据量匹配在总分中的权重百分比',
          configType: '评分权重',
          isEnabled: 1,
          createDate: '2024-01-10 10:00:00'
        },
        {
          id: 3,
          configKey: 'match.format.weight',
          configValue: '20',
          configDesc: '数据格式匹配在总分中的权重百分比',
          configType: '评分权重',
          isEnabled: 1,
          createDate: '2024-01-10 10:00:00'
        },
        {
          id: 4,
          configKey: 'match.type.weight',
          configValue: '15',
          configDesc: '需求类型匹配在总分中的权重百分比',
          configType: '评分权重',
          isEnabled: 1,
          createDate: '2024-01-10 10:00:00'
        },
        {
          id: 5,
          configKey: 'match.score.threshold',
          configValue: '60',
          configDesc: '匹配得分阈值，低于此分数的资源不会被推荐',
          configType: '匹配规则',
          isEnabled: 1,
          createDate: '2024-01-11 14:30:00'
        },
        {
          id: 6,
          configKey: 'match.max.results',
          configValue: '10',
          configDesc: '单次匹配返回的最大资源数量',
          configType: '匹配规则',
          isEnabled: 1,
          createDate: '2024-01-11 14:30:00'
        },
        {
          id: 7,
          configKey: 'auto.match.enabled',
          configValue: 'true',
          configDesc: '是否启用自动匹配功能，新建需求时自动执行匹配',
          configType: '系统配置',
          isEnabled: 0,
          createDate: '2024-01-12 09:15:00'
        },
        {
          id: 8,
          configKey: 'notification.match.complete',
          configValue: 'true',
          configDesc: '匹配完成后是否发送通知给需求创建者',
          configType: '系统配置',
          isEnabled: 1,
          createDate: '2024-01-12 09:15:00'
        }
      ]
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = {
        keyword: '',
        configType: '',
        isEnabled: null,
        pageNum: 1,
        pageSize: 10
      }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNum = val
      this.fetchData()
    },
    handleAdd() {
      this.dialogTitle = '新增配置'
      this.isEdit = false
      this.formData = {
        isEnabled: 1
      }
      this.dialogVisible = true
    },
    handleEdit(row) {
      this.dialogTitle = '编辑配置'
      this.isEdit = true
      this.formData = { ...row }
      this.dialogVisible = true
    },
    handleDelete(row) {
      this.$confirm('确认删除该配置吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteConfig(row.id).then(res => {
          if (res.code === 0) {
            this.$message.success('删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        }).catch((e) => {
          this.$message.error('请求异常：' + (e.message || '删除失败'))
        })
      }).catch(() => {})
    },
    handleStatusChange(row) {
      updateConfigStatus(row.id, row.isEnabled).then(res => {
        if (res.code === 0) {
          this.$message.success('状态更新成功')
        } else {
          this.$message.error(res.msg || '状态更新失败')
          // Revert the switch
          row.isEnabled = row.isEnabled === 1 ? 0 : 1
        }
      }).catch((e) => {
        this.$message.error('请求异常：' + (e.message || '状态更新失败'))
      })
    },
    handleSubmit() {
      this.$refs.dataForm.validate((valid) => {
        if (valid) {
          const apiFunc = this.isEdit ? updateConfig : addConfig
          apiFunc(this.formData).then(res => {
            if (res.code === 0) {
              this.$message.success(this.isEdit ? '更新成功' : '添加成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || (this.isEdit ? '更新失败' : '添加失败'))
            }
          }).catch((e) => {
            this.$message.error('请求异常：' + (e.message || (this.isEdit ? '更新失败' : '添加失败')))
          })
        }
      })
    },
    handleDialogClose() {
      this.$refs.dataForm.resetFields()
      this.formData = {}
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>
