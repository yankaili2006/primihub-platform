<template>
  <div class="container">
    <div class="search-area">
      <el-button type="primary" class="upload-button" @click="handleCreate">
        <i class="el-icon-plus" /> 添加产品
      </el-button>
      <el-form :model="query" label-width="100px" :inline="true" @keyup.enter.native="search">
        <el-form-item label="产品名称">
          <el-input v-model="query.productName" size="small" placeholder="请输入产品名称" />
        </el-form-item>
        <el-form-item label="服务分类">
          <el-select v-model="query.serviceCategory" size="small" placeholder="请选择" clearable>
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
            <el-option label="上架" value="上架" />
            <el-option label="下架" value="下架" />
            <el-option label="维护中" value="维护中" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" class="search-button" size="small" @click="search">查询</el-button>
          <el-button size="small" icon="el-icon-refresh-right" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="resource">
      <el-table :data="supplyList" empty-text="暂无数据" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="productName" label="产品名称" min-width="150" />
        <el-table-column prop="productDesc" label="产品描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="serviceCategory" label="服务分类" width="120" />
        <el-table-column prop="pricingModel" label="定价模式" width="100" />
        <el-table-column prop="priceRange" label="价格区间" width="120" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="{row}">
            <el-tag
              :type="row.status === '上架' ? 'success' : row.status === '维护中' ? 'warning' : 'info'"
              size="small"
            >
              {{ row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="qualityLevel" label="质量等级" width="100">
          <template slot-scope="{row}">
            <el-tag
              :type="row.qualityLevel === '高级' ? 'danger' : row.qualityLevel === '标准' ? 'warning' : ''"
              size="small"
            >
              {{ row.qualityLevel }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="contactPerson" label="联系人" width="120" />
        <el-table-column prop="createdAt" label="创建时间" width="160" />
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
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="900px" @close="handleDialogClose">
      <el-form ref="supplyForm" :model="formData" :rules="formRules" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="产品名称" prop="productName">
              <el-input v-model="formData.productName" placeholder="请输入产品名称" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="产品类型" prop="productType">
              <el-input v-model="formData.productType" placeholder="请输入产品类型" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="产品描述" prop="productDesc">
          <el-input v-model="formData.productDesc" type="textarea" :rows="3" placeholder="请输入产品描述" />
        </el-form-item>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="服务分类" prop="serviceCategory">
              <el-select v-model="formData.serviceCategory" placeholder="请选择服务分类" style="width: 100%">
                <el-option label="数据采集" value="数据采集" />
                <el-option label="数据清洗" value="数据清洗" />
                <el-option label="数据标注" value="数据标注" />
                <el-option label="数据分析" value="数据分析" />
                <el-option label="数据可视化" value="数据可视化" />
                <el-option label="API服务" value="API服务" />
                <el-option label="其他" value="其他" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="质量等级" prop="qualityLevel">
              <el-select v-model="formData.qualityLevel" placeholder="请选择质量等级" style="width: 100%">
                <el-option label="基础" value="基础" />
                <el-option label="标准" value="标准" />
                <el-option label="高级" value="高级" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="定价模式" prop="pricingModel">
              <el-select v-model="formData.pricingModel" placeholder="请选择定价模式" style="width: 100%">
                <el-option label="按次" value="按次" />
                <el-option label="按量" value="按量" />
                <el-option label="包月" value="包月" />
                <el-option label="包年" value="包年" />
                <el-option label="定制" value="定制" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="价格区间" prop="priceRange">
              <el-input v-model="formData.priceRange" placeholder="请输入价格区间" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="能力说明" prop="capabilities">
          <el-input v-model="formData.capabilities" type="textarea" :rows="2" placeholder="请输入能力说明" />
        </el-form-item>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="API端点">
              <el-input v-model="formData.apiEndpoint" placeholder="请输入API端点" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="文档链接">
              <el-input v-model="formData.documentationUrl" placeholder="请输入文档链接" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系人" prop="contactPerson">
              <el-input v-model="formData.contactPerson" placeholder="请输入联系人" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="联系方式" prop="contactInfo">
              <el-input v-model="formData.contactInfo" placeholder="请输入联系方式" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import Pagination from '@/components/Pagination'

export default {
  name: 'DataProductSupply',
  components: { Pagination },
  data() {
    return {
      query: {
        productName: '',
        serviceCategory: '',
        status: ''
      },
      supplyList: [],
      pageNo: 1,
      pageSize: 10,
      pageCount: 0,
      total: 0,
      dialogVisible: false,
      dialogTitle: '',
      dialogMode: 'create',
      formData: this.getDefaultFormData(),
      formRules: {
        productName: [{ required: true, message: '请输入产品名称', trigger: 'blur' }],
        serviceCategory: [{ required: true, message: '请选择服务分类', trigger: 'change' }],
        pricingModel: [{ required: true, message: '请选择定价模式', trigger: 'change' }]
      }
    }
  },
  mounted() {
    this.loadSupplyList()
  },
  methods: {
    getDefaultFormData() {
      return {
        id: null,
        productName: '',
        productDesc: '',
        productType: '',
        serviceCategory: '',
        pricingModel: '',
        priceRange: '',
        qualityLevel: '标准',
        capabilities: '',
        apiEndpoint: '',
        documentationUrl: '',
        contactPerson: '',
        contactInfo: '',
        remark: ''
      }
    },
    async loadSupplyList() {
      try {
        // TODO: 实际API调用
        // const res = await getSupplyList({ ...this.query, pageNo: this.pageNo, pageSize: this.pageSize })
        // this.supplyList = res.data.list
        // this.total = res.data.total
        // this.pageCount = Math.ceil(this.total / this.pageSize)

        // 临时模拟数据
        this.supplyList = []
        this.total = 0
        this.pageCount = 0
        this.$message.info('数据产品供给功能开发中，请等待后端API完成')
      } catch (error) {
        this.$message.error('加载数据失败')
      }
    },
    search() {
      this.pageNo = 1
      this.loadSupplyList()
    },
    reset() {
      this.query = {
        productName: '',
        serviceCategory: '',
        status: ''
      }
      this.search()
    },
    handlePagination() {
      this.loadSupplyList()
    },
    handleCreate() {
      this.dialogMode = 'create'
      this.dialogTitle = '添加产品'
      this.formData = this.getDefaultFormData()
      this.dialogVisible = true
    },
    handleView(row) {
      this.$message.info('查看详情功能开发中')
    },
    handleEdit(row) {
      this.dialogMode = 'edit'
      this.dialogTitle = '编辑产品'
      this.formData = { ...row }
      this.dialogVisible = true
    },
    handleDelete(row) {
      this.$confirm('确认删除该产品吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        this.$message.success('删除功能开发中')
      }).catch(() => {})
    },
    handleSubmit() {
      this.$refs.supplyForm.validate(valid => {
        if (valid) {
          this.$message.success('提交功能开发中，请等待后端API完成')
          this.dialogVisible = false
        }
      })
    },
    handleDialogClose() {
      this.$refs.supplyForm && this.$refs.supplyForm.resetFields()
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
