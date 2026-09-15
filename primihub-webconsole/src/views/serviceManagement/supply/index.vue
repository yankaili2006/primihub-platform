<template>
  <div class="container">
    <el-row :gutter="16" class="stat-cards">
      <el-col :span="6"><div class="stat-card"><div class="stat-num">{{ stats.total }}</div><div class="stat-label">产品总数</div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-num done">{{ stats.online }}</div><div class="stat-label">上架</div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-num warn">{{ stats.maintenance }}</div><div class="stat-label">维护中</div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-num">{{ stats.offline }}</div><div class="stat-label">下架</div></div></el-col>
    </el-row>
    <div class="search-area">
      <el-button type="primary" class="upload-button" @click="handleCreate">
        <i class="el-icon-plus" /> 添加产品
      </el-button>
      <el-button class="upload-button" icon="el-icon-download" @click="exportCsv">导出CSV</el-button>
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

    <!-- 详情对话框 -->
    <el-dialog title="产品详情" :visible.sync="detailVisible" width="820px">
      <el-descriptions v-if="detailRow" :column="2" border size="medium">
        <el-descriptions-item label="产品名称" :span="2">{{ detailRow.productName }}</el-descriptions-item>
        <el-descriptions-item label="服务分类"><el-tag size="small">{{ detailRow.serviceCategory || '—' }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="产品类型">{{ detailRow.productType || '—' }}</el-descriptions-item>
        <el-descriptions-item label="状态"><el-tag size="small" :type="statusTagType(detailRow.status)">{{ detailRow.status || '—' }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="质量等级"><el-tag size="small" :type="qualityTagType(detailRow.qualityLevel)">{{ detailRow.qualityLevel || '—' }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="定价模式">{{ detailRow.pricingModel || '—' }}</el-descriptions-item>
        <el-descriptions-item label="价格区间">{{ detailRow.priceRange || '—' }}</el-descriptions-item>
        <el-descriptions-item label="联系人">{{ detailRow.contactPerson || '—' }}</el-descriptions-item>
        <el-descriptions-item label="联系方式">{{ detailRow.contactInfo || '—' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间" :span="2">{{ fmtDateTime(detailRow.createdAt) }}</el-descriptions-item>
        <el-descriptions-item label="产品描述" :span="2"><span class="pre-wrap">{{ detailRow.productDesc || '—' }}</span></el-descriptions-item>
        <el-descriptions-item label="能力说明" :span="2"><span class="pre-wrap">{{ detailRow.capabilities || '—' }}</span></el-descriptions-item>
        <el-descriptions-item label="API端点" :span="2"><el-link v-if="detailRow.apiEndpoint" type="primary" :href="detailRow.apiEndpoint" target="_blank">{{ detailRow.apiEndpoint }}</el-link><span v-else>—</span></el-descriptions-item>
        <el-descriptions-item label="文档链接" :span="2"><el-link v-if="detailRow.documentationUrl" type="primary" :href="detailRow.documentationUrl" target="_blank">{{ detailRow.documentationUrl }}</el-link><span v-else>—</span></el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">
          <template v-if="extractUrls(detailRow.remark).length">
            <div v-if="stripUrls(detailRow.remark)" class="pre-wrap">{{ stripUrls(detailRow.remark) }}</div>
            <div v-for="(u, i) in extractUrls(detailRow.remark)" :key="i"><el-link type="primary" :href="u" target="_blank">{{ u }}</el-link></div>
          </template>
          <span v-else class="pre-wrap">{{ detailRow.remark || '—' }}</span>
        </el-descriptions-item>
      </el-descriptions>
      <div slot="footer" class="dialog-footer">
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button type="primary" @click="editFromDetail">编辑</el-button>
      </div>
    </el-dialog>

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="dialogTitle" :visible.sync="dialogVisible" width="900px" @close="handleDialogClose">
      <el-form ref="supplyForm" :model="formData" :rules="formRules" :disabled="dialogMode === 'view'" label-width="120px">
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
        <el-button v-if="dialogMode !== 'view'" type="primary" @click="handleSubmit">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import Pagination from '@/components/Pagination'
import { parseTime } from '@/utils'
import { getSupplyList, createSupply, updateSupply, deleteSupply, getSupplyStats } from '@/api/dataProduct'

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
      stats: { total: 0, online: 0, maintenance: 0, offline: 0 },
      supplyList: [],
      pageNo: 1,
      pageSize: 10,
      pageCount: 0,
      total: 0,
      detailVisible: false,
      detailRow: null,
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
    this.loadStats()
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
        const params = { pageNum: this.pageNo, pageSize: this.pageSize }
        if (this.query.productName) params.productName = this.query.productName
        if (this.query.serviceCategory) params.serviceCategory = this.query.serviceCategory
        if (this.query.status) params.status = this.query.status
        const res = await getSupplyList(params)
        const r = (res && res.result) || {}
        this.supplyList = r.list || []
        this.total = r.total || 0
        this.pageCount = Math.ceil(this.total / this.pageSize)
        this.loadStats()
      } catch (error) {
        this.$message.error('加载数据失败')
      }
    },
    buildQuery() {
      const p = {}
      if (this.query.productName) p.productName = this.query.productName
      if (this.query.serviceCategory) p.serviceCategory = this.query.serviceCategory
      if (this.query.status) p.status = this.query.status
      return p
    },
    async loadStats() {
      try {
        const res = await getSupplyStats()
        this.stats = { ...this.stats, ...((res && res.result) || {}) }
      } catch (e) { /* ignore */ }
    },
    async exportCsv() {
      try {
        const cols = [['id','ID'],['productName','产品名称'],['productDesc','产品描述'],['serviceCategory','服务分类'],['productType','产品类型'],['pricingModel','定价模式'],['priceRange','价格区间'],['status','状态'],['qualityLevel','质量等级'],['capabilities','能力说明'],['apiEndpoint','API端点'],['documentationUrl','文档链接'],['contactPerson','联系人'],['contactInfo','联系方式'],['createdAt','创建时间'],['remark','备注']]
        const rows = []
        let page = 1
        for (;;) {
          const params = { pageNum: page, pageSize: 100, ...this.buildQuery() }
          const res = await getSupplyList(params)
          const r = (res && res.result) || {}
          const list = r.list || []
          rows.push(...list)
          if (rows.length >= (r.total || 0) || list.length === 0) break
          page++
        }
        if (!rows.length) { this.$message.info('暂无可导出的数据'); return }
        const esc = v => {
          const s = (v === null || v === undefined) ? '' : String(v)
          return '"' + s.replace(/"/g, '""') + '"'
        }
        const cell = (row, key) => (key === 'createdAt' && row[key]) ? parseTime(new Date(row[key])) : row[key]
        const header = cols.map(c => esc(c[1])).join(',')
        const body = rows.map(row => cols.map(c => esc(cell(row, c[0]))).join(',')).join('\n')
        const csv = '\uFEFF' + header + '\n' + body
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = '数据产品供给_' + parseTime(new Date(), '{y}{m}{d}_{h}{i}{s}') + '.csv'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
        this.$message.success('已导出 ' + rows.length + ' 条')
      } catch (e) {
        this.$message.error('导出失败')
      }
    },
    fmtTime(row, column, value) {
      return value ? parseTime(new Date(value)) : ''
    },
    statusTagType(s) {
      if (s === '已完成' || s === '上架') return 'success'
      if (s === '进行中' || s === '维护中') return 'warning'
      if (s === '已关闭' || s === '下架') return 'info'
      return ''
    },
    priorityTagType(p) {
      return p === '紧急' ? 'danger' : p === '高' ? 'warning' : ''
    },
    qualityTagType(q) {
      return q === '高级' ? 'danger' : q === '标准' ? 'warning' : ''
    },
    fmtDate(v) {
      return v ? parseTime(new Date(v), '{y}-{m}-{d}') : '—'
    },
    fmtDateTime(v) {
      return v ? parseTime(new Date(v)) : '—'
    },
    extractUrls(s) {
      if (!s) return []
      return String(s).match(/https?:\/\/[^\s;，,、（）()]+/g) || []
    },
    stripUrls(s) {
      if (!s) return ''
      return String(s).replace(/https?:\/\/[^\s;，,、（）()]+/g, '').replace(/链接[:：]\s*/g, '').replace(/\s*;\s*/g, ' ').trim()
    },
    editFromDetail() {
      this.detailVisible = false
      this.handleEdit(this.detailRow)
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
      this.detailRow = { ...row }
      this.detailVisible = true
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
      }).then(async() => {
        await deleteSupply(row.id)
        this.$message.success('删除成功')
        this.loadSupplyList()
      }).catch(() => {})
    },
    handleSubmit() {
      this.$refs.supplyForm.validate(async valid => {
        if (!valid) return
        const payload = {}
        Object.keys(this.getDefaultFormData()).forEach(k => { payload[k] = this.formData[k] })
        try {
          if (this.dialogMode === 'edit') {
            await updateSupply(this.formData.id, payload)
            this.$message.success('更新成功')
          } else {
            await createSupply(payload)
            this.$message.success('创建成功')
          }
          this.dialogVisible = false
          this.loadSupplyList()
        } catch (e) {
          // 错误提示由 request 拦截器统一处理
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

.stat-cards {
  margin-bottom: 20px;
}
.stat-card {
  background: white;
  border-radius: 4px;
  padding: 18px 20px;
  text-align: center;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}
.stat-card .stat-num {
  font-size: 28px;
  font-weight: 600;
  color: #303133;
  line-height: 1.2;
}
.stat-card .stat-num.warn { color: #e6a23c; }
.stat-card .stat-num.prog { color: #409eff; }
.stat-card .stat-num.done { color: #67c23a; }
.stat-card .stat-label {
  margin-top: 6px;
  font-size: 13px;
  color: #909399;
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

.pre-wrap {
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
