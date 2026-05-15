<template>
  <div class="app-container">
    <el-page-header content="单方机器学习XGB算法" style="margin-bottom:20px;" @back="$router.go(-1)" />
    <el-alert
      title="XGBoost（Extreme Gradient Boosting）是一种高效的梯度提升决策树算法，支持分类、回归等多种任务，具有高精度、高效率的特点。"
      type="info" show-icon :closable="false" style="margin-bottom:16px;" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>创建XGBoost训练任务</span></div>
          <el-form ref="taskForm" :model="formData" :rules="formRules" label-width="160px">
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
            <el-form-item label="任务类型（objective）" prop="objective">
              <el-select v-model="formData.objective" style="width:100%;">
                <el-option label="二分类 (binary:logistic)" value="binary:logistic" />
                <el-option label="多分类 (multi:softmax)" value="multi:softmax" />
                <el-option label="回归 (reg:squarederror)" value="reg:squarederror" />
                <el-option label="排序 (rank:pairwise)" value="rank:pairwise" />
              </el-select>
            </el-form-item>
            <el-form-item label="树的数量（n_estimators）" prop="nEstimators">
              <el-input-number v-model="formData.nEstimators" :min="10" :max="1000" :step="10" style="width:100%;" />
            </el-form-item>
            <el-form-item label="学习率（eta）">
              <el-input-number v-model="formData.eta" :min="0.01" :max="1" :step="0.01" :precision="2" style="width:100%;" />
            </el-form-item>
            <el-form-item label="最大深度（max_depth）">
              <el-input-number v-model="formData.maxDepth" :min="1" :max="20" :step="1" style="width:100%;" />
            </el-form-item>
            <el-form-item label="子样本比例（subsample）">
              <el-input-number v-model="formData.subsample" :min="0.1" :max="1" :step="0.1" :precision="1" style="width:100%;" />
            </el-form-item>
            <el-form-item label="列采样比例（colsample）">
              <el-input-number v-model="formData.colsampleBytree" :min="0.1" :max="1" :step="0.1" :precision="1" style="width:100%;" />
            </el-form-item>
            <el-form-item label="最小叶节点样本数（min_child_weight）">
              <el-input-number v-model="formData.minChildWeight" :min="1" :max="100" :step="1" style="width:100%;" />
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
        <el-descriptions-item label="任务类型">{{ viewRow.objective }}</el-descriptions-item>
        <el-descriptions-item label="树的数量">{{ viewRow.nEstimators }}</el-descriptions-item>
        <el-descriptions-item label="学习率">{{ viewRow.eta }}</el-descriptions-item>
        <el-descriptions-item label="最大深度">{{ viewRow.maxDepth }}</el-descriptions-item>
        <el-descriptions-item label="子样本比例">{{ viewRow.subsample }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ stateLabel(viewRow.taskState) }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewRow.createDate }}</el-descriptions-item>
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

const PREPROCESS_TYPE = 'XGB_ALGORITHM'
const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'SinglePartyXGBAlgorithm',
  data() {
    return {
      query: { taskName: '', pageNo: 1, pageSize: 10, preprocessType: PREPROCESS_TYPE },
      list: [], total: 0, loading: false,
      resourceList: [],
      submitting: false,
      formData: {
        taskName: '', resourceId: '', labelCol: 'label', featureCols: '',
        objective: 'binary:logistic', nEstimators: 100, eta: 0.1, maxDepth: 6,
        subsample: 0.8, colsampleBytree: 0.8, minChildWeight: 1, remark: '',
        preprocessType: PREPROCESS_TYPE
      },
      formRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        resourceId: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        labelCol: [{ required: true, message: '请输入目标变量列名', trigger: 'blur' }],
        featureCols: [{ required: true, message: '请输入特征列名', trigger: 'blur' }],
        objective: [{ required: true, message: '请选择任务类型', trigger: 'change' }]
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
      this.formData = { taskName: '', resourceId: '', labelCol: 'label', featureCols: '', objective: 'binary:logistic', nEstimators: 100, eta: 0.1, maxDepth: 6, subsample: 0.8, colsampleBytree: 0.8, minChildWeight: 1, remark: '', preprocessType: PREPROCESS_TYPE }
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
        const a = document.createElement('a'); a.href = url; a.download = `${row.taskName}_XGB结果.csv`; a.click()
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
