<template>
  <div class="app-container">
    <el-page-header content="单方机器学习LR算法" style="margin-bottom:20px;" @back="$router.go(-1)" />
    <el-alert
      title="逻辑回归（Logistic Regression）是一种经典的二分类线性模型，通过sigmoid函数将线性预测值映射到[0,1]区间，适用于二分类及概率预测任务。"
      type="info" show-icon :closable="false" style="margin-bottom:16px;" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建LR训练任务</span></div>
          <el-form ref="taskForm" :model="formData" :rules="formRules" label-width="140px">
            <el-form-item label="任务名称" prop="taskName">
              <el-input v-model="formData.taskName" placeholder="请输入任务名称" />
            </el-form-item>
            <el-form-item label="数据资源" prop="resourceId">
              <el-select v-model="formData.resourceId" placeholder="请选择数据资源" style="width:100%;">
                <el-option v-for="r in resourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="目标变量（Label列）" prop="labelCol">
              <el-input v-model="formData.labelCol" placeholder="如：label" />
            </el-form-item>
            <el-form-item label="特征列（逗号分隔）" prop="featureCols">
              <el-input v-model="formData.featureCols" placeholder="如：age,income,score" />
            </el-form-item>
            <el-form-item label="正则化类型" prop="penalty">
              <el-select v-model="formData.penalty" style="width:100%;">
                <el-option label="L1 (Lasso)" value="l1" />
                <el-option label="L2 (Ridge)" value="l2" />
                <el-option label="无正则化" value="none" />
              </el-select>
            </el-form-item>
            <el-form-item label="正则化系数 C">
              <el-input-number v-model="formData.C" :min="0.001" :max="100" :step="0.1" :precision="3" style="width:100%;" />
              <div style="color:#999;font-size:12px;margin-top:4px;">C值越小正则化越强（默认1.0）</div>
            </el-form-item>
            <el-form-item label="最大迭代次数" prop="maxIter">
              <el-input-number v-model="formData.maxIter" :min="50" :max="5000" :step="50" style="width:100%;" />
            </el-form-item>
            <el-form-item label="收敛阈值（tol）">
              <el-input-number v-model="formData.tol" :min="0.00001" :max="0.01" :step="0.00001" :precision="5" style="width:100%;" />
            </el-form-item>
            <el-form-item label="分类阈值">
              <el-input-number v-model="formData.threshold" :min="0.1" :max="0.9" :step="0.05" :precision="2" style="width:100%;" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="formData.remark" type="textarea" :rows="2" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="submitting" @click="handleSubmit">创建任务</el-button>
              <el-button @click="resetForm">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header">
            <span>任务列表</span>
            <el-button size="mini" style="float:right;" icon="el-icon-refresh" @click="fetchList">刷新</el-button>
          </div>
          <el-table v-loading="loading" :data="list" border size="small">
            <el-table-column type="index" width="50" label="序号" />
            <el-table-column prop="taskName" label="任务名称" min-width="120" show-overflow-tooltip />
            <el-table-column prop="taskState" label="状态" width="90" align="center">
              <template slot-scope="{row}">
                <el-tag :type="stateTag(row.taskState)" size="small">{{ stateLabel(row.taskState) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createDate" label="创建时间" width="140" />
            <el-table-column label="操作" width="180" fixed="right">
              <template slot-scope="{row}">
                <el-button type="text" size="small" @click="handleView(row)">查看</el-button>
                <el-button v-if="row.taskState===0" type="text" size="small" @click="handleRun(row)">执行</el-button>
                <el-button v-if="row.taskState===1" type="text" size="small" @click="handleDownload(row)">下载结果</el-button>
                <el-button type="text" size="small" style="color:#f56c6c;" @click="handleDelete(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination style="margin-top:12px;" :current-page="query.pageNo" :page-size="query.pageSize"
            :total="total" layout="total,prev,pager,next" @current-change="p=>{query.pageNo=p;fetchList()}" />
        </el-card>
      </el-col>
    </el-row>

    <el-dialog :title="viewRow.taskName || '任务详情'" :visible.sync="showView" width="600px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="目标变量">{{ viewRow.labelCol }}</el-descriptions-item>
        <el-descriptions-item label="正则化类型">{{ viewRow.penalty }}</el-descriptions-item>
        <el-descriptions-item label="正则化系数C">{{ viewRow.C }}</el-descriptions-item>
        <el-descriptions-item label="最大迭代次数">{{ viewRow.maxIter }}</el-descriptions-item>
        <el-descriptions-item label="分类阈值">{{ viewRow.threshold }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ stateLabel(viewRow.taskState) }}</el-descriptions-item>
        <el-descriptions-item label="创建时间" :span="2">{{ viewRow.createDate }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewRow.remark }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer">
        <el-button @click="showView=false">关闭</el-button>
        <el-button v-if="viewRow.taskState===1" type="primary" @click="handleDownload(viewRow)">下载结果</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getPreprocessTaskList, createPreprocessTask, runPreprocessTask, deletePreprocessTask, downloadPreprocessResult } from '@/api/singleParty'
import { getResourceList } from '@/api/resource'

const PREPROCESS_TYPE = 'LR_ALGORITHM'
const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'SinglePartyLRAlgorithm',
  data() {
    return {
      query: { taskName: '', pageNo: 1, pageSize: 10, preprocessType: PREPROCESS_TYPE },
      list: [], total: 0, loading: false,
      resourceList: [],
      submitting: false,
      formData: {
        taskName: '', resourceId: '', labelCol: 'label', featureCols: '',
        penalty: 'l2', C: 1.0, maxIter: 100, tol: 0.0001, threshold: 0.5, remark: '',
        preprocessType: PREPROCESS_TYPE
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        resourceId: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        labelCol: [{ required: true, message: '请输入目标变量列名', trigger: 'blur' }],
        featureCols: [{ required: true, message: '请输入特征列名', trigger: 'blur' }]
      },
      showView: false, viewRow: {}
    }
  },
  created() { this.fetchList(); this.fetchResources() },
  methods: {
    async fetchList() {
      this.loading = true
      try {
        const res = await getPreprocessTaskList(this.query)
        if (res.code === 0) { this.list = res.result?.list || []; this.total = res.result?.total || 0 }
      } catch (e) { console.error(e) } finally { this.loading = false }
    },
    async fetchResources() {
      try { const res = await getResourceList({ pageNo: 1, pageSize: 100 }); this.resourceList = res.result?.data || [] } catch (e) { console.error(e) }
    },
    resetForm() {
      this.$refs.taskForm && this.$refs.taskForm.resetFields()
      this.formData = { taskName: '', resourceId: '', labelCol: 'label', featureCols: '', penalty: 'l2', C: 1.0, maxIter: 100, tol: 0.0001, threshold: 0.5, remark: '', preprocessType: PREPROCESS_TYPE }
    },
    stateLabel(v) { return STATUS_MAP[v]?.label || '未知' },
    stateTag(v) { return STATUS_MAP[v]?.type || 'info' },
    handleView(row) { this.viewRow = row; this.showView = true },
    async handleRun(row) {
      try {
        const res = await runPreprocessTask({ taskId: row.taskId, preprocessType: PREPROCESS_TYPE })
        if (res.code === 0) { this.$message.success('任务已提交执行'); this.fetchList() } else { this.$message.error(res.message || '执行失败') }
      } catch (e) { this.$message.error('请求异常') }
    },
    async handleDownload(row) {
      try {
        const res = await downloadPreprocessResult({ taskId: row.taskId })
        const url = window.URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a'); a.href = url; a.download = `${row.taskName}_LR结果.csv`; a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('下载失败') }
    },
    async handleDelete(row) {
      try {
        await this.$confirm(`确认删除任务「${row.taskName}」？`, '提示', { type: 'warning' })
        const res = await deletePreprocessTask({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success('已删除'); this.fetchList() } else { this.$message.error(res.message || '删除失败') }
      } catch (e) { if (e !== 'cancel') this.$message.error('操作失败') }
    },
    handleSubmit() {
      this.$refs.taskForm.validate(async valid => {
        if (!valid) return
        this.submitting = true
        try {
          const res = await createPreprocessTask(this.formData)
          if (res.code === 0) { this.$message.success('任务创建成功'); this.resetForm(); this.fetchList() } else { this.$message.error(res.message || '创建失败') }
        } catch (e) { this.$message.error('请求异常') } finally { this.submitting = false }
      })
    }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
