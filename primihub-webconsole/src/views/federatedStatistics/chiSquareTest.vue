<template>
  <div class="app-container">
    <el-page-header content="联邦统计 - 卡方检验" style="margin-bottom:20px;" @back="$router.go(-1)" />
    <el-card>
      <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
        <span>卡方检验任务列表</span>
        <el-button type="primary" icon="el-icon-plus" size="small" @click="showCreate=true">新建任务</el-button>
      </div>
      <el-form :inline="true" :model="query" style="margin-bottom:12px;">
        <el-form-item><el-input v-model="query.taskName" placeholder="任务名称" clearable style="width:180px;" /></el-form-item>
        <el-form-item>
          <el-select v-model="query.taskStatus" placeholder="任务状态" clearable style="width:120px;">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchList">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
      <el-table v-loading="loading" :data="list" border>
        <el-table-column prop="taskId" label="任务ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" min-width="160" />
        <el-table-column prop="variable1" label="变量1" width="130" />
        <el-table-column prop="variable2" label="变量2" width="130" />
        <el-table-column prop="participantCount" label="参与方数" width="90" />
        <el-table-column prop="dataVolume" label="数据量" width="100" />
        <el-table-column prop="taskStatus" label="任务状态" width="100">
          <template slot-scope="{row}"><el-tag :type="stateTag(row.taskStatus)" size="small">{{ stateLabel(row.taskStatus) }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" width="220" fixed="right">
          <template slot-scope="{row}">
            <el-button type="text" size="small" @click="handleView(row)">查看</el-button>
            <el-button v-if="row.taskStatus===0" type="text" size="small" @click="handleRun(row)">执行</el-button>
            <el-button v-if="row.taskStatus===1" type="text" size="small" @click="handleDownload(row)">下载</el-button>
            <el-button type="text" size="small" style="color:#f56c6c;" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:16px;" :current-page="query.pageNo" :page-size="query.pageSize"
        :total="total" layout="total,prev,pager,next" @current-change="p=>{query.pageNo=p;fetchList()}" />
    </el-card>

    <el-dialog title="新建卡方检验任务" :visible.sync="showCreate" width="580px" @close="resetForm">
      <el-form ref="form" :model="form" :rules="rules" label-width="140px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="参与方" prop="participants">
          <el-select v-model="form.participants" multiple placeholder="请选择参与方" style="width:100%;">
            <el-option label="机构A" value="ORG_A" />
            <el-option label="机构B" value="ORG_B" />
            <el-option label="机构C" value="ORG_C" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据资源" prop="dataResources">
          <el-select v-model="form.dataResources" multiple placeholder="请选择数据资源" style="width:100%;">
            <el-option v-for="r in resourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="变量1（分类变量）" prop="variable1">
          <el-input v-model="form.variable1" placeholder="请输入变量1字段名" />
        </el-form-item>
        <el-form-item label="变量2（分类变量）" prop="variable2">
          <el-input v-model="form.variable2" placeholder="请输入变量2字段名" />
        </el-form-item>
        <el-form-item label="显著性水平α" prop="alpha">
          <el-input-number v-model="form.alpha" :min="0.01" :max="0.1" :step="0.01" :precision="2" style="width:160px;" />
          <span style="margin-left:8px;color:#999;">（0.01 - 0.10）</span>
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
        <el-descriptions-item label="任务ID">{{ viewRow.taskId }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ stateLabel(viewRow.taskStatus) }}</el-descriptions-item>
        <el-descriptions-item label="变量1">{{ viewRow.variable1 }}</el-descriptions-item>
        <el-descriptions-item label="变量2">{{ viewRow.variable2 }}</el-descriptions-item>
        <el-descriptions-item label="显著性水平α">{{ viewRow.alpha }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewRow.createDate }}</el-descriptions-item>
      </el-descriptions>
      <div slot="footer"><el-button @click="showView=false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getFederatedStatisticsList, createFederatedStatistics, startFederatedStatistics, deleteFederatedStatistics } from '@/api/federatedStatistics'
import { getResourceList } from '@/api/resource'

const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'FederatedStatisticsChiSquareTest',
  data() {
    return {
      query: { taskName: '', taskStatus: null, statisticsType: 'CHI_SQUARE', pageNo: 1, pageSize: 10 },
      list: [], total: 0, loading: false,
      statusOptions: Object.entries(STATUS_MAP).map(([v, o]) => ({ value: +v, label: o.label })),
      showCreate: false, submitting: false,
      form: { taskName: '', participants: [], dataResources: [], variable1: '', variable2: '', alpha: 0.05, remark: '', statisticsType: 'CHI_SQUARE' },
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        participants: [{ required: true, type: 'array', min: 1, message: '请选择参与方', trigger: 'change' }],
        dataResources: [{ required: true, type: 'array', min: 1, message: '请选择数据资源', trigger: 'change' }],
        variable1: [{ required: true, message: '请输入变量1', trigger: 'blur' }],
        variable2: [{ required: true, message: '请输入变量2', trigger: 'blur' }],
        alpha: [{ required: true, message: '请输入显著性水平', trigger: 'blur' }]
      },
      resourceList: [],
      showView: false, viewRow: {}
    }
  },
  created() { this.fetchList(); this.fetchResources() },
  methods: {
    async fetchList() {
      this.loading = true
      try {
        const res = await getFederatedStatisticsList(this.query)
        if (res.code === 0) { this.list = res.result?.list || []; this.total = res.result?.total || 0 }
      } catch (e) { console.error(e) } finally { this.loading = false }
    },
    async fetchResources() {
      try { const res = await getResourceList({ pageNo: 1, pageSize: 100 }); this.resourceList = res.result?.data || [] } catch (e) { console.error(e) }
    },
    resetQuery() { this.query = { ...this.query, taskName: '', taskStatus: null, pageNo: 1 }; this.fetchList() },
    resetForm() {
      this.$refs.form && this.$refs.form.resetFields()
      this.form = { taskName: '', participants: [], dataResources: [], variable1: '', variable2: '', alpha: 0.05, remark: '', statisticsType: 'CHI_SQUARE' }
    },
    stateLabel(v) { return STATUS_MAP[v]?.label || '未知' },
    stateTag(v) { return STATUS_MAP[v]?.type || 'info' },
    handleView(row) { this.viewRow = row; this.showView = true },
    async handleRun(row) {
      try {
        const res = await startFederatedStatistics({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success('任务已提交执行'); this.fetchList() } else { this.$message.error(res.message || '执行失败') }
      } catch (e) { this.$message.error('请求异常') }
    },
    async handleDownload(row) {
      try {
        const res = await downloadStatisticsTask({ taskId: row.taskId })
        const url = URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a'); a.href = url; a.download = `卡方检验_${row.taskName}_${Date.now()}.csv`
        a.click(); URL.revokeObjectURL(url)
        this.$message.success('下载成功')
      } catch (e) { this.$message.error('下载失败') }
    },
    async handleDelete(row) {
      try {
        await this.$confirm(`确认删除任务「${row.taskName}」？`, '提示', { type: 'warning' })
        const res = await deleteFederatedStatistics({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success('已删除'); this.fetchList() } else { this.$message.error(res.message || '删除失败') }
      } catch (e) { if (e !== 'cancel') this.$message.error('操作失败') }
    },
    handleSubmit() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.submitting = true
        try {
          const res = await createFederatedStatistics(this.form)
          if (res.code === 0) { this.$message.success('任务创建成功'); this.showCreate = false; this.fetchList() } else { this.$message.error(res.message || '创建失败') }
        } catch (e) { this.$message.error('请求异常') } finally { this.submitting = false }
      })
    }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
