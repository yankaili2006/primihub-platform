<template>
  <div class="container">
    <div class="search-area">
      <el-button type="primary" class="upload-button" @click="handleCreate">
        <i class="el-icon-plus" /> 添加需求
      </el-button>
      <el-form :model="query" label-width="100px" :inline="true" @keyup.enter.native="search">
        <el-form-item label="需求名称">
          <el-input v-model="query.demandName" size="small" placeholder="请输入需求名称" />
        </el-form-item>
        <el-form-item label="需求类型">
          <el-select v-model="query.demandType" size="small" placeholder="请选择" clearable>
            <el-option label="数据采集" value="数据采集" />
            <el-option label="数据清洗" value="数据清洗" />
            <el-option label="数据标注" value="数据标注" />
            <el-option label="数据分析" value="数据分析" />
            <el-option label="数据可视化" value="数据可视化" />
            <el-option label="API服务" value="API服务" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" size="small" placeholder="请选择" clearable>
            <el-option label="待处理" value="待处理" />
            <el-option label="进行中" value="进行中" />
            <el-option label="已完成" value="已完成" />
            <el-option label="已关闭" value="已关闭" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" class="search-button" size="small" @click="search">查询</el-button>
          <el-button size="small" icon="el-icon-refresh-right" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="resource">
      <el-table :data="demandList" empty-text="暂无数据" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="demandName" label="需求名称" min-width="150" />
        <el-table-column prop="demandDesc" label="需求描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="demandType" label="需求类型" width="120" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="{row}">
            <el-tag
              :type="row.status === '已完成' ? 'success' : row.status === '进行中' ? 'warning' : row.status === '已关闭' ? 'info' : ''"
              size="small"
            >
              {{ row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="priority" label="优先级" width="100">
          <template slot-scope="{row}">
            <el-tag
              :type="row.priority === '紧急' ? 'danger' : row.priority === '高' ? 'warning' : ''"
              size="small"
            >
              {{ row.priority }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="budget" label="预算" width="120" />
        <el-table-column prop="contactPerson" label="联系人" width="120" />
        <el-table-column prop="createdAt" label="创建时间" width="160" :formatter="fmtTime" />
        <el-table-column label="操作" fixed="right" width="180" align="center">
          <template slot-scope="{row}">
            <el-button type="text" @click="handleView(row)">查看</el-button>
            <el-button type="text" @click="handleEdit(row)">编辑</el-button>
            <el-button type="text" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <pagination
        v-show="pageCount > 1"
        :limit.sync="pageSize"
        :page-count="pageCount"
        :page.sync="pageNo"
        :total="total"
        @pagination="handlePagination"
      />
    </div>

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="800px" @close="handleDialogClose">
      <el-form ref="demandForm" :model="formData" :rules="formRules" :disabled="dialogMode === 'view'" label-width="120px">
        <el-form-item label="需求名称" prop="demandName">
          <el-input v-model="formData.demandName" placeholder="请输入需求名称" />
        </el-form-item>
        <el-form-item label="需求描述" prop="demandDesc">
          <el-input v-model="formData.demandDesc" type="textarea" :rows="3" placeholder="请输入需求描述" />
        </el-form-item>
        <el-form-item label="需求类型" prop="demandType">
          <el-select v-model="formData.demandType" placeholder="请选择需求类型">
            <el-option label="数据采集" value="数据采集" />
            <el-option label="数据清洗" value="数据清洗" />
            <el-option label="数据标注" value="数据标注" />
            <el-option label="数据分析" value="数据分析" />
            <el-option label="数据可视化" value="数据可视化" />
            <el-option label="API服务" value="API服务" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="预算" prop="budget">
          <el-input v-model="formData.budget" placeholder="请输入预算" />
        </el-form-item>
        <el-form-item label="期望交付时间" prop="expectedDelivery">
          <el-date-picker
            v-model="formData.expectedDelivery"
            type="date"
            placeholder="选择日期"
            value-format="yyyy-MM-dd"
          />
        </el-form-item>
        <el-form-item label="优先级" prop="priority">
          <el-select v-model="formData.priority" placeholder="请选择优先级">
            <el-option label="低" value="低" />
            <el-option label="中" value="中" />
            <el-option label="高" value="高" />
            <el-option label="紧急" value="紧急" />
          </el-select>
        </el-form-item>
        <el-form-item label="联系人" prop="contactPerson">
          <el-input v-model="formData.contactPerson" placeholder="请输入联系人" />
        </el-form-item>
        <el-form-item label="联系方式" prop="contactInfo">
          <el-input v-model="formData.contactInfo" placeholder="请输入联系方式" />
        </el-form-item>
        <el-form-item label="技术要求" prop="techRequirements">
          <el-input v-model="formData.techRequirements" type="textarea" :rows="3" placeholder="请输入技术要求" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button v-if="dialogMode !== 'view'" type="primary" @click="handleSubmit">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import Pagination from '@/components/Pagination'
import { parseTime } from '@/utils'
import { getDemandList, createDemand, updateDemand, deleteDemand } from '@/api/dataProduct'

export default {
  name: 'DataProductDemand',
  components: { Pagination },
  data() {
    return {
      query: {
        demandName: '',
        demandType: '',
        status: ''
      },
      demandList: [],
      pageNo: 1,
      pageSize: 10,
      pageCount: 0,
      total: 0,
      dialogVisible: false,
      dialogTitle: '',
      dialogMode: 'create',
      formData: this.getDefaultFormData(),
      formRules: {
        demandName: [{ required: true, message: '请输入需求名称', trigger: 'blur' }],
        demandType: [{ required: true, message: '请选择需求类型', trigger: 'change' }],
        priority: [{ required: true, message: '请选择优先级', trigger: 'change' }]
      }
    }
  },
  mounted() {
    this.loadDemandList()
  },
  methods: {
    getDefaultFormData() {
      return {
        id: null,
        demandName: '',
        demandDesc: '',
        demandType: '',
        budget: '',
        expectedDelivery: '',
        priority: '中',
        contactPerson: '',
        contactInfo: '',
        techRequirements: '',
        remark: ''
      }
    },
    async loadDemandList() {
      try {
        const params = { pageNum: this.pageNo, pageSize: this.pageSize }
        if (this.query.demandName) params.demandName = this.query.demandName
        if (this.query.demandType) params.demandType = this.query.demandType
        if (this.query.status) params.status = this.query.status
        const res = await getDemandList(params)
        const r = (res && res.result) || {}
        this.demandList = r.list || []
        this.total = r.total || 0
        this.pageCount = Math.ceil(this.total / this.pageSize)
      } catch (error) {
        this.$message.error('加载数据失败')
      }
    },
    fmtTime(row, column, value) {
      return value ? parseTime(new Date(value)) : ''
    },
    search() {
      this.pageNo = 1
      this.loadDemandList()
    },
    reset() {
      this.query = {
        demandName: '',
        demandType: '',
        status: ''
      }
      this.search()
    },
    handlePagination() {
      this.loadDemandList()
    },
    handleCreate() {
      this.dialogMode = 'create'
      this.dialogTitle = '添加需求'
      this.formData = this.getDefaultFormData()
      this.dialogVisible = true
    },
    handleView(row) {
      this.dialogMode = 'view'
      this.dialogTitle = '查看需求'
      this.formData = this.normalizeRow(row)
      this.dialogVisible = true
    },
    normalizeRow(row) {
      const data = { ...row }
      data.expectedDelivery = row.expectedDelivery ? parseTime(new Date(row.expectedDelivery), '{y}-{m}-{d}') : ''
      return data
    },
    handleEdit(row) {
      this.dialogMode = 'edit'
      this.dialogTitle = '编辑需求'
      this.formData = this.normalizeRow(row)
      this.dialogVisible = true
    },
    handleDelete(row) {
      this.$confirm('确认删除该需求吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        await deleteDemand(row.id)
        this.$message.success('删除成功')
        this.loadDemandList()
      }).catch(() => {})
    },
    handleSubmit() {
      this.$refs.demandForm.validate(async valid => {
        if (!valid) return
        // 只提交表单字段，剥离 createdAt/organId 等回读字段（日期回传会触发反序列化失败）
        const payload = {}
        Object.keys(this.getDefaultFormData()).forEach(k => { payload[k] = this.formData[k] })
        try {
          if (this.dialogMode === 'edit') {
            await updateDemand(this.formData.id, payload)
            this.$message.success('更新成功')
          } else {
            await createDemand(payload)
            this.$message.success('创建成功')
          }
          this.dialogVisible = false
          this.loadDemandList()
        } catch (e) {
          // 错误提示由 request 拦截器统一处理
        }
      })
    },
    handleDialogClose() {
      this.$refs.demandForm && this.$refs.demandForm.resetFields()
    }
  }
}
</script>

<style scoped>
.container {
  padding: 20px;
}

.search-area {
  background: white;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 4px;
}

.upload-button {
  margin-bottom: 15px;
}

.resource {
  background: white;
  padding: 20px;
  border-radius: 4px;
}
</style>
