<template>
  <div class="app-container">
    <el-page-header content="单方数据统计" style="margin-bottom:20px;" @back="$router.go(-1)" />
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6">
        <el-card shadow="never">
          <div style="font-size:13px;color:#999;">统计任务总数</div>
          <div style="font-size:24px;font-weight:600;margin-top:4px;">{{ stats.total }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never">
          <div style="font-size:13px;color:#999;">已完成</div>
          <div style="font-size:24px;font-weight:600;color:#67c23a;margin-top:4px;">{{ stats.done }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never">
          <div style="font-size:13px;color:#999;">执行中</div>
          <div style="font-size:24px;font-weight:600;color:#e6a23c;margin-top:4px;">{{ stats.running }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never">
          <div style="font-size:13px;color:#999;">失败</div>
          <div style="font-size:24px;font-weight:600;color:#f56c6c;margin-top:4px;">{{ stats.failed }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card>
      <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
        <span>数据统计任务列表</span>
        <el-button type="primary" icon="el-icon-plus" size="small" @click="showCreate=true">新建统计任务</el-button>
      </div>
      <el-form :inline="true" :model="query" style="margin-bottom:12px;">
        <el-form-item>
          <el-input v-model="query.taskName" placeholder="任务名称" clearable style="width:180px;" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.statType" placeholder="统计类型" clearable style="width:140px;">
            <el-option v-for="t in statTypes" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
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
        <el-table-column prop="statType" label="统计类型" width="120">
          <template slot-scope="{row}">
            <el-tag size="small">{{ statTypeLabel(row.statType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="datasetName" label="数据集" width="160" />
        <el-table-column prop="taskState" label="状态" width="100">
          <template slot-scope="{row}">
            <el-tag :type="stateTag(row.taskState)" size="small">{{ stateLabel(row.taskState) }}</el-tag>
          </template>
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

    <!-- 新建任务弹窗 -->
    <el-dialog title="新建单方数据统计任务" :visible.sync="showCreate" width="560px" @close="resetForm">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="统计类型" prop="statType">
          <el-select v-model="form.statType" placeholder="请选择统计类型" style="width:100%;">
            <el-option v-for="t in statTypes" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据资源" prop="resourceId">
          <el-select v-model="form.resourceId" placeholder="请选择数据资源" style="width:100%;">
            <el-option v-for="r in resourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="统计字段" prop="fields">
          <el-select v-model="form.fields" multiple placeholder="请选择统计字段" style="width:100%;">
            <el-option v-for="f in fieldList" :key="f" :label="f" :value="f" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.statType==='GROUP'" label="分组字段">
          <el-select v-model="form.groupField" placeholder="请选择分组字段" style="width:100%;">
            <el-option v-for="f in fieldList" :key="f" :label="f" :value="f" />
          </el-select>
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

    <!-- 查看结果弹窗 -->
    <el-dialog :title="viewRow.taskName" :visible.sync="showView" width="700px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="统计类型">{{ statTypeLabel(viewRow.statType) }}</el-descriptions-item>
        <el-descriptions-item label="数据集">{{ viewRow.datasetName }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ stateLabel(viewRow.taskState) }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewRow.createDate }}</el-descriptions-item>
      </el-descriptions>
      <el-table v-if="viewRow.resultData && viewRow.resultData.length" :data="viewRow.resultData"
        border style="margin-top:16px;">
        <el-table-column prop="field" label="字段" />
        <el-table-column prop="statType" label="统计项" />
        <el-table-column prop="value" label="结果值" />
      </el-table>
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

const STAT_TYPES = [
  { value: 'DESCRIBE', label: '描述性统计（均值/最值/方差）' },
  { value: 'COUNT', label: '计数统计' },
  { value: 'SUM', label: '求和统计' },
  { value: 'FREQ', label: '频率分布' },
  { value: 'MISSING', label: '缺失值统计' },
  { value: 'UNIQUE', label: '唯一值统计' }
]

const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'SinglePartyDataStats',
  data() {
    return {
      query: { taskName: '', statType: '', taskState: null, pageNo: 1, pageSize: 10, preprocessType: 'DATA_STATS' },
      list: [], total: 0, loading: false,
      stats: { total: 0, done: 0, running: 0, failed: 0 },
      statTypes: STAT_TYPES, statusOptions: Object.entries(STATUS_MAP).map(([v, o]) => ({ value: +v, label: o.label })),
      showCreate: false, submitting: false,
      form: { taskName: '', statType: 'DESCRIBE', resourceId: '', fields: [], groupField: '', remark: '', preprocessType: 'DATA_STATS' },
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        statType: [{ required: true, message: '请选择统计类型', trigger: 'change' }],
        resourceId: [{ required: true, message: '请选择数据资源', trigger: 'change' }],
        fields: [{ required: true, type: 'array', min: 1, message: '请选择至少一个统计字段', trigger: 'change' }]
      },
      resourceList: [], fieldList: [],
      showView: false, viewRow: {}
    }
  },
  watch: {
    'form.resourceId'(id) { if (id) this.fetchFields(id) }
  },
  created() { this.fetchList(); this.fetchResources() },
  methods: {
    async fetchList() {
      this.loading = true
      try {
        const res = await getPreprocessTaskList(this.query)
        if (res.code === 0) {
          this.list = res.result?.list || []
          this.total = res.result?.total || 0
          this.stats.total = this.total
          this.stats.done = this.list.filter(t => t.taskState === 1).length
          this.stats.running = this.list.filter(t => t.taskState === 2).length
          this.stats.failed = this.list.filter(t => t.taskState === 3).length
        }
      } catch (e) { console.error(e) } finally { this.loading = false }
    },
    async fetchResources() {
      try { const res = await getResourceList({ pageNo: 1, pageSize: 100 }); this.resourceList = res.result?.data || [] } catch (e) { console.error(e) }
    },
    async fetchFields(id) {
      const r = this.resourceList.find(r => r.resourceId === id)
      this.fieldList = r?.fieldNames || ['id', 'name', 'age', 'score', 'amount']
    },
    resetQuery() { this.query = { ...this.query, taskName: '', statType: '', taskState: null, pageNo: 1 }; this.fetchList() },
    resetForm() { this.$refs.form && this.$refs.form.resetFields(); this.form = { taskName: '', statType: 'DESCRIBE', resourceId: '', fields: [], groupField: '', remark: '', preprocessType: 'DATA_STATS' } },
    statTypeLabel(v) { return STAT_TYPES.find(t => t.value === v)?.label || v },
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
        const a = document.createElement('a'); a.href = url; a.download = `${row.taskName}_结果.csv`; a.click()
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

<style scoped>
.app-container { padding: 20px; }
</style>
