<template>
  <div class="app-container">
    <el-page-header content="联邦学习数据融合" style="margin-bottom:20px;" @back="$router.go(-1)" />

    <el-alert
      title="横向融合由真实联邦求并引擎执行（两方样本并集，gRPC 派发至隐私计算节点）；纵向融合请使用『特征对齐』功能。"
      type="info" show-icon :closable="false" style="margin-bottom:20px;" />

    <el-card>
      <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
        <span>数据融合任务列表</span>
        <el-button type="primary" icon="el-icon-plus" size="small" @click="showCreate=true">新建融合任务</el-button>
      </div>
      <el-form :inline="true" :model="query" style="margin-bottom:12px;">
        <el-form-item><el-input v-model="query.taskName" placeholder="任务名称" clearable style="width:180px;" /></el-form-item>
        <el-form-item>
          <el-select v-model="query.taskState" placeholder="任务状态" clearable style="width:120px;">
            <el-option label="待执行" :value="0" />
            <el-option label="执行中" :value="2" />
            <el-option label="已完成" :value="1" />
            <el-option label="执行失败" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchList">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
      <el-table v-loading="loading" :data="list" border>
        <el-table-column type="index" width="50" label="序号" />
        <el-table-column prop="taskName" label="融合任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="resourceName" label="本方数据集" width="130" show-overflow-tooltip />
        <el-table-column prop="taskState" label="状态" width="100">
          <template slot-scope="{row}">
            <el-tag :type="stateTag(row.taskState)" size="small">{{ stateLabel(row.taskState) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="errorMsg" label="失败原因" min-width="160" show-overflow-tooltip />
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" width="220" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="row.taskState===0" type="text" size="small" @click="handleRun(row)">执行</el-button>
            <el-button v-if="row.taskState===1" type="text" size="small" @click="handleDownload(row)">下载结果</el-button>
            <el-button v-if="row.taskState===1" type="text" size="small" @click="handleUse(row)">用于建模</el-button>
            <el-button type="text" size="small" style="color:#f56c6c;" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:16px;" :current-page="query.pageNo" :page-size="query.pageSize"
        :total="total" layout="total,prev,pager,next" @current-change="p=>{query.pageNo=p;fetchList()}" />
    </el-card>

    <el-dialog title="新建数据融合任务" :visible.sync="showCreate" width="640px" @close="resetForm">
      <el-form ref="form" :model="form" :rules="rules" label-width="130px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" placeholder="请输入任务名称" @blur="autoFillResultName" />
        </el-form-item>
        <el-form-item label="融合类型" prop="fusionType">
          <el-radio-group v-model="form.fusionType">
            <el-radio label="HORIZONTAL">
              横向融合
              <span class="opt-tip">（各方拥有相同特征、不同样本，取样本并集）</span>
            </el-radio>
            <el-radio label="VERTICAL">
              纵向融合
              <span class="opt-tip">（相同样本ID、不同特征，请使用『特征对齐』）</span>
            </el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="协作方" prop="otherOrganId">
          <el-select v-model="form.otherOrganId" placeholder="请选择协作方机构" style="width:100%;" @change="onOtherOrganChange">
            <el-option v-for="o in organList" :key="o.globalId" :label="o.globalName" :value="o.globalId" />
          </el-select>
        </el-form-item>
        <el-form-item label="本机构数据集" prop="ownResourceId">
          <el-select v-model="form.ownResourceId" filterable placeholder="请选择本机构数据集" style="width:100%;" @change="onOwnResourceChange">
            <el-option v-for="r in ownResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="本方关联字段" prop="ownKeyword">
          <el-select v-model="form.ownKeyword" placeholder="请选择本方用于并集对齐的字段" style="width:100%;">
            <el-option v-for="f in ownFieldList" :key="f.fieldName" :label="f.fieldName" :value="f.fieldName" />
          </el-select>
        </el-form-item>
        <el-form-item label="协作方数据集" prop="otherResourceId">
          <el-select v-model="form.otherResourceId" filterable placeholder="请先选择协作方，再选其数据集" style="width:100%;" @change="onOtherResourceChange">
            <el-option v-for="r in otherResourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="协作方关联字段" prop="otherKeyword">
          <el-select v-model="form.otherKeyword" placeholder="请选择协作方用于并集对齐的字段" style="width:100%;">
            <el-option v-for="f in otherFieldList" :key="f.fieldName" :label="f.fieldName" :value="f.fieldName" />
          </el-select>
        </el-form-item>
        <el-form-item label="结果名称" prop="resultName">
          <el-input v-model="form.resultName" placeholder="融合结果资源名称" />
        </el-form-item>
        <el-form-item label="结果获取方">
          <el-checkbox :value="true" disabled>本机构 (发起方)</el-checkbox>
          <el-checkbox v-model="includeOther" :disabled="!form.otherOrganId">协作方</el-checkbox>
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
  </div>
</template>

<script>
import { getFLPreprocessList, createFLPreprocess, runFLPreprocess, deleteFLPreprocess, downloadFLPreprocessResult } from '@/api/federatedLearning'
import { getResourceList } from '@/api/fusionResource'
import { getAvailableOrganList } from '@/api/center'

const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'FLDataFusion',
  data() {
    return {
      query: { taskName: '', taskState: null, pageNo: 1, pageSize: 10, preprocessType: 'DATA_FUSION' },
      list: [], total: 0, loading: false,
      showCreate: false, submitting: false, includeOther: false,
      organList: [], ownResourceList: [], otherResourceList: [],
      ownFieldList: [], otherFieldList: [],
      form: {
        taskName: '', fusionType: 'HORIZONTAL',
        otherOrganId: '', ownResourceId: '', ownKeyword: '',
        otherResourceId: '', otherKeyword: '', resultName: '', remark: '',
        preprocessType: 'DATA_FUSION'
      },
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        fusionType: [{ required: true, trigger: 'change' }],
        otherOrganId: [{ required: true, message: '请选择协作方', trigger: 'change' }],
        ownResourceId: [{ required: true, message: '请选择本机构数据集', trigger: 'change' }],
        ownKeyword: [{ required: true, message: '请选择本方关联字段', trigger: 'change' }],
        otherResourceId: [{ required: true, message: '请选择协作方数据集', trigger: 'change' }],
        otherKeyword: [{ required: true, message: '请选择协作方关联字段', trigger: 'change' }],
        resultName: [{ required: true, message: '请输入结果名称', trigger: 'blur' }]
      }
    }
  },
  created() {
    this.fetchList()
    this.loadOrgans()
    this.loadOwnResources()
  },
  methods: {
    stateLabel(v) { return STATUS_MAP[v]?.label || '未知' },
    stateTag(v) { return STATUS_MAP[v]?.type || 'info' },
    autoFillResultName() {
      if (!this.form.resultName && this.form.taskName) this.form.resultName = this.form.taskName + '_融合结果'
    },
    async loadOrgans() {
      try {
        const res = await getAvailableOrganList()
        if (res.code === 0) this.organList = res.result || []
      } catch (e) { console.error(e) }
    },
    async loadOwnResources() {
      try {
        const res = await getResourceList({ pageNo: 1, pageSize: 100, organId: this.$store.getters.userOrganId })
        if (res.code === 0) this.ownResourceList = res.result?.data || []
      } catch (e) { console.error(e) }
    },
    async onOtherOrganChange(organId) {
      this.form.otherResourceId = ''
      this.form.otherKeyword = ''
      this.otherFieldList = []
      this.otherResourceList = []
      if (!organId) return
      try {
        const res = await getResourceList({ pageNo: 1, pageSize: 100, organId })
        if (res.code === 0) this.otherResourceList = res.result?.data || []
      } catch (e) { console.error(e) }
    },
    onOwnResourceChange(id) {
      const r = this.ownResourceList.find(x => x.resourceId === id)
      this.ownFieldList = (r && r.fieldList) || []
      this.form.ownKeyword = ''
    },
    onOtherResourceChange(id) {
      const r = this.otherResourceList.find(x => x.resourceId === id)
      this.otherFieldList = (r && r.fieldList) || []
      this.form.otherKeyword = ''
    },
    async fetchList() {
      this.loading = true
      try {
        const res = await getFLPreprocessList(this.query)
        if (res.code === 0) { this.list = res.result?.list || []; this.total = res.result?.total || 0 }
      } catch (e) { console.error(e) } finally { this.loading = false }
    },
    resetQuery() { this.query = { ...this.query, taskName: '', taskState: null, pageNo: 1 }; this.fetchList() },
    resetForm() {
      this.$refs.form && this.$refs.form.resetFields()
      this.includeOther = false
      this.ownFieldList = []
      this.otherFieldList = []
      this.otherResourceList = []
    },
    async handleRun(row) {
      try {
        const res = await runFLPreprocess({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success(res.result || '任务执行成功'); this.fetchList() } else { this.$message.error(res.message || '执行失败'); this.fetchList() }
      } catch (e) { this.$message.error('请求异常') }
    },
    async handleDownload(row) {
      try {
        const res = await downloadFLPreprocessResult({ taskId: row.taskId })
        const url = URL.createObjectURL(new Blob([res]))
        const a = document.createElement('a')
        a.href = url
        a.download = `data_fusion_${row.taskId}.csv`
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('下载失败') }
    },
    handleUse(row) { this.$router.push({ path: '/federatedLearning/index', query: { fusionTaskId: row.taskId } }) },
    async handleDelete(row) {
      try {
        await this.$confirm(`确认删除融合任务「${row.taskName}」？`, '提示', { type: 'warning' })
        const res = await deleteFLPreprocess({ taskId: row.taskId })
        if (res.code === 0) { this.$message.success('已删除'); this.fetchList() } else this.$message.error(res.message)
      } catch (e) { if (e !== 'cancel') this.$message.error('操作失败') }
    },
    handleSubmit() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        if (this.form.fusionType === 'VERTICAL') {
          this.$message.warning('纵向融合需 PSI 对齐，请使用『特征对齐』功能')
          return
        }
        this.submitting = true
        try {
          const ownOrganId = this.$store.getters.userOrganId
          const ownResource = this.ownResourceList.find(r => r.resourceId === this.form.ownResourceId)
          const resultOrganIds = this.includeOther && this.form.otherOrganId
            ? `${ownOrganId},${this.form.otherOrganId}` : `${ownOrganId}`
          const res = await createFLPreprocess({
            ...this.form,
            ownOrganId,
            resourceId: this.form.ownResourceId,
            resourceName: ownResource ? ownResource.resourceName : '',
            resultOrganIds,
            tag: 0
          })
          if (res.code === 0) { this.$message.success('融合任务创建成功'); this.showCreate = false; this.fetchList() } else this.$message.error(res.message || '创建失败')
        } catch (e) { this.$message.error('请求异常') } finally { this.submitting = false }
      })
    }
  }
}
</script>
<style scoped>
.app-container { padding: 20px; }
.opt-tip { font-size: 12px; color: #999; }
</style>
