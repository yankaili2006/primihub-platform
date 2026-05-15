<template>
  <div class="app-container">
    <el-page-header content="联邦学习数据融合" style="margin-bottom:20px;" @back="$router.go(-1)" />

    <el-alert
      title="数据融合将多个参与方的数据集通过隐私保护协议进行横向或纵向对齐，为后续联邦建模提供统一的样本视图。"
      type="info" show-icon :closable="false" style="margin-bottom:20px;" />

    <el-card>
      <div slot="header" style="display:flex;justify-content:space-between;align-items:center;">
        <span>数据融合任务列表</span>
        <el-button type="primary" icon="el-icon-plus" size="small" @click="showCreate=true">新建融合任务</el-button>
      </div>
      <el-form :inline="true" :model="query" style="margin-bottom:12px;">
        <el-form-item><el-input v-model="query.taskName" placeholder="任务名称" clearable style="width:180px;" /></el-form-item>
        <el-form-item>
          <el-select v-model="query.fusionType" placeholder="融合类型" clearable style="width:140px;">
            <el-option label="纵向融合" value="VERTICAL" />
            <el-option label="横向融合" value="HORIZONTAL" />
          </el-select>
        </el-form-item>
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
        <el-table-column prop="taskName" label="融合任务名称" min-width="180" />
        <el-table-column prop="fusionType" label="融合类型" width="110">
          <template slot-scope="{row}">
            <el-tag :type="row.fusionType==='VERTICAL' ? 'primary' : 'success'" size="small">
              {{ row.fusionType==='VERTICAL' ? '纵向融合' : '横向融合' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="participantCount" label="参与方数" width="90" align="center" />
        <el-table-column prop="sampleCount" label="样本数量" width="110" align="center" />
        <el-table-column prop="featureCount" label="特征维度" width="100" align="center" />
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
            <el-button v-if="row.taskState===1" type="text" size="small" @click="handleUse(row)">用于建模</el-button>
            <el-button type="text" size="small" style="color:#f56c6c;" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:16px;" :current-page="query.pageNo" :page-size="query.pageSize"
        :total="total" layout="total,prev,pager,next" @current-change="p=>{query.pageNo=p;fetchList()}" />
    </el-card>

    <el-dialog title="新建数据融合任务" :visible.sync="showCreate" width="620px" @close="resetForm">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="融合类型" prop="fusionType">
          <el-radio-group v-model="form.fusionType">
            <el-radio label="VERTICAL">
              纵向融合
              <span style="font-size:12px;color:#999;">（各方拥有相同样本ID、不同特征）</span>
            </el-radio>
            <el-radio label="HORIZONTAL">
              横向融合
              <span style="font-size:12px;color:#999;">（各方拥有相同特征、不同样本）</span>
            </el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="参与方" prop="participants">
          <el-select v-model="form.participants" multiple placeholder="请选择参与方" style="width:100%;">
            <el-option label="本机构" value="LOCAL" />
            <el-option label="合作方A" value="PARTY_A" />
            <el-option label="合作方B" value="PARTY_B" />
            <el-option label="合作方C" value="PARTY_C" />
          </el-select>
        </el-form-item>
        <el-form-item label="本机构数据集" prop="localResourceId">
          <el-select v-model="form.localResourceId" placeholder="请选择本机构数据集" style="width:100%;">
            <el-option v-for="r in resourceList" :key="r.resourceId" :label="r.resourceName" :value="r.resourceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="对齐字段（ID）" prop="alignFields">
          <el-select v-model="form.alignFields" multiple placeholder="请选择用于对齐的字段" style="width:100%;">
            <el-option v-for="f in fieldList" :key="f" :label="f" :value="f" />
          </el-select>
        </el-form-item>
        <el-form-item label="对齐协议">
          <el-select v-model="form.alignProtocol" style="width:100%;">
            <el-option label="PSI（隐私集合求交）" value="PSI" />
            <el-option label="OT（不经意传输）" value="OT" />
            <el-option label="同态加密" value="HE" />
          </el-select>
        </el-form-item>
        <el-form-item label="融合后样本策略">
          <el-select v-model="form.samplePolicy" style="width:100%;">
            <el-option label="取交集（仅保留所有方均有的样本）" value="INTERSECT" />
            <el-option label="取并集（保留所有样本，缺失填充）" value="UNION" />
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
  </div>
</template>

<script>
import { getFLPreprocessList, createFLPreprocess, runFLPreprocess, deleteFLPreprocess } from '@/api/federatedLearning'
import { getResourceList } from '@/api/resource'

const STATUS_MAP = { 0: { label: '待执行', type: 'info' }, 1: { label: '已完成', type: 'success' }, 2: { label: '执行中', type: 'warning' }, 3: { label: '执行失败', type: 'danger' } }

export default {
  name: 'FLDataFusion',
  data() {
    return {
      query: { taskName: '', fusionType: '', taskState: null, pageNo: 1, pageSize: 10, preprocessType: 'DATA_FUSION' },
      list: [], total: 0, loading: false,
      showCreate: false, submitting: false,
      form: { taskName: '', fusionType: 'VERTICAL', participants: ['LOCAL'], localResourceId: '', alignFields: [], alignProtocol: 'PSI', samplePolicy: 'INTERSECT', remark: '', preprocessType: 'DATA_FUSION' },
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        fusionType: [{ required: true, trigger: 'change' }],
        participants: [{ required: true, type: 'array', min: 2, message: '请选择至少2个参与方', trigger: 'change' }],
        localResourceId: [{ required: true, message: '请选择本机构数据集', trigger: 'change' }],
        alignFields: [{ required: true, type: 'array', min: 1, message: '请选择对齐字段', trigger: 'change' }]
      },
      resourceList: [], fieldList: ['user_id', 'phone', 'id_card', 'order_id']
    }
  },
  created() { this.fetchList(); this.fetchResources() },
  methods: {
    stateLabel(v) { return STATUS_MAP[v]?.label || '未知' },
    stateTag(v) { return STATUS_MAP[v]?.type || 'info' },
    async fetchList() {
      this.loading = true
      try { const res = await getFLPreprocessList(this.query); if (res.code === 0) { this.list = res.result?.list || []; this.total = res.result?.total || 0 } } catch (e) { console.error(e) } finally { this.loading = false }
    },
    async fetchResources() {
      try { const res = await getResourceList({ pageNo: 1, pageSize: 100 }); this.resourceList = res.result?.data || [] } catch (e) { console.error(e) }
    },
    resetQuery() { this.query = { ...this.query, taskName: '', fusionType: '', taskState: null, pageNo: 1 }; this.fetchList() },
    resetForm() { this.$refs.form && this.$refs.form.resetFields() },
    handleView(row) { this.$message.info(`查看融合任务: ${row.taskName}`) },
    async handleRun(row) {
      try { const res = await runFLPreprocess({ taskId: row.taskId }); if (res.code === 0) { this.$message.success('融合任务已提交执行'); this.fetchList() } else this.$message.error(res.message || '执行失败') } catch (e) { this.$message.error('请求异常') }
    },
    handleUse(row) { this.$router.push({ path: '/federatedLearning/index', query: { fusionTaskId: row.taskId } }) },
    async handleDelete(row) {
      try { await this.$confirm(`确认删除融合任务「${row.taskName}」？`, '提示', { type: 'warning' }); const res = await deleteFLPreprocess({ taskId: row.taskId }); if (res.code === 0) { this.$message.success('已删除'); this.fetchList() } else this.$message.error(res.message) } catch (e) { if (e !== 'cancel') this.$message.error('操作失败') }
    },
    handleSubmit() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.submitting = true
        try { const res = await createFLPreprocess(this.form); if (res.code === 0) { this.$message.success('融合任务创建成功'); this.showCreate = false; this.fetchList() } else this.$message.error(res.message || '创建失败') } catch (e) { this.$message.error('请求异常') } finally { this.submitting = false }
      })
    }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
