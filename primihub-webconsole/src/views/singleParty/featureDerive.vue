<template>
  <div class="app-container">
    <el-page-header content="单方特征衍生" style="margin-bottom:20px;" @back="$router.go(-1)" />
    <el-card>
      <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
        <span>特征衍生任务列表</span>
        <el-button type="primary" icon="el-icon-plus" size="small" @click="showCreate=true">新建衍生任务</el-button>
      </div>
      <el-form :inline="true" :model="query" style="margin-bottom:12px;">
        <el-form-item><el-input v-model="query.taskName" placeholder="任务名称" clearable style="width:180px;" /></el-form-item>
        <el-form-item>
          <el-select v-model="query.taskState" placeholder="任务状态" clearable style="width:120px;">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchList">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
      <el-table v-loading="loading" :data="list" border>
        <el-table-column type="index" width="50" label="序号" />
        <el-table-column prop="taskName" label="任务名称" min-width="160" />
        <el-table-column prop="deriveMethods" label="衍生方式" min-width="180">
          <template slot-scope="{row}">
            <el-tag v-for="m in (row.deriveMethods||[])" :key="m" size="small" style="margin-right:4px;">{{ deriveMethodLabel(m) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="datasetName" label="数据集" width="160" />
        <el-table-column prop="taskState" label="状态" width="100">
          <template slot-scope="{row}"><el-tag :type="stateTag(row.taskState)" size="small">{{ stateLabel(row.taskState) }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" width="220" fixed="right">
          <template slot-scope="{row}">
            <el-button type="text" size="small" @click="handleView(row)">查看</el-button>
            <el-button v-if="row.taskState===0" type="text" size="small" @click="handleRun(row)">执行</el-button>
            <el-button v-if="row.taskState===1" type="text" size="small" @click="handleDownload(row)">下载结果</el-button>
            <el-button type="text" size="small" style="color:#f56c6c;" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:16px;" :current-page="query.pageNo" :page-size="query.pageSize"
        :total="total" layout="total,prev,pager,next" @current-change="p=>{query.pageNo=p;fetchList()}" />
    </el-card>

    <el-dialog title="新建特征衍生任务" :visible.sync="showCreate" width="600px" @close="resetForm">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="数据资源" prop="resourceId">
          <el-select v-model="form.resourceId" placeholder="请选择数据资源" style="width:100%;">
            <el-option v-for="r in resourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="衍生方式" prop="deriveMethods">
          <el-checkbox-group v-model="form.deriveMethods">
            <el-checkbox v-for="m in deriveMethods" :key="m.value" :label="m.value">{{ m.label }}</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="基础字段" prop="baseFields">
          <el-select v-model="form.baseFields" multiple placeholder="请选择基础字段" style="width:100%;">
            <el-option v-for="f in fieldList" :key="f" :label="f" :value="f" />
          </el-select>
        </el-form-item>
        <el-form-item label="多项式阶数">
          <el-input-number v-model="form.polyDegree" :min="1" :max="3" style="width:120px;" />
          <span style="margin-left:8px;color:#999;">（1-3阶，多项式特征有效）</span>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="showCreate=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">创建</el-button>
      </div>
    </el-dialog>

    <el-dialog :title="viewRow.taskName || '任务详情'" :visible.sync="showView" width="560px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="数据集">{{ viewRow.datasetName }}</el-descriptions-item>
        <el-descriptions-item label="多项式阶数">{{ viewRow.polyDegree }}</el-descriptions-item>
        <el-descriptions-item label="衍生方式" :span="2">
          <el-tag v-for="m in (viewRow.deriveMethods||[])" :key="m" size="small" style="margin-right:4px;">{{ deriveMethodLabel(m) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="基础字段" :span="2">{{ (viewRow.baseFields || []).join('、') }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ stateLabel(viewRow.taskState) }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewRow.createDate }}</el-descriptions-item>
      </el-descriptions>
      <div slot="footer">
        <el-button @click="showView=false">关闭</el-button>
        <el-button v-if="viewRow.taskState===1" type="primary" @click="handleDownload(viewRow)">下载结果</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getPreprocessTaskList, createPreprocessTask, runPreprocessTask, deletePreprocessTask, downloadPreprocessResult } from '@/api/singleParty'
import { getResourceList } from '@/api/resource'

const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }
const DERIVE_METHODS = [
  { value: 'POLYNOMIAL', label: '多项式特征' },
  { value: 'CROSS', label: '交叉特征' },
  { value: 'MATH_TRANSFORM', label: '数学变换(log/sqrt/square)' },
  { value: 'TIME_EXTRACT', label: '时间特征提取' },
  { value: 'TEXT_EXTRACT', label: '文本特征提取' }
]

export default {
  name: 'SinglePartyFeatureDerive',
  data() {
    return {
      query: { taskName: '', taskState: null, pageNo: 1, pageSize: 10, preprocessType: 'FEATURE_DERIVE' },
      list: [], total: 0, loading: false,
      deriveMethods: DERIVE_METHODS,
      statusOptions: Object.entries(STATUS_MAP).map(([v, o]) => ({ value: +v, label: o.label })),
      showCreate: false, submitting: false,
      form: { taskName: '', resourceId: '', deriveMethods: [], baseFields: [], polyDegree: 2, remark: '', preprocessType: 'FEATURE_DERIVE' },
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        resourceId: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        deriveMethods: [{ required: true, type: 'array', min: 1, message: '请至少选择一种衍生方式', trigger: 'change' }],
        baseFields: [{ required: true, type: 'array', min: 1, message: '请至少选择一个基础字段', trigger: 'change' }]
      },
      resourceList: [],
      fieldList: ['age', 'score', 'income', 'feature1', 'feature2', 'create_time', 'description'],
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
    resetQuery() { this.query = { ...this.query, taskName: '', taskState: null, pageNo: 1 }; this.fetchList() },
    resetForm() {
      this.$refs.form && this.$refs.form.resetFields()
      this.form = { taskName: '', resourceId: '', deriveMethods: [], baseFields: [], polyDegree: 2, remark: '', preprocessType: 'FEATURE_DERIVE' }
    },
    deriveMethodLabel(v) { return DERIVE_METHODS.find(m => m.value === v)?.label || v || '-' },
    stateLabel(v) { return STATUS_MAP[v]?.label || '未知' },
    stateTag(v) { return STATUS_MAP[v]?.type || 'info' },
    handleView(row) { this.viewRow = row; this.showView = true },
    async handleRun(row) {
      try {
        const res = await runPreprocessTask({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success('任务已提交执行'); this.fetchList() } else { this.$message.error(res.message || '执行失败') }
      } catch (e) { this.$message.error('请求异常') }
    },
    async handleDownload(row) {
      try {
        const res = await downloadPreprocessResult({ taskId: row.taskId })
        const url = window.URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a'); a.href = url; a.download = `${row.taskName}_衍生结果.csv`; a.click()
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
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.submitting = true
        try {
          const res = await createPreprocessTask(this.form)
          if (res.code === 0) { this.$message.success('任务创建成功'); this.showCreate = false; this.fetchList() } else { this.$message.error(res.message || '创建失败') }
        } catch (e) { this.$message.error('请求异常') } finally { this.submitting = false }
      })
    }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
