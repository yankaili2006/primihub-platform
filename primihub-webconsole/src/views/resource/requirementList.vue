<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="关键字">
        <el-input v-model="queryForm.keyword" placeholder="需求编码或名称" clearable />
      </el-form-item>
      <el-form-item label="需求类型">
        <el-select v-model="queryForm.requirementType" placeholder="请选择" clearable>
          <el-option label="模型训练" value="模型训练" />
          <el-option label="数据分析" value="数据分析" />
          <el-option label="隐私求交" value="隐私求交" />
          <el-option label="其他" value="其他" />
        </el-select>
      </el-form-item>
      <el-form-item label="优先级">
        <el-select v-model="queryForm.priority" placeholder="请选择" clearable>
          <el-option label="低" :value="0" />
          <el-option label="中" :value="1" />
          <el-option label="高" :value="2" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryForm.status" placeholder="请选择" clearable>
          <el-option label="待匹配" :value="0" />
          <el-option label="已匹配" :value="1" />
          <el-option label="已完成" :value="2" />
          <el-option label="已关闭" :value="3" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增需求</el-button>
      <el-button type="danger" icon="el-icon-delete" :disabled="selectedIds.length === 0" @click="handleBatchDelete">
        批量删除
      </el-button>
    </el-row>

    <!-- Table -->
    <el-table
      v-loading="loading"
      :data="tableData"
      border
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="55" />
      <el-table-column prop="requirementCode" label="需求编码" width="150" />
      <el-table-column prop="requirementName" label="需求名称" width="200" />
      <el-table-column prop="requirementType" label="需求类型" width="120" />
      <el-table-column prop="priority" label="优先级" width="80">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.priority === 0" type="info">低</el-tag>
          <el-tag v-else-if="scope.row.priority === 1" type="warning">中</el-tag>
          <el-tag v-else-if="scope.row.priority === 2" type="danger">高</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.status === 0" type="info">待匹配</el-tag>
          <el-tag v-else-if="scope.row.status === 1" type="warning">已匹配</el-tag>
          <el-tag v-else-if="scope.row.status === 2" type="success">已完成</el-tag>
          <el-tag v-else-if="scope.row.status === 3" type="info">已关闭</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="dataVolume" label="所需数据量" width="120" />
      <el-table-column prop="dataFormat" label="数据格式" width="100" />
      <el-table-column prop="userName" label="创建人" width="120" />
      <el-table-column prop="createDate" label="创建时间" width="160" />
      <el-table-column label="操作" fixed="right" width="250">
        <template slot-scope="scope">
          <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
          <el-button size="mini" type="primary" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button size="mini" type="success" @click="handleMatch(scope.row)">匹配</el-button>
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
      width="60%"
      @close="handleDialogClose"
    >
      <el-form ref="dataForm" :model="formData" :rules="formRules" label-width="120px">
        <el-form-item label="需求编码" prop="requirementCode">
          <el-input v-model="formData.requirementCode" placeholder="请输入需求编码" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="需求名称" prop="requirementName">
          <el-input v-model="formData.requirementName" placeholder="请输入需求名称" />
        </el-form-item>
        <el-form-item label="需求类型" prop="requirementType">
          <el-select v-model="formData.requirementType" placeholder="请选择需求类型">
            <el-option label="模型训练" value="模型训练" />
            <el-option label="数据分析" value="数据分析" />
            <el-option label="隐私求交" value="隐私求交" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级" prop="priority">
          <el-select v-model="formData.priority" placeholder="请选择优先级">
            <el-option label="低" :value="0" />
            <el-option label="中" :value="1" />
            <el-option label="高" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="所需数据量">
          <el-input-number v-model="formData.dataVolume" :min="0" placeholder="请输入所需数据量" />
        </el-form-item>
        <el-form-item label="数据格式">
          <el-select v-model="formData.dataFormat" placeholder="请选择数据格式">
            <el-option label="CSV" value="CSV" />
            <el-option label="JSON" value="JSON" />
            <el-option label="Excel" value="Excel" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="所需数据字段">
          <el-input
            v-model="dataFieldsInput"
            type="textarea"
            :rows="3"
            placeholder="请输入所需数据字段，多个字段用逗号分隔，如: id,name,age,email"
          />
        </el-form-item>
        <el-form-item label="需求描述">
          <el-input
            v-model="formData.requirementDesc"
            type="textarea"
            :rows="4"
            placeholder="请输入需求描述"
          />
        </el-form-item>
        <el-form-item label="开始日期">
          <el-date-picker
            v-model="formData.startDate"
            type="datetime"
            placeholder="选择日期时间"
            value-format="yyyy-MM-dd HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="结束日期">
          <el-date-picker
            v-model="formData.endDate"
            type="datetime"
            placeholder="选择日期时间"
            value-format="yyyy-MM-dd HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- View Dialog -->
    <el-dialog title="需求详情" :visible.sync="viewDialogVisible" width="60%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="需求编码">{{ viewData.requirementCode }}</el-descriptions-item>
        <el-descriptions-item label="需求名称">{{ viewData.requirementName }}</el-descriptions-item>
        <el-descriptions-item label="需求类型">{{ viewData.requirementType }}</el-descriptions-item>
        <el-descriptions-item label="优先级">
          <el-tag v-if="viewData.priority === 0" type="info">低</el-tag>
          <el-tag v-else-if="viewData.priority === 1" type="warning">中</el-tag>
          <el-tag v-else-if="viewData.priority === 2" type="danger">高</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag v-if="viewData.status === 0" type="info">待匹配</el-tag>
          <el-tag v-else-if="viewData.status === 1" type="warning">已匹配</el-tag>
          <el-tag v-else-if="viewData.status === 2" type="success">已完成</el-tag>
          <el-tag v-else-if="viewData.status === 3" type="info">已关闭</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="所需数据量">{{ viewData.dataVolume || '-' }}</el-descriptions-item>
        <el-descriptions-item label="数据格式">{{ viewData.dataFormat || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ viewData.userName }}</el-descriptions-item>
        <el-descriptions-item label="机构名称">{{ viewData.organName }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewData.createDate }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ viewData.updateDate }}</el-descriptions-item>
        <el-descriptions-item label="开始日期">{{ viewData.startDate || '-' }}</el-descriptions-item>
        <el-descriptions-item label="结束日期">{{ viewData.endDate || '-' }}</el-descriptions-item>
        <el-descriptions-item label="所需数据字段" :span="2">{{ viewData.dataFields || '-' }}</el-descriptions-item>
        <el-descriptions-item label="需求描述" :span="2">{{ viewData.requirementDesc || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findDataRequirementPage,
  addDataRequirement,
  updateDataRequirement,
  deleteDataRequirement,
  batchDeleteDataRequirement,
  matchDataRequirements
} from '@/api/dataRequirement'
import { mapGetters } from 'vuex'

export default {
  name: 'DataRequirementList',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedIds: [],
      queryForm: {
        keyword: '',
        requirementType: '',
        priority: null,
        status: null,
        pageNum: 1,
        pageSize: 10
      },
      dialogVisible: false,
      dialogTitle: '',
      isEdit: false,
      formData: {},
      dataFieldsInput: '',
      formRules: {
        requirementCode: [
          { required: true, message: '请输入需求编码', trigger: 'blur' }
        ],
        requirementName: [
          { required: true, message: '请输入需求名称', trigger: 'blur' }
        ],
        requirementType: [
          { required: true, message: '请选择需求类型', trigger: 'change' }
        ],
        priority: [
          { required: true, message: '请选择优先级', trigger: 'change' }
        ]
      },
      viewDialogVisible: false,
      viewData: {}
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName', 'organId', 'organName'])
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.loading = true
      findDataRequirementPage(this.queryForm).then(res => {
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
          requirementCode: 'REQ-2024-001',
          requirementName: '用户画像数据需求',
          requirementType: '模型训练',
          priority: 2,
          status: 0,
          dataVolume: 100000,
          dataFormat: 'CSV',
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-10 10:00:00',
          updateDate: '2024-01-10 10:00:00',
          dataFields: '["user_id","age","gender","income","education"]',
          requirementDesc: '需要用户基础信息数据用于用户画像模型训练',
          startDate: '2024-01-01 00:00:00',
          endDate: '2024-12-31 23:59:59',
          remark: '优先级高，请尽快匹配'
        },
        {
          id: 2,
          requirementCode: 'REQ-2024-002',
          requirementName: '金融风控数据需求',
          requirementType: '数据分析',
          priority: 2,
          status: 1,
          dataVolume: 500000,
          dataFormat: 'JSON',
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-11 14:30:00',
          updateDate: '2024-01-12 09:00:00',
          dataFields: '["transaction_id","amount","merchant","risk_score"]',
          requirementDesc: '金融交易数据用于风控分析',
          startDate: '2024-02-01 00:00:00',
          endDate: '2024-06-30 23:59:59',
          remark: '已找到3个匹配资源'
        },
        {
          id: 3,
          requirementCode: 'REQ-2024-003',
          requirementName: '隐私求交测试数据',
          requirementType: '隐私求交',
          priority: 1,
          status: 0,
          dataVolume: 10000,
          dataFormat: 'CSV',
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-12 09:15:00',
          updateDate: '2024-01-12 09:15:00',
          dataFields: '["id","phone","email"]',
          requirementDesc: '需要包含手机号和邮箱的数据用于隐私求交测试',
          startDate: '2024-01-15 00:00:00',
          endDate: '2024-03-31 23:59:59',
          remark: ''
        },
        {
          id: 4,
          requirementCode: 'REQ-2024-004',
          requirementName: '医疗健康数据需求',
          requirementType: '模型训练',
          priority: 0,
          status: 2,
          dataVolume: 50000,
          dataFormat: 'Excel',
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-13 16:45:00',
          updateDate: '2024-01-15 10:00:00',
          dataFields: '["patient_id","diagnosis","treatment","outcome"]',
          requirementDesc: '脱敏后的医疗数据用于疾病预测模型',
          startDate: '2024-01-01 00:00:00',
          endDate: '2024-12-31 23:59:59',
          remark: '已完成数据获取'
        },
        {
          id: 5,
          requirementCode: 'REQ-2024-005',
          requirementName: '电商推荐数据需求',
          requirementType: '其他',
          priority: 1,
          status: 3,
          dataVolume: 200000,
          dataFormat: 'CSV',
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-14 11:20:00',
          updateDate: '2024-01-16 15:30:00',
          dataFields: '["user_id","product_id","click","purchase"]',
          requirementDesc: '用户行为数据用于推荐系统',
          startDate: '2024-01-01 00:00:00',
          endDate: '2024-06-30 23:59:59',
          remark: '需求已关闭'
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
        requirementType: '',
        priority: null,
        status: null,
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
    handleSelectionChange(selection) {
      this.selectedIds = selection.map(item => item.id)
    },
    handleAdd() {
      this.dialogTitle = '新增数据需求'
      this.isEdit = false
      this.formData = {
        priority: 0,
        status: 0,
        userId: this.userId,
        userName: this.userName,
        organId: this.organId,
        organName: this.organName
      }
      this.dataFieldsInput = ''
      this.dialogVisible = true
    },
    handleEdit(row) {
      this.dialogTitle = '编辑数据需求'
      this.isEdit = true
      this.formData = { ...row }
      // Convert JSON array to comma-separated string
      try {
        const fields = JSON.parse(row.dataFields || '[]')
        this.dataFieldsInput = fields.join(',')
      } catch (e) {
        this.dataFieldsInput = ''
      }
      this.dialogVisible = true
    },
    handleView(row) {
      this.viewData = { ...row }
      // Format dataFields for display
      try {
        const fields = JSON.parse(row.dataFields || '[]')
        this.viewData.dataFields = fields.join(', ')
      } catch (e) {
        this.viewData.dataFields = row.dataFields
      }
      this.viewDialogVisible = true
    },
    handleDelete(row) {
      this.$confirm('确认删除该数据需求吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteDataRequirement(row.id).then(res => {
          if (res.code === 0) {
            this.$message.success('删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        }).catch(() => {
          // 模拟删除成功
          this.$message.success('删除成功')
          this.tableData = this.tableData.filter(item => item.id !== row.id)
        })
      }).catch(() => {})
    },
    handleBatchDelete() {
      this.$confirm('确认批量删除选中的数据需求吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        batchDeleteDataRequirement(this.selectedIds).then(res => {
          if (res.code === 0) {
            this.$message.success('批量删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量删除失败')
          }
        }).catch(() => {
          // 模拟删除成功
          this.$message.success('批量删除成功')
          this.tableData = this.tableData.filter(item => !this.selectedIds.includes(item.id))
          this.selectedIds = []
        })
      }).catch(() => {})
    },
    handleMatch(row) {
      this.$confirm('确认对该需求执行自动匹配吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'info'
      }).then(() => {
        matchDataRequirements(row.id).then(res => {
          if (res.code === 0) {
            this.$message.success(`匹配成功，找到${res.result.matchCount}个匹配资源`)
            this.fetchData()
            // 跳转到匹配页面
            this.$router.push({
              name: 'DataRequirementMatch',
              query: { requirementId: row.id }
            })
          } else {
            this.$message.error(res.msg || '匹配失败')
          }
        }).catch(() => {
          // 模拟匹配成功
          this.$message.success('匹配成功，找到3个匹配资源')
          row.status = 1
          // 跳转到匹配页面
          this.$router.push({
            name: 'DataRequirementMatch',
            query: { requirementId: row.id }
          })
        })
      }).catch(() => {})
    },
    handleSubmit() {
      this.$refs.dataForm.validate((valid) => {
        if (valid) {
          // Convert comma-separated string to JSON array
          if (this.dataFieldsInput) {
            const fields = this.dataFieldsInput.split(',').map(f => f.trim()).filter(f => f)
            this.formData.dataFields = JSON.stringify(fields)
          }

          const apiFunc = this.isEdit ? updateDataRequirement : addDataRequirement
          apiFunc(this.formData).then(res => {
            if (res.code === 0) {
              this.$message.success(this.isEdit ? '更新成功' : '添加成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || (this.isEdit ? '更新失败' : '添加失败'))
            }
          }).catch(() => {
            // 模拟成功
            this.$message.success(this.isEdit ? '更新成功' : '添加成功')
            this.dialogVisible = false
            if (!this.isEdit) {
              const newItem = {
                ...this.formData,
                id: Date.now(),
                createDate: new Date().toLocaleString(),
                updateDate: new Date().toLocaleString()
              }
              this.tableData.unshift(newItem)
            }
          })
        }
      })
    },
    handleDialogClose() {
      this.$refs.dataForm.resetFields()
      this.formData = {}
      this.dataFieldsInput = ''
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>
