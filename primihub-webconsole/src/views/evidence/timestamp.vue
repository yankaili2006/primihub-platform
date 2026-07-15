<template>
  <div class="app-container">
    <h2>时间戳管理</h2>

    <!-- 搜索栏 -->
    <div class="filter-container">
      <el-input v-model="listQuery.title" placeholder="搜索标题" clearable style="width: 200px" class="filter-item" @keyup.enter.native="handleFilter" />
      <el-select v-model="listQuery.applyStatus" placeholder="申请状态" clearable class="filter-item" style="width: 130px">
        <el-option label="待提交" :value="0" />
        <el-option label="已提交" :value="1" />
        <el-option label="已签发" :value="2" />
        <el-option label="失败" :value="3" />
      </el-select>
      <el-button class="filter-item" type="primary" icon="el-icon-search" @click="handleFilter">搜索</el-button>
      <el-button class="filter-item" type="success" icon="el-icon-plus" @click="handleApply">申请时间戳</el-button>
    </div>

    <!-- 数据表格 -->
    <el-table v-loading="listLoading" :data="list" border fit highlight-current-row class="table-list">
      <el-table-column align="center" label="序号" width="60" type="index" />
      <el-table-column label="申请编号" width="180" prop="applyId" />
      <el-table-column label="标题" prop="title" min-width="200" show-overflow-tooltip />
      <el-table-column label="文件哈希" prop="fileHash" width="200" show-overflow-tooltip>
        <template slot-scope="{ row }">
          <span style="font-family: monospace; font-size: 12px;">{{ row.fileHash ? row.fileHash.substring(0, 20) + '...' : '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="申请状态" width="100" align="center" prop="applyStatus">
        <template slot-scope="{ row }">
          <el-tag :type="statusTag(row.applyStatus)" size="mini">{{ statusLabel(row.applyStatus) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="时间戳值" width="150" prop="timestampValue" />
      <el-table-column label="证书编号" width="180" prop="certNumber" />
      <el-table-column label="申请人" width="120" prop="applyUserName" />
      <el-table-column label="申请时间" width="160" prop="applyTime" />
      <el-table-column align="center" label="操作" fixed="right" width="200">
        <template slot-scope="{ row }">
          <el-button v-if="row.applyStatus === 0" type="text" icon="el-icon-upload" style="color:#409eff" @click="handleSubmit(row)">提交申请</el-button>
          <el-button type="text" icon="el-icon-document" @click="handleDetail(row)">详情</el-button>
          <el-button type="text" icon="el-icon-delete" style="color:#f56c6c" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" :page.sync="listQuery.pageNum" :limit.sync="listQuery.pageSize" @pagination="getList" />

    <!-- 申请时间戳对话框 -->
    <el-dialog title="申请时间戳" :visible.sync="applyDialogVisible" width="550px" :before-close="closeApplyDialog">
      <el-form ref="applyForm" :model="applyForm" :rules="applyRules" label-width="100px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="applyForm.title" placeholder="请输入时间戳标题" maxlength="200" />
        </el-form-item>
        <el-form-item label="文件哈希" prop="fileHash">
          <el-input v-model="applyForm.fileHash" placeholder="请输入文件SHA256哈希值" maxlength="128" />
          <span class="tip-text">支持输入任意数据的哈希值，用于存证</span>
        </el-form-item>
        <el-form-item label="文件名称" prop="fileName">
          <el-input v-model="applyForm.fileName" placeholder="请输入原始文件名（选填）" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="applyForm.remark" type="textarea" :rows="3" placeholder="备注信息（选填）" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="closeApplyDialog">取 消</el-button>
        <el-button type="primary" :loading="applyLoading" @click="submitApplyForm">提交申请</el-button>
      </span>
    </el-dialog>

    <!-- 详情对话框 -->
    <el-dialog title="时间戳详情" :visible.sync="detailDialogVisible" width="600px">
      <el-form v-if="detailData" label-width="120px" label-position="left">
        <el-form-item label="申请编号"><span>{{ detailData.applyId }}</span></el-form-item>
        <el-form-item label="标题"><span>{{ detailData.title }}</span></el-form-item>
        <el-form-item label="文件名称"><span>{{ detailData.fileName || '-' }}</span></el-form-item>
        <el-form-item label="文件哈希"><span style="font-family: monospace; word-break: break-all;">{{ detailData.fileHash }}</span></el-form-item>
        <el-form-item label="申请状态">
          <el-tag :type="statusTag(detailData.applyStatus)">{{ statusLabel(detailData.applyStatus) }}</el-tag>
        </el-form-item>
        <el-form-item label="时间戳值"><span>{{ detailData.timestampValue || '待签发' }}</span></el-form-item>
        <el-form-item label="证书编号"><span>{{ detailData.certNumber || '待签发' }}</span></el-form-item>
        <el-form-item label="申请人"><span>{{ detailData.applyUserName || '-' }}</span></el-form-item>
        <el-form-item label="申请时间"><span>{{ detailData.applyTime || '-' }}</span></el-form-item>
        <el-form-item label="签发时间"><span>{{ detailData.issueTime || '-' }}</span></el-form-item>
        <el-form-item label="备注"><span>{{ detailData.remark || '-' }}</span></el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="detailDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getTimestampPage, applyTimestamp, submitTimestamp, deleteTimestamp, getTimestampDetail } from '@/api/timestamp'
import Pagination from '@/components/Pagination'

export default {
  name: 'TimestampManage',
  components: { Pagination },
  data() {
    return {
      list: null,
      total: 0,
      listLoading: false,
      applyLoading: false,
      listQuery: { pageNum: 1, pageSize: 10, title: '', applyStatus: null },
      applyDialogVisible: false,
      detailDialogVisible: false,
      detailData: null,
      applyForm: { title: '', fileHash: '', fileName: '', remark: '' },
      applyRules: {
        title: [{ required: true, message: '请输入时间戳标题', trigger: 'blur' }],
        fileHash: [{ required: true, message: '请输入文件哈希值', trigger: 'blur' }]
      }
    }
  },
  created() { this.getList() },
  methods: {
    statusLabel(val) {
      return { 0: '待提交', 1: '已提交', 2: '已签发', 3: '失败' }[val] || '未知'
    },
    statusTag(val) {
      return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger' }[val] || 'info'
    },
    async getList() {
      this.listLoading = true
      try {
        const res = await getTimestampPage(this.listQuery)
        if (res.code === 0) {
          this.list = res.result.list || []
          this.total = res.result.total || 0
        }
      } catch (e) {
        console.error(e)
        this.$message({ type: 'error', message: '请求异常' })
      } finally {
        this.listLoading = false
      }
    },
    handleFilter() { this.listQuery.pageNum = 1; this.getList() },
    handleApply() {
      this.applyForm = { title: '', fileHash: '', fileName: '', remark: '' }
      this.applyDialogVisible = true
      this.$nextTick(() => { this.$refs.applyForm && this.$refs.applyForm.clearValidate() })
    },
    closeApplyDialog() {
      this.applyDialogVisible = false
      this.$refs.applyForm && this.$refs.applyForm.resetFields()
    },
    async submitApplyForm() {
      this.$refs.applyForm.validate(async valid => {
        if (!valid) return
        this.applyLoading = true
        try {
          const res = await applyTimestamp(this.applyForm)
          if (res.code === 0) {
            this.$message({ type: 'success', message: '申请成功，请提交到授时中心' })
            this.closeApplyDialog()
            this.getList()
          } else {
            this.$message({ type: 'error', message: res.msg || '申请失败' })
          }
        } catch (e) {
          console.error(e)
          this.$message({ type: 'error', message: '申请失败，请稍后重试' })
        } finally {
          this.applyLoading = false
        }
      })
    },
    async handleSubmit(row) {
      this.$confirm('确定提交该时间戳申请到授时中心?', '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        const res = await submitTimestamp({ id: row.id })
        if (res.code === 0) {
          this.$message({ type: 'success', message: '提交成功，时间戳已签发' })
          this.getList()
        } else {
          this.$message({ type: 'error', message: res.msg || '提交失败' })
        }
      }).catch(() => {})
    },
    async handleDetail(row) {
      const res = await getTimestampDetail({ id: row.id })
      if (res.code === 0) {
        this.detailData = res.result
        this.detailDialogVisible = true
      }
    },
    handleDelete(row) {
      this.$confirm('确定删除该时间戳记录?', '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        await deleteTimestamp({ id: row.id })
        this.$message({ type: 'success', message: '删除成功' })
        this.getList()
      }).catch(() => {})
    }
  }
}
</script>

<style lang="scss" scoped>
.filter-container {
  padding: 12px 0;
  .filter-item { margin-right: 10px; vertical-align: middle; }
}
.table-list { margin-top: 10px; }
.tip-text { font-size: 12px; color: #999; }
</style>