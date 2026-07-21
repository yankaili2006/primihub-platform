<template>
  <div class="app-container">
    <!-- Search filters -->
    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="关键字">
        <el-input v-model="queryForm.keyword" placeholder="数据集名称或编码" clearable />
      </el-form-item>
      <el-form-item label="数据类型">
        <el-select v-model="queryForm.dataType" placeholder="请选择" clearable>
          <el-option label="结构化数据" value="结构化数据" />
          <el-option label="非结构化数据" value="非结构化数据" />
          <el-option label="半结构化数据" value="半结构化数据" />
        </el-select>
      </el-form-item>
      <el-form-item label="共享状态">
        <el-select v-model="queryForm.shareStatus" placeholder="请选择" clearable>
          <el-option label="待审核" :value="0" />
          <el-option label="已共享" :value="1" />
          <el-option label="已拒绝" :value="2" />
          <el-option label="已下架" :value="3" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- Action buttons -->
    <el-row style="margin-bottom: 20px;">
      <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增共享数据集</el-button>
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
      <el-table-column prop="datasetCode" label="数据集编码" width="150" />
      <el-table-column prop="datasetName" label="数据集名称" width="200" />
      <el-table-column prop="dataType" label="数据类型" width="120" />
      <el-table-column prop="dataFormat" label="数据格式" width="100" />
      <el-table-column prop="dataVolume" label="数据量" width="100" />
      <el-table-column prop="shareStatus" label="共享状态" width="100">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.shareStatus === 0" type="info">待审核</el-tag>
          <el-tag v-else-if="scope.row.shareStatus === 1" type="success">已共享</el-tag>
          <el-tag v-else-if="scope.row.shareStatus === 2" type="danger">已拒绝</el-tag>
          <el-tag v-else-if="scope.row.shareStatus === 3" type="warning">已下架</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="shareScope" label="共享范围" width="120">
        <template slot-scope="scope">
          <el-tag v-if="scope.row.shareScope === 0" type="info">仅本机构</el-tag>
          <el-tag v-else-if="scope.row.shareScope === 1" type="primary">指定机构</el-tag>
          <el-tag v-else-if="scope.row.shareScope === 2" type="success">全部机构</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="userName" label="创建人" width="100" />
      <el-table-column prop="createDate" label="创建时间" width="160" />
      <el-table-column label="操作" fixed="right" width="250">
        <template slot-scope="scope">
          <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
          <el-button size="mini" type="primary" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button
            v-if="scope.row.shareStatus === 1"
            size="mini"
            type="warning"
            @click="handleOffline(scope.row)"
          >下架</el-button>
          <el-button
            v-if="scope.row.shareStatus === 3"
            size="mini"
            type="success"
            @click="handleOnline(scope.row)"
          >上架</el-button>
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
        <el-form-item label="数据集编码" prop="datasetCode">
          <el-input v-model="formData.datasetCode" placeholder="请输入数据集编码" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="数据集名称" prop="datasetName">
          <el-input v-model="formData.datasetName" placeholder="请输入数据集名称" />
        </el-form-item>
        <el-form-item label="数据类型" prop="dataType">
          <el-select v-model="formData.dataType" placeholder="请选择数据类型">
            <el-option label="结构化数据" value="结构化数据" />
            <el-option label="非结构化数据" value="非结构化数据" />
            <el-option label="半结构化数据" value="半结构化数据" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据格式">
          <el-select v-model="formData.dataFormat" placeholder="请选择数据格式">
            <el-option label="CSV" value="CSV" />
            <el-option label="JSON" value="JSON" />
            <el-option label="Excel" value="Excel" />
            <el-option label="Parquet" value="Parquet" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据量">
          <el-input-number v-model="formData.dataVolume" :min="0" placeholder="请输入数据量" />
          <span style="margin-left: 10px;">条</span>
        </el-form-item>
        <el-form-item label="共享范围" prop="shareScope">
          <el-select v-model="formData.shareScope" placeholder="请选择共享范围">
            <el-option label="仅本机构" :value="0" />
            <el-option label="指定机构" :value="1" />
            <el-option label="全部机构" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="formData.shareScope === 1" label="指定机构">
          <el-select v-model="formData.targetOrganIds" multiple placeholder="请选择目标机构">
            <el-option
              v-for="org in organList"
              :key="org.organId"
              :label="org.organName"
              :value="org.organId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="关联资源">
          <el-select v-model="formData.resourceId" placeholder="请选择关联资源" filterable>
            <el-option
              v-for="res in resourceList"
              :key="res.resourceId"
              :label="res.resourceName"
              :value="res.resourceId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="数据字段">
          <el-input
            v-model="dataFieldsInput"
            type="textarea"
            :rows="3"
            placeholder="请输入数据字段，多个字段用逗号分隔，如: id,name,age,email"
          />
        </el-form-item>
        <el-form-item label="数据集描述">
          <el-input
            v-model="formData.datasetDesc"
            type="textarea"
            :rows="4"
            placeholder="请输入数据集描述"
          />
        </el-form-item>
        <el-form-item label="使用条款">
          <el-input
            v-model="formData.usageTerms"
            type="textarea"
            :rows="3"
            placeholder="请输入使用条款"
          />
        </el-form-item>
        <el-form-item label="有效期">
          <el-date-picker
            v-model="formData.validityPeriod"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="yyyy-MM-dd"
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
    <el-dialog title="共享数据集详情" :visible.sync="viewDialogVisible" width="60%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="数据集编码">{{ viewData.datasetCode }}</el-descriptions-item>
        <el-descriptions-item label="数据集名称">{{ viewData.datasetName }}</el-descriptions-item>
        <el-descriptions-item label="数据类型">{{ viewData.dataType }}</el-descriptions-item>
        <el-descriptions-item label="数据格式">{{ viewData.dataFormat || '-' }}</el-descriptions-item>
        <el-descriptions-item label="数据量">{{ viewData.dataVolume || '-' }} 条</el-descriptions-item>
        <el-descriptions-item label="共享状态">
          <el-tag v-if="viewData.shareStatus === 0" type="info">待审核</el-tag>
          <el-tag v-else-if="viewData.shareStatus === 1" type="success">已共享</el-tag>
          <el-tag v-else-if="viewData.shareStatus === 2" type="danger">已拒绝</el-tag>
          <el-tag v-else-if="viewData.shareStatus === 3" type="warning">已下架</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="共享范围">
          <el-tag v-if="viewData.shareScope === 0" type="info">仅本机构</el-tag>
          <el-tag v-else-if="viewData.shareScope === 1" type="primary">指定机构</el-tag>
          <el-tag v-else-if="viewData.shareScope === 2" type="success">全部机构</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建人">{{ viewData.userName }}</el-descriptions-item>
        <el-descriptions-item label="机构名称">{{ viewData.organName }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewData.createDate }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ viewData.updateDate }}</el-descriptions-item>
        <el-descriptions-item label="有效期">{{ viewData.startDate || '-' }} 至 {{ viewData.endDate || '-' }}</el-descriptions-item>
        <el-descriptions-item label="数据字段" :span="2">{{ viewData.dataFields || '-' }}</el-descriptions-item>
        <el-descriptions-item label="数据集描述" :span="2">{{ viewData.datasetDesc || '-' }}</el-descriptions-item>
        <el-descriptions-item label="使用条款" :span="2">{{ viewData.usageTerms || '-' }}</el-descriptions-item>
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
  findSharedDatasetPage,
  addSharedDataset,
  updateSharedDataset,
  deleteSharedDataset,
  batchDeleteSharedDataset,
  updateSharedDatasetStatus,
  getShareableResources
} from '@/api/dataShare'
import { mapGetters } from 'vuex'

export default {
  name: 'SharedDatasetList',
  data() {
    return {
      loading: false,
      tableData: [],
      total: 0,
      selectedIds: [],
      queryForm: {
        keyword: '',
        dataType: '',
        shareStatus: null,
        pageNum: 1,
        pageSize: 10
      },
      dialogVisible: false,
      dialogTitle: '',
      isEdit: false,
      formData: {},
      dataFieldsInput: '',
      formRules: {
        datasetCode: [
          { required: true, message: '请输入数据集编码', trigger: 'blur' }
        ],
        datasetName: [
          { required: true, message: '请输入数据集名称', trigger: 'blur' }
        ],
        dataType: [
          { required: true, message: '请选择数据类型', trigger: 'change' }
        ],
        shareScope: [
          { required: true, message: '请选择共享范围', trigger: 'change' }
        ]
      },
      viewDialogVisible: false,
      viewData: {},
      organList: [],
      resourceList: []
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName', 'organId', 'organName'])
  },
  mounted() {
    this.fetchData()
    this.loadOrganList()
    this.loadResourceList()
  },
  methods: {
    fetchData() {
      this.loading = true
      findSharedDatasetPage(this.queryForm).then(res => {
        this.loading = false
        if (res.code === 0) {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          this.$message.warning('查询失败：' + (res.msg || '未知错误'))
          this.tableData = []
          this.total = 0
        }
      }).catch(() => {
        this.loading = false
        this.$message.warning('查询失败，请检查网络或联系管理员')
        this.tableData = []
        this.total = 0
      })
    },
    getMockData() {
      return [
        {
          id: 1,
          datasetCode: 'DS-2024-001',
          datasetName: '用户行为数据集',
          dataType: '结构化数据',
          dataFormat: 'CSV',
          dataVolume: 100000,
          shareStatus: 1,
          shareScope: 2,
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-10 10:00:00',
          updateDate: '2024-01-10 10:00:00',
          dataFields: 'user_id,action,timestamp,device',
          datasetDesc: '用户行为分析数据集，包含用户操作记录',
          usageTerms: '仅限于数据分析和模型训练使用'
        },
        {
          id: 2,
          datasetCode: 'DS-2024-002',
          datasetName: '金融交易数据集',
          dataType: '结构化数据',
          dataFormat: 'Parquet',
          dataVolume: 500000,
          shareStatus: 1,
          shareScope: 1,
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-11 14:30:00',
          updateDate: '2024-01-11 14:30:00',
          dataFields: 'transaction_id,amount,merchant,category,timestamp',
          datasetDesc: '金融交易记录数据集',
          usageTerms: '需签署数据使用协议'
        },
        {
          id: 3,
          datasetCode: 'DS-2024-003',
          datasetName: '医疗健康数据集',
          dataType: '半结构化数据',
          dataFormat: 'JSON',
          dataVolume: 50000,
          shareStatus: 0,
          shareScope: 0,
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-12 09:15:00',
          updateDate: '2024-01-12 09:15:00',
          dataFields: 'patient_id,diagnosis,treatment,outcome',
          datasetDesc: '脱敏后的医疗健康数据',
          usageTerms: '仅限医疗研究使用'
        },
        {
          id: 4,
          datasetCode: 'DS-2024-004',
          datasetName: '电商商品数据集',
          dataType: '结构化数据',
          dataFormat: 'CSV',
          dataVolume: 200000,
          shareStatus: 3,
          shareScope: 2,
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-13 16:45:00',
          updateDate: '2024-01-14 10:00:00',
          dataFields: 'product_id,name,category,price,sales',
          datasetDesc: '电商平台商品信息数据集',
          usageTerms: '可用于推荐系统训练'
        },
        {
          id: 5,
          datasetCode: 'DS-2024-005',
          datasetName: '图像识别训练集',
          dataType: '非结构化数据',
          dataFormat: '其他',
          dataVolume: 10000,
          shareStatus: 2,
          shareScope: 1,
          userName: 'admin',
          organName: '机构A',
          createDate: '2024-01-14 11:20:00',
          updateDate: '2024-01-14 15:30:00',
          dataFields: 'image_path,label,category',
          datasetDesc: '图像分类训练数据集',
          usageTerms: '仅限图像识别模型训练'
        }
      ]
    },
    loadOrganList() {
      // TODO: 从后端获取机构列表
      this.organList = [
        { organId: 1, organName: '机构A' },
        { organId: 2, organName: '机构B' },
        { organId: 3, organName: '机构C' }
      ]
    },
    loadResourceList() {
      getShareableResources({}).then(res => {
        if (res.code === 0) {
          this.resourceList = res.result || []
        } else {
          // 使用测试数据
          this.resourceList = [
            { resourceId: 1, resourceName: '用户数据资源' },
            { resourceId: 2, resourceName: '交易数据资源' },
            { resourceId: 3, resourceName: '商品数据资源' }
          ]
        }
      }).catch(() => {
        this.resourceList = [
          { resourceId: 1, resourceName: '用户数据资源' },
          { resourceId: 2, resourceName: '交易数据资源' },
          { resourceId: 3, resourceName: '商品数据资源' }
        ]
      })
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = {
        keyword: '',
        dataType: '',
        shareStatus: null,
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
      this.dialogTitle = '新增共享数据集'
      this.isEdit = false
      this.formData = {
        shareStatus: 0,
        shareScope: 0,
        userId: this.userId,
        userName: this.userName,
        organId: this.organId,
        organName: this.organName
      }
      this.dataFieldsInput = ''
      this.dialogVisible = true
    },
    handleEdit(row) {
      this.dialogTitle = '编辑共享数据集'
      this.isEdit = true
      this.formData = { ...row }
      this.dataFieldsInput = row.dataFields || ''
      if (row.startDate && row.endDate) {
        this.formData.validityPeriod = [row.startDate, row.endDate]
      }
      this.dialogVisible = true
    },
    handleView(row) {
      this.viewData = { ...row }
      this.viewDialogVisible = true
    },
    handleDelete(row) {
      this.$confirm('确认删除该共享数据集吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteSharedDataset(row.id).then(res => {
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
    handleBatchDelete() {
      this.$confirm('确认批量删除选中的共享数据集吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        batchDeleteSharedDataset(this.selectedIds).then(res => {
          if (res.code === 0) {
            this.$message.success('批量删除成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量删除失败')
          }
        }).catch((e) => {
          this.$message.error('请求异常：' + (e.message || '批量删除失败'))
        })
      }).catch(() => {})
    },
    handleOffline(row) {
      this.$confirm('确认下架该共享数据集吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        updateSharedDatasetStatus(row.id, 3).then(res => {
          if (res.code === 0) {
            this.$message.success('下架成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '下架失败')
          }
        }).catch((e) => {
          this.$message.error('请求异常：' + (e.message || '下架失败'))
        })
      }).catch(() => {})
    },
    handleOnline(row) {
      this.$confirm('确认上架该共享数据集吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'info'
      }).then(() => {
        updateSharedDatasetStatus(row.id, 1).then(res => {
          if (res.code === 0) {
            this.$message.success('上架成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '上架失败')
          }
        }).catch((e) => {
          this.$message.error('请求异常：' + (e.message || '上架失败'))
        })
      }).catch(() => {})
    },
    handleSubmit() {
      this.$refs.dataForm.validate((valid) => {
        if (valid) {
          // 处理数据字段
          if (this.dataFieldsInput) {
            this.formData.dataFields = this.dataFieldsInput
          }
          // 处理有效期
          if (this.formData.validityPeriod && this.formData.validityPeriod.length === 2) {
            this.formData.startDate = this.formData.validityPeriod[0]
            this.formData.endDate = this.formData.validityPeriod[1]
          }

          const apiFunc = this.isEdit ? updateSharedDataset : addSharedDataset
          apiFunc(this.formData).then(res => {
            if (res.code === 0) {
              this.$message.success(this.isEdit ? '更新成功' : '添加成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || (this.isEdit ? '更新失败' : '添加失败'))
            }
          }).catch((e) => {
            this.$message.error('请求异常：' + (e.message || '请检查网络或联系管理员'))
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
